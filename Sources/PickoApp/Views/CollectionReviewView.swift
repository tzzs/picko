import SwiftUI

public struct CollectionReviewView: View {
    public enum Mode: String, Identifiable {
        case time
        case place

        public var id: String { rawValue }

        var title: String {
            switch self {
            case .time:
                return "时间整理"
            case .place:
                return "地点整理"
            }
        }

        var message: String {
            switch self {
            case .time:
                return "Picko 已预留按时间整理的入口。后续会基于真实图库索引，把同一天、同一段旅程或同一活动的照片组织成可复核合集。"
            case .place:
                return "Picko 已预留按地点整理的入口。后续会基于照片地点信息，把同一城市或地点附近的照片组织成可复核合集。"
            }
        }

        var systemImage: String {
            switch self {
            case .time:
                return "clock"
            case .place:
                return "location"
            }
        }
    }

    private let mode: Mode

    public init(mode: Mode) {
        self.mode = mode
    }

    public var body: some View {
        VStack(spacing: PickoDesign.Spacing.md) {
            Image(systemName: mode.systemImage)
                .font(.system(size: 36, weight: .semibold))
                .frame(width: 80, height: 80)
                .background(PickoDesign.ColorToken.primarySoft.opacity(0.7), in: Circle())
                .foregroundStyle(PickoDesign.ColorToken.primary)

            Text(mode.title)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(PickoDesign.ColorToken.primary)

            Text(mode.message)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                .padding(.horizontal, PickoDesign.Spacing.page)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(PickoDesign.Spacing.page)
        .navigationTitle(mode.title)
        .pickoInlineNavigationTitle()
        .pickoScreenBackground()
    }
}

#Preview {
    NavigationStack {
        CollectionReviewView(mode: .time)
    }
}
