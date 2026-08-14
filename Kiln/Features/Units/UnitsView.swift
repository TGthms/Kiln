import SwiftUI

struct UnitsView: View {
    @ObservedObject var model: UnitsModel

    var body: some View {
        HStack(spacing: 0) {
            if model.sidebarVisible {
                categoryList
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
                .font(.system(size: 14, weight: model.category == category ? .semibold : .regular))
                .tag(category)
                .listRowBackground(
                    model.category == category
                        ? KilnTheme.amber.opacity(0.18)
                        : Color.clear
                )
        }
        .listStyle(.sidebar)
        .frame(width: 220)
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
        VStack(alignment: .leading, spacing: 20) {
            Text(LocalizedStringKey(model.category.localizationKey))
                .font(.system(size: 26, weight: .semibold))
                .tracking(-0.4)

            conversionCard(role: .from)
            HStack {
                Spacer(minLength: 0)
                Button(action: { model.swap() }) {
                    Label {
                        Text("units.swap")
                    } icon: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(Color.primary.opacity(0.06), in: Capsule())
                Spacer(minLength: 0)
            }
            conversionCard(role: .to)

            Button(action: { model.copyResult() }) {
                Text("units.copy")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color.primary.opacity(0.06), in: Capsule())
            .disabled(model.result == nil)

            if model.category.isCurrency {
                currencyFooter
            }
            Spacer(minLength: 0)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private enum RowRole { case from, to }

    private func conversionCard(role: RowRole) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(role == .from ? "units.from" : "units.to")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                if role == .from {
                    TextField("1", text: $model.inputText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .controlSize(.large)
                } else if let result = model.result {
                    Text(model.format(result))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                } else {
                    Text("—")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Picker(selection: role == .from ? $model.fromID : $model.toID) {
                    ForEach(model.unitSpecs) { spec in
                        Text(spec.symbol).tag(spec.id)
                    }
                } label: {
                    Text(role == .from ? "units.from" : "units.to")
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.large)
                .frame(minWidth: 140)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
        }
    }

    private var currencyFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let label = model.lastUpdatedLabel {
                    Text("units.updated") + Text(" ") + Text(label)
                }
                if model.isStale {
                    Text("units.stale")
                        .foregroundStyle(KilnTheme.amber)
                }
                Button {
                    Task { await model.refresh() }
                } label: {
                    if model.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("units.refresh")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(model.isRefreshing)
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            if let error = model.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }
        }
    }
}
