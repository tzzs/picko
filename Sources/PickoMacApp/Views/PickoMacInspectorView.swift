import PickoCore
import SwiftUI

struct PickoMacInspectorView: View {
    @Bindable var model: PickoMacWorkbenchModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let asset = model.selectedAsset {
                Text("Inspector")
                    .font(.title3.bold())

                LabeledContent("Identifier", value: asset.id)
                LabeledContent("Type", value: mediaTypeText(asset.mediaType))
                LabeledContent("Dimensions", value: "\(asset.pixelWidth)x\(asset.pixelHeight)")
                LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file))
                LabeledContent("Status", value: statusText(asset.status))
                LabeledContent("Favorite", value: asset.isFavorite ? "Yes" : "No")
                LabeledContent("Edited", value: asset.isEdited ? "Yes" : "No")

                Divider()

                Button("Keep") {
                    model.keepSelectedAsset()
                }
                .keyboardShortcut("k", modifiers: [])

                Button("Review Later") {
                    model.preDeleteSelectedAsset()
                }
                .keyboardShortcut("d", modifiers: [])
            } else {
                ContentUnavailableView("No selection", systemImage: "sidebar.right")
            }

            Spacer()
        }
        .padding()
    }

    private func mediaTypeText(_ mediaType: PhotoAsset.MediaType) -> String {
        switch mediaType {
        case .photo:
            return "Photo"
        case .video:
            return "Video"
        case .livePhoto:
            return "Live Photo"
        case .screenshot:
            return "Screenshot"
        }
    }

    private func statusText(_ status: PhotoAsset.ReviewStatus) -> String {
        switch status {
        case .unreviewed:
            return "Unreviewed"
        case .kept:
            return "Kept"
        case .preDeleted:
            return "In basket"
        case .skipped:
            return "Skipped"
        }
    }
}
