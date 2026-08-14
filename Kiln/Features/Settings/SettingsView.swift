import SwiftUI

enum KilnRepo {
    static let url = URL(string: "https://github.com/TGthms/Kiln")!
    static let displayHost = "github.com/TGthms/Kiln"
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    var showsDone: Bool = false
    var onDone: () -> Void = {}

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $model.settings.language) {
                        Text("settings.language.system").tag(AppLanguage.system)
                        Divider()
                        ForEach(AppLanguage.allCases.filter { $0 != .system }) { language in
                            Text(language.autonym).tag(language)
                        }
                    } label: {
                        Text("settings.language")
                    }
                    Picker(selection: $model.settings.appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(LocalizedStringKey(appearance.localizationKey)).tag(appearance)
                        }
                    } label: {
                        Text("settings.appearance")
                    }
                }

                Section {
                    Picker(selection: $model.settings.destination) {
                        ForEach(DestinationPolicy.allCases) { policy in
                            Text(LocalizedStringKey(policy.localizationKey)).tag(policy)
                        }
                    } label: {
                        Text("settings.destination")
                    }
                    Toggle(isOn: $model.settings.notifyOnComplete) {
                        Text("settings.notifications")
                    }
                }

                Section {
                    Toggle(isOn: $model.settings.currencyAutoRefresh) {
                        Text("units.auto_refresh")
                    }
                    Text("settings.currency.privacy")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } header: {
                    Text("settings.currency")
                }

                Section {
                    Link(destination: KilnRepo.url) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.repo")
                                Text(KilnRepo.displayHost)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("settings.about")
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("settings.title"))
            .toolbar {
                if showsDone {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            onDone()
                        } label: {
                            Text("action.done")
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 500)
        .onChange(of: model.settings.language) { _, _ in model.persistSettings() }
        .onChange(of: model.settings.appearance) { _, _ in model.persistSettings() }
        .onChange(of: model.settings.destination) { _, _ in model.persistSettings() }
        .onChange(of: model.settings.notifyOnComplete) { _, _ in model.persistSettings() }
        .onChange(of: model.settings.currencyAutoRefresh) { _, value in
            model.units.autoRefreshEnabled = value
            model.persistSettings()
        }
    }
}
