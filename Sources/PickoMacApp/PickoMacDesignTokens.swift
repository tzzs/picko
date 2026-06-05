import SwiftUI

enum PickoMacDesign {
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
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 18
    }

    enum Spacing {
        static let page: CGFloat = 24
        static let gutter: CGFloat = 12
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
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

struct PickoMacScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(PickoMacDesign.ColorToken.background)
            .scrollContentBackground(.hidden)
    }
}

extension View {
    func pickoMacScreenBackground() -> some View {
        modifier(PickoMacScreenBackground())
    }
}

struct PickoMacPageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)
                .tracking(0.6)

            Text(title)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(PickoMacDesign.ColorToken.primary)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PickoMacStatusPill: View {
    let title: String
    let systemImage: String?
    let color: Color

    init(_ title: String, systemImage: String? = nil, color: Color) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .lineLimit(1)
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }
}

struct PickoMacEmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: PickoMacDesign.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .frame(width: 72, height: 72)
                .background(PickoMacDesign.ColorToken.primarySoft.opacity(0.7), in: Circle())
                .foregroundStyle(PickoMacDesign.ColorToken.primary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(PickoMacDesign.ColorToken.primary)
                Text(message)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)
                    .frame(maxWidth: 360)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(PickoMacDesign.Spacing.lg)
        .background(PickoMacDesign.ColorToken.background)
    }
}

struct PickoMacActionButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
    }

    let title: String
    let systemImage: String
    var style: Style = .secondary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .padding(.horizontal, 12)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: PickoMacDesign.Radius.md))
                .foregroundStyle(foregroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: PickoMacDesign.Radius.md)
                        .stroke(borderColor, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return PickoMacDesign.ColorToken.primary
        case .secondary:
            return PickoMacDesign.ColorToken.surface
        case .destructive:
            return PickoMacDesign.ColorToken.coralDeep
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return PickoMacDesign.ColorToken.primarySoft
        case .secondary:
            return PickoMacDesign.ColorToken.primary
        case .destructive:
            return PickoMacDesign.ColorToken.coral
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return PickoMacDesign.ColorToken.primary.opacity(0)
        case .secondary:
            return PickoMacDesign.ColorToken.outline.opacity(0.5)
        case .destructive:
            return PickoMacDesign.ColorToken.coral.opacity(0.18)
        }
    }
}
