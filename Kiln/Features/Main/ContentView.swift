import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            background
            if model.workspace == .units {
                UnitsView(model: model.units)
            } else if model.items.isEmpty {
                DropZoneView(model: model)
            } else {
                HStack(spacing: 0) {
                    QueueView(model: model)
                    InspectorView(model: model)
                }
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.16) : KilnTheme.spring, value: model.items.isEmpty)
        .animation(reduceMotion ? .easeInOut(duration: 0.16) : KilnTheme.spring, value: model.units.sidebarVisible)
        .onDrop(of: [.fileURL], isTargeted: $model.isDropTargeted) { providers in
            handleDrop(providers)
            return true
        }
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
        .focusable()
        .onDeleteCommand {
            if let id = model.selection {
                model.remove(id)
            }
        }
        .onKeyPress(.space) {
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

    /// Load file URLs only via `loadItem`. `loadObject(URL)` plus a later MainActor hop
    /// lets the security scope expire and has crashed the app on drop.
    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            let type = [UTType.fileURL.identifier, "public.file-url"]
                .first { provider.hasItemConformingToTypeIdentifier($0) }
                ?? UTType.fileURL.identifier
            provider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in
                guard let url = FileImport.resolveProviderItem(item) else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                let path = url.path
                DispatchQueue.main.async {
                    let imported: URL
                    if accessed {
                        imported = url
                    } else {
                        imported = URL(fileURLWithPath: path)
                    }
                    model.importURLs([imported])
                }
            }
        }
    }
}
