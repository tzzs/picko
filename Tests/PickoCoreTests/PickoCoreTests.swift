import XCTest
@testable import PickoCore

final class PickoCoreTests: XCTestCase {
    func testPreDeletedAssetsEnterDeletionQueueWithEstimatedBytes() {
        let asset = makeAsset(id: "a1", fileSizeBytes: 4_000_000)
        var store = ReviewStateStore(assets: [asset])

        store.apply(.preDelete(asset.id))

        XCTAssertEqual(store.asset(id: asset.id)?.status, .preDeleted)
        XCTAssertEqual(store.deletionQueue.itemIds, [asset.id])
        XCTAssertEqual(store.deletionQueue.estimatedBytes, 4_000_000)
    }

    func testUndoRestoresPreviousAssetStatusAndBasket() {
        let asset = makeAsset(id: "a1", fileSizeBytes: 10)
        var store = ReviewStateStore(assets: [asset])

        store.apply(.preDelete(asset.id))
        store.undo()

        XCTAssertEqual(store.asset(id: asset.id)?.status, .unreviewed)
        XCTAssertTrue(store.deletionQueue.itemIds.isEmpty)
    }

    func testKeepRemovesAssetFromDeletionQueue() {
        let asset = makeAsset(id: "a1", fileSizeBytes: 10)
        var store = ReviewStateStore(assets: [asset])

        store.apply(.preDelete("a1"))
        store.apply(.keep("a1"))

        XCTAssertEqual(store.asset(id: "a1")?.status, .kept)
        XCTAssertTrue(store.deletionQueue.itemIds.isEmpty)
    }

    func testSkipMarksAssetSkippedWithoutQueueingForDeletion() {
        let asset = makeAsset(id: "a1", fileSizeBytes: 10)
        var store = ReviewStateStore(assets: [asset])

        store.apply(.skip("a1"))

        XCTAssertEqual(store.asset(id: "a1")?.status, .skipped)
        XCTAssertTrue(store.deletionQueue.itemIds.isEmpty)
    }

    func testPreDeletingSameAssetTwiceDoesNotDuplicateQueueItem() {
        let asset = makeAsset(id: "a1", fileSizeBytes: 10)
        var store = ReviewStateStore(assets: [asset])

        store.apply(.preDelete("a1"))
        store.apply(.preDelete("a1"))

        XCTAssertEqual(store.deletionQueue.itemIds, ["a1"])
        XCTAssertEqual(store.deletionQueue.estimatedBytes, 10)
    }

    func testClearingReviewStateResetsAssetGroupAndBasketState() {
        let group = SimilarGroup(
            id: "group-1",
            assetIds: ["a1", "a2"],
            groupType: .similar,
            timeRange: nil,
            locationSummary: nil,
            recommendedKeepIds: ["a2"],
            keepCount: 1,
            confidenceScore: 0.8,
            status: .unreviewed
        )
        var store = ReviewStateStore(
            assets: [
                makeAsset(id: "a1", fileSizeBytes: 10),
                makeAsset(id: "a2", fileSizeBytes: 20)
            ],
            groups: [group]
        )
        store.apply(.keepOnly(assetIds: ["a1"], inGroup: "group-1"))

        store.clearReviewState()

        XCTAssertEqual(store.orderedAssets.map(\.status), [.unreviewed, .unreviewed])
        XCTAssertEqual(store.group(id: "group-1")?.status, .unreviewed)
        XCTAssertEqual(store.group(id: "group-1")?.recommendedKeepIds, ["a2"])
        XCTAssertEqual(store.group(id: "group-1")?.keepCount, 1)
        XCTAssertTrue(store.deletionQueue.itemIds.isEmpty)
    }

    func testApplyingSimilarGroupSelectionKeepsSelectedAssetsAndPreDeletesTheRest() {
        let assets = [
            makeAsset(id: "a1", fileSizeBytes: 10),
            makeAsset(id: "a2", fileSizeBytes: 20),
            makeAsset(id: "a3", fileSizeBytes: 30)
        ]
        let group = SimilarGroup(
            id: "g1",
            assetIds: ["a1", "a2", "a3"],
            groupType: .similar,
            timeRange: nil,
            locationSummary: nil,
            recommendedKeepIds: ["a2"],
            keepCount: 1,
            confidenceScore: 0.8,
            status: .unreviewed
        )
        var store = ReviewStateStore(assets: assets, groups: [group])

        store.apply(.keepOnly(assetIds: ["a2"], inGroup: "g1"))

        XCTAssertEqual(store.asset(id: "a2")?.status, .kept)
        XCTAssertEqual(store.asset(id: "a1")?.status, .preDeleted)
        XCTAssertEqual(store.asset(id: "a3")?.status, .preDeleted)
        XCTAssertEqual(store.deletionQueue.itemIds, ["a1", "a3"])
        XCTAssertEqual(store.group(id: "g1")?.status, .reviewed)
    }

    func testSimilarAssetsAreGroupedWithinTimeWindowAndHashMatch() {
        let base = Date(timeIntervalSince1970: 1_000)
        let assets = [
            makeAsset(id: "a1", creationDate: base, thumbnailHash: "same", perceptualHash: "same"),
            makeAsset(id: "a2", creationDate: base.addingTimeInterval(12), thumbnailHash: "same", perceptualHash: "same"),
            makeAsset(id: "a3", creationDate: base.addingTimeInterval(600), thumbnailHash: "different", perceptualHash: "different")
        ]

        let groups = SimilarityEngine(configuration: .init(timeWindow: 60)).groups(from: assets)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].assetIds, ["a1", "a2"])
    }

    func testFavoriteAssetIsPreferredAsRecommendedKeep() {
        let base = Date(timeIntervalSince1970: 1_000)
        let assets = [
            makeAsset(id: "a1", creationDate: base, fileSizeBytes: 10, isFavorite: false, thumbnailHash: "same", perceptualHash: "same"),
            makeAsset(id: "a2", creationDate: base.addingTimeInterval(8), fileSizeBytes: 20, isFavorite: true, thumbnailHash: "same", perceptualHash: "same")
        ]

        let groups = SimilarityEngine(configuration: .init(timeWindow: 60)).groups(from: assets)

        XCTAssertEqual(groups.first?.recommendedKeepIds, ["a2"])
    }

    func testAssetsOutsideLocationThresholdAreNotGrouped() {
        let base = Date(timeIntervalSince1970: 1_000)
        let assets = [
            makeAsset(id: "a1", creationDate: base, location: .init(latitude: 31.2304, longitude: 121.4737), thumbnailHash: "same", perceptualHash: "same"),
            makeAsset(id: "a2", creationDate: base.addingTimeInterval(10), location: .init(latitude: 39.9042, longitude: 116.4074), thumbnailHash: "same", perceptualHash: "same")
        ]

        let groups = SimilarityEngine(configuration: .init(timeWindow: 60, locationThresholdMeters: 100)).groups(from: assets)

        XCTAssertTrue(groups.isEmpty)
    }

    func testAssetsWithDifferentMediaTypesAreNotGrouped() {
        let base = Date(timeIntervalSince1970: 1_000)
        let assets = [
            makeAsset(id: "a1", mediaType: .photo, creationDate: base, thumbnailHash: "same", perceptualHash: "same"),
            makeAsset(id: "a2", mediaType: .video, creationDate: base.addingTimeInterval(10), thumbnailHash: "same", perceptualHash: "same")
        ]

        let groups = SimilarityEngine(configuration: .init(timeWindow: 60)).groups(from: assets)

        XCTAssertTrue(groups.isEmpty)
    }

    func testAssetsOutsideTimeWindowAreNotGroupedEvenWhenHashesMatch() {
        let base = Date(timeIntervalSince1970: 1_000)
        let assets = [
            makeAsset(id: "a1", creationDate: base, thumbnailHash: "same", perceptualHash: "same"),
            makeAsset(id: "a2", creationDate: base.addingTimeInterval(120), thumbnailHash: "same", perceptualHash: "same")
        ]

        let groups = SimilarityEngine(configuration: .init(timeWindow: 60)).groups(from: assets)

        XCTAssertTrue(groups.isEmpty)
    }

    func testRecommendationPrefersEditedAssetOverLargerUneditedAsset() {
        let base = Date(timeIntervalSince1970: 1_000)
        let assets = [
            makeAsset(id: "a1", creationDate: base, pixelWidth: 6000, pixelHeight: 4000, fileSizeBytes: 8_000_000, isEdited: false),
            makeAsset(id: "a2", creationDate: base, pixelWidth: 3000, pixelHeight: 2000, fileSizeBytes: 2_000_000, isEdited: true)
        ]

        let recommended = RecommendationEngine().recommendedKeepIds(from: assets, keepCount: 1)

        XCTAssertEqual(recommended, ["a2"])
    }

    func testRecommendationReturnsRequestedKeepCountInScoreOrder() {
        let assets = [
            makeAsset(id: "a1", pixelWidth: 1000, pixelHeight: 1000, fileSizeBytes: 1),
            makeAsset(id: "a2", pixelWidth: 4000, pixelHeight: 3000, fileSizeBytes: 1),
            makeAsset(id: "a3", pixelWidth: 3000, pixelHeight: 2000, fileSizeBytes: 1)
        ]

        let recommended = RecommendationEngine().recommendedKeepIds(from: assets, keepCount: 2)

        XCTAssertEqual(recommended, ["a2", "a3"])
    }

}

private extension PickoCoreTests {
    func makeAsset(
        id: String,
        mediaType: PhotoAsset.MediaType = .photo,
        creationDate: Date = Date(timeIntervalSince1970: 10),
        location: PhotoAsset.Location? = nil,
        pixelWidth: Int = 3000,
        pixelHeight: Int = 2000,
        fileSizeBytes: Int64 = 4_000_000,
        isFavorite: Bool = false,
        isEdited: Bool = false,
        isScreenshot: Bool = false,
        duration: TimeInterval? = nil,
        thumbnailHash: String? = "aa",
        perceptualHash: String? = "aa"
    ) -> PhotoAsset {
        PhotoAsset(
            id: id,
            mediaType: mediaType,
            creationDate: creationDate,
            location: location,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            fileSizeBytes: fileSizeBytes,
            isFavorite: isFavorite,
            isEdited: isEdited,
            isScreenshot: isScreenshot,
            duration: duration,
            thumbnailHash: thumbnailHash,
            perceptualHash: perceptualHash
        )
    }
}
