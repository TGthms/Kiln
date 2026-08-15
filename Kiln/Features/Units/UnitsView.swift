import SwiftUI

struct UnitsView: View {
    @ObservedObject var model: UnitsModel

    var body: some View {
        HStack(spacing: 0) {
            if model.sidebarVisible {
                categoryList
                    .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)
            }
            converter
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            await model.refreshIfNeeded()
        }
        .onChange(of: model.category) { _, new in
            if new.isCurrency {
                Task { await model.refreshIfNeeded() }
            }
        }
    }

    private var categoryList: some View {
        List(UnitCategory.allCases, selection: categoryBinding) { category in
            Text(LocalizedStringKey(category.localizationKey))
                .tag(category)
        }
        .listStyle(.sidebar)
        .accessibilityLabel(Text("units.sidebar"))
    }

    private var categoryBinding: Binding<UnitCategory?> {
        Binding(
            get: { model.category },
            set: { newValue in
                if let newValue {
                    model.select(category: newValue)
                }
            }
        )
    }

    private var converter: some View {
        Form {
            Section {
                HStack {
                    TextField("1", text: $model.inputText)
                        .textFieldStyle(.roundedBorder)
                        .font(.title.weight(.regular).monospacedDigit())
                        .controlSize(.large)
                        .accessibilityLabel(Text("units.from"))
                    Picker(selection: $model.fromID) {
                        ForEach(model.unitSpecs) { spec in
                            Text(spec.symbol).tag(spec.id)
                        }
                    } label: {
                        Text("units.from")
                    }
                    .labelsHidden()
                    .accessibilityLabel(Text("units.from"))
                    .frame(minWidth: 88)
                }
            } header: {
                Text("units.from")
            }

            Section {
                Button {
                    model.swap()
                } label: {
                    Label {
                        Text("units.swap")
                    } icon: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }

            Section {
                HStack {
                    Group {
                        if let result = model.result {
                            Text(model.format(result))
                                .textSelection(.enabled)
                        } else {
                            Text("—")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .font(.title.weight(.regular).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Picker(selection: $model.toID) {
                        ForEach(model.unitSpecs) { spec in
                            Text(spec.symbol).tag(spec.id)
                        }
                    } label: {
                        Text("units.to")
                    }
                    .labelsHidden()
                    .accessibilityLabel(Text("units.to"))
                    .frame(minWidth: 88)
                }
            } header: {
                Text("units.to")
            }

            Section {
                Button {
                    model.copyResult()
                } label: {
                    Text("units.copy")
                }
                .disabled(model.result == nil)
            }

            if model.category.isCurrency {
                Section {
                    currencyFooter
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var currencyFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if let label = model.lastUpdatedLabel {
                    Text("units.updated") + Text(" ") + Text(label)
                }
                if model.isStale {
                    Text("units.stale")
                        .foregroundStyle(.orange)
                }
                Spacer(minLength: 0)
                Button {
                    Task { await model.refresh() }
                } label: {
                    if model.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("units.refresh")
                    }
                }
                .disabled(model.isRefreshing)
                .keyboardShortcut("r", modifiers: [.command])
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if let error = model.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
