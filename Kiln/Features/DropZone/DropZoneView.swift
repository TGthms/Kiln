import SwiftUI

struct DropZoneView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 40, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("drop.title")
                .font(.title2.weight(.semibold))
                .tracking(-0.35)

            Text("drop.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)

            Button {
                model.browse()
            } label: {
                Text("drop.browse")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("o", modifiers: [.command])
            .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    model.isDropTargeted ? Color.accentColor : Color.primary.opacity(0.08),
                    style: StrokeStyle(lineWidth: model.isDropTargeted ? 2 : 1, dash: model.isDropTargeted ? [] : [7, 5])
                )
                .padding(20)
                .allowsHitTesting(false)
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.12) : KilnTheme.spring, value: model.isDropTargeted)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("drop.title"))
        .accessibilityHint(Text("drop.subtitle"))
        .accessibilityAddTraits(model.isDropTargeted ? [.updatesFrequently] : [])
    }
}
