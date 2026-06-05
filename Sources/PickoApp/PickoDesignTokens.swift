import SwiftUI

enum PickoDesign {
    enum ColorToken {
        static let background = Color(hex: 0xF9F9F7)
        static let surface = Color(hex: 0xFFFFFF)
        static let surfaceLow = Color(hex: 0xF4F4F2)
        static let surfaceContainer = Color(hex: 0xEEEEEC)
        static let surfaceHigh = Color(hex: 0xE2E3E1)
        static let ink = Color(hex: 0x1A1C1B)
        static let secondaryInk = Color(hex: 0x42474B)
        static let outline = Color(hex: 0xC2C7CC)
        static let primary = Color(hex: 0x1A3A4A)
        static let primaryDeep = Color(hex: 0x002434)
        static let primarySoft = Color(hex: 0xC7E7FC)
        static let gold = Color(hex: 0xD4AF37)
        static let goldSoft = Color(hex: 0xFED65B)
        static let coral = Color(hex: 0xE88D67)
        static let coralDeep = Color(hex: 0x602305)
        static let destructive = Color(hex: 0xBA1A1A)
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let page: CGFloat = 20
        static let gutter: CGFloat = 12
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 32
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

struct PickoScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(PickoDesign.ColorToken.background.ignoresSafeArea())
            .scrollContentBackground(.hidden)
    }
}

extension View {
    func pickoScreenBackground() -> some View {
        modifier(PickoScreenBackground())
    }

    @ViewBuilder
    func pickoInlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

struct PickoBrandHeader: View {
    let title: String
    var trailingSystemImage: String = "gearshape"
    var trailingAction: (() -> Void)?

    var body: some View {
        HStack(spacing: PickoDesign.Spacing.gutter) {
            Circle()
                .fill(PickoDesign.ColorToken.primarySoft)
                .overlay {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PickoDesign.ColorToken.primaryDeep)
                }
                .frame(width: 34, height: 34)

            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(PickoDesign.ColorToken.primary)

            Spacer()

            if let trailingAction {
                Button(action: trailingAction) {
                    Image(systemName: trailingSystemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PickoSectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            .tracking(0.6)
    }
}

struct PickoMetricCapsule: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(PickoDesign.ColorToken.primary)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                .stroke(PickoDesign.ColorToken.outline.opacity(0.5), lineWidth: 1)
        }
    }
}

struct PickoFloatingBasketButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("预删除篮")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                    Text("\(count) 项待复核")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 34, height: 34)
                    .background(PickoDesign.ColorToken.goldSoft, in: Circle())
                    .foregroundStyle(PickoDesign.ColorToken.coralDeep)
            }
            .padding(.leading, 18)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .background(PickoDesign.ColorToken.coralDeep, in: Capsule())
            .foregroundStyle(PickoDesign.ColorToken.coral)
            .shadow(color: PickoDesign.ColorToken.primary.opacity(0.14), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct PickoEmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
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
        }
        .frame(maxWidth: .infinity)
        .padding(PickoDesign.Spacing.lg)
        .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
        }
        .padding(PickoDesign.Spacing.page)
    }
}
