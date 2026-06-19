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
            if let presentation = PickoSingleReviewPresentation(model: model) {
                GeometryReader { proxy in
                    VStack(spacing: PickoDesign.Spacing.md) {
                        VStack(spacing: 2) {
                            Text("复核")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(PickoDesign.ColorToken.primary)
                            Text("\(model.currentAssetIndex + 1) / \(max(model.assets.count, 1))")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                        }

                        Button {
                            previewAsset = presentation.asset
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                PickoThumbnailView(
                                    asset: presentation.asset,
                                    thumbnailProvider: model.thumbnailProvider,
                                    targetPixelWidth: 900,
                                    targetPixelHeight: 900,
                                    contentMode: .fit
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: SingleReviewLayout.mainImageHeight(availableHeight: proxy.size.height))
                                .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                                .background(PickoDesign.ColorToken.surfaceLow, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                                .overlay(alignment: .top) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "chevron.compact.up")
                                            .font(.system(size: 30, weight: .semibold))
                                        Text("点击预览")
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    }
                                    .foregroundStyle(PickoDesign.ColorToken.primary.opacity(0.45))
                                    .padding(.top, 12)
                                }
                                .overlay(alignment: .bottom) {
                                    LinearGradient(
                                        colors: [.clear, .black.opacity(0.62)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                                        .stroke(PickoDesign.ColorToken.outline.opacity(0.7), lineWidth: 1)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("2026年5月30日 · 上海")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)
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
                        }
                        .buttonStyle(.plain)

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

                            reviewCircleButton(title: presentation.primaryActions[0].title, displayTitle: "保留", systemImage: "star.fill", accent: PickoDesign.ColorToken.gold) {
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
                    .padding(PickoDesign.Spacing.page)
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
        .pickoScreenBackground()
        .sheet(item: $previewAsset) { asset in
            PhotoPreviewView(asset: asset, model: model)
        }
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
    static func mainImageHeight(availableHeight: CGFloat) -> CGFloat {
        min(max(availableHeight * 0.48, 260), 390)
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
