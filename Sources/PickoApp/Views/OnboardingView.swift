import SwiftUI

public struct OnboardingView: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: PickoDesign.Spacing.lg) {
            PickoBrandHeader(title: "拾影")

            VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                PickoSectionLabel(title: "本地分析 · 删除前复核")

                Text("先看一遍，再决定保留什么。")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Picko 会读取相册缩略图和基础信息，在设备本地帮你找出相似照片、截图和待复核内容。")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .lineSpacing(3)
                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 7),
                    GridItem(.flexible(), spacing: 7),
                    GridItem(.flexible(), spacing: 7)
                ],
                spacing: 7
            ) {
                ForEach(0..<9, id: \.self) { index in
                    RoundedRectangle(cornerRadius: PickoDesign.Radius.sm)
                        .fill(previewGradient(index: index))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .rotationEffect(.degrees(-2))
            .padding(.vertical, PickoDesign.Spacing.sm)

            VStack(spacing: PickoDesign.Spacing.gutter) {
                Label("照片内容默认不上传", systemImage: "lock.shield")
                Label("预删除项目会等你最终确认", systemImage: "checkmark.shield")
                Label("所有复核进度保存在本机", systemImage: "externaldrive.badge.checkmark")
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(PickoDesign.ColorToken.primary)

        }
        .padding(PickoDesign.Spacing.page)
        .padding(.top, 44)
        .pickoScreenBackground()
    }

    private func previewGradient(index: Int) -> LinearGradient {
        let palettes: [[Color]] = [
            [Color(hex: 0x8AA59A), Color(hex: 0xF0C987)],
            [Color(hex: 0x748CA3), Color(hex: 0xF0DDD1)],
            [Color(hex: 0xD7966C), Color(hex: 0xE8DCC6)],
            [PickoDesign.ColorToken.primary, PickoDesign.ColorToken.primarySoft]
        ]
        let colors = palettes[index % palettes.count]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    OnboardingView()
}
