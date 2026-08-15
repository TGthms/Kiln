import SwiftUI

struct QueueView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List(model.items, selection: $model.selection) { item in
            QueueRow(item: item)
                .tag(item.id)
                .contextMenu {
                    Button("action.remove") { model.remove(item.id) }
                    if let out = item.outputURL {
                        Button("action.reveal") { model.reveal(out) }
                    }
                }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Text(fileCountLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Button("action.clear") {
                    model.clear()
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var fileCountLabel: String {
        let format = L10n.string("queue.count", locale: model.settings.locale)
        return String(format: format, locale: model.settings.locale, model.items.count)
    }
}

struct QueueRow: View {
    var item: QueueItem

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
                }
            }
        }
        .padding(.vertical, 2)
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
