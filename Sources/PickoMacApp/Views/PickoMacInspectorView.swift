import SwiftUI

struct PickoMacInspectorView: View {
    @Bindable var model: PickoMacWorkbenchModel

    var body: some View {
        VStack(alignment: .leading, spacing: PickoMacDesign.Spacing.md) {
            if let presentation = model.inspectorPresentation {
                Text("Inspector")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(PickoMacDesign.ColorToken.primary)

                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent("Identifier", value: presentation.assetId)
                    LabeledContent("Type", value: presentation.mediaTypeLabel)
                    LabeledContent("Dimensions", value: presentation.dimensionsLabel)
                    LabeledContent("Size", value: presentation.fileSizeLabel)
                    LabeledContent("Status", value: presentation.statusLabel)
                }
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(PickoMacDesign.ColorToken.ink)

                VStack(alignment: .leading, spacing: 7) {
                    Text("Recommendation")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(PickoMacDesign.ColorToken.primary)
                    Text(presentation.recommendationLabel)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(PickoMacDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg))
                .overlay {
                    RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg)
                        .stroke(PickoMacDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
                }

                Divider()
                    .overlay(PickoMacDesign.ColorToken.outline.opacity(0.45))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Keyboard")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(PickoMacDesign.ColorToken.primary)
                    ForEach(presentation.shortcutHints) { hint in
                        HStack {
                            Text(hint.key)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(PickoMacDesign.ColorToken.primaryDeep)
                                .frame(minWidth: 44, alignment: .leading)
                                .padding(.vertical, 3)
                                .background(PickoMacDesign.ColorToken.primarySoft.opacity(0.55), in: RoundedRectangle(cornerRadius: 5))
                            Text(hint.title)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)
                        }
                    }
                }

                HStack {
                    Button("Keep") {
                        model.keepSelectedAsset()
                    }
                    .keyboardShortcut("k", modifiers: [])
                    .buttonStyle(.borderedProminent)

                    Button("Review Later") {
                        model.preDeleteSelectedAsset()
                    }
                    .keyboardShortcut("d", modifiers: [])
                    .buttonStyle(.bordered)
                }
            } else {
                PickoMacEmptyStateView(
                    title: "No selection",
                    message: "Select an item to inspect metadata, recommendations, and review shortcuts.",
                    systemImage: "sidebar.right"
                )
            }

            Spacer()
        }
        .padding(PickoMacDesign.Spacing.md)
        .tint(PickoMacDesign.ColorToken.primary)
    }
}
