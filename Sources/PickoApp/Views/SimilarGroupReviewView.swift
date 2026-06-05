import PickoCore
import SwiftUI

public struct SimilarGroupReviewView: View {
    @Bindable private var model: PickoAppModel
    @State private var selectedAssetIds: Set<PhotoAsset.ID>
    @State private var keepsMultiple = false

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

                        Picker("Keep mode", selection: $keepsMultiple) {
                            Text(presentation.modeTitles[0]).tag(false)
                            Text(presentation.modeTitles[1]).tag(true)
                        }
                        .pickerStyle(.segmented)

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
                                    Button {
                                        toggle(row.id)
                                    } label: {
                                        similarAssetCard(row)
                                    }
                                    .buttonStyle(.plain)
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
                PickoEmptyStateView(
                    title: "暂无相似照片组",
                    message: "Picko 还没有发现需要成组复核的相似照片。继续单张整理或等待新的图库索引。",
                    systemImage: "square.grid.2x2"
                )
            }
        }
        .navigationTitle("Similar")
        .pickoScreenBackground()
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

            Button("跳过此组") {}
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(PickoDesign.ColorToken.gold)
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
                Text("BEST QUALITY")
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
                    Label("Keep selected", systemImage: "arrow.right")
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
