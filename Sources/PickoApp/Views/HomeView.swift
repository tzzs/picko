import SwiftUI

public struct HomeView: View {
    @Bindable private var model: PickoAppModel
    @State private var selectedCollectionMode: CollectionReviewView.Mode?

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

                HStack(spacing: 1) {
                    ForEach(Array(presentation.metricRows.enumerated()), id: \.element.label) { index, metric in
                        Button {
                            openMetric(at: index)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(metric.value)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(PickoDesign.ColorToken.primary)
                                Text(metric.label)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)

                        if index < presentation.metricRows.count - 1 {
                            Rectangle()
                                .fill(PickoDesign.ColorToken.outline.opacity(0.35))
                                .frame(width: 1, height: 36)
                        }
                    }
                }
                .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                .overlay {
                    RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                        .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
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
                                    Text(task.title)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(task.tintRole == .keep ? .white : PickoDesign.ColorToken.ink)
                                    Text(task.subtitle)
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
                    NavigationLink {
                        CollectionReviewView(mode: .time, model: model)
                    } label: {
                        collectionRow(title: "时间", subtitle: "按拍摄日期", systemImage: "clock")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        CollectionReviewView(mode: .place, model: model)
                    } label: {
                        collectionRow(title: "地点", subtitle: "城市与地点", systemImage: "location")
                    }
                    .buttonStyle(.plain)
                }

                PickoFloatingBasketButton(count: model.deletionQueueCount) {
                    model.selectedTab = .basket
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(PickoDesign.Spacing.page)
            .padding(.bottom, 96)
        }
        .navigationDestination(item: $selectedCollectionMode) { mode in
            CollectionReviewView(mode: mode, model: model)
        }
        .pickoScreenBackground()
        #if os(iOS)
        .toolbar(HomeLayout.hidesNavigationBar ? .hidden : .visible, for: .navigationBar)
        #endif
    }

    private func openMetric(at index: Int) {
        switch index {
        case 1:
            model.selectedTab = .similar
        case 2:
            model.selectedTab = .basket
        default:
            model.selectedTab = .review
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
            selectedCollectionMode = .time
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

}

enum HomeLayout {
    static let navigationTitle: String? = nil
    static let hidesNavigationBar = true
}

private extension PickoTaskPresentation {
    var stitchForegroundColor: Color {
        switch tintRole {
        case .keep:
            return PickoDesign.ColorToken.primarySoft
        case .review:
            return PickoDesign.ColorToken.primary
        case .similar:
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
        case .similar:
            return PickoDesign.ColorToken.primarySoft.opacity(0.42)
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
