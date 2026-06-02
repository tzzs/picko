import Foundation
import PickoCore
import SwiftData

public final class ReviewDecisionStore {
    public let container: ModelContainer
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }

    public static func inMemory() throws -> ReviewDecisionStore {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ReviewDecisionRecord.self,
            ReviewSessionRecord.self,
            GroupDecisionRecord.self,
            BasketItemRecord.self,
            configurations: configuration
        )
        return ReviewDecisionStore(container: container)
    }

    public static func persistent(storeURL: URL? = nil) throws -> ReviewDecisionStore {
        let configuration: ModelConfiguration
        if let storeURL {
            configuration = ModelConfiguration(url: storeURL)
        } else {
            configuration = ModelConfiguration()
        }
        let container = try ModelContainer(
            for: ReviewDecisionRecord.self,
            ReviewSessionRecord.self,
            GroupDecisionRecord.self,
            BasketItemRecord.self,
            configurations: configuration
        )
        return ReviewDecisionStore(container: container)
    }

    public func save(assetId: String, status: PhotoAsset.ReviewStatus) throws {
        let rawValue = status.persistenceRawValue
        let descriptor = FetchDescriptor<ReviewDecisionRecord>(
            predicate: #Predicate { $0.assetId == assetId }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.statusRawValue = rawValue
            existing.updatedAt = Date()
        } else {
            context.insert(ReviewDecisionRecord(assetId: assetId, statusRawValue: rawValue))
        }

        try context.save()
    }

    public func save(state: ReviewStateStore) throws {
        for asset in state.orderedAssets {
            try save(assetId: asset.id, status: asset.status)
        }

        for group in state.orderedGroups {
            try save(group: group)
        }

        try saveBasket(from: state)
    }

    public func status(for assetId: String) throws -> PhotoAsset.ReviewStatus? {
        let descriptor = FetchDescriptor<ReviewDecisionRecord>(
            predicate: #Predicate { $0.assetId == assetId }
        )
        guard let record = try context.fetch(descriptor).first else {
            return nil
        }
        return PhotoAsset.ReviewStatus(persistenceRawValue: record.statusRawValue)
    }

    public func applyingSavedDecisions(to state: ReviewStateStore) throws -> ReviewStateStore {
        var restored = state
        let records = try context.fetch(FetchDescriptor<ReviewDecisionRecord>())

        for record in records {
            guard let status = PhotoAsset.ReviewStatus(persistenceRawValue: record.statusRawValue) else {
                continue
            }

            switch status {
            case .unreviewed:
                continue
            case .kept:
                restored.apply(.keep(record.assetId))
            case .preDeleted:
                restored.apply(.preDelete(record.assetId))
            case .skipped:
                restored.apply(.skip(record.assetId))
            }
        }

        let groupRecords = try context.fetch(FetchDescriptor<GroupDecisionRecord>())
        for record in groupRecords {
            guard let group = group(from: record) else {
                continue
            }
            restored.restoreGroupDecision(group)
        }

        let basketAssetIds = try basketItems().map(\.assetId)
        restored.restoreDeletionQueueOrder(basketAssetIds)

        return restored
    }

    public func save(session: ReviewSession) throws {
        let sessionId = session.id
        let rawMode = session.mode.persistenceRawValue
        let descriptor = FetchDescriptor<ReviewSessionRecord>(
            predicate: #Predicate { $0.sessionId == sessionId }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.modeRawValue = rawMode
            existing.startedAt = session.startedAt
            existing.completedAt = session.completedAt
            existing.reviewedCount = session.reviewedCount
            existing.keptCount = session.keptCount
            existing.preDeletedCount = session.preDeletedCount
            existing.skippedCount = session.skippedCount
            existing.freedBytesEstimate = session.freedBytesEstimate
        } else {
            context.insert(
                ReviewSessionRecord(
                    sessionId: session.id,
                    modeRawValue: rawMode,
                    startedAt: session.startedAt,
                    completedAt: session.completedAt,
                    reviewedCount: session.reviewedCount,
                    keptCount: session.keptCount,
                    preDeletedCount: session.preDeletedCount,
                    skippedCount: session.skippedCount,
                    freedBytesEstimate: session.freedBytesEstimate
                )
            )
        }

        try context.save()
    }

    public func reviewSession(id: ReviewSession.ID) throws -> ReviewSession? {
        let descriptor = FetchDescriptor<ReviewSessionRecord>(
            predicate: #Predicate { $0.sessionId == id }
        )
        guard let record = try context.fetch(descriptor).first,
              let mode = ReviewSession.Mode(persistenceRawValue: record.modeRawValue) else {
            return nil
        }

        return ReviewSession(
            id: record.sessionId,
            mode: mode,
            startedAt: record.startedAt,
            completedAt: record.completedAt,
            reviewedCount: record.reviewedCount,
            keptCount: record.keptCount,
            preDeletedCount: record.preDeletedCount,
            skippedCount: record.skippedCount,
            freedBytesEstimate: record.freedBytesEstimate
        )
    }

    public func latestIncompleteReviewSession() throws -> ReviewSession? {
        var descriptor = FetchDescriptor<ReviewSessionRecord>(
            predicate: #Predicate { $0.completedAt == nil }
        )
        descriptor.sortBy = [SortDescriptor(\.startedAt, order: .reverse)]
        guard let record = try context.fetch(descriptor).first,
              let mode = ReviewSession.Mode(persistenceRawValue: record.modeRawValue) else {
            return nil
        }

        return ReviewSession(
            id: record.sessionId,
            mode: mode,
            startedAt: record.startedAt,
            completedAt: record.completedAt,
            reviewedCount: record.reviewedCount,
            keptCount: record.keptCount,
            preDeletedCount: record.preDeletedCount,
            skippedCount: record.skippedCount,
            freedBytesEstimate: record.freedBytesEstimate
        )
    }

    public func save(group: SimilarGroup) throws {
        let groupId = group.id
        let descriptor = FetchDescriptor<GroupDecisionRecord>(
            predicate: #Predicate { $0.groupId == groupId }
        )
        let timeStart = group.timeRange?.start
        let timeEnd = group.timeRange?.end
        let groupType = group.groupType.persistenceRawValue
        let status = group.status.persistenceRawValue

        if let existing = try context.fetch(descriptor).first {
            existing.assetIds = group.assetIds
            existing.groupTypeRawValue = groupType
            existing.timeStart = timeStart
            existing.timeEnd = timeEnd
            existing.locationSummary = group.locationSummary
            existing.selectedKeepIds = group.recommendedKeepIds
            existing.keepCount = group.keepCount
            existing.confidenceScore = group.confidenceScore
            existing.statusRawValue = status
            existing.updatedAt = Date()
        } else {
            context.insert(
                GroupDecisionRecord(
                    groupId: group.id,
                    assetIds: group.assetIds,
                    groupTypeRawValue: groupType,
                    timeStart: timeStart,
                    timeEnd: timeEnd,
                    locationSummary: group.locationSummary,
                    selectedKeepIds: group.recommendedKeepIds,
                    keepCount: group.keepCount,
                    confidenceScore: group.confidenceScore,
                    statusRawValue: status
                )
            )
        }

        try context.save()
    }

    public func groupDecision(id: SimilarGroup.ID) throws -> SimilarGroup? {
        let descriptor = FetchDescriptor<GroupDecisionRecord>(
            predicate: #Predicate { $0.groupId == id }
        )
        guard let record = try context.fetch(descriptor).first else {
            return nil
        }

        return group(from: record)
    }

    private func group(from record: GroupDecisionRecord) -> SimilarGroup? {
        guard let groupType = SimilarGroup.GroupType(persistenceRawValue: record.groupTypeRawValue),
              let status = SimilarGroup.ReviewStatus(persistenceRawValue: record.statusRawValue) else {
            return nil
        }

        let timeRange: DateInterval?
        if let timeStart = record.timeStart, let timeEnd = record.timeEnd {
            timeRange = DateInterval(start: timeStart, end: timeEnd)
        } else {
            timeRange = nil
        }

        return SimilarGroup(
            id: record.groupId,
            assetIds: record.assetIds,
            groupType: groupType,
            timeRange: timeRange,
            locationSummary: record.locationSummary,
            recommendedKeepIds: record.selectedKeepIds,
            keepCount: record.keepCount,
            confidenceScore: record.confidenceScore,
            status: status
        )
    }

    public func saveBasket(from state: ReviewStateStore) throws {
        let existing = try context.fetch(FetchDescriptor<BasketItemRecord>())
        for record in existing {
            context.delete(record)
        }

        for (index, assetId) in state.deletionQueue.itemIds.enumerated() {
            guard let asset = state.asset(id: assetId) else {
                continue
            }

            context.insert(
                BasketItemRecord(
                    assetId: assetId,
                    orderIndex: index,
                    fileSizeBytes: asset.fileSizeBytes
                )
            )
        }

        try context.save()
    }

    public func basketItems() throws -> [BasketItemRecord] {
        var descriptor = FetchDescriptor<BasketItemRecord>()
        descriptor.sortBy = [SortDescriptor(\.orderIndex)]
        return try context.fetch(descriptor)
    }

    public func clearAllReviewState() throws {
        try deleteAll(ReviewDecisionRecord.self)
        try deleteAll(ReviewSessionRecord.self)
        try deleteAll(GroupDecisionRecord.self)
        try deleteAll(BasketItemRecord.self)
        try context.save()
    }

    private func deleteAll<T: PersistentModel>(_ modelType: T.Type) throws {
        for record in try context.fetch(FetchDescriptor<T>()) {
            context.delete(record)
        }
    }
}

private extension PhotoAsset.ReviewStatus {
    var persistenceRawValue: String {
        switch self {
        case .unreviewed:
            return "unreviewed"
        case .kept:
            return "kept"
        case .preDeleted:
            return "preDeleted"
        case .skipped:
            return "skipped"
        }
    }

    init?(persistenceRawValue: String) {
        switch persistenceRawValue {
        case "unreviewed":
            self = .unreviewed
        case "kept":
            self = .kept
        case "preDeleted":
            self = .preDeleted
        case "skipped":
            self = .skipped
        default:
            return nil
        }
    }
}

private extension ReviewSession.Mode {
    var persistenceRawValue: String {
        switch self {
        case .single:
            return "single"
        case .similarGroup:
            return "similarGroup"
        case .timeRange:
            return "timeRange"
        case .location:
            return "location"
        }
    }

    init?(persistenceRawValue: String) {
        switch persistenceRawValue {
        case "single":
            self = .single
        case "similarGroup":
            self = .similarGroup
        case "timeRange":
            self = .timeRange
        case "location":
            self = .location
        default:
            return nil
        }
    }
}

private extension SimilarGroup.GroupType {
    var persistenceRawValue: String {
        switch self {
        case .similar:
            return "similar"
        case .burst:
            return "burst"
        case .timeWindow:
            return "timeWindow"
        case .location:
            return "location"
        }
    }

    init?(persistenceRawValue: String) {
        switch persistenceRawValue {
        case "similar":
            self = .similar
        case "burst":
            self = .burst
        case "timeWindow":
            self = .timeWindow
        case "location":
            self = .location
        default:
            return nil
        }
    }
}

private extension SimilarGroup.ReviewStatus {
    var persistenceRawValue: String {
        switch self {
        case .unreviewed:
            return "unreviewed"
        case .reviewed:
            return "reviewed"
        case .skipped:
            return "skipped"
        }
    }

    init?(persistenceRawValue: String) {
        switch persistenceRawValue {
        case "unreviewed":
            self = .unreviewed
        case "reviewed":
            self = .reviewed
        case "skipped":
            self = .skipped
        default:
            return nil
        }
    }
}
