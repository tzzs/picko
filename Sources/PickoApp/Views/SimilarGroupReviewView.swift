import PickoCore
import SwiftUI

public struct SimilarGroupReviewView: View {
    @Bindable private var model: PickoAppModel
    @State private var selectedAssetIds: Set<PhotoAsset.ID>

    public init(model: PickoAppModel) {
        self.model = model
        let firstGroup = model.groups.first
        self._selectedAssetIds = State(initialValue: Set(firstGroup?.recommendedKeepIds ?? []))
    }

    public var body: some View {
        Group {
            if let group = model.groups.first {
                List {
                    Section("Recommended keep") {
                        Text("Keep \(max(selectedAssetIds.count, 1)) from this similar group.")
                            .foregroundStyle(.secondary)
                    }

                    Section("Group") {
                        ForEach(assets(in: group)) { asset in
                            Button {
                                toggle(asset.id)
                            } label: {
                                HStack(spacing: 12) {
                                    PickoThumbnailView(
                                        asset: asset,
                                        thumbnailProvider: model.thumbnailProvider,
                                        targetPixelWidth: 160,
                                        targetPixelHeight: 120
                                    )
                                    .frame(width: 72, height: 54)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Image(systemName: selectedAssetIds.contains(asset.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedAssetIds.contains(asset.id) ? .blue : .secondary)

                                    VStack(alignment: .leading) {
                                        Text(asset.id)
                                        Text(ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        model.keep(assetIds: Array(selectedAssetIds), in: group)
                    } label: {
                        Label("Keep selected", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .background(.bar)
                }
            } else {
                ContentUnavailableView("No similar groups", systemImage: "square.grid.2x2")
            }
        }
        .navigationTitle("Similar")
    }

    private func assets(in group: SimilarGroup) -> [PhotoAsset] {
        model.assets.filter { group.assetIds.contains($0.id) }
    }

    private func toggle(_ id: PhotoAsset.ID) {
        if selectedAssetIds.contains(id) {
            selectedAssetIds.remove(id)
        } else {
            selectedAssetIds.insert(id)
        }
    }
}

#Preview {
    NavigationStack {
        SimilarGroupReviewView(model: .preview())
    }
}
