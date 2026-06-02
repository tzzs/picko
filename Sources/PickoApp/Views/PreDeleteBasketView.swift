import SwiftUI

public struct PreDeleteBasketView: View {
    @Bindable private var model: PickoAppModel
    @State private var showsDeletionConfirmation = false
    @State private var isConfirmingDeletion = false
    @State private var deletionErrorMessage: String?

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(model.deletionQueueCount) items waiting for review")
                        .font(.headline)
                    Text(ByteCountFormatter.string(fromByteCount: model.estimatedPreDeleteBytes, countStyle: .file))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Items") {
                ForEach(model.store.deletionQueue.itemIds, id: \.self) { id in
                    if let asset = model.store.asset(id: id) {
                        HStack(spacing: 12) {
                            PickoThumbnailView(
                                asset: asset,
                                thumbnailProvider: model.thumbnailProvider,
                                targetPixelWidth: 160,
                                targetPixelHeight: 120
                            )
                            .frame(width: 72, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading) {
                                Text(asset.id)
                                Text(ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Restore") {
                                model.restoreFromBasket(assetId: id)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showsDeletionConfirmation = true
                } label: {
                    Label("Confirm with Photos", systemImage: "checkmark.shield")
                }
                .disabled(model.deletionQueueCount == 0 || model.photoDeleter == nil || isConfirmingDeletion)

                Button(role: .destructive) {
                    model.clearBasket()
                } label: {
                    Label("Clear basket", systemImage: "arrow.uturn.backward")
                }
            }

            if let deletionErrorMessage {
                Section {
                    Text(deletionErrorMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Basket")
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

#Preview {
    let model = PickoAppModel.preview()
    model.preDeleteCurrentAsset()
    return NavigationStack {
        PreDeleteBasketView(model: model)
    }
}
