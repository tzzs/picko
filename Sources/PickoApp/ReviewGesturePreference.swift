import Foundation

enum ReviewGesturePreference: String, CaseIterable, Identifiable {
    case keepOnUp
    case keepOnDown

    static let storageKey = "picko.review.keepDirection"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepOnUp:
            return "上滑保留"
        case .keepOnDown:
            return "下滑保留"
        }
    }

    var subtitle: String {
        switch self {
        case .keepOnUp:
            return "上滑保留，下滑放入预删除篮"
        case .keepOnDown:
            return "下滑保留，上滑放入预删除篮"
        }
    }

    var topHintTitle: String {
        switch self {
        case .keepOnUp:
            return "向上保留"
        case .keepOnDown:
            return "向上预删除"
        }
    }

    var bottomHintTitle: String {
        switch self {
        case .keepOnUp:
            return "向下预删除"
        case .keepOnDown:
            return "向下保留"
        }
    }

    var topAction: SingleReviewGestureAction {
        switch self {
        case .keepOnUp:
            return .keep
        case .keepOnDown:
            return .preDelete
        }
    }

    var bottomAction: SingleReviewGestureAction {
        switch self {
        case .keepOnUp:
            return .preDelete
        case .keepOnDown:
            return .keep
        }
    }

    static func resolved(rawValue: String) -> ReviewGesturePreference {
        ReviewGesturePreference(rawValue: rawValue) ?? .keepOnUp
    }
}

enum SingleReviewGestureAction: Equatable {
    case keep
    case preDelete
    case skip
    case undo
}
