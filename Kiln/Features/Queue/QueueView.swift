import SwiftUI

struct QueueView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(fileCountLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    model.clear()
                } label: {
                    Text("action.clear")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(model.items) { item in
                        QueueRow(item: item, selected: model.selection == item.id)
                            .onTapGesture { model.selection = item.id }
                            .contextMenu {
                                Button("action.remove") { model.remove(item.id) }
                                if let out = item.outputURL {
                                    Button("action.reveal") { model.reveal(out) }
                                }
                            }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 16)
            }
        }
        .frame(minWidth: 360)
        .background(.thinMaterial)
    }

    private var fileCountLabel: String {
        let format = L10n.string("queue.count", locale: model.settings.locale)
        return String(format: format, locale: model.settings.locale, model.items.count)
    }
}

struct QueueRow: View {
    var item: QueueItem
    var selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 3) {
                Text(item.url.lastPathComponent)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let format = item.format {
                        Text(format.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(KilnTheme.amber.opacity(0.16), in: Capsule())
                    }
                    Text(LocalizedStringKey(item.status.localizationKey))
                        .font(.system(size: 11))
                        .foregroundStyle(statusColor)
                    if item.status == .done, let out = item.outputBytes {
                        Text(sizeLine(in: item.inputBytes, out: out))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(out < item.inputBytes ? KilnTheme.amber : .secondary)
                    }
                }
                if let message = item.message, item.status == .failed {
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                if item.status == .converting {
                    ProgressView(value: item.progress)
                        .progressViewStyle(.linear)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selected ? KilnTheme.amber.opacity(0.14) : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(selected ? KilnTheme.amber.opacity(0.45) : Color.clear, lineWidth: 1)
        )
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
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statusColor: Color {
        switch item.status {
        case .done: return KilnTheme.amber
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
