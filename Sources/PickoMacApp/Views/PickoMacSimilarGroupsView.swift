import PickoApp
import PickoCore
import SwiftUI

struct PickoMacSimilarGroupsView: View {
    @Bindable var model: PickoMacWorkbenchModel

    var body: some View {
        List(model.groups) { group in
            HStack(alignment: .top, spacing: 12) {
                thumbnailStrip(for: group)

                VStack(alignment: .leading, spacing: 6) {
                    Text(group.id)
                        .font(.headline)
                    Text("\(group.assetIds.count) similar items · keep \(group.keepCount)")
                        .foregroundStyle(.secondary)
                    Text("Recommended: \(group.recommendedKeepIds.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
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
