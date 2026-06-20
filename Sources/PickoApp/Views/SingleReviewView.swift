import PickoCore
import PickoPhotos
import SwiftUI

public struct SingleReviewView: View {
    @Bindable private var model: PickoAppModel
    @State private var previewAsset: PhotoAsset?

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            if model.hasCompletedReviewScope {
                scopedCompletionView
            } else if let presentation = PickoSingleReviewPresentation(model: model) {
                GeometryReader { proxy in
                    ZStack(alignment: .bottom) {
                        reviewContent(presentation: presentation, availableHeight: proxy.size.height)
                            .padding(.horizontal, PickoDesign.Spacing.page)
                            .padding(.top, SingleReviewLayout.contentTopPadding)
                            .padding(.bottom, SingleReviewLayout.actionDockReservedHeight)

                        reviewActionDock(presentation: presentation)
                            .padding(.horizontal, PickoDesign.Spacing.page)
                            .padding(.bottom, SingleReviewLayout.actionDockBottomPadding)
                    }
                }
            } else {
                PickoEmptyStateView(
                    title: "暂无待复核照片",
                    message: "当前图库没有可继续整理的项目。你可以返回首页查看相似组或预删除篮。",
                    systemImage: "photo.on.rectangle"
                )
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
    }

    private func reviewContent(presentation: PickoSingleReviewPresentation, availableHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: SingleReviewLayout.contentSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: PickoDesign.Spacing.gutter) {
                Text(PickoCopy.Tabs.review)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.primary)

                Spacer(minLength: PickoDesign.Spacing.gutter)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(reviewProgressText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                    if let scopeTitle = model.reviewScope?.title {
                        Text(scopeTitle)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                            .lineLimit(1)
                    }
                }
            }

            Button {
                previewAsset = presentation.asset
            } label: {
                mainPhotoCard(presentation: presentation, availableHeight: availableHeight)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
    }

    private func mainPhotoCard(presentation: PickoSingleReviewPresentation, availableHeight: CGFloat) -> some View {
        let imageHeight = SingleReviewLayout.mainImageHeight(availableHeight: availableHeight)

        return GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                PickoThumbnailView(
                    asset: presentation.asset,
                    thumbnailProvider: model.thumbnailProvider,
                    targetPixelWidth: 1100,
                    targetPixelHeight: 1100,
                    contentMode: SingleReviewLayout.mainImageContentMode
                )
                .frame(width: proxy.size.width, height: imageHeight)
                .background(PickoDesign.ColorToken.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                .overlay(alignment: .top) {
                    VStack(spacing: 2) {
                        Image(systemName: "chevron.compact.up")
                            .font(.system(size: 30, weight: .semibold))
                        Text("点击预览")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(.white.opacity(0.62))
                    .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 2)
                    .padding(.top, 12)
                }
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

    private func reviewActionDock(presentation: PickoSingleReviewPresentation) -> some View {
        VStack(spacing: PickoDesign.Spacing.sm) {
            HStack(alignment: .top, spacing: PickoDesign.Spacing.md) {
                reviewCircleButton(title: "撤销", displayTitle: "撤销", systemImage: "arrow.uturn.backward") {
                    model.undo()
                }

                Button {
                    model.skipCurrentAsset()
                } label: {
                    VStack(spacing: 5) {
                        Text("跳过")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(PickoDesign.ColorToken.surfaceHigh, in: Capsule())
                            .foregroundStyle(PickoDesign.ColorToken.primary)
                        Text("下一张")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(presentation.primaryActions[2].title)

                reviewCircleButton(
                    title: presentation.primaryActions[0].title,
                    displayTitle: "保留",
                    systemImage: "star.fill",
                    accent: PickoDesign.ColorToken.gold
                ) {
                    model.keepCurrentAsset()
                }
            }

            Button {
                model.preDeleteCurrentAsset()
            } label: {
                Label("向下预删除", systemImage: presentation.primaryActions[1].systemImage)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(PickoDesign.ColorToken.coralDeep, in: Capsule())
                    .foregroundStyle(PickoDesign.ColorToken.coral)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(presentation.primaryActions[1].title)
        }
    }

    private var scopedCompletionView: some View {
        PickoPageEmptyStateView(
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
        return "\(model.currentAssetIndex + 1) / \(totalCount)"
    }

    private func reviewCircleButton(
        title: String,
        displayTitle: String,
        systemImage: String,
        accent: Color = PickoDesign.ColorToken.secondaryInk,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 56, height: 56)
                    .background(PickoDesign.ColorToken.surface, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(PickoDesign.ColorToken.outline.opacity(0.65), lineWidth: 1)
                    }
                    .foregroundStyle(accent)
                Text(displayTitle)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

enum SingleReviewLayout {
    static let contentSpacing: CGFloat = 12
    static let contentTopPadding: CGFloat = 4
    static let actionDockReservedHeight: CGFloat = 180
    static let actionDockBottomPadding: CGFloat = 32
    static let mainImageContentMode: ContentMode = .fill

    static func mainImageHeight(availableHeight: CGFloat) -> CGFloat {
        min(max(availableHeight * 0.56, 300), 430)
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
