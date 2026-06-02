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
        (0..<assetCount).map { index in
            PhotoAssetSnapshot(
                localIdentifier: "synthetic-\(index)",
                mediaType: mediaType(for: index),
                creationDate: baseDate.addingTimeInterval(TimeInterval(index)),
                latitude: latitude(for: index),
                longitude: longitude(for: index),
                pixelWidth: 3_024 + (index % 4) * 256,
                pixelHeight: 4_032 + (index % 3) * 144,
                fileSizeBytes: Int64(1_500_000 + (index % 400) * 8_192),
                isFavorite: index.isMultiple(of: 37),
                isEdited: index.isMultiple(of: 23),
                isScreenshot: index.isMultiple(of: 19),
                duration: index.isMultiple(of: 11) ? 12.5 : nil,
                thumbnailHash: "thumb-\(index % 997)",
                perceptualHash: "perceptual-\(index % 509)"
            )
        }
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
