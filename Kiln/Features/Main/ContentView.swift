import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            background
                .allowsHitTesting(false)
            if model.workspace == .units {
                UnitsView(model: model.units)
            } else if model.items.isEmpty {
                DropZoneView(model: model)
                    .onDrop(of: [.fileURL], isTargeted: $model.isDropTargeted, perform: handleDrop)
            } else {
                HStack(spacing: 0) {
                    QueueView(model: model)
                        .onDrop(of: [.fileURL], isTargeted: $model.isDropTargeted, perform: handleDrop)
                    InspectorView(model: model)
                }
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.16) : KilnTheme.spring, value: model.items.isEmpty)
        .animation(reduceMotion ? .easeInOut(duration: 0.16) : KilnTheme.spring, value: model.units.sidebarVisible)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker(selection: $model.workspace) {
                    ForEach(WorkspaceMode.allCases) { mode in
                        Text(LocalizedStringKey(mode.localizationKey)).tag(mode)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .frame(minWidth: 280)
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
                    .controlSize(.large)
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
                .controlSize(.large)
                .help(Text("drop.browse"))

                Button {
                    model.settingsPresented = true
                } label: {
                    Label {
                        Text("action.settings")
                    } icon: {
                        Image(systemName: "gearshape")
                    }
                }
                .controlSize(.large)
                .help(Text("action.settings"))
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
        .sheet(isPresented: $model.settingsPresented) {
            SettingsView(model: model, showsDone: true) {
                model.settingsPresented = false
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

    private var background: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                KilnTheme.ember.opacity(0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
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
            let type = [UTType.fileURL.identifier, "public.file-url"]
                .first { provider.hasItemConformingToTypeIdentifier($0) }
                ?? UTType.fileURL.identifier
            provider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in
                guard let url = FileImport.resolveProviderItem(item) else { return }
                let owned = FileImport.claim([url], into: inbox)
                guard !owned.isEmpty else { return }
                DispatchQueue.main.async {
                    onMain(owned)
                }
            }
        }
    }
}
