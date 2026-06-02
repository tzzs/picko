import Foundation
import SwiftData

@Model
public final class ReviewSessionRecord {
    @Attribute(.unique) public var sessionId: String
    public var modeRawValue: String
    public var startedAt: Date
    public var completedAt: Date?
    public var reviewedCount: Int
    public var keptCount: Int
    public var preDeletedCount: Int
    public var skippedCount: Int
    public var freedBytesEstimate: Int64

    public init(
        sessionId: String,
        modeRawValue: String,
        startedAt: Date,
        completedAt: Date?,
        reviewedCount: Int,
        keptCount: Int,
        preDeletedCount: Int,
        skippedCount: Int,
        freedBytesEstimate: Int64
    ) {
        self.sessionId = sessionId
        self.modeRawValue = modeRawValue
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.reviewedCount = reviewedCount
        self.keptCount = keptCount
        self.preDeletedCount = preDeletedCount
        self.skippedCount = skippedCount
        self.freedBytesEstimate = freedBytesEstimate
    }
}
