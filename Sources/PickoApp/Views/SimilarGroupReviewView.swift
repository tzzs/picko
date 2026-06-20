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
                        PickoTopLevelHeader(spec: .similar)

                        header(presentation)

                        keepModeControl(presentation.modeTitles)

                        if let hero = presentation.assetRows.first {
                            similarHeroCard(hero, badge: presentation.recommendationBadge)
                        }

                        VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                            HStack {
                                PickoSectionLabel(title: "其他相似照片")
                                Spacer()
                                Button(selectionShortcutTitle(for: presentation)) {
                                    applySelectionShortcut(for: presentation)
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
                                        .accessibilityLabel("选择相似照片 \(row.id)")
                                        .accessibilityValue(selectedAssetIds.contains(row.id) ? "已选择" : "未选择")

                                        Button("预览") {
                                            previewAsset = row.asset
                                        }
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(PickoDesign.ColorToken.primary)
                                    }
                                }
                            }
                        }

                        inlineConfirmationFooter(presentation)
                    }
                    .padding(PickoDesign.Spacing.page)
                    .padding(.bottom, 112)
                }
            } else {
                similarEmptyStateView
            }
        }
        .pickoScreenBackground()
        #if os(iOS)
        .toolbar(SimilarReviewLayout.hidesNavigationBar ? .hidden : .visible, for: .navigationBar)
        #endif
        .sheet(item: $previewAsset) { asset in
            PhotoPreviewView(asset: asset, model: model)
        }
    }

    private var similarEmptyStateView: some View {
        VStack(alignment: .leading, spacing: PickoDesign.Spacing.lg) {
            PickoTopLevelHeader(spec: .similar)

            VStack(spacing: PickoDesign.Spacing.md) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 36, weight: .semibold))
                    .frame(width: 76, height: 76)
                    .background(PickoDesign.ColorToken.primarySoft.opacity(0.7), in: Circle())
                    .foregroundStyle(PickoDesign.ColorToken.primary)

                VStack(spacing: 8) {
                    Text(PickoCopy.Similar.emptyTitle)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(PickoDesign.ColorToken.primary)
                    Text(PickoCopy.Similar.emptyMessage)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                }

                Button {
                    model.selectedTab = .review
                } label: {
                    Label(PickoCopy.Similar.goReview, systemImage: "rectangle.stack")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(PickoDesign.ColorToken.primary, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                        .foregroundStyle(PickoDesign.ColorToken.primarySoft)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 168)
        }
        .padding(PickoDesign.Spacing.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        let result = SimilarSelectionBehavior.toggledSelection(
            currentSelection: selectedAssetIds,
            toggledId: id,
            keepsMultiple: keepsMultiple
        )
        selectedAssetIds = result.selectedAssetIds
        keepsMultiple = result.keepsMultiple
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
        let shape = RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)

        return ZStack(alignment: .bottomLeading) {
            PickoThumbnailView(
                asset: row.asset,
                thumbnailProvider: model.thumbnailProvider,
                targetPixelWidth: 700,
                targetPixelHeight: 520
            )
            .aspectRatio(1.3, contentMode: .fill)
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
        .clipShape(shape)
        .overlay {
            shape.stroke(PickoDesign.ColorToken.outline.opacity(0.4), lineWidth: 1)
        }
    }

    private func similarAssetCard(_ row: PickoSimilarAssetPresentation) -> some View {
        let isSelected = selectedAssetIds.contains(row.id)
        let shape = RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)

        return ZStack(alignment: .topTrailing) {
            PickoThumbnailView(
                asset: row.asset,
                thumbnailProvider: model.thumbnailProvider,
                targetPixelWidth: 260,
                targetPixelHeight: 260
            )
            .aspectRatio(1, contentMode: .fill)
            .opacity(isSelected ? 1 : 0.62)
            .overlay {
                if isSelected {
                    shape.fill(PickoDesign.ColorToken.gold.opacity(0.18))
                }
            }

            selectionIndicator(isSelected: isSelected)
                .padding(8)
        }
        .clipShape(shape)
        .overlay {
            shape.stroke(isSelected ? PickoDesign.ColorToken.gold : PickoDesign.ColorToken.outline.opacity(0.72), lineWidth: isSelected ? 2 : 1)
        }
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(PickoDesign.ColorToken.surface.opacity(isSelected ? 0.94 : 0.78))

            Circle()
                .stroke(
                    isSelected ? PickoDesign.ColorToken.gold.opacity(0.95) : PickoDesign.ColorToken.primary.opacity(0.38),
                    lineWidth: isSelected ? 1.5 : 1
                )

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(PickoDesign.ColorToken.primary)
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityLabel(isSelected ? "已选择" : "未选择")
    }

    private func inlineConfirmationFooter(_ presentation: PickoSimilarGroupPresentation) -> some View {
        VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
            Divider()
                .overlay(PickoDesign.ColorToken.outline.opacity(0.55))

            HStack(alignment: .center, spacing: PickoDesign.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("已选择 \(selectedAssetIds.count) 张 · 其余将进入预删除篮")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(PickoDesign.ColorToken.primary)
                    Text(presentation.footerExplanation)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                }

                Spacer(minLength: PickoDesign.Spacing.gutter)

                Button {
                    restoreRecommendation(from: presentation)
                } label: {
                    Text("恢复推荐")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .buttonStyle(.plain)
                .foregroundStyle(PickoDesign.ColorToken.gold)
            }

            Button {
                model.keep(assetIds: Array(selectedAssetIds), in: presentation.group)
            } label: {
                Label("确认选择", systemImage: "checkmark")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(PickoDesign.ColorToken.primary, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                    .foregroundStyle(PickoDesign.ColorToken.primarySoft)
            }
            .buttonStyle(.plain)
            .disabled(selectedAssetIds.isEmpty)
            .opacity(selectedAssetIds.isEmpty ? 0.54 : 1)
        }
        .padding(.top, PickoDesign.Spacing.sm)
    }

    private func restoreRecommendation(from presentation: PickoSimilarGroupPresentation) {
        selectedAssetIds = Set(presentation.group.recommendedKeepIds)
        keepsMultiple = presentation.group.recommendedKeepIds.count > 1
    }

    private func selectionShortcutTitle(for presentation: PickoSimilarGroupPresentation) -> String {
        SimilarSelectionBehavior.shortcutTitle(
            currentSelection: selectedAssetIds,
            allAssetIds: presentation.group.assetIds
        )
    }

    private func applySelectionShortcut(for presentation: PickoSimilarGroupPresentation) {
        let result = SimilarSelectionBehavior.applyingShortcut(
            currentSelection: selectedAssetIds,
            allAssetIds: presentation.group.assetIds,
            recommendedKeepIds: presentation.group.recommendedKeepIds
        )
        selectedAssetIds = result.selectedAssetIds
        keepsMultiple = result.keepsMultiple
    }
}

struct SimilarSelectionBehavior {
    struct Result: Equatable {
        var selectedAssetIds: Set<PhotoAsset.ID>
        var keepsMultiple: Bool
    }

    static func toggledSelection(
        currentSelection: Set<PhotoAsset.ID>,
        toggledId: PhotoAsset.ID,
        keepsMultiple: Bool
    ) -> Result {
        var nextSelection = currentSelection

        if nextSelection.contains(toggledId) {
            nextSelection.remove(toggledId)
            return Result(selectedAssetIds: nextSelection, keepsMultiple: keepsMultiple)
        }

        if keepsMultiple || !nextSelection.isEmpty {
            nextSelection.insert(toggledId)
            return Result(selectedAssetIds: nextSelection, keepsMultiple: true)
        }

        return Result(selectedAssetIds: [toggledId], keepsMultiple: false)
    }

    static func shortcutTitle(currentSelection: Set<PhotoAsset.ID>, allAssetIds: [PhotoAsset.ID]) -> String {
        currentSelection.isSuperset(of: Set(allAssetIds)) ? "恢复推荐" : "全选"
    }

    static func applyingShortcut(
        currentSelection: Set<PhotoAsset.ID>,
        allAssetIds: [PhotoAsset.ID],
        recommendedKeepIds: [PhotoAsset.ID]
    ) -> Result {
        let allAssetIds = Set(allAssetIds)
        let nextSelection: Set<PhotoAsset.ID>

        if currentSelection.isSuperset(of: allAssetIds) {
            nextSelection = Set(recommendedKeepIds)
        } else {
            nextSelection = allAssetIds
        }

        return Result(selectedAssetIds: nextSelection, keepsMultiple: nextSelection.count > 1)
    }
}

enum SimilarReviewLayout {
    static let navigationTitle: String? = nil
    static let hidesNavigationBar = true
    static let emptyStateUsesTopAlignment = true
    static let usesFloatingActionBar = false
    static let usesInlineActionSummary = true
    static let clipsHeroOverlaysToRoundedShape = true
    static let clipsGridSelectionOverlayToRoundedShape = true
    static let usesHighContrastSelectionIndicator = false
    static let usesSubtleSelectionIndicator = true
    static let usesStandaloneConfirmationCard = false
    static let usesInlineConfirmationFooter = true
    static let restoresRecommendationWithoutSubmitting = true
}

#Preview {
    NavigationStack {
        SimilarGroupReviewView(model: .preview())
    }
}
