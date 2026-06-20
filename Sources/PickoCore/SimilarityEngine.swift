import Foundation

public struct SimilarityEngine: Equatable {
    public struct Configuration: Equatable {
        public var timeWindow: TimeInterval
        public var locationThresholdMeters: Double?
        public var usesMetadataFallbackWhenHashesAreMissing: Bool
        public var dimensionTolerance: Double
        public var fileSizeTolerance: Double

        public init(
            timeWindow: TimeInterval,
            locationThresholdMeters: Double? = nil,
            usesMetadataFallbackWhenHashesAreMissing: Bool = false,
            dimensionTolerance: Double = 0.08,
            fileSizeTolerance: Double = 0.35
        ) {
            self.timeWindow = timeWindow
            self.locationThresholdMeters = locationThresholdMeters
            self.usesMetadataFallbackWhenHashesAreMissing = usesMetadataFallbackWhenHashesAreMissing
            self.dimensionTolerance = dimensionTolerance
            self.fileSizeTolerance = fileSizeTolerance
        }

        public static let realLibraryDefault = Configuration(
            timeWindow: 300,
            locationThresholdMeters: 250,
            usesMetadataFallbackWhenHashesAreMissing: true,
            dimensionTolerance: 0.08,
            fileSizeTolerance: 0.35
        )
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

        if matchingHash(lhs.thumbnailHash, rhs.thumbnailHash) ||
            matchingHash(lhs.perceptualHash, rhs.perceptualHash) {
            return true
        }

        return metadataFallbackMatches(lhs, rhs)
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

    private func metadataFallbackMatches(_ lhs: PhotoAsset, _ rhs: PhotoAsset) -> Bool {
        guard configuration.usesMetadataFallbackWhenHashesAreMissing else {
            return false
        }

        guard lhs.thumbnailHash == nil,
              lhs.perceptualHash == nil,
              rhs.thumbnailHash == nil,
              rhs.perceptualHash == nil else {
            return false
        }

        return dimensionsAreClose(lhs, rhs) && fileSizesAreClose(lhs.fileSizeBytes, rhs.fileSizeBytes)
    }

    private func dimensionsAreClose(_ lhs: PhotoAsset, _ rhs: PhotoAsset) -> Bool {
        ratiosAreClose(Double(lhs.pixelWidth), Double(rhs.pixelWidth), tolerance: configuration.dimensionTolerance) &&
            ratiosAreClose(Double(lhs.pixelHeight), Double(rhs.pixelHeight), tolerance: configuration.dimensionTolerance)
    }

    private func fileSizesAreClose(_ lhs: Int64, _ rhs: Int64) -> Bool {
        ratiosAreClose(Double(lhs), Double(rhs), tolerance: configuration.fileSizeTolerance)
    }

    private func ratiosAreClose(_ lhs: Double, _ rhs: Double, tolerance: Double) -> Bool {
        guard lhs > 0, rhs > 0 else {
            return false
        }

        let smaller = min(lhs, rhs)
        let larger = max(lhs, rhs)
        return (larger - smaller) / larger <= tolerance
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
