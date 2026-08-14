import SwiftUI

struct DropZoneView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(KilnTheme.ember.opacity(0.18))
                    .frame(width: 120, height: 120)
                    .blur(radius: model.isDropTargeted ? 6 : 0)
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 44, weight: .regular))
                    .foregroundStyle(KilnTheme.amber)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(model.isDropTargeted ? 1.04 : 1)
            .animation(reduceMotion ? .easeInOut(duration: 0.12) : KilnTheme.spring, value: model.isDropTargeted)

            VStack(spacing: 6) {
                Text("drop.title")
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.4)
                Text("drop.subtitle")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Button {
                model.browse()
            } label: {
                Text("drop.browse")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(KilnPressStyle())
            .keyboardShortcut("o", modifiers: [.command])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("drop.title"))
        .accessibilityHint(Text("drop.subtitle"))
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(KilnTheme.amber.opacity(model.isDropTargeted ? 0.85 : 0.22), lineWidth: model.isDropTargeted ? 2.5 : 1.2)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .padding(28)
        }
    }
}
