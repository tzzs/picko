import PickoApp
import PickoCore
import SwiftUI

struct PickoMacSimilarGroupsView: View {
    @Bindable var model: PickoMacWorkbenchModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PickoMacDesign.Spacing.lg) {
                PickoMacPageHeader(
                    eyebrow: "Similarity review",
                    title: "Similar Groups",
                    subtitle: "Review recommendations, then decide whether to keep one or keep a few before moving the rest to the basket."
                )

                LazyVStack(spacing: 12) {
                    ForEach(model.groups) { group in
                        groupCard(group)
                    }
                }
            }
            .padding(PickoMacDesign.Spacing.page)
        }
    }

    private func groupCard(_ group: SimilarGroup) -> some View {
        let presentation = model.similarGroupPresentation(for: group)

        return HStack(alignment: .top, spacing: 14) {
            thumbnailStrip(for: group)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(presentation.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(PickoMacDesign.ColorToken.ink)
                    Spacer()
                    PickoMacStatusPill(
                        presentation.statusLabel,
                        color: PickoMacDesign.ColorToken.coralDeep
                    )
                }

                Text(presentation.summary)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)

                Label(presentation.recommendation, systemImage: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(PickoMacDesign.ColorToken.primary)

                Text(presentation.context)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)

                HStack(spacing: 8) {
                    PickoMacStatusPill("Keep 1", color: PickoMacDesign.ColorToken.primary)
                    PickoMacStatusPill("Keep N", color: PickoMacDesign.ColorToken.gold)
                    PickoMacStatusPill("Manual review", color: PickoMacDesign.ColorToken.secondaryInk)
                }
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(PickoMacDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg)
                .stroke(PickoMacDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
        }
    }

    private func thumbnailStrip(for group: SimilarGroup) -> some View {
        HStack(spacing: -10) {
            ForEach(assets(in: group).prefix(3)) { asset in
                PickoThumbnailView(
                    asset: asset,
                    thumbnailProvider: model.thumbnailProvider,
                    targetPixelWidth: 120,
                    targetPixelHeight: 120
                )
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: PickoMacDesign.Radius.sm))
                .overlay {
                    RoundedRectangle(cornerRadius: PickoMacDesign.Radius.sm)
                        .stroke(PickoMacDesign.ColorToken.surface, lineWidth: 2)
                }
            }
        }
        .frame(width: 96, alignment: .leading)
    }

    private func assets(in group: SimilarGroup) -> [PhotoAsset] {
        model.assets.filter { group.assetIds.contains($0.id) }
    }
}
