import PickoCore
import PickoPhotos
import SwiftUI

public struct SingleReviewView: View {
    @Bindable private var model: PickoAppModel

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            if let presentation = PickoSingleReviewPresentation(model: model) {
                VStack(spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        PickoThumbnailView(asset: presentation.asset, thumbnailProvider: model.thumbnailProvider)
                            .aspectRatio(4 / 3, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .background(.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))

                        Text("Suggested keep")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.green.opacity(0.9), in: Capsule())
                            .foregroundStyle(.white)
                            .padding(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(presentation.asset.id)
                            .font(.title3.bold())
                            .lineLimit(1)
                        Text(presentation.metadataSummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(presentation.decisionHint)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 0)

                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Button {
                                model.keepCurrentAsset()
                            } label: {
                                Label(presentation.primaryActions[0].title, systemImage: presentation.primaryActions[0].systemImage)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)

                            Button {
                                model.preDeleteCurrentAsset()
                            } label: {
                                Label(presentation.primaryActions[1].title, systemImage: presentation.primaryActions[1].systemImage)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        HStack {
                            Button {
                                model.undo()
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }
                            .buttonStyle(.borderless)

                            Spacer()

                            Button {
                                model.skipCurrentAsset()
                            } label: {
                                Label(presentation.primaryActions[2].title, systemImage: presentation.primaryActions[2].systemImage)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding()
            } else {
                ContentUnavailableView("No items ready", systemImage: "photo")
            }
        }
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
