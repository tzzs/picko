import Foundation
import Observation
import PickoCore
import PickoPhotos

@Observable
public final class PickoAppModel {
    public enum Tab: Hashable {
        case home
        case review
        case similar
        case basket
    }

    public var selectedTab: Tab
    public var store: ReviewStateStore
    public var currentAssetIndex: Int
    public var currentSession: ReviewSession
    public var photoDeleter: (any PhotoDeleting)?
    public var thumbnailProvider: (any PhotoThumbnailProviding)?
    public var lastPersistenceError: Error?
    private let decisionStore: ReviewDecisionStore?

    public init(
        store: ReviewStateStore,
        selectedTab: Tab = .home,
        currentAssetIndex: Int = 0,
        currentSession: ReviewSession,
        photoDeleter: (any PhotoDeleting)? = nil,
        thumbnailProvider: (any PhotoThumbnailProviding)? = nil,
        decisionStore: ReviewDecisionStore? = nil
    ) {
        self.store = store
        self.selectedTab = selectedTab
        self.currentAssetIndex = currentAssetIndex
        self.currentSession = currentSession
        self.photoDeleter = photoDeleter
        self.thumbnailProvider = thumbnailProvider
        self.decisionStore = decisionStore
    }

    public convenience init(
        store: ReviewStateStore,
        selectedTab: Tab = .home,
        currentAssetIndex: Int = 0,
        photoDeleter: (any PhotoDeleting)? = nil,
        thumbnailProvider: (any PhotoThumbnailProviding)? = nil,
        decisionStore: ReviewDecisionStore? = nil
    ) {
        self.init(
            store: store,
            selectedTab: selectedTab,
            currentAssetIndex: currentAssetIndex,
            currentSession: PickoAppModel.makeSession(mode: .single),
            photoDeleter: photoDeleter,
            thumbnailProvider: thumbnailProvider,
            decisionStore: decisionStore
        )
    }

    public static func preview() -> PickoAppModel {
        PickoAppModel(
            store: ReviewStateStore(
                assets: PickoPreviewFixtures.assets,
                groups: PickoPreviewFixtures.groups
            )
        )
    }

    public static func loadingFromPhotoLibrary(
        indexer: PhotoAssetIndexing,
        mapper: PhotoAssetMapper = PhotoAssetMapper(),
        similarityEngine: SimilarityEngine = SimilarityEngine(configuration: .realLibraryDefault),
        decisionStore: ReviewDecisionStore? = nil,
        photoDeleter: (any PhotoDeleting)? = nil,
        thumbnailProvider: (any PhotoThumbnailProviding)? = nil
    ) async throws -> PickoAppModel {
        let snapshots = try await indexer.fetchAssetSnapshots()
        let assets = snapshots.map { mapper.asset(from: $0) }
        let groups = similarityEngine.groups(from: assets)
        let reviewState = ReviewStateStore(assets: assets, groups: groups)
        let restoredState = try decisionStore?.applyingSavedDecisions(to: reviewState) ?? reviewState
        let currentSession = try decisionStore?.latestIncompleteReviewSession() ?? makeSession(mode: .single)

        return PickoAppModel(
            store: restoredState,
            currentSession: currentSession,
            photoDeleter: photoDeleter,
            thumbnailProvider: thumbnailProvider,
            decisionStore: decisionStore
        )
    }

    public var assets: [PhotoAsset] {
        store.orderedAssets
    }

    public var groups: [SimilarGroup] {
        store.orderedGroups
    }

    public var currentAsset: PhotoAsset? {
        guard assets.indices.contains(currentAssetIndex) else {
            return nil
        }
        return assets[currentAssetIndex]
    }

    public var deletionQueueCount: Int {
        store.deletionQueue.itemIds.count
    }

    public var estimatedPreDeleteBytes: Int64 {
        store.deletionQueue.estimatedBytes
    }

    public func keepCurrentAsset() {
        applyCurrentAssetAction(.keep)
    }

    public func preDeleteCurrentAsset() {
        applyCurrentAssetAction(.preDelete)
    }

    public func skipCurrentAsset() {
        applyCurrentAssetAction(.skip)
    }

    public func undo() {
        store.undo()
        persistCurrentState()
    }

    public func keep(assetIds: [PhotoAsset.ID], in group: SimilarGroup) {
        store.apply(.keepOnly(assetIds: assetIds, inGroup: group.id))
        recordSessionGroupAction(keptAssetIds: assetIds, group: group)
        persistCurrentState()
    }

    public func keep(assetId: PhotoAsset.ID) {
        applyAssetAction(.keep, assetId: assetId, recordsSession: true)
    }

    public func preDelete(assetId: PhotoAsset.ID) {
        applyAssetAction(.preDelete, assetId: assetId, recordsSession: true)
    }

    public func restoreFromBasket(assetId: PhotoAsset.ID) {
        applyAssetAction(.keep, assetId: assetId, recordsSession: false)
    }

    public func clearBasket() {
        for id in store.deletionQueue.itemIds {
            applyAssetAction(.keep, assetId: id, recordsSession: false, persistsImmediately: false)
        }
        persistCurrentState()
    }

    public func clearLocalReviewState() {
        if let decisionStore {
            do {
                try decisionStore.clearAllReviewState()
                lastPersistenceError = nil
            } catch {
                lastPersistenceError = error
                return
            }
        }

        var resetStore = store
        resetStore.clearReviewState()
        store = resetStore
        currentAssetIndex = 0
        currentSession = PickoAppModel.makeSession(mode: .single)
    }

    @discardableResult
    public func confirmPreDeleteBasket(deleter: any PhotoDeleting) async throws -> [PhotoAsset.ID] {
        let assetIds = store.deletionQueue.itemIds
        guard !assetIds.isEmpty else {
            return []
        }

        try await deleter.requestDeletion(assetIds: assetIds)
        clearBasket()
        return assetIds
    }

    @discardableResult
    public func confirmPreDeleteBasket() async throws -> [PhotoAsset.ID] {
        guard let photoDeleter else {
            return []
        }

        return try await confirmPreDeleteBasket(deleter: photoDeleter)
    }

    private func applyCurrentAssetAction(_ action: AssetAction) {
        guard let asset = currentAsset else {
            return
        }

        applyAssetAction(action, assetId: asset.id, recordsSession: true)
        moveToNextAsset()
    }

    private func applyAssetAction(
        _ action: AssetAction,
        assetId: PhotoAsset.ID,
        recordsSession: Bool,
        persistsImmediately: Bool = true
    ) {
        let asset = store.asset(id: assetId)

        switch action {
        case .keep:
            store.apply(.keep(assetId))
        case .preDelete:
            store.apply(.preDelete(assetId))
        case .skip:
            store.apply(.skip(assetId))
        }

        if recordsSession, let asset {
            recordSessionAction(action, asset: asset)
        }

        if persistsImmediately {
            persistCurrentState()
        }
    }

    private func recordSessionAction(_ action: AssetAction, asset: PhotoAsset) {
        currentSession.reviewedCount += 1

        switch action {
        case .keep:
            currentSession.keptCount += 1
        case .preDelete:
            currentSession.preDeletedCount += 1
            currentSession.freedBytesEstimate += asset.fileSizeBytes
        case .skip:
            currentSession.skippedCount += 1
        }
    }

    private func recordSessionGroupAction(keptAssetIds: [PhotoAsset.ID], group: SimilarGroup) {
        let keptIds = Set(keptAssetIds)

        for assetId in group.assetIds {
            guard let asset = store.asset(id: assetId) else {
                continue
            }

            if keptIds.contains(assetId) {
                recordSessionAction(.keep, asset: asset)
            } else {
                recordSessionAction(.preDelete, asset: asset)
            }
        }
    }

    private func moveToNextAsset() {
        guard !assets.isEmpty else {
            currentAssetIndex = 0
            return
        }
        currentAssetIndex = min(currentAssetIndex + 1, assets.count - 1)
    }

    private func persistCurrentState() {
        guard let decisionStore else {
            return
        }

        do {
            try decisionStore.save(state: store)
            try decisionStore.save(session: currentSession)
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }

    public static func makeSession(mode: ReviewSession.Mode) -> ReviewSession {
        ReviewSession(id: UUID().uuidString, mode: mode, startedAt: Date())
    }
}

private enum AssetAction {
    case keep
    case preDelete
    case skip
}
