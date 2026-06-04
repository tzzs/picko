public struct DeletionQueue: Equatable {
    private var assetsById: [PhotoAsset.ID: PhotoAsset]
    private var orderedIds: [PhotoAsset.ID]

    public init() {
        assetsById = [:]
        orderedIds = []
    }

    public var itemIds: [PhotoAsset.ID] {
        orderedIds
    }

    public var estimatedBytes: Int64 {
        orderedIds.reduce(0) { total, id in
            total + (assetsById[id]?.fileSizeBytes ?? 0)
        }
    }

    public mutating func add(_ asset: PhotoAsset) {
        if assetsById[asset.id] == nil {
            orderedIds.append(asset.id)
        }
        assetsById[asset.id] = asset
    }

    public mutating func restore(id: PhotoAsset.ID) {
        assetsById[id] = nil
        orderedIds.removeAll { $0 == id }
    }

    public mutating func clear() {
        assetsById.removeAll()
        orderedIds.removeAll()
    }
}
