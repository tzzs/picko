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
        let presentation = PickoBasketPresentation(model: model)

        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(presentation.summaryTitle)
                        .font(.title3.bold())
                    Text(presentation.summarySubtitle)
                        .foregroundStyle(.secondary)
                    Text(presentation.secondaryActionTitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Final review") {
                ForEach(presentation.items) { item in
                    HStack(spacing: 12) {
                        PickoThumbnailView(
                            asset: item.asset,
                            thumbnailProvider: model.thumbnailProvider,
                            targetPixelWidth: 160,
                            targetPixelHeight: 120
                        )
                        .frame(width: 76, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.id)
                                .font(.headline)
                                .lineLimit(1)
                            Text(item.byteText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("From review flow")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Restore") {
                            model.restoreFromBasket(assetId: item.id)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showsDeletionConfirmation = true
                } label: {
                    Label(presentation.primaryActionTitle, systemImage: "checkmark.shield")
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

            Section {
                Text(presentation.recoveryMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
