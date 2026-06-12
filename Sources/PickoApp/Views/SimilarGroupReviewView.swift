import PickoCore
import SwiftUI

public struct SimilarGroupReviewView: View {
    @Bindable private var model: PickoAppModel
    @State private var selectedAssetIds: Set<PhotoAsset.ID>
    @State private var keepsMultiple = false
    @State private var previewAsset: PhotoAsset?

    public init(model: PickoAppModel) {
        self.model = model
        let firstGroup = model.groups.first
        self._selectedAssetIds = State(initialValue: Set(firstGroup?.recommendedKeepIds ?? []))
    }

    public var body: some View {
        Group {
            if let presentation = PickoSimilarGroupPresentation(model: model) {
                ScrollView {
                    VStack(alignment: .leading, spacing: PickoDesign.Spacing.lg) {
                        header(presentation)

                        keepModeControl(presentation.modeTitles)

                        if let hero = presentation.assetRows.first {
                            similarHeroCard(hero, badge: presentation.recommendationBadge)
                        }

                        VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                            HStack {
                                PickoSectionLabel(title: "其他相似照片")
                                Spacer()
                                Button("取消全选") {
                                    selectedAssetIds.removeAll()
                                }
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(PickoDesign.ColorToken.gold)
                            }

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: PickoDesign.Spacing.gutter),
                                    GridItem(.flexible(), spacing: PickoDesign.Spacing.gutter)
                                ],
                                spacing: PickoDesign.Spacing.gutter
                            ) {
                                ForEach(presentation.assetRows) { row in
                                    VStack(spacing: 8) {
                                        Button {
                                            toggle(row.id)
                                        } label: {
                                            similarAssetCard(row)
                                        }
                                        .buttonStyle(.plain)

                                        Button("预览") {
                                            previewAsset = row.asset
                                        }
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(PickoDesign.ColorToken.primary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(PickoDesign.Spacing.page)
                    .padding(.bottom, 160)
                }
                .safeAreaInset(edge: .bottom) {
                    stickyActionBar(presentation)
                }
            } else {
                PickoPageEmptyStateView(
                    title: PickoCopy.Similar.emptyTitle,
                    message: PickoCopy.Similar.emptyMessage,
                    systemImage: "square.grid.2x2"
                ) {
                    Button {
                        model.selectedTab = .review
                    } label: {
                        Label(PickoCopy.Similar.goReview, systemImage: "rectangle.stack")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding(.vertical, 14)
                    .background(PickoDesign.ColorToken.primary, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                    .foregroundStyle(PickoDesign.ColorToken.primarySoft)
                }
            }
        }
        .navigationTitle(PickoCopy.Tabs.similar)
        .pickoScreenBackground()
        .sheet(item: $previewAsset) { asset in
            PhotoPreviewView(asset: asset, model: model)
        }
    }

    private func header(_ presentation: PickoSimilarGroupPresentation) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                PickoSectionLabel(title: "相似组整理")
                Text("上海之行")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.primary)
                Text("\(presentation.group.assetIds.count) 张照片 · 保留 \(max(selectedAssetIds.count, 1)) 张")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            }

            Spacer()
        }
    }

    private func toggle(_ id: PhotoAsset.ID) {
        if selectedAssetIds.contains(id) {
            selectedAssetIds.remove(id)
        } else if keepsMultiple {
            selectedAssetIds.insert(id)
        } else {
            selectedAssetIds = [id]
        }
    }

    private func keepModeControl(_ titles: [String]) -> some View {
        HStack(spacing: 0) {
            keepModeButton(title: titles[0], isSelected: !keepsMultiple) {
                keepsMultiple = false
                if selectedAssetIds.count > 1, let first = selectedAssetIds.first {
                    selectedAssetIds = [first]
                }
            }

            keepModeButton(title: titles[1], isSelected: keepsMultiple) {
                keepsMultiple = true
            }
        }
        .padding(4)
        .background(PickoDesign.ColorToken.surfaceContainer, in: Capsule())
        .overlay {
            Capsule()
                .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("保留模式")
    }

    private func keepModeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? PickoDesign.ColorToken.surface : Color.clear, in: Capsule())
                .foregroundStyle(isSelected ? PickoDesign.ColorToken.primary : PickoDesign.ColorToken.secondaryInk)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func similarHeroCard(_ row: PickoSimilarAssetPresentation, badge: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            PickoThumbnailView(
                asset: row.asset,
                thumbnailProvider: model.thumbnailProvider,
                targetPixelWidth: 700,
                targetPixelHeight: 520
            )
            .aspectRatio(1.3, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
            .overlay(alignment: .topTrailing) {
                Text(badge)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(PickoDesign.ColorToken.goldSoft, in: Capsule())
                    .foregroundStyle(PickoDesign.ColorToken.primaryDeep)
                    .padding(14)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, .black.opacity(0.62)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("推荐")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(.white.opacity(0.76))
                Text("推荐保留")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(PickoDesign.Spacing.md)
        }
    }

    private func similarAssetCard(_ row: PickoSimilarAssetPresentation) -> some View {
        let isSelected = selectedAssetIds.contains(row.id)

        return ZStack(alignment: .topTrailing) {
            PickoThumbnailView(
                asset: row.asset,
                thumbnailProvider: model.thumbnailProvider,
                targetPixelWidth: 260,
                targetPixelHeight: 260
            )
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
            .opacity(isSelected ? 1 : 0.62)
            .overlay {
                if isSelected {
                    PickoDesign.ColorToken.gold.opacity(0.18)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                    .stroke(isSelected ? PickoDesign.ColorToken.gold : PickoDesign.ColorToken.outline.opacity(0.65), lineWidth: isSelected ? 2 : 1)
            }

            Image(systemName: isSelected ? "checkmark" : "circle")
                .font(.system(size: 12, weight: .bold))
                .frame(width: 26, height: 26)
                .background(isSelected ? PickoDesign.ColorToken.gold : .white.opacity(0.42), in: Circle())
                .foregroundStyle(isSelected ? PickoDesign.ColorToken.primaryDeep : .white)
                .padding(8)
        }
    }

    private func stickyActionBar(_ presentation: PickoSimilarGroupPresentation) -> some View {
        VStack(spacing: PickoDesign.Spacing.gutter) {
            HStack(spacing: PickoDesign.Spacing.gutter) {
                Image(systemName: "basket")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(PickoDesign.ColorToken.coral)
                    .overlay(alignment: .topTrailing) {
                        Text("\(max(presentation.group.assetIds.count - selectedAssetIds.count, 0))")
                            .font(.system(size: 9, weight: .bold))
                            .padding(4)
                            .background(PickoDesign.ColorToken.destructive, in: Circle())
                            .foregroundStyle(.white)
                            .offset(x: 9, y: -9)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("已选择 \(selectedAssetIds.count) 张")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text(presentation.footerExplanation)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(PickoDesign.ColorToken.coral.opacity(0.75))
                }

                Spacer()
            }
            .padding(PickoDesign.Spacing.md)
            .background(PickoDesign.ColorToken.coralDeep, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
            .foregroundStyle(PickoDesign.ColorToken.coral)

            HStack(spacing: PickoDesign.Spacing.md) {
                Button {
                    model.keep(assetIds: Array(selectedAssetIds), in: presentation.group)
                } label: {
                    Label("保留推荐", systemImage: "star")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .padding(.vertical, 16)
                .background(PickoDesign.ColorToken.surfaceHigh, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                .foregroundStyle(PickoDesign.ColorToken.primary)

                Button {
                    model.keep(assetIds: Array(selectedAssetIds), in: presentation.group)
                } label: {
                    Label("保留所选", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .padding(.vertical, 16)
                .background(PickoDesign.ColorToken.primary, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                .foregroundStyle(PickoDesign.ColorToken.primarySoft)
            }
        }
        .padding(PickoDesign.Spacing.page)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationStack {
        SimilarGroupReviewView(model: .preview())
    }
}
