import SwiftUI

struct InspectorView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section {
                preview
            }

            Section {
                Picker(selection: $model.mode) {
                    ForEach(ConversionMode.allCases) { mode in
                        Text(LocalizedStringKey(mode.localizationKey)).tag(mode)
                    }
                } label: {
                    Text("mode.convert")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel(Text("mode.convert"))
                .onChange(of: model.mode) { _, _ in
                    model.reconcileDestination()
                }
            }

            if model.mode != .compress {
                Section {
                    if model.availableDestinations.isEmpty {
                        Text("error.unsupported")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker(selection: $model.destinationFormatID) {
                            ForEach(model.availableDestinations) { format in
                                Text(format.requiresFFMPEG
                                     ? "\(format.displayName) · \(L10n.string("inspector.via_ffmpeg", locale: model.settings.locale))"
                                     : format.displayName)
                                    .tag(Optional(format.id))
                            }
                        } label: {
                            Text("inspector.destination")
                        }
                        .accessibilityLabel(Text("inspector.destination"))
                        .accessibilityValue(Text(model.destinationFormatID ?? ""))
                    }
                } header: {
                    Text("inspector.destination")
                }
            }

            if model.mode == .compress {
                Section {
                    Picker(selection: presetBinding) {
                        ForEach(KilnPreset.allCases) { preset in
                            Text(LocalizedStringKey(preset.titleKey)).tag(preset)
                        }
                    } label: {
                        Text("inspector.quality")
                    }
                    .pickerStyle(.radioGroup)

                    HStack {
                        Text("inspector.quality")
                        Slider(value: $model.quality, in: 0.1...1)
                            .accessibilityLabel(Text("inspector.quality"))
                            .accessibilityValue(Text("\(Int(model.quality * 100))%"))
                        Text("\(Int(model.quality * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                            .accessibilityHidden(true)
                    }
                }

                Section {
                    Toggle(isOn: $model.stripMetadata) {
                        Text("inspector.metadata.strip")
                    }
                    Picker(selection: dimensionBinding) {
                        Text("inspector.resize.original").tag(Optional<Int>.none)
                        Text("1280").tag(Optional(1280))
                        Text("1920").tag(Optional(1920))
                        Text("2560").tag(Optional(2560))
                    } label: {
                        Text("inspector.resize")
                    }
                } header: {
                    Text("inspector.advanced")
                }
            }

            Section {
                Button {
                    if model.isRunning {
                        model.cancel()
                    } else {
                        model.run()
                    }
                } label: {
                    if model.isRunning {
                        Text("action.cancel")
                    } else {
                        Text(batchActionTitle)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!model.canRun && !model.isRunning)
                .keyboardShortcut(.return, modifiers: [.command])
                .accessibilityLabel(Text(LocalizedStringKey(model.mode.actionKey)))
                .accessibilityValue(Text(batchActionTitle))
                .accessibilityHint(Text("inspector.destination"))
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var preview: some View {
        HStack(spacing: 12) {
            Group {
                if let image = model.selectedItem?.thumbnail {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "doc")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 72, height: 72)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(model.selectedItem?.url.lastPathComponent ?? "—")
                    .font(.headline)
                    .lineLimit(2)
                if let format = model.selectedItem?.format {
                    Text(format.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(model.selectedItem?.url.lastPathComponent ?? "inspector.preview"))
        .accessibilityHint(Text("inspector.preview"))
    }

    private var batchActionTitle: String {
        let action = L10n.string(model.mode.actionKey, locale: model.settings.locale)
        let count = model.itemsToProcess.count
        if count > 1 {
            return "\(action) · \(count)"
        }
        return action
    }

    private var presetBinding: Binding<KilnPreset> {
        Binding(
            get: { model.preset },
            set: { model.apply(preset: $0) }
        )
    }

    private var dimensionBinding: Binding<Int?> {
        Binding(
            get: { model.maxDimension },
            set: { model.maxDimension = $0 }
        )
    }
}
