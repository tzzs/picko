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
        heroTitle = PickoCopy.Home.heroTitle
        heroSubtitle = "已准备 \(model.assets.count) 张照片。整理决定会先保存在本机，确认前不会修改系统照片。"
        metricRows = [
            PickoMetricPresentation(label: PickoCopy.Home.libraryMetric, value: "\(model.assets.count)", detail: "待整理"),
            PickoMetricPresentation(label: PickoCopy.Home.similarMetric, value: "\(model.groups.count)", detail: "待复核"),
            PickoMetricPresentation(
                label: PickoCopy.Home.basketMetric,
                value: "\(model.deletionQueueCount)",
                detail: PickoCopy.byteText(model.estimatedPreDeleteBytes)
            )
        ]
        taskRows = [
            PickoTaskPresentation(
                title: PickoCopy.Home.reviewOneByOne,
                subtitle: PickoCopy.Home.reviewOneByOneSubtitle,
                systemImage: "rectangle.stack",
                tintRole: .review
            ),
            PickoTaskPresentation(
                title: PickoCopy.Home.reviewSimilar,
                subtitle: PickoCopy.Home.reviewSimilarSubtitle,
                systemImage: "square.grid.2x2",
                tintRole: .keep
            ),
            PickoTaskPresentation(
                title: PickoCopy.Home.reviewBasket,
                subtitle: PickoCopy.Home.reviewBasketSubtitle,
                systemImage: "tray.full",
                tintRole: .basket
            ),
            PickoTaskPresentation(
                title: PickoCopy.Home.timeAndPlace,
                subtitle: PickoCopy.Home.timeAndPlaceSubtitle,
                systemImage: "calendar.badge.clock",
                tintRole: .time
            )
        ]
        privacyFootnote = PickoCopy.Home.privacyFootnote
    }
}

public struct PickoSingleReviewPresentation: Equatable {
    public let asset: PhotoAsset
    public let decisionHint: String
    public let dateLocationText: String
    public let metadataSummary: String
    public let primaryActions: [PickoActionPresentation]

    public init?(model: PickoAppModel) {
        guard let asset = model.currentAsset else {
            return nil
        }

        self.asset = asset
        decisionHint = PickoCopy.Review.decisionHint
        dateLocationText = Self.dateLocationText(for: asset)
        metadataSummary = "\(asset.pixelWidth)x\(asset.pixelHeight) · \(Self.byteText(asset.fileSizeBytes)) · \(PickoCopy.Review.similarGroupPosition(Self.groupPosition(for: asset.id, in: model)))"
        primaryActions = [
            PickoActionPresentation(title: PickoCopy.Review.keep, systemImage: "checkmark.circle.fill"),
            PickoActionPresentation(title: PickoCopy.Review.preDelete, systemImage: "tray.and.arrow.down"),
            PickoActionPresentation(title: PickoCopy.Review.skip, systemImage: "forward")
        ]
    }

    private static func groupPosition(for assetId: PhotoAsset.ID, in model: PickoAppModel) -> String {
        guard let groupIndex = model.groups.firstIndex(where: { $0.assetIds.contains(assetId) }) else {
            return PickoCopy.Review.metadataNoGroup
        }

        return "\(groupIndex + 1)/\(model.groups.count)"
    }

    private static func byteText(_ bytes: Int64) -> String {
        PickoCopy.byteText(bytes)
    }

    private static func dateLocationText(for asset: PhotoAsset) -> String {
        let dateText = reviewDateFormatter.string(from: asset.creationDate)
        guard asset.location != nil else {
            return "\(dateText) · \(PickoCopy.Review.noLocation)"
        }

        return "\(dateText) · \(PickoCopy.Review.nearbyPlace)"
    }

    private static let reviewDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()
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
        byteText = PickoCopy.byteText(asset.fileSizeBytes)
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
        modeTitles = [PickoCopy.Similar.keepOne, PickoCopy.Similar.keepMany]
        recommendationBadge = PickoCopy.Similar.suggestedKeep
        footerExplanation = PickoCopy.Similar.footerExplanation
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
        byteText = PickoCopy.byteText(asset.fileSizeBytes)
    }
}

public struct PickoBasketPresentation: Equatable {
    public let summaryTitle: String
    public let summarySubtitle: String
    public let primaryActionTitle: String
    public let secondaryActionTitle: String
    public let disabledReason: String?
    public let recoveryMessage: String
    public let items: [PickoBasketItemPresentation]

    public init(model: PickoAppModel) {
        let count = model.deletionQueueCount
        summaryTitle = PickoCopy.Basket.summaryTitle(count: count)
        summarySubtitle = PickoCopy.Basket.summarySubtitle(bytes: model.estimatedPreDeleteBytes)
        primaryActionTitle = PickoCopy.Basket.primaryAction
        secondaryActionTitle = PickoCopy.Basket.secondaryAction
        if count == 0 {
            disabledReason = PickoCopy.Basket.emptyDisabledReason
        } else if model.photoDeleter == nil {
            disabledReason = PickoCopy.Basket.sampleLibraryDisabledReason
        } else {
            disabledReason = nil
        }
        recoveryMessage = ReviewCopy.photosConfirmationMessage
        items = model.store.deletionQueue.itemIds.compactMap { id in
            model.store.asset(id: id).map(PickoBasketItemPresentation.init(asset:))
        }
    }
}
