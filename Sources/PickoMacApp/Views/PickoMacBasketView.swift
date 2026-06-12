import PickoApp
import PickoCore
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

            ScrollView {
                LazyVStack(spacing: PickoMacDesign.Spacing.gutter) {
                    ForEach(model.appModel.store.deletionQueue.itemIds, id: \.self) { id in
                        if let asset = model.appModel.store.asset(id: id) {
                            basketRow(asset)
                        }
                    }
                }
                .padding(PickoMacDesign.Spacing.gutter)
            }
            .frame(minHeight: 160)
            .background(PickoMacDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg))
            .clipShape(RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: PickoMacDesign.Radius.lg)
                    .stroke(PickoMacDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
            }

            HStack {
                PickoMacActionButton(title: "Confirm with Photos", systemImage: "checkmark.shield", style: .destructive) {
                    showsDeletionConfirmation = true
                }
                .disabled(model.deletionQueueCount == 0 || model.appModel.photoDeleter == nil || isConfirmingDeletion)
                .opacity(model.deletionQueueCount == 0 || model.appModel.photoDeleter == nil || isConfirmingDeletion ? 0.45 : 1)

                PickoMacActionButton(title: "Clear basket", systemImage: "arrow.uturn.backward", style: .secondary) {
                    model.appModel.clearBasket()
                }
                .disabled(model.deletionQueueCount == 0 || isConfirmingDeletion)
                .opacity(model.deletionQueueCount == 0 || isConfirmingDeletion ? 0.45 : 1)
            }

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

    private func basketRow(_ asset: PhotoAsset) -> some View {
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

            VStack(alignment: .leading, spacing: 4) {
                Text(asset.id)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(PickoMacDesign.ColorToken.ink)
                    .lineLimit(1)
                Text(ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)
            }

            Spacer()

            PickoMacActionButton(title: "Restore", systemImage: "arrow.uturn.backward", style: .secondary) {
                model.appModel.restoreFromBasket(assetId: asset.id)
            }
            .frame(width: 116)
        }
        .padding(10)
        .background(PickoMacDesign.ColorToken.surfaceLow, in: RoundedRectangle(cornerRadius: PickoMacDesign.Radius.md))
        .overlay {
            RoundedRectangle(cornerRadius: PickoMacDesign.Radius.md)
                .stroke(PickoMacDesign.ColorToken.outline.opacity(0.35), lineWidth: 1)
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
