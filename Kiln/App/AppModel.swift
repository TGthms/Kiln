import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications
import QuickLookThumbnailing

enum QueueStatus: Equatable, Sendable {
    case ready
    case converting
    case done
    case failed
    case unsupported

    var localizationKey: String {
        switch self {
        case .ready: return "status.ready"
        case .converting: return "status.converting"
        case .done: return "status.done"
        case .failed: return "status.failed"
        case .unsupported: return "status.unsupported"
        }
    }
}

struct QueueItem: Identifiable, Equatable {
    let id: UUID
    var url: URL
    var format: Format?
    var status: QueueStatus
    var destinationID: String?
    var outputURL: URL?
    var inputBytes: Int64
    var outputBytes: Int64?
    var message: String?
    var progress: Double
    var thumbnail: NSImage?

    init(url: URL, format: Format?) {
        self.id = UUID()
        self.url = url
        self.format = format
        self.status = format == nil ? .unsupported : .ready
        self.destinationID = nil
        self.outputURL = nil
        self.inputBytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        self.outputBytes = nil
        self.message = format == nil ? L10n.string("error.unsupported") : nil
        self.progress = 0
        self.thumbnail = nil
    }
}

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var items: [QueueItem] = []
    @Published var selection: UUID?
    @Published var mode: ConversionMode = .convert
    @Published var preset: KilnPreset = .original
    @Published var quality: Double = 0.85
    @Published var maxDimension: Int? = nil
    @Published var stripMetadata: Bool = false
    @Published var destinationFormatID: String?
    @Published var settings: AppSettings
    @Published var isDropTargeted = false
    @Published var settingsPresented = false
    @Published var isRunning = false
    @Published var standingFolder: URL?
    @Published var workspace: WorkspaceMode = .files

    let service = ConversionService()
    let units = UnitsModel()
    private var runTask: Task<Void, Never>?
    private var accessURLs: [URL] = []

    init() {
        settings = SettingsStore.load()
        units.autoRefreshEnabled = settings.currencyAutoRefresh
        quality = preset.quality
        maxDimension = preset.maxDimension
        stripMetadata = preset.stripMetadata
        if let data = settings.lastFolderBookmark {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale),
               url.startAccessingSecurityScopedResource() {
                standingFolder = url
                accessURLs.append(url)
            }
        }
    }

    var selectedItem: QueueItem? {
        items.first(where: { $0.id == selection }) ?? items.first
    }

    var runnableItems: [QueueItem] {
        items.filter { $0.status != .unsupported }
    }

    var availableDestinations: [Format] {
        service.destinations(for: runnableItems.map(\.url), mode: mode)
    }

    var groupedDestinations: [(FormatFamily, [Format])] {
        let dests = availableDestinations
        return FormatFamily.allCases.compactMap { family in
            let list = dests.filter { $0.family == family }
            return list.isEmpty ? nil : (family, list)
        }
    }

    var canRun: Bool {
        ConversionReadiness.canStart(
            runnableCount: runnableItems.count,
            destinationID: destinationFormatID,
            mode: mode,
            isRunning: isRunning
        )
    }

    func importURLs(_ urls: [URL]) {
        let prepared = FileImport.ingest(
            urls: urls,
            already: items.map(\.url),
            inbox: FileImport.defaultInbox(),
            identify: { url in
                service.identify(url: url)
            }
        )
        var added: [QueueItem] = []
        for pair in prepared {
            if pair.url.startAccessingSecurityScopedResource() {
                accessURLs.append(pair.url)
            }
            let item = QueueItem(url: pair.url, format: pair.format)
            added.append(item)
            loadThumbnail(for: item.id, url: pair.url)
        }
        items.append(contentsOf: added)
        if selection == nil {
            selection = items.first?.id
        }
        if !added.isEmpty {
            workspace = .files
        }
        reconcileDestination()
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        if selection == id {
            selection = items.first?.id
        }
        reconcileDestination()
    }

    func clear() {
        items.removeAll()
        selection = nil
        destinationFormatID = nil
    }

    func apply(preset: KilnPreset) {
        self.preset = preset
        quality = preset.quality
        maxDimension = preset.maxDimension
        stripMetadata = preset.stripMetadata
        if preset == .shareJPEG, availableDestinations.contains(where: { $0.id == "jpeg" }) {
            destinationFormatID = "jpeg"
        }
    }

    func reconcileDestination() {
        let dests = availableDestinations
        if mode == .combine {
            let preferred = destinationFormatID == "zip" ? "zip" : "pdf"
            if dests.contains(where: { $0.id == preferred }) {
                destinationFormatID = preferred
                return
            }
        }
        if let current = destinationFormatID, dests.contains(where: { $0.id == current }) {
            return
        }
        if let family = runnableItems.first?.format?.family,
           let remembered = settings.lastFormat(for: family),
           dests.contains(where: { $0.id == remembered }) {
            destinationFormatID = remembered
            return
        }
        destinationFormatID = dests.first?.id
    }

    func previewSelection() {
        let url = selectedItem?.outputURL ?? selectedItem?.url
        guard let url else { return }
        QuickLookPreview.shared.show(url: url)
    }

    func run() {
        guard !isRunning else { return }
        isRunning = true
        let mode = self.mode
        let destID = destinationFormatID
        let quality = self.quality
        let maxDimension = self.maxDimension
        let strip = stripMetadata
        runTask = Task { [weak self] in
            guard let self else { return }
            do {
                let directory = try await self.resolveDestinationDirectory()
                switch mode {
                case .combine:
                    try await self.runCombine(directory: directory, destID: destID, quality: quality, maxDimension: maxDimension, strip: strip)
                case .split:
                    try await self.runSplit(directory: directory, destID: destID, quality: quality, maxDimension: maxDimension, strip: strip)
                case .convert, .compress:
                    try await self.runPerFile(mode: mode, directory: directory, destID: destID, quality: quality, maxDimension: maxDimension, strip: strip)
                }
            } catch {
                if let idx = items.indices.first(where: { items[$0].status == .converting }) {
                    items[idx].status = .failed
                    items[idx].message = error.localizedDescription
                }
            }
            isRunning = false
            if settings.notifyOnComplete {
                notifyDone()
            }
        }
    }

    func cancel() {
        runTask?.cancel()
        runTask = nil
        isRunning = false
        for i in items.indices where items[i].status == .converting {
            items[i].status = .ready
            items[i].progress = 0
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func browse() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.begin { [weak self] result in
            guard result == .OK else { return }
            Task { @MainActor in
                self?.importURLs(panel.urls)
            }
        }
    }

    func persistSettings() {
        SettingsStore.save(settings)
    }

    private func runPerFile(
        mode: ConversionMode,
        directory: URL,
        destID: String?,
        quality: Double,
        maxDimension: Int?,
        strip: Bool
    ) async throws {
        for index in items.indices {
            if Task.isCancelled { return }
            if items[index].status == .unsupported { continue }
            items[index].status = .converting
            items[index].progress = 0.15
            let url = items[index].url
            let spec = OutputSpec(
                mode: mode,
                formatID: destID,
                quality: quality,
                maxDimension: maxDimension,
                stripMetadata: strip,
                destinationDirectory: directory
            )
            do {
                let output: URL
                if mode == .compress {
                    output = try service.compress(input: url, spec: spec)
                } else {
                    guard let destID else { throw KilnError.missingDestination }
                    output = try service.convert(input: url, to: destID, spec: spec)
                    if let family = items[index].format?.family {
                        settings.remember(formatID: destID, family: family)
                        persistSettings()
                    }
                }
                items[index].outputURL = output
                items[index].outputBytes = (try? output.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
                items[index].status = .done
                items[index].progress = 1
                items[index].message = nil
            } catch {
                items[index].status = .failed
                items[index].message = error.localizedDescription
            }
        }
    }

    private func runCombine(directory: URL, destID: String?, quality: Double, maxDimension: Int?, strip: Bool) async throws {
        let urls = runnableItems.map(\.url)
        for i in items.indices where items[i].status != .unsupported {
            items[i].status = .converting
        }
        let spec = OutputSpec(
            mode: .combine,
            formatID: destID ?? "pdf",
            quality: quality,
            maxDimension: maxDimension,
            stripMetadata: strip,
            destinationDirectory: directory
        )
        let output = try service.combine(inputs: urls, spec: spec)
        let size = (try? output.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
        if let first = items.firstIndex(where: { $0.status != .unsupported }) {
            items[first].outputURL = output
            items[first].outputBytes = size
            items[first].status = .done
            items[first].progress = 1
        }
        for i in items.indices where items[i].status == .converting {
            items[i].status = .done
            items[i].progress = 1
        }
    }

    private func runSplit(directory: URL, destID: String?, quality: Double, maxDimension: Int?, strip: Bool) async throws {
        for index in items.indices {
            if items[index].status == .unsupported { continue }
            items[index].status = .converting
            let spec = OutputSpec(
                mode: .split,
                formatID: destID ?? "pdf",
                quality: quality,
                maxDimension: maxDimension,
                stripMetadata: strip,
                destinationDirectory: directory
            )
            do {
                let outs = try service.split(input: items[index].url, spec: spec)
                items[index].outputURL = outs.first
                let total = outs.compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }.reduce(0, +)
                items[index].outputBytes = Int64(total)
                items[index].status = .done
                items[index].progress = 1
            } catch {
                items[index].status = .failed
                items[index].message = error.localizedDescription
            }
        }
    }

    private func resolveDestinationDirectory() async throws -> URL {
        switch settings.destination {
        case .downloads:
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        case .choose:
            if let standingFolder { return standingFolder }
            return try await pickFolder()
        case .sameFolder:
            if let parent = runnableItems.first?.url.deletingLastPathComponent() {
                if FileManager.default.isWritableFile(atPath: parent.path) {
                    return parent
                }
                if let standingFolder, standingFolder.path == parent.path {
                    return standingFolder
                }
                return try await pickFolder(starting: parent)
            }
            throw KilnError.missingDestination
        }
    }

    private func pickFolder(starting: URL? = nil) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.prompt = L10n.string("settings.destination.choose", locale: settings.locale)
            panel.message = L10n.string("error.write_permission", locale: settings.locale)
            if let starting { panel.directoryURL = starting }
            panel.begin { [weak self] result in
                guard result == .OK, let url = panel.url else {
                    continuation.resume(throwing: KilnError.missingDestination)
                    return
                }
                _ = url.startAccessingSecurityScopedResource()
                Task { @MainActor in
                    self?.standingFolder = url
                    self?.accessURLs.append(url)
                    if let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                        self?.settings.lastFolderBookmark = data
                        self?.persistSettings()
                    }
                    continuation.resume(returning: url)
                }
            }
        }
    }

    private func loadThumbnail(for id: UUID, url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: 120, height: 120), scale: 2, representationTypes: .thumbnail)
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { [weak self] representation, _, _ in
            guard let image = representation?.nsImage else { return }
            Task { @MainActor in
                if let idx = self?.items.firstIndex(where: { $0.id == id }) {
                    self?.items[idx].thumbnail = image
                }
            }
        }
    }

    private func notifyDone() {
        let content = UNMutableNotificationContent()
        content.title = "Kiln"
        content.body = L10n.string("done.ok", locale: settings.locale)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
