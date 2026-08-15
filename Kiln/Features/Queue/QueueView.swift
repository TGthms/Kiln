import SwiftUI

struct QueueView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List(selection: $model.selection) {
            ForEach(model.items) { item in
                QueueRow(item: item, selected: model.selection.contains(item.id))
                    .tag(item.id)
                    .contextMenu {
                        Button("action.remove") { model.remove(item.id) }
                        if let out = item.outputURL {
                            Button("action.reveal") { model.reveal(out) }
                        }
                    }
            }
            .onDelete { indexSet in
                let ids = indexSet.compactMap { model.items.indices.contains($0) ? model.items[$0].id : nil }
                for id in ids { model.remove(id) }
            }
        }
        .listStyle(.sidebar)
        .accessibilityLabel(Text(fileCountLabel))
        .focusable()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(fileCountLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text(fileCountLabel))
                HStack(spacing: 8) {
                    Button("action.add") { model.browse() }
                        .accessibilityHint(Text("drop.subtitle"))
                    Button("action.remove_selected") { model.removeSelected() }
                        .disabled(model.selection.isEmpty)
                    Spacer(minLength: 0)
                    Button("action.clear") { model.clear() }
                        .disabled(model.items.isEmpty)
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var fileCountLabel: String {
        let format = L10n.string("queue.count", locale: model.settings.locale)
        let total = String(format: format, locale: model.settings.locale, model.items.count)
        let ready = model.itemsToProcess.count
        if ready > 0 {
            let readyFormat = L10n.string("inspector.batch_ready", locale: model.settings.locale)
            return total + " · " + String(format: readyFormat, locale: model.settings.locale, ready)
        }
        return total
    }
}

struct QueueRow: View {
    var item: QueueItem
    var selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            thumbnail
            VStack(alignment: .leading, spacing: 2) {
                Text(item.url.lastPathComponent)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let format = item.format {
                        Text(format.displayName)
                            .foregroundStyle(.secondary)
                    }
                    Text(LocalizedStringKey(item.status.localizationKey))
                        .foregroundStyle(statusColor)
                    if item.status == .done, let out = item.outputBytes {
                        Text(sizeLine(in: item.inputBytes, out: out))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .font(.caption)
                if let message = item.message, item.status == .failed {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                if item.status == .converting {
                    ProgressView(value: item.progress)
                        .controlSize(.small)
                        .accessibilityValue(Text("\(Int(item.progress * 100))%"))
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(rowLabel))
        .accessibilityValue(Text(LocalizedStringKey(item.status.localizationKey)))
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityHint(Text("action.remove"))
    }

    private var rowLabel: String {
        var parts = [item.url.lastPathComponent]
        if let format = item.format {
            parts.append(format.displayName)
        }
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private var thumbnail: some View {
        Group {
            if let image = item.thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "doc")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityHidden(true)
    }

    private var statusColor: Color {
        switch item.status {
        case .done: return .secondary
        case .failed: return .red
        case .unsupported: return .secondary
        case .converting: return .primary
        case .ready: return .secondary
        }
    }

    private func sizeLine(in input: Int64, out: Int64) -> String {
        let inStr = ByteCountFormatStyle(style: .file).format(input)
        let outStr = ByteCountFormatStyle(style: .file).format(out)
        return "\(inStr) → \(outStr)"
    }
}
