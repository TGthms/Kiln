import Foundation
import UniformTypeIdentifiers

enum FileImport {
    static func identityKey(for url: URL) -> String {
        url.standardizedFileURL.path
    }

    static func uniqueNew(urls: [URL], already: [URL]) -> [URL] {
        collectFiles(from: urls, already: already)
    }

    static func defaultInbox() -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = root.appendingPathComponent("Kiln/Inbox", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Copy `url` into `inbox` while any security scope is still valid.
    /// Returns a sandbox-owned file the rest of the app can read later.
    static func adoptIncoming(_ url: URL, into inbox: URL) -> URL? {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        let stem = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var dest = inbox.appendingPathComponent(url.lastPathComponent)
        var n = 2
        while FileManager.default.fileExists(atPath: dest.path) {
            let name = ext.isEmpty ? "\(stem) \(n)" : "\(stem) \(n).\(ext)"
            dest = inbox.appendingPathComponent(name)
            n += 1
        }
        do {
            try FileManager.default.copyItem(at: url, to: dest)
            return dest
        } catch {
            if FileManager.default.isReadableFile(atPath: url.path) {
                return url.standardizedFileURL
            }
            return nil
        }
    }

    /// Flatten folders, copy each file into `inbox`, then identify. Safe after the drop callback returns.
    static func ingest(
        urls: [URL],
        already: [URL],
        inbox: URL,
        identify: (URL) -> Format?
    ) -> [(url: URL, format: Format?)] {
        let collected = collectFiles(from: urls, already: [])
        var adopted: [URL] = []
        for url in collected {
            if let safe = adoptIncoming(url, into: inbox) {
                adopted.append(safe)
            }
        }
        return prepare(urls: adopted, already: already, identify: identify)
    }

    /// Iterative flatten. Never recurses, so a deep or cyclic folder cannot blow the stack.
    static func collectFiles(
        from urls: [URL],
        already: [URL],
        maxDepth: Int = 6,
        maxCount: Int = 400
    ) -> [URL] {
        var seen = Set(already.map(identityKey(for:)))
        var result: [URL] = []
        var stack: [(URL, Int)] = urls.reversed().map { ($0, 0) }
        let fm = FileManager.default
        while let (url, depth) = stack.popLast() {
            if result.count >= maxCount { break }
            let key = identityKey(for: url)
            if seen.contains(key) { continue }

            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: url.path, isDirectory: &isDir)
            if exists && isDir.boolValue {
                seen.insert(key)
                guard depth < maxDepth else { continue }
                let kids = (try? fm.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )) ?? []
                for kid in kids where kid.lastPathComponent != ".DS_Store" {
                    stack.append((kid, depth + 1))
                }
                continue
            }
            seen.insert(key)
            result.append(url.standardizedFileURL)
        }
        return result
    }

    /// Resolve an NSItemProvider / pasteboard payload to a file URL. Never throws.
    static func resolveProviderItem(_ item: Any?) -> URL? {
        if let url = item as? URL { return url }
        if let url = item as? NSURL { return url as URL }
        if let data = item as? Data {
            if let url = URL(dataRepresentation: data, relativeTo: nil) { return url }
            if let text = String(data: data, encoding: .utf8) {
                return urlFromText(text)
            }
        }
        if let text = item as? String { return urlFromText(text) }
        if let text = item as? NSString { return urlFromText(text as String) }
        return nil
    }

    static func prepare(
        urls: [URL],
        already: [URL],
        identify: (URL) -> Format?
    ) -> [(url: URL, format: Format?)] {
        collectFiles(from: urls, already: already).map { url in
            (url, identify(url))
        }
    }

    private static func urlFromText(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("file:"), let url = URL(string: trimmed) { return url }
        if trimmed.hasPrefix("/") { return URL(fileURLWithPath: trimmed) }
        return nil
    }
}

enum ConversionReadiness {
    static func canStart(
        runnableCount: Int,
        destinationID: String?,
        mode: ConversionMode,
        isRunning: Bool
    ) -> Bool {
        guard !isRunning, runnableCount > 0 else { return false }
        switch mode {
        case .compress:
            return true
        case .convert, .combine, .split:
            return destinationID != nil
        }
    }
}
