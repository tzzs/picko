import Foundation
import SwiftData

@Model
public final class BasketItemRecord {
    @Attribute(.unique) public var assetId: String
    public var queuedAt: Date
    public var orderIndex: Int
    public var fileSizeBytes: Int64
    public var sessionId: String?

    public init(
        assetId: String,
        queuedAt: Date = Date(),
        orderIndex: Int,
        fileSizeBytes: Int64,
        sessionId: String? = nil
    ) {
        self.assetId = assetId
        self.queuedAt = queuedAt
        self.orderIndex = orderIndex
        self.fileSizeBytes = fileSizeBytes
        self.sessionId = sessionId
    }
}
