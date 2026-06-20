import PickoCore
import PickoPhotos
import SwiftUI

public struct SingleReviewView: View {
    @Bindable private var model: PickoAppModel
    @AppStorage(ReviewGesturePreference.storageKey) private var gesturePreferenceRawValue = ReviewGesturePreference.keepOnUp.rawValue
    @State private var previewAsset: PhotoAsset?
    @State private var showsGestureSettings = false
    @State private var dragOffset: CGSize = .zero

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            if model.hasCompletedReviewScope {
                scopedCompletionView
            } else if let presentation = PickoSingleReviewPresentation(model: model) {
                GeometryReader { proxy in
                    reviewContent(
                        presentation: presentation,
                        availableWidth: max(proxy.size.width - PickoDesign.Spacing.page * 2, 1),
                        availableHeight: max(
                            proxy.size.height
                            - SingleReviewLayout.contentTopPadding
                            - PickoDesign.Spacing.page,
                            1
                        )
                    )
                    .padding(.horizontal, PickoDesign.Spacing.page)
                    .padding(.top, SingleReviewLayout.contentTopPadding)
                    .padding(.bottom, PickoDesign.Spacing.page)
                }
            } else {
                emptyReviewView
            }
        }
        .navigationTitle(PickoCopy.Tabs.review)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .pickoScreenBackground()
        .sheet(item: $previewAsset) { asset in
            PhotoPreviewView(asset: asset, model: model)
        }
        .sheet(isPresented: $showsGestureSettings) {
            ReviewGestureSettingsView()
        }
    }

    private func reviewContent(
        presentation: PickoSingleReviewPresentation,
        availableWidth: CGFloat,
        availableHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: SingleReviewLayout.contentSpacing) {
            reviewHeader(showsProgress: true, showsUndoAction: true)

            photoStage(
                presentation: presentation,
                availableWidth: availableWidth,
                availableHeight: availableHeight
            )
        }
    }

    private var emptyReviewView: some View {
        let action = PickoReviewEmptyActionPresentation(model: model)

        return reviewStatePage(
            title: PickoCopy.Review.emptyTitle,
            message: PickoCopy.Review.emptyMessage,
            systemImage: "photo.on.rectangle",
            usesBackgroundCard: SingleReviewLayout.emptyStateUsesBackgroundCard
        ) {
            Button {
                model.selectedTab = action.destinationTab
            } label: {
                Label(action.title, systemImage: action.systemImage)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(PickoDesign.ColorToken.primary, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                    .foregroundStyle(PickoDesign.ColorToken.primarySoft)
            }
            .buttonStyle(.plain)
        }
    }

    private func reviewHeader(showsProgress: Bool, showsUndoAction: Bool) -> some View {
        PickoTopLevelHeader(
            spec: .review,
            trailingPrimaryText: showsProgress ? reviewProgressText : nil,
            trailingSecondaryText: model.reviewScope?.title,
            auxiliaryTrailingSystemImage: showsUndoAction ? "arrow.uturn.backward" : nil,
            auxiliaryTrailingAccessibilityLabel: showsUndoAction ? "上一张" : nil,
            auxiliaryTrailingAction: showsUndoAction ? {
                model.undoAndReturnToPreviousAsset()
            } : nil,
            trailingSystemImage: "gearshape",
            trailingAccessibilityLabel: "设置",
            trailingAction: {
                showsGestureSettings = true
            }
        )
    }

    private func reviewStatePage<Actions: View>(
        title: String,
        message: String,
        systemImage: String,
        usesBackgroundCard: Bool = true,
        @ViewBuilder actions: @escaping () -> Actions
    ) -> some View {
        VStack(alignment: .leading, spacing: SingleReviewLayout.contentSpacing) {
            reviewHeader(showsProgress: false, showsUndoAction: false)

            VStack {
                Spacer(minLength: PickoDesign.Spacing.lg)

                reviewStateCard(
                    title: title,
                    message: message,
                    systemImage: systemImage,
                    usesBackgroundCard: usesBackgroundCard,
                    actions: actions
                )

                Spacer(minLength: PickoDesign.Spacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, PickoDesign.Spacing.page)
        .padding(.top, SingleReviewLayout.emptyStateTopPadding)
        .padding(.bottom, PickoDesign.Spacing.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func reviewStateCard<Actions: View>(
        title: String,
        message: String,
        systemImage: String,
        usesBackgroundCard: Bool,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(spacing: PickoDesign.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .frame(width: 72, height: 72)
                .background(PickoDesign.ColorToken.primarySoft.opacity(0.7), in: Circle())
                .foregroundStyle(PickoDesign.ColorToken.primary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.primary)
                Text(message)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            }

            actions()
                .padding(.top, PickoDesign.Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(usesBackgroundCard ? PickoDesign.Spacing.lg : 0)
        .background {
            if usesBackgroundCard {
                RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                    .fill(PickoDesign.ColorToken.surface)
            }
        }
        .overlay {
            if usesBackgroundCard {
                RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                    .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
            }
        }
    }

    private func photoStage(
        presentation: PickoSingleReviewPresentation,
        availableWidth: CGFloat,
        availableHeight: CGFloat
    ) -> some View {
        let aspectRatio = SingleReviewLayout.aspectRatio(for: presentation.asset)
        let imageHeight = SingleReviewLayout.mainImageHeight(
            availableWidth: availableWidth,
            availableHeight: availableHeight,
            aspectRatio: aspectRatio
        )
        let contentMode = SingleReviewLayout.mainImageContentMode(forAspectRatio: aspectRatio)
        let usesBackdrop = SingleReviewLayout.usesBackdropFill(forAspectRatio: aspectRatio)
        let preference = reviewGesturePreference
        let activeAction = SingleReviewLayout.gestureAction(for: dragOffset, preference: preference)

        return GeometryReader { proxy in
            VStack(spacing: PickoDesign.Spacing.gutter) {
                gestureHint(
                    title: preference.topHintTitle,
                    systemImage: preference.topAction.systemImage,
                    action: preference.topAction,
                    isActive: activeAction == preference.topAction
                )

                ZStack {
                    ForEach(Array(model.reviewStackPreviewAssets(limit: SingleReviewLayout.stackedCardCount).enumerated()).reversed(), id: \.element.id) { index, asset in
                        stackedPreviewCard(
                            asset: asset,
                            index: index,
                            width: proxy.size.width,
                            height: imageHeight
                        )
                    }

                    mainPhotoCard(
                        presentation: presentation,
                        imageHeight: imageHeight,
                        contentMode: contentMode,
                        usesBackdrop: usesBackdrop
                    )
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width / 28)))
                    .animation(.spring(response: 0.26, dampingFraction: 0.82), value: dragOffset)
                    .overlay(alignment: activeAction?.overlayAlignment ?? .center) {
                        if let activeAction {
                            actionBadge(activeAction.badgeTitle, systemImage: activeAction.systemImage, action: activeAction)
                                .padding(PickoDesign.Spacing.md)
                        }
                    }
                    .onTapGesture {
                        previewAsset = presentation.asset
                    }
                    .gesture(reviewDragGesture(preference: preference))
                }
                .frame(width: proxy.size.width, height: imageHeight + 34)

                gestureHint(
                    title: preference.bottomHintTitle,
                    systemImage: preference.bottomAction.systemImage,
                    action: preference.bottomAction,
                    isActive: activeAction == preference.bottomAction
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func mainPhotoCard(
        presentation: PickoSingleReviewPresentation,
        imageHeight: CGFloat,
        contentMode: ContentMode,
        usesBackdrop: Bool
    ) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                if usesBackdrop {
                    PickoThumbnailView(
                        asset: presentation.asset,
                        thumbnailProvider: model.thumbnailProvider,
                        targetPixelWidth: 1100,
                        targetPixelHeight: 1100,
                        contentMode: .fill
                    )
                    .frame(width: proxy.size.width, height: imageHeight)
                    .scaleEffect(1.08)
                    .blur(radius: 18)
                    .opacity(0.74)
                    .overlay(PickoDesign.ColorToken.primary.opacity(0.2))
                    .clipped()
                }

                PickoThumbnailView(
                    asset: presentation.asset,
                    thumbnailProvider: model.thumbnailProvider,
                    targetPixelWidth: 1100,
                    targetPixelHeight: 1100,
                    contentMode: contentMode,
                    loadedPlaceholderOpacity: usesBackdrop ? 0 : 1
                )
                .frame(width: proxy.size.width, height: imageHeight)
                .background(PickoDesign.ColorToken.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.68)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                        .stroke(PickoDesign.ColorToken.outline.opacity(0.58), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(presentation.dateLocationText)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text(presentation.metadataSummary)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 34, height: 34)
                            .background(PickoDesign.ColorToken.goldSoft, in: Circle())
                            .foregroundStyle(PickoDesign.ColorToken.primaryDeep)
                    }
                }
                .padding(PickoDesign.Spacing.md)
            }
            .contentShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
        }
        .frame(height: imageHeight)
    }

    private func stackedPreviewCard(asset: PhotoAsset, index: Int, width: CGFloat, height: CGFloat) -> some View {
        let level = CGFloat(index + 1)
        let corner = RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
        let scale = 1 - level * 0.045

        return PickoThumbnailView(
            asset: asset,
            thumbnailProvider: model.thumbnailProvider,
            targetPixelWidth: 900,
            targetPixelHeight: 900,
            contentMode: .fill
        )
        .frame(width: width, height: height)
        .background(PickoDesign.ColorToken.surfaceLow)
        .clipShape(corner)
        .overlay {
            corner
                .stroke(PickoDesign.ColorToken.outline.opacity(0.4), lineWidth: 1)
        }
        .scaleEffect(scale)
        .offset(x: level * 10, y: level * 14)
        .overlay {
            corner
                .fill(PickoDesign.ColorToken.surface.opacity(level * 0.18))
        }
        .shadow(color: PickoDesign.ColorToken.primary.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private func gestureHint(title: String, systemImage: String, action: SingleReviewGestureAction, isActive: Bool) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(action.tint.opacity(isActive ? 0.24 : 0.1), in: Capsule())
            .foregroundStyle(isActive ? action.tint : PickoDesign.ColorToken.secondaryInk)
    }

    private func actionBadge(_ title: String, systemImage: String, action: SingleReviewGestureAction) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(action.tint.opacity(0.92), in: Capsule())
            .foregroundStyle(.white)
            .shadow(color: action.tint.opacity(0.24), radius: 12, x: 0, y: 6)
    }

    private func reviewDragGesture(preference: ReviewGesturePreference) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let action = SingleReviewLayout.gestureAction(for: value.translation, preference: preference)

                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    dragOffset = .zero
                }

                guard let action else {
                    return
                }
                applyGestureAction(action)
            }
    }

    private func applyGestureAction(_ action: SingleReviewGestureAction) {
        switch action {
        case .keep:
            model.keepCurrentAsset()
        case .preDelete:
            model.preDeleteCurrentAsset()
        case .skip:
            model.skipCurrentAsset()
        case .undo:
            model.undoAndReturnToPreviousAsset()
        }
    }

    private var scopedCompletionView: some View {
        reviewStatePage(
            title: "本合集已整理完成",
            message: "这个时间或地点合集内的照片已处理完。已放入预删除篮的项目仍可在最终确认前恢复。",
            systemImage: "checkmark.circle"
        ) {
            VStack(spacing: PickoDesign.Spacing.gutter) {
                Button {
                    model.clearReviewScope()
                    model.selectedTab = .home
                } label: {
                    Label("返回首页", systemImage: "house")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(PickoDesign.ColorToken.primary, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button {
                    model.clearReviewScope()
                    model.selectedTab = .basket
                } label: {
                    Label("查看预删除篮", systemImage: "basket")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(PickoDesign.ColorToken.surface, in: Capsule())
                        .foregroundStyle(PickoDesign.ColorToken.primary)
                        .overlay {
                            Capsule()
                                .stroke(PickoDesign.ColorToken.outline.opacity(0.55), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var reviewProgressText: String {
        let totalCount = max(model.activeReviewAssetCount, 1)
        return SingleReviewLayout.reviewProgressText(
            currentIndex: model.currentAssetIndex,
            totalCount: totalCount
        )
    }

    private var reviewGesturePreference: ReviewGesturePreference {
        ReviewGesturePreference.resolved(rawValue: gesturePreferenceRawValue)
    }

}

enum SingleReviewLayout {
    static let contentSpacing: CGFloat = 12
    static let contentTopPadding: CGFloat = PickoDesign.Spacing.page
    static let emptyStateTopPadding: CGFloat = contentTopPadding
    static let actionDockReservedHeight: CGFloat = 0
    static let actionDockBottomPadding: CGFloat = 0
    static let gestureThreshold: CGFloat = 72
    static let stackedCardCount = 2
    static let showsStackedCards = true
    static let emptyStateUsesTopLevelHeader = true
    static let emptyStateUsesScreenBackground = true
    static let emptyStateMatchesSimilarEmptyStateStyle = true
    static let emptyStateUsesBackgroundCard = false
    static let emptyStateUsesPrimaryNextAction = true
    static let centersPhotoStageVertically = true
    static let showsLargePreDeleteDockButton = false
    static let showsFallbackActionDock = false
    static let showsTopUndoAction = true

    static func reviewProgressText(currentIndex: Int, totalCount: Int) -> String {
        "第 \(currentIndex + 1) / \(max(totalCount, 1)) 张"
    }

    static func gestureAction(
        for translation: CGSize,
        preference: ReviewGesturePreference
    ) -> SingleReviewGestureAction? {
        let horizontalDistance = abs(translation.width)
        let verticalDistance = abs(translation.height)
        let primaryDistance = max(horizontalDistance, verticalDistance)

        guard primaryDistance >= gestureThreshold else {
            return nil
        }

        if horizontalDistance > verticalDistance {
            return translation.width < 0 ? .undo : .skip
        }

        if translation.height < 0 {
            return preference.topAction
        }
        return preference.bottomAction
    }

    static func mainImageHeight(
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        aspectRatio: Double
    ) -> CGFloat {
        let normalizedAspectRatio = max(CGFloat(aspectRatio), 0.1)
        let preferredHeight = max(availableWidth, 1) / normalizedAspectRatio
        let maxHeight = min(max(availableHeight * 0.56, 300), 430)
        return min(preferredHeight, maxHeight)
    }

    static func aspectRatio(for asset: PhotoAsset) -> Double {
        guard asset.pixelWidth > 0, asset.pixelHeight > 0 else {
            return 1
        }

        return Double(asset.pixelWidth) / Double(asset.pixelHeight)
    }

    static func mainImageContentMode(forAspectRatio aspectRatio: Double) -> ContentMode {
        usesBackdropFill(forAspectRatio: aspectRatio) ? .fit : .fill
    }

    static func usesBackdropFill(forAspectRatio aspectRatio: Double) -> Bool {
        aspectRatio >= 1.65 || aspectRatio <= 0.62
    }
}

extension SingleReviewGestureAction {
    var badgeTitle: String {
        switch self {
        case .keep:
            return "保留"
        case .preDelete:
            return "预删除"
        case .skip:
            return "跳过"
        case .undo:
            return "上一张"
        }
    }

    var systemImage: String {
        switch self {
        case .keep:
            return "star.fill"
        case .preDelete:
            return "tray.and.arrow.down"
        case .skip:
            return "arrow.right"
        case .undo:
            return "arrow.left"
        }
    }

    var tint: Color {
        switch self {
        case .keep:
            return PickoDesign.ColorToken.gold
        case .preDelete:
            return PickoDesign.ColorToken.coralDeep
        case .skip:
            return PickoDesign.ColorToken.primary
        case .undo:
            return PickoDesign.ColorToken.secondaryInk
        }
    }

    var overlayAlignment: Alignment {
        switch self {
        case .keep:
            return .top
        case .preDelete:
            return .bottom
        case .skip:
            return .trailing
        case .undo:
            return .leading
        }
    }
}

struct AssetSummaryView: View {
    let asset: PhotoAsset
    let thumbnailProvider: (any PhotoThumbnailProviding)?

    var body: some View {
        VStack(spacing: 12) {
            PickoThumbnailView(asset: asset, thumbnailProvider: thumbnailProvider)
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))

            VStack(spacing: 4) {
                Text(asset.id)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.primary)
                Text("\(asset.pixelWidth)x\(asset.pixelHeight) · \(byteText)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            }
        }
        .padding(PickoDesign.Spacing.md)
        .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
    }

    private var byteText: String {
        ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file)
    }
}

#Preview {
    NavigationStack {
        SingleReviewView(model: .preview())
    }
}
