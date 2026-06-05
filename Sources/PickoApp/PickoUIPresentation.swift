import Foundation
import PickoCore

public struct PickoActionPresentation: Equatable {
    public let title: String
    public let systemImage: String

    public init(title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }
}

public struct PickoMetricPresentation: Equatable {
    public let label: String
    public let value: String
    public let detail: String

    public init(label: String, value: String, detail: String) {
        self.label = label
        self.value = value
        self.detail = detail
    }
}

public struct PickoTaskPresentation: Equatable {
    public let title: String
    public let subtitle: String
    public let systemImage: String
    public let tintRole: TintRole

    public enum TintRole: Equatable {
        case keep
        case review
        case time
        case basket
    }

    public init(title: String, subtitle: String, systemImage: String, tintRole: TintRole) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tintRole = tintRole
    }
}

public struct PickoHomePresentation: Equatable {
    public let heroTitle: String
    public let heroSubtitle: String
    public let metricRows: [PickoMetricPresentation]
    public let taskRows: [PickoTaskPresentation]
    public let privacyFootnote: String

    public init(model: PickoAppModel) {
        heroTitle = "Ready to keep what matters"
        heroSubtitle = "\(model.assets.count) items prepared. Picko keeps review decisions local until you confirm them."
        metricRows = [
            PickoMetricPresentation(label: "Library", value: "\(model.assets.count)", detail: "items ready"),
            PickoMetricPresentation(label: "Similar groups", value: "\(model.groups.count)", detail: "review candidates"),
            PickoMetricPresentation(
                label: "Pre-delete basket",
                value: "\(model.deletionQueueCount)",
                detail: ByteCountFormatter.string(fromByteCount: model.estimatedPreDeleteBytes, countStyle: .file)
            )
        ]
        taskRows = [
            PickoTaskPresentation(
                title: "Review one by one",
                subtitle: "Quick keep, review later, skip, and undo.",
                systemImage: "rectangle.stack",
                tintRole: .review
            ),
            PickoTaskPresentation(
                title: "Review similar photos",
                subtitle: "Use suggestions, then choose Keep 1 or Keep N.",
                systemImage: "square.grid.2x2",
                tintRole: .keep
            ),
            PickoTaskPresentation(
                title: "Review pre-delete basket",
                subtitle: "Restore items before Photos confirmation.",
                systemImage: "tray.full",
                tintRole: .basket
            ),
            PickoTaskPresentation(
                title: "Browse by time and place",
                subtitle: "Plan the next event-based review.",
                systemImage: "calendar.badge.clock",
                tintRole: .time
            )
        ]
        privacyFootnote = "Photos are not deleted when you review. Picko only asks Photos after the basket confirmation."
    }
}

public struct PickoSingleReviewPresentation: Equatable {
    public let asset: PhotoAsset
    public let decisionHint: String
    public let metadataSummary: String
    public let primaryActions: [PickoActionPresentation]

    public init?(model: PickoAppModel) {
        guard let asset = model.currentAsset else {
            return nil
        }

        self.asset = asset
        decisionHint = "Swipe up to keep, down to send to the basket."
        metadataSummary = "\(asset.pixelWidth)x\(asset.pixelHeight) · \(Self.byteText(asset.fileSizeBytes)) · Similar group \(Self.groupPosition(for: asset.id, in: model))"
        primaryActions = [
            PickoActionPresentation(title: "Keep", systemImage: "checkmark.circle.fill"),
            PickoActionPresentation(title: "Review Later", systemImage: "tray.and.arrow.down"),
            PickoActionPresentation(title: "Skip", systemImage: "forward")
        ]
    }

    private static func groupPosition(for assetId: PhotoAsset.ID, in model: PickoAppModel) -> String {
        guard let groupIndex = model.groups.firstIndex(where: { $0.assetIds.contains(assetId) }) else {
            return "none"
        }

        return "\(groupIndex + 1)/\(model.groups.count)"
    }

    private static func byteText(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

public struct PickoSimilarAssetPresentation: Equatable, Identifiable {
    public let id: PhotoAsset.ID
    public let asset: PhotoAsset
    public let isSuggested: Bool
    public let byteText: String

    public init(asset: PhotoAsset, isSuggested: Bool) {
        id = asset.id
        self.asset = asset
        self.isSuggested = isSuggested
        byteText = ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file)
    }
}

public struct PickoSimilarGroupPresentation: Equatable {
    public let group: SimilarGroup
    public let modeTitles: [String]
    public let recommendationBadge: String
    public let footerExplanation: String
    public let assetRows: [PickoSimilarAssetPresentation]

    public init?(model: PickoAppModel) {
        guard let group = model.groups.first else {
            return nil
        }

        self.group = group
        modeTitles = ["Keep 1", "Keep N"]
        recommendationBadge = "Suggested keep"
        footerExplanation = "Unselected photos move to the pre-delete basket for final review."
        let suggestedIds = Set(group.recommendedKeepIds)
        assetRows = model.assets
            .filter { group.assetIds.contains($0.id) }
            .map { PickoSimilarAssetPresentation(asset: $0, isSuggested: suggestedIds.contains($0.id)) }
    }
}

public struct PickoBasketItemPresentation: Equatable, Identifiable {
    public let id: PhotoAsset.ID
    public let asset: PhotoAsset
    public let byteText: String

    public init(asset: PhotoAsset) {
        id = asset.id
        self.asset = asset
        byteText = ByteCountFormatter.string(fromByteCount: asset.fileSizeBytes, countStyle: .file)
    }
}

public struct PickoBasketPresentation: Equatable {
    public let summaryTitle: String
    public let summarySubtitle: String
    public let primaryActionTitle: String
    public let secondaryActionTitle: String
    public let recoveryMessage: String
    public let items: [PickoBasketItemPresentation]

    public init(model: PickoAppModel) {
        let count = model.deletionQueueCount
        summaryTitle = "\(count) \(count == 1 ? "item" : "items") waiting for final review"
        summarySubtitle = "Estimated space: \(ByteCountFormatter.string(fromByteCount: model.estimatedPreDeleteBytes, countStyle: .file))"
        primaryActionTitle = "Confirm with Photos"
        secondaryActionTitle = "Restore or clear before confirming"
        recoveryMessage = ReviewCopy.photosConfirmationMessage
        items = model.store.deletionQueue.itemIds.compactMap { id in
            model.store.asset(id: id).map(PickoBasketItemPresentation.init(asset:))
        }
    }
}
