import SwiftUI

struct InspectorView: View {
    @ObservedObject var model: AppModel
    @State private var advanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            preview
            modePicker
            if model.mode != .compress {
                formatChips
            }
            presets
            qualitySlider
            DisclosureGroup(isExpanded: $advanced) {
                advancedBlock
            } label: {
                Text("inspector.advanced")
                    .font(.system(size: 13, weight: .semibold))
            }
            Spacer(minLength: 0)
            runButton
        }
        .padding(18)
        .frame(minWidth: 380)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("inspector.preview")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                if let image = model.selectedItem?.thumbnail {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 180)
        }
    }

    private var modePicker: some View {
        Picker(selection: $model.mode) {
            ForEach(ConversionMode.allCases) { mode in
                Text(LocalizedStringKey(mode.localizationKey)).tag(mode)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
        .onChange(of: model.mode) { _, _ in
            model.reconcileDestination()
        }
    }

    private var formatChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(model.groupedDestinations, id: \.0) { family, formats in
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey(family.localizationKey))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    FlowChips(formats: formats, selected: model.destinationFormatID) { format in
                        model.destinationFormatID = format.id
                    }
                }
            }
        }
    }

    private var presets: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(KilnPreset.allCases) { preset in
                Button {
                    model.apply(preset: preset)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(preset.titleKey))
                            .font(.system(size: 12, weight: .semibold))
                        Text(LocalizedStringKey(preset.detailKey))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(model.preset == preset ? KilnTheme.amber.opacity(0.16) : Color.primary.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(model.preset == preset ? KilnTheme.amber.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(KilnPressStyle())
            }
        }
    }

    private var qualitySlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("inspector.quality")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("\(Int(model.quality * 100))%")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $model.quality, in: 0.1...1)
                .tint(KilnTheme.amber)
        }
    }

    private var advancedBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $model.stripMetadata) {
                Text("inspector.metadata.strip")
            }
            .toggleStyle(.checkbox)
            Picker(selection: dimensionBinding) {
                Text("inspector.resize.original").tag(Optional<Int>.none)
                Text("1280").tag(Optional(1280))
                Text("1920").tag(Optional(1920))
                Text("2560").tag(Optional(2560))
            } label: {
                Text("inspector.resize")
            }
        }
        .padding(.top, 6)
    }

    private var dimensionBinding: Binding<Int?> {
        Binding(
            get: { model.maxDimension },
            set: { model.maxDimension = $0 }
        )
    }

    private var runButton: some View {
        Button {
            if model.isRunning {
                model.cancel()
            } else {
                model.run()
            }
        } label: {
            HStack {
                if model.isRunning {
                    ProgressView().controlSize(.small)
                    Text("action.cancel")
                } else {
                    Text(LocalizedStringKey(model.mode.actionKey))
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(KilnPressStyle())
        .background(KilnTheme.amber, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .foregroundStyle(.white)
        .disabled(!model.canRun && !model.isRunning)
        .keyboardShortcut(.return, modifiers: [.command])
        .accessibilityLabel(Text(LocalizedStringKey(model.mode.actionKey)))
        .accessibilityValue(Text(model.destinationFormatID ?? ""))
    }
}

struct FlowChips: View {
    var formats: [Format]
    var selected: String?
    var onSelect: (Format) -> Void

    var body: some View {
        FlexibleChipWrap(formats: formats, selected: selected, onSelect: onSelect)
    }
}

struct FlexibleChipWrap: View {
    var formats: [Format]
    var selected: String?
    var onSelect: (Format) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 6)], alignment: .leading, spacing: 6) {
            ForEach(formats) { format in
                Button {
                    onSelect(format)
                } label: {
                    HStack(spacing: 4) {
                        Text(format.displayName)
                            .font(.system(size: 11, weight: .semibold))
                        if format.requiresFFMPEG {
                            Text("inspector.via_ffmpeg")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(selected == format.id ? KilnTheme.amber.opacity(0.22) : Color.primary.opacity(0.06))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(selected == format.id ? KilnTheme.amber : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(KilnPressStyle())
                .help(format.displayName)
            }
        }
    }
}
