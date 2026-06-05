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

        ScrollView {
            VStack(alignment: .leading, spacing: PickoDesign.Spacing.lg) {
                PickoBrandHeader(title: "拾影", trailingSystemImage: "gearshape") {}

                VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                    PickoSectionLabel(title: "Savings Overview")

                    VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("总计节省")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                                Text(presentation.summarySubtitle.replacingOccurrences(of: "Estimated space: ", with: ""))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(PickoDesign.ColorToken.primary)
                            }
                            Spacer()
                            Button("复核") {}
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(PickoDesign.ColorToken.goldSoft, in: Capsule())
                                .foregroundStyle(PickoDesign.ColorToken.primaryDeep)
                        }

                        Text(presentation.summaryTitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(PickoDesign.ColorToken.ink)

                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(PickoDesign.ColorToken.gold)
                            Text("照片将移至系统“最近删除”相册，可在该处恢复。")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                        }
                        .padding(PickoDesign.Spacing.md)
                        .background(PickoDesign.ColorToken.surfaceContainer, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(PickoDesign.ColorToken.gold)
                                .frame(width: 4)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                    }
                    .padding(24)
                    .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                    .overlay {
                        RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                            .stroke(PickoDesign.ColorToken.outline.opacity(0.55), lineWidth: 1)
                    }
                }

                VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                    HStack {
                        Text("相似组")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Spacer()
                        Text("\(presentation.items.count) ITEMS")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                    }

                    if presentation.items.isEmpty {
                        ContentUnavailableView("No reviewed items", systemImage: "basket")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, PickoDesign.Spacing.lg)
                            .background(PickoDesign.ColorToken.surfaceLow, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: PickoDesign.Spacing.md) {
                                ForEach(presentation.items) { item in
                                    basketCard(item)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                    HStack {
                        Text("单张复核")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Spacer()
                        Text("\(presentation.items.count) PHOTOS")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PickoDesign.Spacing.gutter) {
                        ForEach(presentation.items) { item in
                            ZStack(alignment: .topTrailing) {
                                PickoThumbnailView(
                                    asset: item.asset,
                                    thumbnailProvider: model.thumbnailProvider,
                                    targetPixelWidth: 220,
                                    targetPixelHeight: 220
                                )
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))

                                Button("Restore") {
                                    model.restoreFromBasket(assetId: item.id)
                                }
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.78), in: Capsule())
                                .foregroundStyle(PickoDesign.ColorToken.primary)
                                .padding(8)
                            }
                        }
                    }
                }

                if let deletionErrorMessage {
                    Text(deletionErrorMessage)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                        .padding(PickoDesign.Spacing.md)
                        .background(PickoDesign.ColorToken.surfaceLow, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                }

                Text(presentation.recoveryMessage)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                    .padding(.bottom, 120)
            }
            .padding(PickoDesign.Spacing.page)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: PickoDesign.Spacing.gutter) {
                Button(role: .destructive) {
                    showsDeletionConfirmation = true
                } label: {
                    Label(presentation.primaryActionTitle, systemImage: "checkmark.shield")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(PickoDesign.ColorToken.primary, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                        .foregroundStyle(PickoDesign.ColorToken.primarySoft)
                }
                .buttonStyle(.plain)
                .disabled(model.deletionQueueCount == 0 || model.photoDeleter == nil || isConfirmingDeletion)
                .opacity(model.deletionQueueCount == 0 || model.photoDeleter == nil || isConfirmingDeletion ? 0.45 : 1)

                Button(role: .destructive) {
                    model.clearBasket()
                } label: {
                    Label("Clear basket", systemImage: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(PickoDesign.ColorToken.surfaceHigh, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                        .foregroundStyle(PickoDesign.ColorToken.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(PickoDesign.Spacing.page)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Basket")
        .pickoScreenBackground()
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

    private func basketCard(_ item: PickoBasketItemPresentation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PickoThumbnailView(
                asset: item.asset,
                thumbnailProvider: model.thumbnailProvider,
                targetPixelWidth: 320,
                targetPixelHeight: 320
            )
            .frame(width: 220, height: 220)
            .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
            .overlay(alignment: .topTrailing) {
                Text(item.byteText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(PickoDesign.ColorToken.primary.opacity(0.82), in: RoundedRectangle(cornerRadius: PickoDesign.Radius.sm))
                    .foregroundStyle(.white)
                    .padding(10)
            }

            Text(item.id)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .lineLimit(1)
            Text("From review flow")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
        }
        .frame(width: 220, alignment: .leading)
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
