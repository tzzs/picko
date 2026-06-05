import PickoCore
import SwiftUI

public struct SimilarGroupReviewView: View {
    @Bindable private var model: PickoAppModel
    @State private var selectedAssetIds: Set<PhotoAsset.ID>
    @State private var keepsMultiple = false

    public init(model: PickoAppModel) {
        self.model = model
        let firstGroup = model.groups.first
        self._selectedAssetIds = State(initialValue: Set(firstGroup?.recommendedKeepIds ?? []))
    }

    public var body: some View {
        Group {
            if let presentation = PickoSimilarGroupPresentation(model: model) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Similar group 1/\(max(model.groups.count, 1))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text("Keep \(max(selectedAssetIds.count, 1)) from \(presentation.group.assetIds.count) similar photos")
                                .font(.title2.bold())
                            Text(presentation.footerExplanation)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Picker("Keep mode", selection: $keepsMultiple) {
                            Text(presentation.modeTitles[0]).tag(false)
                            Text(presentation.modeTitles[1]).tag(true)
                        }
                        .pickerStyle(.segmented)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 12)], spacing: 12) {
                            ForEach(presentation.assetRows) { row in
                                Button {
                                    toggle(row.id)
                                } label: {
                                    similarAssetCard(row, badge: presentation.recommendationBadge)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        model.keep(assetIds: Array(selectedAssetIds), in: presentation.group)
                    } label: {
                        Label("Keep selected", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
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
        } else if keepsMultiple {
            selectedAssetIds.insert(id)
        } else {
            selectedAssetIds = [id]
        }
    }

    private func similarAssetCard(_ row: PickoSimilarAssetPresentation, badge: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                PickoThumbnailView(
                    asset: row.asset,
                    thumbnailProvider: model.thumbnailProvider,
                    targetPixelWidth: 260,
                    targetPixelHeight: 220
                )
                .aspectRatio(1.15, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                if row.isSuggested {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.green.opacity(0.9), in: Capsule())
                        .foregroundStyle(.white)
                        .padding(8)
                }
            }

            HStack {
                Image(systemName: selectedAssetIds.contains(row.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedAssetIds.contains(row.id) ? .green : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.id)
                        .font(.headline)
                        .lineLimit(1)
                    Text(row.byteText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(selectedAssetIds.contains(row.id) ? Color.green : Color.clear, lineWidth: 2)
        }
    }
}

#Preview {
    NavigationStack {
        SimilarGroupReviewView(model: .preview())
    }
}
