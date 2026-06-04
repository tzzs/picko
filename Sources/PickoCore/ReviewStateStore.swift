public enum ReviewAction: Equatable {
    case keep(PhotoAsset.ID)
    case preDelete(PhotoAsset.ID)
    case skip(PhotoAsset.ID)
    case keepOnly(assetIds: [PhotoAsset.ID], inGroup: SimilarGroup.ID)
}

public struct ReviewStateStore: Equatable {
    private struct Snapshot: Equatable {
        var assets: [PhotoAsset.ID: PhotoAsset]
        var assetOrder: [PhotoAsset.ID]
        var groups: [SimilarGroup.ID: SimilarGroup]
        var groupOrder: [SimilarGroup.ID]
        var deletionQueue: DeletionQueue
    }

    private var assets: [PhotoAsset.ID: PhotoAsset]
    private var assetOrder: [PhotoAsset.ID]
    private var groups: [SimilarGroup.ID: SimilarGroup]
    private var groupOrder: [SimilarGroup.ID]
    private var initialAssets: [PhotoAsset.ID: PhotoAsset]
    private var initialGroups: [SimilarGroup.ID: SimilarGroup]
    private var history: [Snapshot]

    public private(set) var deletionQueue: DeletionQueue

    public init(assets: [PhotoAsset], groups: [SimilarGroup] = []) {
        self.assets = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0) })
        self.assetOrder = assets.map(\.id)
        self.groups = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) })
        self.groupOrder = groups.map(\.id)
        self.initialAssets = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0) })
        self.initialGroups = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) })
        self.deletionQueue = DeletionQueue()
        self.history = []
    }

    public func asset(id: PhotoAsset.ID) -> PhotoAsset? {
        assets[id]
    }

    public func group(id: SimilarGroup.ID) -> SimilarGroup? {
        groups[id]
    }

    public var orderedAssets: [PhotoAsset] {
        assetOrder.compactMap { assets[$0] }
    }

    public var orderedGroups: [SimilarGroup] {
        groupOrder.compactMap { groups[$0] }
    }

    public mutating func apply(_ action: ReviewAction) {
        history.append(snapshot())

        switch action {
        case .keep(let id):
            setStatus(.kept, for: id)
        case .preDelete(let id):
            setStatus(.preDeleted, for: id)
        case .skip(let id):
            setStatus(.skipped, for: id)
        case .keepOnly(let selectedIds, let groupId):
            applyKeepOnly(selectedIds: Set(selectedIds), groupId: groupId)
        }
    }

    public mutating func undo() {
        guard let previous = history.popLast() else {
            return
        }

        assets = previous.assets
        assetOrder = previous.assetOrder
        groups = previous.groups
        groupOrder = previous.groupOrder
        deletionQueue = previous.deletionQueue
    }

    public mutating func clearReviewState() {
        history.removeAll()
        deletionQueue.clear()

        for id in assetOrder {
            guard var asset = initialAssets[id] ?? assets[id] else {
                continue
            }
            asset.status = .unreviewed
            assets[id] = asset
        }

        for id in groupOrder {
            guard var group = initialGroups[id] ?? groups[id] else {
                continue
            }
            group.status = .unreviewed
            groups[id] = group
        }
    }

    public mutating func restoreGroupDecision(_ decision: SimilarGroup) {
        guard var group = groups[decision.id],
              Set(group.assetIds) == Set(decision.assetIds) else {
            return
        }

        let validAssetIds = Set(group.assetIds)
        group.recommendedKeepIds = decision.recommendedKeepIds.filter { validAssetIds.contains($0) }
        group.keepCount = decision.keepCount
        group.status = decision.status
        groups[decision.id] = group
    }

    public mutating func restoreDeletionQueueOrder(_ assetIds: [PhotoAsset.ID]) {
        var restoredQueue = DeletionQueue()
        var restoredIds = Set<PhotoAsset.ID>()

        for id in assetIds {
            guard !restoredIds.contains(id),
                  let asset = assets[id],
                  asset.status == .preDeleted else {
                continue
            }
            restoredQueue.add(asset)
            restoredIds.insert(id)
        }

        for id in deletionQueue.itemIds where !restoredIds.contains(id) {
            guard let asset = assets[id] else {
                continue
            }
            restoredQueue.add(asset)
        }

        deletionQueue = restoredQueue
    }

    private func snapshot() -> Snapshot {
        Snapshot(
            assets: assets,
            assetOrder: assetOrder,
            groups: groups,
            groupOrder: groupOrder,
            deletionQueue: deletionQueue
        )
    }

    private mutating func applyKeepOnly(selectedIds: Set<PhotoAsset.ID>, groupId: SimilarGroup.ID) {
        guard var group = groups[groupId] else {
            return
        }

        for id in group.assetIds {
            if selectedIds.contains(id) {
                setStatus(.kept, for: id)
            } else {
                setStatus(.preDeleted, for: id)
            }
        }

        group.recommendedKeepIds = group.assetIds.filter { selectedIds.contains($0) }
        group.keepCount = selectedIds.count
        group.status = .reviewed
        groups[groupId] = group
    }

    private mutating func setStatus(_ status: PhotoAsset.ReviewStatus, for id: PhotoAsset.ID) {
        guard var asset = assets[id] else {
            return
        }

        asset.status = status
        assets[id] = asset

        if status == .preDeleted {
            deletionQueue.add(asset)
        } else {
            deletionQueue.restore(id: id)
        }
    }
}
