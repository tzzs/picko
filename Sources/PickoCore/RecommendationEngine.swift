public struct RecommendationEngine: Equatable {
    public init() {}

    public func recommendedKeepIds(from assets: [PhotoAsset], keepCount: Int) -> [PhotoAsset.ID] {
        guard keepCount > 0 else {
            return []
        }

        return assets
            .sorted { lhs, rhs in
                let lhsScore = score(for: lhs)
                let rhsScore = score(for: rhs)
                if lhsScore == rhsScore {
                    return lhs.id < rhs.id
                }
                return lhsScore > rhsScore
            }
            .prefix(keepCount)
            .map(\.id)
    }

    public func score(for asset: PhotoAsset) -> Int64 {
        var value = Int64(asset.pixelWidth * asset.pixelHeight)
        value += asset.fileSizeBytes / 1_000

        if asset.isFavorite {
            value += 10_000_000_000
        }

        if asset.isEdited {
            value += 1_000_000_000
        }

        return value
    }
}
