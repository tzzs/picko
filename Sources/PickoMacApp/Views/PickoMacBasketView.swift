import PickoApp
import SwiftUI

struct PickoMacBasketView: View {
    @Bindable var model: PickoMacWorkbenchModel
    @State private var showsDeletionConfirmation = false
    @State private var isConfirmingDeletion = false
    @State private var deletionErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(model.deletionQueueCount) items waiting for review")
                .font(.title2.bold())

            Text(ByteCountFormatter.string(fromByteCount: model.estimatedPreDeleteBytes, countStyle: .file))
                .foregroundStyle(.secondary)

            List(model.appModel.store.deletionQueue.itemIds, id: \.self) { id in
                if let asset = model.appModel.store.asset(id: id) {
                    HStack(spacing: 12) {
                        PickoThumbnailView(
                            asset: asset,
                            thumbnailProvider: model.thumbnailProvider,
                            targetPixelWidth: 180,
                            targetPixelHeight: 140
                        )
                        .frame(width: 84, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading) {
                            Text(asset.id)
                            Text(ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Restore") {
                            model.appModel.restoreFromBasket(assetId: id)
                        }
                    }
                }
            }

            HStack {
                Button("Confirm with Photos", role: .destructive) {
                    showsDeletionConfirmation = true
                }
                .disabled(model.deletionQueueCount == 0 || model.appModel.photoDeleter == nil || isConfirmingDeletion)

                Button("Clear basket", role: .destructive) {
                    model.appModel.clearBasket()
                }
                .disabled(model.deletionQueueCount == 0 || isConfirmingDeletion)
            }

            if let deletionErrorMessage {
                Text(deletionErrorMessage)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .confirmationDialog(
            "Confirm reviewed items with Photos",
            isPresented: $showsDeletionConfirmation,
            titleVisibility: .visible
        ) {
            Button("Continue", role: .destructive) {
                Task {
                    await confirmDeletion()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(ReviewCopy.photosConfirmationMessage)
        }
    }

    @MainActor
    private func confirmDeletion() async {
        isConfirmingDeletion = true
        deletionErrorMessage = nil

        do {
            _ = try await model.confirmPreDeleteBasket()
        } catch {
            deletionErrorMessage = "Photos confirmation could not be completed."
        }

        isConfirmingDeletion = false
    }
}
