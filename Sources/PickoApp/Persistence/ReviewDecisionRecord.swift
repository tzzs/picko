import Foundation
import SwiftData

@Model
public final class ReviewDecisionRecord {
    @Attribute(.unique) public var assetId: String
    public var statusRawValue: String
    public var updatedAt: Date

    public init(assetId: String, statusRawValue: String, updatedAt: Date = Date()) {
        self.assetId = assetId
        self.statusRawValue = statusRawValue
        self.updatedAt = updatedAt
    }
}
