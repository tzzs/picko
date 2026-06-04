import Foundation

public struct SimilarityEngine: Equatable {
    public struct Configuration: Equatable {
        public var timeWindow: TimeInterval
        public var locationThresholdMeters: Double?

        public init(timeWindow: TimeInterval, locationThresholdMeters: Double? = nil) {
            self.timeWindow = timeWindow
            self.locationThresholdMeters = locationThresholdMeters
        }
    }

    public var configuration: Configuration

    public init(configuration: Configuration = .init(timeWindow: 90)) {
        self.configuration = configuration
    }

    public func groups(from assets: [PhotoAsset]) -> [SimilarGroup] {
        let sortedAssets = assets.sorted {
            if $0.creationDate == $1.creationDate {
                return $0.id < $1.id
            }
            return $0.creationDate < $1.creationDate
        }

        var groups: [[PhotoAsset]] = []
        var currentGroup: [PhotoAsset] = []

        for asset in sortedAssets {
            guard let previous = currentGroup.last else {
                currentGroup = [asset]
                continue
            }

            if areSimilar(previous, asset) {
                currentGroup.append(asset)
            } else {
                appendGroupIfNeeded(currentGroup, to: &groups)
                currentGroup = [asset]
            }
        }

        appendGroupIfNeeded(currentGroup, to: &groups)

        return groups.enumerated().map { index, assets in
            let ids = assets.map(\.id)
            let recommended = RecommendationEngine().recommendedKeepIds(from: assets, keepCount: 1)
            let start = assets.first?.creationDate ?? Date(timeIntervalSince1970: 0)
            let end = assets.last?.creationDate ?? start

            return SimilarGroup(
                id: "similar-\(index + 1)",
                assetIds: ids,
                groupType: .similar,
                timeRange: DateInterval(start: start, end: end),
                locationSummary: nil,
                recommendedKeepIds: recommended,
                keepCount: 1,
                confidenceScore: confidenceScore(for: assets),
                status: .unreviewed
            )
        }
    }

    private func areSimilar(_ lhs: PhotoAsset, _ rhs: PhotoAsset) -> Bool {
        guard lhs.mediaType == rhs.mediaType else {
            return false
        }

        guard abs(rhs.creationDate.timeIntervalSince(lhs.creationDate)) <= configuration.timeWindow else {
            return false
        }

        guard isWithinLocationThreshold(lhs.location, rhs.location) else {
            return false
        }

        return matchingHash(lhs.thumbnailHash, rhs.thumbnailHash) ||
            matchingHash(lhs.perceptualHash, rhs.perceptualHash)
    }

    private func isWithinLocationThreshold(_ lhs: PhotoAsset.Location?, _ rhs: PhotoAsset.Location?) -> Bool {
        guard let threshold = configuration.locationThresholdMeters else {
            return true
        }

        guard let lhs, let rhs else {
            return true
        }

        return distanceMeters(from: lhs, to: rhs) <= threshold
    }

    private func distanceMeters(from lhs: PhotoAsset.Location, to rhs: PhotoAsset.Location) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let lat1 = degreesToRadians(lhs.latitude)
        let lat2 = degreesToRadians(rhs.latitude)
        let deltaLat = degreesToRadians(rhs.latitude - lhs.latitude)
        let deltaLon = degreesToRadians(rhs.longitude - lhs.longitude)

        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
            cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusMeters * c
    }

    private func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    private func matchingHash(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs, let rhs else {
            return false
        }
        return lhs == rhs
    }

    private func appendGroupIfNeeded(_ group: [PhotoAsset], to groups: inout [[PhotoAsset]]) {
        if group.count > 1 {
            groups.append(group)
        }
    }

    private func confidenceScore(for assets: [PhotoAsset]) -> Double {
        guard assets.count > 1 else {
            return 0
        }
        return 0.8
    }
}
