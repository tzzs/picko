import PickoApp
import PickoCore
import SwiftUI

struct PickoMacGridReviewView: View {
    @Bindable var model: PickoMacWorkbenchModel

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PickoMacDesign.Spacing.lg) {
                PickoMacPageHeader(
                    eyebrow: "Review desk",
                    title: "Workbench Review",
                    subtitle: "Scan the library, keep the best shots, and send uncertain items to the basket for final review."
                )

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(model.assets) { asset in
                        Button {
                            model.selectAsset(id: asset.id)
                        } label: {
                            assetCard(asset)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Keep") {
                                model.selectAsset(id: asset.id)
                                model.keepSelectedAsset()
                            }
                            Button("Review Later") {
                                model.selectAsset(id: asset.id)
                                model.preDeleteSelectedAsset()
                            }
                        }
                    }
                }
            }
            .padding(PickoMacDesign.Spacing.page)
        }
    }

    private func assetCard(_ asset: PhotoAsset) -> some View {
        let presentation = model.assetPresentation(for: asset)

        return VStack(alignment: .leading, spacing: 8) {
            PickoThumbnailView(
                asset: asset,
                thumbnailProvider: model.thumbnailProvider,
                targetPixelWidth: 320,
                targetPixelHeight: 260
            )
                .background(
                    asset.id == model.selectedAssetId
                    ? PickoMacDesign.ColorToken.primarySoft.opacity(0.72)
                    : PickoMacDesign.ColorToken.surfaceContainer
                )
                .aspectRatio(1.2, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: PickoMacDesign.Radius.md))

            Text(asset.id)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(PickoMacDesign.ColorToken.ink)
                .lineLimit(1)

            HStack {
                PickoMacStatusPill(
                    presentation.statusLabel,
                    systemImage: presentation.statusSystemImage,
                    color: statusColor(for: asset.status)
                )
                Spacer()
            }

            Text(presentation.metadataSummary)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)
        }
        .padding(10)
        .background(PickoMacDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg)
                .stroke(
                    asset.id == model.selectedAssetId
                    ? PickoMacDesign.ColorToken.gold
                    : PickoMacDesign.ColorToken.outline.opacity(0.45),
                    lineWidth: asset.id == model.selectedAssetId ? 2 : 1
                )
        }
    }

    private func statusColor(for status: PhotoAsset.ReviewStatus) -> Color {
        switch status {
        case .unreviewed:
            return PickoMacDesign.ColorToken.secondaryInk
        case .kept:
            return PickoMacDesign.ColorToken.primary
        case .preDeleted:
            return PickoMacDesign.ColorToken.destructive
        case .skipped:
            return PickoMacDesign.ColorToken.coralDeep
        }
    }
}
