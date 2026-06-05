import SwiftUI

struct PickoMacInspectorView: View {
    @Bindable var model: PickoMacWorkbenchModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let presentation = model.inspectorPresentation {
                Text("Inspector")
                    .font(.title3.bold())

                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent("Identifier", value: presentation.assetId)
                    LabeledContent("Type", value: presentation.mediaTypeLabel)
                    LabeledContent("Dimensions", value: presentation.dimensionsLabel)
                    LabeledContent("Size", value: presentation.fileSizeLabel)
                    LabeledContent("Status", value: presentation.statusLabel)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommendation")
                        .font(.headline)
                    Text(presentation.recommendationLabel)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Keyboard")
                        .font(.headline)
                    ForEach(presentation.shortcutHints) { hint in
                        HStack {
                            Text(hint.key)
                                .font(.caption.monospaced().weight(.semibold))
                                .frame(minWidth: 44, alignment: .leading)
                            Text(hint.title)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack {
                    Button("Keep") {
                        model.keepSelectedAsset()
                    }
                    .keyboardShortcut("k", modifiers: [])

                    Button("Review Later") {
                        model.preDeleteSelectedAsset()
                    }
                    .keyboardShortcut("d", modifiers: [])
                }
            } else {
                ContentUnavailableView("No selection", systemImage: "sidebar.right")
            }

            Spacer()
        }
        .padding()
    }
}
