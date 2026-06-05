import PickoApp
import PickoCore
import SwiftUI

struct PickoMacSimilarGroupsView: View {
    @Bindable var model: PickoMacWorkbenchModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Similar Groups")
                        .font(.title2.bold())
                    Text("Review recommendations, then decide whether to keep one or keep a few before moving the rest to the basket.")
                        .foregroundStyle(.secondary)
                }

                LazyVStack(spacing: 12) {
                    ForEach(model.groups) { group in
                        groupCard(group)
                    }
                }
            }
            .padding()
        }
    }

    private func groupCard(_ group: SimilarGroup) -> some View {
        let presentation = model.similarGroupPresentation(for: group)

        return HStack(alignment: .top, spacing: 14) {
            thumbnailStrip(for: group)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(presentation.title)
                        .font(.headline)
                    Spacer()
                    Text(presentation.statusLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }

                Text(presentation.summary)
                    .foregroundStyle(.secondary)

                Label(presentation.recommendation, systemImage: "checkmark.seal.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.green)

                Text(presentation.context)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text("Keep 1")
                    Text("Keep N")
                    Text("Manual review")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.16))
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.background, lineWidth: 2)
                }
            }
        }
        .frame(width: 96, alignment: .leading)
    }

    private func assets(in group: SimilarGroup) -> [PhotoAsset] {
        model.assets.filter { group.assetIds.contains($0.id) }
    }
}
