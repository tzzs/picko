import SwiftUI

public struct PreDeleteBasketView: View {
    @Bindable private var model: PickoAppModel
    @State private var showsDeletionConfirmation = false
    @State private var showsClearBasketConfirmation = false
    @State private var isConfirmingDeletion = false
    @State private var deletionErrorMessage: String?
    @State private var previewAsset: PickoBasketItemPresentation?

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        let presentation = PickoBasketPresentation(model: model)

        ScrollView {
            VStack(alignment: .leading, spacing: PickoDesign.Spacing.lg) {
                PickoTopLevelHeader(spec: .basket)

                finalConfirmationSection(presentation: presentation)

                basketItemsSection(presentation: presentation)

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
                    .padding(.bottom, PickoDesign.Spacing.page)
            }
            .padding(PickoDesign.Spacing.page)
        }
        .pickoScreenBackground()
        #if os(iOS)
        .toolbar(PreDeleteBasketLayout.hidesNavigationBar ? .hidden : .visible, for: .navigationBar)
        #endif
        .sheet(item: $previewAsset) { item in
            PhotoPreviewView(asset: item.asset, model: model, context: .basket)
        }
        .confirmationDialog(
            PickoCopy.Basket.confirmationTitle,
            isPresented: $showsDeletionConfirmation,
            titleVisibility: .visible
        ) {
            Button(PickoCopy.Basket.continueAction, role: .destructive) {
                Task {
                    await confirmDeletion()
                }
            }

            Button(PickoCopy.Basket.cancelAction, role: .cancel) {}
        } message: {
            Text(ReviewCopy.photosConfirmationMessage)
        }
        .confirmationDialog(
            PickoCopy.Basket.clearConfirmationTitle,
            isPresented: $showsClearBasketConfirmation,
            titleVisibility: .visible
        ) {
            Button(PickoCopy.Basket.clearConfirmationAction, role: .destructive) {
                model.clearBasket()
            }

            Button(PickoCopy.Basket.cancelAction, role: .cancel) {}
        } message: {
            Text(PickoCopy.Basket.clearConfirmationMessage)
        }
    }

    private var isPrimaryActionDisabled: Bool {
        model.deletionQueueCount == 0 || model.photoDeleter == nil || isConfirmingDeletion
    }

    private var primaryActionBackground: Color {
        isPrimaryActionDisabled ? PickoDesign.ColorToken.surfaceHigh : PickoDesign.ColorToken.primary
    }

    private var primaryActionForeground: Color {
        isPrimaryActionDisabled ? PickoDesign.ColorToken.ink.opacity(0.7) : PickoDesign.ColorToken.primarySoft
    }

    private func finalConfirmationSection(presentation: PickoBasketPresentation) -> some View {
        VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(PickoCopy.Basket.finalActionTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.ink)
                Spacer()
                Text(presentation.summarySubtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(presentation.summaryTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.ink)
                Text(PickoCopy.Basket.finalActionMessage)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            }

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

            if PreDeleteBasketLayout.showsFinalActions(itemCount: presentation.items.count) {
                VStack(alignment: .leading, spacing: PickoDesign.Spacing.gutter) {
                    Button(role: .destructive) {
                        showsDeletionConfirmation = true
                    } label: {
                        Label(presentation.primaryActionTitle, systemImage: "checkmark.shield")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(primaryActionBackground, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                            .foregroundStyle(primaryActionForeground)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPrimaryActionDisabled)

                    if let disabledReason = isConfirmingDeletion ? PickoCopy.Basket.confirmingDisabledReason : presentation.disabledReason {
                        Text(disabledReason)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(role: .destructive) {
                        showsClearBasketConfirmation = true
                    } label: {
                        Label(PickoCopy.Basket.clear, systemImage: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(PickoDesign.ColorToken.surfaceLow, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                            .foregroundStyle(PickoDesign.ColorToken.primary)
                            .overlay {
                                RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                                    .stroke(PickoDesign.ColorToken.outline.opacity(0.6), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                .stroke(PickoDesign.ColorToken.outline.opacity(0.55), lineWidth: 1)
        }
    }

    private func basketItemsSection(presentation: PickoBasketPresentation) -> some View {
        VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(PickoCopy.Basket.itemSectionTitle)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(PickoDesign.ColorToken.ink)
                    Text(PickoCopy.Basket.itemSectionSubtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                }
                Spacer()
                Text("\(presentation.items.count) 项")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            }

            if presentation.items.isEmpty {
                PickoEmptyStateView(
                    title: PickoCopy.Basket.emptyTitle,
                    message: PickoCopy.Basket.emptyMessage,
                    systemImage: "basket"
                )
                .padding(0)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: PickoDesign.Spacing.gutter
                ) {
                    ForEach(presentation.items) { item in
                        basketItemCard(item)
                    }
                }
            }
        }
    }

    private func basketItemCard(_ item: PickoBasketItemPresentation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Button {
                    previewAsset = item
                } label: {
                    PickoThumbnailView(
                        asset: item.asset,
                        thumbnailProvider: model.thumbnailProvider,
                        targetPixelWidth: 320,
                        targetPixelHeight: 320
                    )
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("查看预删除项目 \(item.id)")

                Text(item.byteText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(PickoDesign.ColorToken.primary.opacity(0.82), in: RoundedRectangle(cornerRadius: PickoDesign.Radius.sm))
                    .foregroundStyle(.white)
                    .padding(8)
            }

            Button(PickoCopy.Basket.restore) {
                model.restoreFromBasket(assetId: item.id)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(PickoDesign.ColorToken.surfaceHigh, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.md))
            .foregroundStyle(PickoDesign.ColorToken.primary)
        }
    }

    @MainActor
    private func confirmDeletion() async {
        isConfirmingDeletion = true
        deletionErrorMessage = nil

        do {
            _ = try await model.confirmPreDeleteBasket()
        } catch {
            deletionErrorMessage = "系统照片确认未完成，请稍后重试。"
        }

        isConfirmingDeletion = false
    }
}

enum PreDeleteBasketLayout {
    static let navigationTitle: String? = nil
    static let hidesNavigationBar = true
    static let usesInlineFinalActions = true
    static let usesFloatingFinalActions = false
    static let requiresClearConfirmation = true
    static let placesItemListBeforeFinalActions = false
    static let mergesSavingsOverviewWithFinalActions = true
    static let showsStandaloneSavingsOverview = false
    static let usesUnifiedItemList = true
    static let showsSourceBuckets = false

    static func showsFinalActions(itemCount: Int) -> Bool {
        itemCount > 0
    }
}

#Preview {
    let model = PickoAppModel.preview()
    model.preDeleteCurrentAsset()
    return NavigationStack {
        PreDeleteBasketView(model: model)
    }
}
