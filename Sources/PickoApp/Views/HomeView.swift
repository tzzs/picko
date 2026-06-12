import SwiftUI

public struct HomeView: View {
    @Bindable private var model: PickoAppModel
    @State private var isConfirmingClearState = false

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        let presentation = PickoHomePresentation(model: model)

        ScrollView {
            VStack(alignment: .leading, spacing: PickoDesign.Spacing.lg) {
                PickoBrandHeader(title: "拾影")

                VStack(alignment: .leading, spacing: PickoDesign.Spacing.sm) {
                    PickoSectionLabel(title: "今日建议")
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        PickoDesign.ColorToken.primary,
                                        PickoDesign.ColorToken.primaryDeep
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 68, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.08))
                                    .padding(20)
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("本周新增 \(model.assets.count) 张照片")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(presentation.privacyFootnote)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(3)
                            HStack(spacing: 8) {
                                Text("\(model.groups.count) 组相似照片")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(PickoDesign.ColorToken.goldSoft, in: Capsule())
                                    .foregroundStyle(PickoDesign.ColorToken.primaryDeep)
                                Text("点击整理")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }
                        .padding(PickoDesign.Spacing.md)
                    }
                    .frame(minHeight: 205)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                    ForEach(presentation.metricRows, id: \.label) { metric in
                        PickoMetricCapsule(value: metric.value, label: localizedMetricLabel(metric.label))
                    }
                }

                VStack(alignment: .leading, spacing: PickoDesign.Spacing.gutter) {
                    PickoSectionLabel(title: "快速开始")

                    ForEach(Array(presentation.taskRows.enumerated()), id: \.element.title) { index, task in
                        Button {
                            openTask(at: index)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: task.systemImage)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(task.stitchForegroundColor)
                                    .frame(width: 42, height: 42)
                                    .background(task.stitchBackgroundColor, in: Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(localizedTaskTitle(task.title))
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(task.tintRole == .keep ? .white : PickoDesign.ColorToken.ink)
                                    Text(localizedTaskSubtitle(task.subtitle))
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(task.tintRole == .keep ? .white.opacity(0.62) : PickoDesign.ColorToken.secondaryInk)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(PickoDesign.Spacing.md)
                        .background(
                            task.tintRole == .keep ? PickoDesign.ColorToken.primary : PickoDesign.ColorToken.surface,
                            in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                                .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: task.tintRole == .keep ? 0 : 1)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: PickoDesign.Spacing.gutter) {
                    PickoSectionLabel(title: "探索合集")
                    collectionRow(title: "时间", subtitle: "2014 - 2024", systemImage: "clock")
                    collectionRow(title: "地点", subtitle: "12 个国家 / 地区", systemImage: "location")
                }

                PickoFloatingBasketButton(count: model.deletionQueueCount) {
                    model.selectedTab = .basket
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(PickoDesign.Spacing.page)
            .padding(.bottom, 96)
        }
        .navigationTitle("Picko")
        .pickoInlineNavigationTitle()
        .pickoScreenBackground()
        .confirmationDialog(
            "Clear Picko review state?",
            isPresented: $isConfirmingClearState,
            titleVisibility: .visible
        ) {
            Button("Clear Picko state", role: .destructive) {
                model.clearLocalReviewState()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This only resets local Picko review progress. It does not delete or modify photos.")
        }
    }

    private func openTask(at index: Int) {
        switch index {
        case 0:
            model.selectedTab = .review
        case 1:
            model.selectedTab = .similar
        case 2:
            model.selectedTab = .basket
        default:
            model.selectedTab = .home
        }
    }

    private func collectionRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: PickoDesign.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(PickoDesign.ColorToken.primary)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Spacer()
            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PickoDesign.ColorToken.outline)
        }
        .padding(PickoDesign.Spacing.md)
        .background(PickoDesign.ColorToken.surfaceLow, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                .stroke(PickoDesign.ColorToken.outline.opacity(0.35), lineWidth: 1)
        }
    }

    private func localizedMetricLabel(_ label: String) -> String {
        switch label {
        case "Library":
            return "图库"
        case "Similar groups":
            return "相似组"
        case "Pre-delete basket":
            return "预删除篮"
        default:
            return label
        }
    }

    private func localizedTaskTitle(_ title: String) -> String {
        switch title {
        case "Review one by one":
            return "单张整理"
        case "Review similar photos":
            return "智能整理"
        case "Review pre-delete basket":
            return "预删除篮复核"
        case "Browse by time and place":
            return "按时间地点浏览"
        default:
            return title
        }
    }

    private func localizedTaskSubtitle(_ subtitle: String) -> String {
        if subtitle.contains("Quick keep") {
            return "逐一筛选珍贵回忆"
        }
        if subtitle.contains("suggestions") {
            return "每组保留 1 张或多张"
        }
        if subtitle.contains("Restore") {
            return "最终确认前可随时恢复"
        }
        if subtitle.contains("event-based") {
            return "从日期和地点继续整理"
        }
        return subtitle
    }
}

private extension PickoTaskPresentation {
    var stitchForegroundColor: Color {
        switch tintRole {
        case .keep:
            return PickoDesign.ColorToken.primarySoft
        case .review:
            return PickoDesign.ColorToken.primary
        case .time:
            return PickoDesign.ColorToken.primary
        case .basket:
            return PickoDesign.ColorToken.coralDeep
        }
    }

    var stitchBackgroundColor: Color {
        switch tintRole {
        case .keep:
            return PickoDesign.ColorToken.primarySoft.opacity(0.18)
        case .review:
            return PickoDesign.ColorToken.goldSoft
        case .time:
            return PickoDesign.ColorToken.surfaceHigh
        case .basket:
            return PickoDesign.ColorToken.coral
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(model: .preview())
    }
}
