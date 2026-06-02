import XCTest
import Photos
import PickoCore
@testable import PickoPhotos

final class PickoPhotosTests: XCTestCase {
    func testAuthorizationStatusPreservesLimitedAccess() {
        XCTAssertEqual(PhotoLibraryAuthorizationStatus(platformStatus: .limited), .limited)
    }

    func testPhotoSnapshotMapsToCoreAsset() {
        let snapshot = PhotoAssetSnapshot(
            localIdentifier: "asset-1",
            mediaType: .image,
            creationDate: Date(timeIntervalSince1970: 100),
            latitude: 31.2,
            longitude: 121.4,
            pixelWidth: 4000,
            pixelHeight: 3000,
            fileSizeBytes: 3_500_000,
            isFavorite: true,
            isEdited: false,
            isScreenshot: false,
            duration: nil,
            thumbnailHash: nil,
            perceptualHash: nil
        )

        let asset = PhotoAssetMapper().asset(from: snapshot)

        XCTAssertEqual(asset.id, "asset-1")
        XCTAssertEqual(asset.mediaType, .photo)
        XCTAssertEqual(asset.creationDate, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(asset.location?.latitude, 31.2)
        XCTAssertEqual(asset.location?.longitude, 121.4)
        XCTAssertEqual(asset.pixelWidth, 4000)
        XCTAssertEqual(asset.pixelHeight, 3000)
        XCTAssertEqual(asset.fileSizeBytes, 3_500_000)
        XCTAssertTrue(asset.isFavorite)
        XCTAssertFalse(asset.isEdited)
        XCTAssertFalse(asset.isScreenshot)
        XCTAssertNil(asset.duration)
        XCTAssertEqual(asset.status, .unreviewed)
    }

    func testPhotoSnapshotMapsVideoToCoreAsset() {
        let snapshot = PhotoAssetSnapshot(
            localIdentifier: "video-1",
            mediaType: .video,
            creationDate: Date(timeIntervalSince1970: 200),
            latitude: nil,
            longitude: nil,
            pixelWidth: 1920,
            pixelHeight: 1080,
            fileSizeBytes: 20_000_000,
            isFavorite: false,
            isEdited: true,
            isScreenshot: false,
            duration: 12.5,
            thumbnailHash: "thumb",
            perceptualHash: "perceptual"
        )

        let asset = PhotoAssetMapper().asset(from: snapshot)

        XCTAssertEqual(asset.id, "video-1")
        XCTAssertEqual(asset.mediaType, .video)
        XCTAssertNil(asset.location)
        XCTAssertEqual(asset.duration, 12.5)
        XCTAssertEqual(asset.thumbnailHash, "thumb")
        XCTAssertEqual(asset.perceptualHash, "perceptual")
        XCTAssertTrue(asset.isEdited)
    }

    func testPhotosLibraryAdapterConformsToProtocols() {
        let adapter = PhotosLibraryAdapter()
        let authorizer: PhotoLibraryAuthorizing = adapter
        let indexer: PhotoAssetIndexing = adapter
        let deleter: PhotoDeleting = adapter
        let thumbnails: PhotoThumbnailProviding = adapter

        XCTAssertNotNil(authorizer)
        XCTAssertNotNil(indexer)
        XCTAssertNotNil(deleter)
        XCTAssertNotNil(thumbnails)
    }

    func testMemoryThumbnailProviderCachesWithoutRefetching() async throws {
        let source = CountingThumbnailProvider(data: Data([1, 2, 3]))
        let cache = MemoryCachingPhotoThumbnailProvider(source: source)
        let request = PhotoThumbnailRequest(assetId: "a1", targetPixelWidth: 120, targetPixelHeight: 90)

        let first = try await cache.thumbnailData(for: request)
        let second = try await cache.thumbnailData(for: request)

        XCTAssertEqual(first, Data([1, 2, 3]))
        XCTAssertEqual(second, Data([1, 2, 3]))
        XCTAssertEqual(source.requestCount, 1)
    }

    func testIndexingBenchmarkReportsFetchedSnapshotCount() async throws {
        let benchmark = AssetIndexingBenchmark(indexer: SyntheticPhotoAssetIndexer(assetCount: 1_000))

        let result = try await benchmark.measure()

        XCTAssertEqual(result.assetCount, 1_000)
        XCTAssertGreaterThanOrEqual(result.elapsedSeconds, 0)
        XCTAssertGreaterThanOrEqual(result.assetsPerSecond, 0)
    }

    func testIndexingBenchmarkRunnerRunsSyntheticFixtureCounts() async throws {
        let results = try await AssetIndexingBenchmarkRunner().runSynthetic(assetCounts: [1_000, 10_000, 50_000])

        XCTAssertEqual(results.map(\.assetCount), [1_000, 10_000, 50_000])
        XCTAssertTrue(results.allSatisfy { $0.elapsedSeconds >= 0 })
    }

    func testIndexingBenchmarkReportEncodesStableJSON() throws {
        let report = AssetIndexingBenchmarkReport(
            mode: "Synthetic fixture",
            results: [
                AssetIndexingBenchmarkResult(assetCount: 10, elapsedSeconds: 0.25)
            ]
        )

        let json = String(data: try report.jsonData(), encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains(#""mode" : "Synthetic fixture""#) == true)
        XCTAssertTrue(json?.contains(#""assetCount" : 10"#) == true)
        XCTAssertTrue(json?.contains(#""assetsPerSecond" : 40"#) == true)
    }

    func testSyntheticPhotoAssetIndexerProvidesDeterministicFixtureSizes() async throws {
        let snapshots = try await SyntheticPhotoAssetIndexer(assetCount: 50_000).fetchAssetSnapshots()

        XCTAssertEqual(snapshots.count, 50_000)
        XCTAssertEqual(snapshots.first?.localIdentifier, "synthetic-0")
        XCTAssertEqual(snapshots.last?.localIdentifier, "synthetic-49999")
        XCTAssertEqual(snapshots[11].mediaType, .video)
        XCTAssertEqual(snapshots[19].mediaType, .screenshot)
        XCTAssertNil(snapshots[5].latitude)
        XCTAssertNotNil(snapshots[6].latitude)
    }
}

private final class CountingThumbnailProvider: PhotoThumbnailProviding {
    private let data: Data?
    private(set) var requestCount = 0

    init(data: Data?) {
        self.data = data
    }

    func thumbnailData(for request: PhotoThumbnailRequest) async throws -> Data? {
        requestCount += 1
        return data
    }
}
