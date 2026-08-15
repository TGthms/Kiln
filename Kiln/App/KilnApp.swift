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
                    Text("drop.browse")
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            CommandMenu("Kiln") {
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
                .disabled(!model.isRunning)
                Button {
                    Task { await model.units.refresh() }
                } label: {
                    Text("units.refresh")
                }
                .keyboardShortcut("r", modifiers: [.command])
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
