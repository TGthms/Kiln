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
                }

                Button {
                    model.browse()
                } label: {
                    Label {
                        Text("drop.browse")
                    } icon: {
                        Image(systemName: "folder")
                    }
                }
                .help(Text("drop.browse"))

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
            }
        }
        .onDeleteCommand {
            if let id = model.selection {
                model.remove(id)
            }
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

    private static func deliver(
        _ provider: NSItemProvider,
        inbox: URL,
        onMain: @escaping @MainActor ([URL]) -> Void
    ) {
        let suggested = provider.suggestedName
        let finish: (URL) -> Void = { url in
            let target = FileImport.narrowToDroppedFile(url, suggestedName: suggested)
            let owned = FileImport.claim([target], into: inbox)
            guard !owned.isEmpty else { return }
            Task { @MainActor in
                onMain(owned)
            }
        }

        if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url {
                    finish(url)
                    return
                }
                loadItem(provider, finish: finish)
            }
            return
        }
        loadItem(provider, finish: finish)
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
