import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Group {
            if model.workspace == .units {
                UnitsView(model: model.units)
            } else if model.items.isEmpty {
                DropZoneView(model: model)
                    .onDrop(of: [.fileURL], isTargeted: $model.isDropTargeted, perform: handleDrop)
            } else {
                NavigationSplitView {
                    QueueView(model: model)
                        .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 400)
                } detail: {
                    InspectorView(model: model)
                }
                .onDrop(of: [.fileURL], isTargeted: $model.isDropTargeted, perform: handleDrop)
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : KilnTheme.spring, value: model.items.isEmpty)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : KilnTheme.spring, value: model.units.sidebarVisible)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker(selection: $model.workspace) {
                    ForEach(WorkspaceMode.allCases) { mode in
                        Text(LocalizedStringKey(mode.localizationKey)).tag(mode)
                    }
                } label: {
                    Text("workspace.files")
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 200)
                .accessibilityLabel(Text("workspace.files"))
            }
            ToolbarItemGroup(placement: .primaryAction) {
                if model.workspace == .units {
                    Button {
                        model.units.sidebarVisible.toggle()
                    } label: {
                        Label {
                            Text("units.sidebar")
                        } icon: {
                            Image(systemName: "sidebar.leading")
                        }
                    }
                    .help(Text("units.sidebar"))
                    .accessibilityLabel(Text("units.sidebar"))
                }

                if model.workspace == .files {
                    Button {
                        model.browse()
                    } label: {
                        Label {
                            Text("action.add")
                        } icon: {
                            Image(systemName: "plus")
                        }
                    }
                    .help(Text("action.add"))
                    .accessibilityLabel(Text("action.add"))
                    .accessibilityHint(Text("drop.subtitle"))

                    Button {
                        if model.isRunning {
                            model.cancel()
                        } else {
                            model.run()
                        }
                    } label: {
                        Label {
                            Text(LocalizedStringKey(model.isRunning ? "action.cancel" : model.mode.actionKey))
                        } icon: {
                            Image(systemName: model.isRunning ? "stop.fill" : "play.fill")
                        }
                    }
                    .disabled(!model.canRun && !model.isRunning)
                    .help(Text(LocalizedStringKey(model.mode.actionKey)))
                    .accessibilityLabel(Text(LocalizedStringKey(model.mode.actionKey)))
                    .accessibilityValue(Text("\(model.itemsToProcess.count)"))
                    .keyboardShortcut(.return, modifiers: [.command])
                }

                Button {
                    openSettings()
                } label: {
                    Label {
                        Text("action.settings")
                    } icon: {
                        Image(systemName: "gearshape")
                    }
                }
                .help(Text("action.settings"))
                .accessibilityLabel(Text("action.settings"))
            }
        }
        .onDeleteCommand {
            model.removeSelected()
        }
        .onKeyPress(.space) {
            guard model.workspace == .files else { return .ignored }
            model.previewSelection()
            return .handled
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        DropImport.enqueue(providers) { urls in
            model.importURLs(urls)
        }
        return true
    }
}

enum DropImport {
    /// Copy each dropped file into the inbox **on the provider callback thread**,
    /// then hop to the main actor with only those copies.
    static func enqueue(_ providers: [NSItemProvider], onMain: @escaping @MainActor ([URL]) -> Void) {
        let inbox = FileImport.defaultInbox()
        for provider in providers {
            deliver(provider, inbox: inbox, onMain: onMain)
        }
    }

    private static func isExplicitFolder(_ provider: NSItemProvider) -> Bool {
        let folder = provider.hasItemConformingToTypeIdentifier(UTType.folder.identifier)
            || provider.hasItemConformingToTypeIdentifier(UTType.directory.identifier)
        guard folder else { return false }
        return !FileImport.looksLikeFileName(provider.suggestedName)
    }

    private static func deliver(
        _ provider: NSItemProvider,
        inbox: URL,
        onMain: @escaping @MainActor ([URL]) -> Void
    ) {
        let suggested = provider.suggestedName
        let folderDrop = isExplicitFolder(provider)
        let finish: (URL) -> Void = { url in
            let target = FileImport.narrowToDroppedFile(url, suggestedName: suggested)
            let intent: FileImport.Intent = folderDrop ? .allowFolders : .filesOnly
            let owned = FileImport.claim([target], into: inbox, intent: intent, suggestedName: suggested)
            guard !owned.isEmpty else { return }
            Task { @MainActor in
                onMain(owned)
            }
        }

        if folderDrop {
            loadItem(provider, finish: finish)
            return
        }

        let fileType = provider.registeredTypeIdentifiers.first { id in
            id != UTType.folder.identifier && id != UTType.directory.identifier
        } ?? UTType.item.identifier
        provider.loadFileRepresentation(forTypeIdentifier: fileType) { url, _ in
            if let url {
                finish(url)
                return
            }
            loadItem(provider, finish: finish)
        }
    }

    private static func loadItem(_ provider: NSItemProvider, finish: @escaping (URL) -> Void) {
        let type = [UTType.fileURL.identifier, "public.file-url"]
            .first { provider.hasItemConformingToTypeIdentifier($0) }
            ?? UTType.fileURL.identifier
        provider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in
            guard let url = FileImport.resolveProviderItem(item) else { return }
            finish(url)
        }
    }
}
