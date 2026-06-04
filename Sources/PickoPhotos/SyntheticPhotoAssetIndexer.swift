#if canImport(Photos)
import Foundation

public struct SyntheticPhotoAssetIndexer: PhotoAssetIndexing {
    private let assetCount: Int
    private let baseDate: Date

    public init(assetCount: Int, baseDate: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.assetCount = max(0, assetCount)
        self.baseDate = baseDate
    }

    public func fetchAssetSnapshots() async throws -> [PhotoAssetSnapshot] {
        var snapshots: [PhotoAssetSnapshot] = []
        snapshots.reserveCapacity(assetCount)

        for index in 0..<assetCount {
            let mediaType = mediaType(for: index)
            let creationDate = baseDate.addingTimeInterval(TimeInterval(index))
            let latitude = latitude(for: index)
            let longitude = longitude(for: index)
            let pixelWidth = 3_024 + (index % 4) * 256
            let pixelHeight = 4_032 + (index % 3) * 144
            let fileSizeBytes = Int64(1_500_000 + (index % 400) * 8_192)
            let duration: TimeInterval? = index.isMultiple(of: 11) ? 12.5 : nil

            snapshots.append(PhotoAssetSnapshot(
                localIdentifier: "synthetic-\(index)",
                mediaType: mediaType,
                creationDate: creationDate,
                latitude: latitude,
                longitude: longitude,
                pixelWidth: pixelWidth,
                pixelHeight: pixelHeight,
                fileSizeBytes: fileSizeBytes,
                isFavorite: index.isMultiple(of: 37),
                isEdited: index.isMultiple(of: 23),
                isScreenshot: index.isMultiple(of: 19),
                duration: duration,
                thumbnailHash: "thumb-\(index % 997)",
                perceptualHash: "perceptual-\(index % 509)"
            ))
        }

        return snapshots
    }

    private func mediaType(for index: Int) -> PhotoAssetSnapshot.MediaType {
        if index.isMultiple(of: 19) {
            return .screenshot
        }

        if index.isMultiple(of: 11) {
            return .video
        }

        if index.isMultiple(of: 7) {
            return .livePhoto
        }

        return .image
    }

    private func latitude(for index: Int) -> Double? {
        guard !index.isMultiple(of: 5) else {
            return nil
        }

        return 31.0 + Double(index % 1000) / 10_000
    }

    private func longitude(for index: Int) -> Double? {
        guard !index.isMultiple(of: 5) else {
            return nil
        }

        return 121.0 + Double(index % 1000) / 10_000
    }
}
#endif
