import PickoApp
import SwiftUI

struct PickoMacBasketView: View {
    @Bindable var model: PickoMacWorkbenchModel
    @State private var showsDeletionConfirmation = false
    @State private var isConfirmingDeletion = false
    @State private var deletionErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PickoMacDesign.Spacing.md) {
            PickoMacPageHeader(
                eyebrow: "Pre-delete basket",
                title: "\(model.deletionQueueCount) items waiting for review",
                subtitle: "Confirm only after reviewing the queue. Picko will ask Photos to complete the final action."
            )

            PickoMacStatusPill(
                ByteCountFormatter.string(fromByteCount: model.estimatedPreDeleteBytes, countStyle: .file),
                systemImage: "externaldrive",
                color: PickoMacDesign.ColorToken.primary
            )

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
                        .background(PickoMacDesign.ColorToken.surfaceContainer)
                        .clipShape(RoundedRectangle(cornerRadius: PickoMacDesign.Radius.sm))

                        VStack(alignment: .leading) {
                            Text(asset.id)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(PickoMacDesign.ColorToken.ink)
                            Text(ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file))
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)
                        }

                        Spacer()

                        Button("Restore") {
                            model.appModel.restoreFromBasket(assetId: id)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg)
                    .stroke(PickoMacDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
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
            .buttonStyle(.bordered)

            if let deletionErrorMessage {
                Text(deletionErrorMessage)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(PickoMacDesign.ColorToken.destructive)
            }
        }
        .padding(PickoMacDesign.Spacing.page)
        .tint(PickoMacDesign.ColorToken.primary)
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
