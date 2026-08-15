import SwiftUI

@main
struct KilnApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var model = AppModel.shared

    var body: some Scene {
        Window("Kiln", id: "main") {
            ContentView(model: model)
                .frame(minWidth: 780, minHeight: 520)
                .environment(\.locale, model.settings.locale)
                .environment(\.layoutDirection, model.settings.layoutDirection)
                .preferredColorScheme(model.settings.appearance.colorScheme)
        }
        .windowToolbarStyle(.unified)
        .defaultSize(width: 980, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button {
                    model.browse()
                } label: {
                    Text("action.add")
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            CommandGroup(after: .newItem) {
                Button {
                    model.run()
                } label: {
                    Text(LocalizedStringKey(model.mode.actionKey))
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(!model.canRun || model.workspace != .files)
                Button {
                    model.cancel()
                } label: {
                    Text("action.cancel")
                }
                .keyboardShortcut(".", modifiers: [.command])
                .disabled(!model.isRunning)
            }
            CommandGroup(after: .pasteboard) {
                Button {
                    model.selectAll()
                } label: {
                    Text("action.select_all")
                }
                .keyboardShortcut("a")
                .disabled(model.workspace != .files || model.items.isEmpty)
                Button {
                    model.removeSelected()
                } label: {
                    Text("action.remove_selected")
                }
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled(model.workspace != .files || model.selection.isEmpty)
                Button {
                    model.removeFinished()
                } label: {
                    Text("action.remove_finished")
                }
                .disabled(model.workspace != .files || !model.items.contains(where: { $0.status == .done }))
                Button {
                    model.retryFailed()
                } label: {
                    Text("action.retry_failed")
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(model.workspace != .files || !model.items.contains(where: { $0.status == .failed }))
                Button {
                    model.clear()
                } label: {
                    Text("action.clear")
                }
                .disabled(model.workspace != .files || model.items.isEmpty)
            }
            CommandMenu("Kiln") {
                Button {
                    model.workspace = .files
                } label: {
                    Text("workspace.files")
                }
                .keyboardShortcut("1", modifiers: [.command])
                Button {
                    model.workspace = .units
                } label: {
                    Text("workspace.units")
                }
                .keyboardShortcut("2", modifiers: [.command])
                Button {
                    Task { await model.units.refresh() }
                } label: {
                    Text("units.refresh")
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(model.workspace != .units || !model.units.category.isCurrency)
            }
        }

        Settings {
            SettingsView(model: model, showsDone: false)
                .environment(\.locale, model.settings.locale)
                .environment(\.layoutDirection, model.settings.layoutDirection)
                .preferredColorScheme(model.settings.appearance.colorScheme)
        }
    }
}
