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
            .padding()
        }
    }

    private func assetCard(_ asset: PhotoAsset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PickoThumbnailView(
                asset: asset,
                thumbnailProvider: model.thumbnailProvider,
                targetPixelWidth: 320,
                targetPixelHeight: 260
            )
                .background(asset.id == model.selectedAssetId ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.14))
                .aspectRatio(1.2, contentMode: .fit)

            Text(asset.id)
                .font(.headline)
                .lineLimit(1)

            Text(ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(asset.id == model.selectedAssetId ? Color.accentColor : Color.clear, lineWidth: 2)
        }
    }
}
