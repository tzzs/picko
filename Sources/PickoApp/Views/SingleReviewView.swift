import PickoCore
import PickoPhotos
import SwiftUI

public struct SingleReviewView: View {
    @Bindable private var model: PickoAppModel

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 20) {
            if let asset = model.currentAsset {
                AssetSummaryView(asset: asset, thumbnailProvider: model.thumbnailProvider)

                HStack(spacing: 12) {
                    Button {
                        model.keepCurrentAsset()
                    } label: {
                        Label("Keep", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        model.preDeleteCurrentAsset()
                    } label: {
                        Label("Review Later", systemImage: "tray.and.arrow.down")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        model.skipCurrentAsset()
                    } label: {
                        Label("Skip", systemImage: "forward")
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ContentUnavailableView("No items ready", systemImage: "photo")
            }

            Button {
                model.undo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .navigationTitle("Review")
    }
}

struct AssetSummaryView: View {
    let asset: PhotoAsset
    let thumbnailProvider: (any PhotoThumbnailProviding)?

    var body: some View {
        VStack(spacing: 12) {
            PickoThumbnailView(asset: asset, thumbnailProvider: thumbnailProvider)
                .aspectRatio(4 / 3, contentMode: .fit)

            VStack(spacing: 4) {
                Text(asset.id)
                    .font(.headline)
                Text("\(asset.pixelWidth)x\(asset.pixelHeight) · \(byteText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var byteText: String {
        ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file)
    }
}

#Preview {
    NavigationStack {
        SingleReviewView(model: .preview())
    }
}
