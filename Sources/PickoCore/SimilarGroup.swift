import Foundation

public struct SimilarGroup: Equatable, Identifiable {
    public enum GroupType: Equatable {
        case similar
        case burst
        case timeWindow
        case location
    }

    public enum ReviewStatus: Equatable {
        case unreviewed
        case reviewed
        case skipped
    }

    public var id: String
    public var assetIds: [PhotoAsset.ID]
    public var groupType: GroupType
    public var timeRange: DateInterval?
    public var locationSummary: String?
    public var recommendedKeepIds: [PhotoAsset.ID]
    public var keepCount: Int
    public var confidenceScore: Double
    public var status: ReviewStatus

    public init(
        id: String,
        assetIds: [PhotoAsset.ID],
        groupType: GroupType,
        timeRange: DateInterval?,
        locationSummary: String?,
        recommendedKeepIds: [PhotoAsset.ID],
        keepCount: Int,
        confidenceScore: Double,
        status: ReviewStatus
    ) {
        self.id = id
        self.assetIds = assetIds
        self.groupType = groupType
        self.timeRange = timeRange
        self.locationSummary = locationSummary
        self.recommendedKeepIds = recommendedKeepIds
        self.keepCount = keepCount
        self.confidenceScore = confidenceScore
        self.status = status
    }
}
