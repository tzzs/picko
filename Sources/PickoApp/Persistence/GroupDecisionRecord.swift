import Foundation
import SwiftData

@Model
public final class GroupDecisionRecord {
    @Attribute(.unique) public var groupId: String
    public var assetIds: [String]
    public var groupTypeRawValue: String
    public var timeStart: Date?
    public var timeEnd: Date?
    public var locationSummary: String?
    public var selectedKeepIds: [String]
    public var keepCount: Int
    public var confidenceScore: Double
    public var statusRawValue: String
    public var updatedAt: Date

    public init(
        groupId: String,
        assetIds: [String],
        groupTypeRawValue: String,
        timeStart: Date?,
        timeEnd: Date?,
        locationSummary: String?,
        selectedKeepIds: [String],
        keepCount: Int,
        confidenceScore: Double,
        statusRawValue: String,
        updatedAt: Date = Date()
    ) {
        self.groupId = groupId
        self.assetIds = assetIds
        self.groupTypeRawValue = groupTypeRawValue
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.locationSummary = locationSummary
        self.selectedKeepIds = selectedKeepIds
        self.keepCount = keepCount
        self.confidenceScore = confidenceScore
        self.statusRawValue = statusRawValue
        self.updatedAt = updatedAt
    }
}
