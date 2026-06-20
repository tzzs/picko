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

    func testRealLibraryAssetsWithoutHashesCanBeGroupedByConservativeMetadataFallback() {
        let base = Date(timeIntervalSince1970: 1_000)
        let assets = [
            makeAsset(id: "a1", creationDate: base, pixelWidth: 3024, pixelHeight: 4032, fileSizeBytes: 2_100_000, thumbnailHash: nil, perceptualHash: nil),
            makeAsset(id: "a2", creationDate: base.addingTimeInterval(24), pixelWidth: 3024, pixelHeight: 4032, fileSizeBytes: 2_250_000, thumbnailHash: nil, perceptualHash: nil),
            makeAsset(id: "a3", creationDate: base.addingTimeInterval(48), pixelWidth: 3000, pixelHeight: 4000, fileSizeBytes: 2_050_000, thumbnailHash: nil, perceptualHash: nil),
            makeAsset(id: "a4", creationDate: base.addingTimeInterval(72), pixelWidth: 3024, pixelHeight: 4032, fileSizeBytes: 2_300_000, thumbnailHash: nil, perceptualHash: nil),
            makeAsset(id: "a5", creationDate: base.addingTimeInterval(96), pixelWidth: 3024, pixelHeight: 4032, fileSizeBytes: 2_200_000, thumbnailHash: nil, perceptualHash: nil),
            makeAsset(id: "a6", creationDate: base.addingTimeInterval(120), pixelWidth: 3000, pixelHeight: 4000, fileSizeBytes: 2_150_000, thumbnailHash: nil, perceptualHash: nil)
        ]

        let groups = SimilarityEngine(configuration: .realLibraryDefault).groups(from: assets)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].assetIds, ["a1", "a2", "a3", "a4", "a5", "a6"])
    }

    func testMetadataFallbackDoesNotGroupVeryDifferentAssetsWithoutHashes() {
        let base = Date(timeIntervalSince1970: 1_000)
        let assets = [
            makeAsset(id: "a1", creationDate: base, pixelWidth: 3024, pixelHeight: 4032, fileSizeBytes: 2_100_000, thumbnailHash: nil, perceptualHash: nil),
            makeAsset(id: "a2", creationDate: base.addingTimeInterval(24), pixelWidth: 1200, pixelHeight: 800, fileSizeBytes: 280_000, thumbnailHash: nil, perceptualHash: nil)
        ]

        let groups = SimilarityEngine(configuration: .realLibraryDefault).groups(from: assets)

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

    func testTimeCollectionGroupsCreateFixedRelativeBuckets() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 20, hour: 12)))
        let engine = PhotoCollectionGroupingEngine()
        let assets = [
            makeAsset(id: "today", creationDate: date(year: 2026, month: 6, day: 20, calendar: calendar)),
            makeAsset(id: "yesterday", creationDate: date(year: 2026, month: 6, day: 19, calendar: calendar)),
            makeAsset(id: "week", creationDate: date(year: 2026, month: 6, day: 17, calendar: calendar)),
            makeAsset(id: "last-month", creationDate: date(year: 2026, month: 5, day: 12, calendar: calendar)),
            makeAsset(id: "archive", creationDate: date(year: 2025, month: 12, day: 3, calendar: calendar))
        ]

        let groups = engine.timeGroups(from: assets, now: now, calendar: calendar)

        XCTAssertEqual(groups.map(\.title), [
            "今天 · 周六",
            "昨天 · 周五",
            "本周早些",
            "上个月 · 五月",
            "2025年12月"
        ])
        XCTAssertEqual(groups.map(\.assetIds), [
            ["today"],
            ["yesterday"],
            ["week"],
            ["last-month"],
            ["archive"]
        ])
        XCTAssertEqual(groups.map(\.kind), [.time, .time, .time, .time, .time])
    }

    func testTimeCollectionGroupsCountSimilarGroupsInsideBuckets() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 20, hour: 12)))
        let assets = [
            makeAsset(id: "a1", creationDate: date(year: 2026, month: 6, day: 20, calendar: calendar)),
            makeAsset(id: "a2", creationDate: date(year: 2026, month: 6, day: 20, calendar: calendar)),
            makeAsset(id: "a3", creationDate: date(year: 2026, month: 6, day: 19, calendar: calendar))
        ]
        let similarGroup = SimilarGroup(
            id: "similar-today",
            assetIds: ["a1", "a2"],
            groupType: .similar,
            timeRange: nil,
            locationSummary: nil,
            recommendedKeepIds: ["a1"],
            keepCount: 1,
            confidenceScore: 0.9,
            status: .unreviewed
        )

        let groups = PhotoCollectionGroupingEngine().timeGroups(
            from: assets,
            similarGroups: [similarGroup],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(groups.first?.title, "今天 · 周六")
        XCTAssertEqual(groups.first?.similarGroupCount, 1)
        XCTAssertEqual(groups.dropFirst().first?.similarGroupCount, 0)
    }

    func testPlaceCollectionGroupsClusterNearbyCoordinatesAndSkipMissingLocations() async {
        let assets = [
            makeAsset(id: "near-1", location: .init(latitude: 31.2304, longitude: 121.4737)),
            makeAsset(id: "near-2", location: .init(latitude: 31.2310, longitude: 121.4740)),
            makeAsset(id: "far", location: .init(latitude: 30.2741, longitude: 120.1551)),
            makeAsset(id: "no-location", location: nil)
        ]

        let groups = await PhotoCollectionGroupingEngine().placeGroups(
            from: assets,
            resolver: FakePlaceLabelResolver(labels: [
                "31.2307,121.4739": "上海 · 武康路",
                "30.2741,120.1551": "杭州 · 西湖"
            ])
        )

        XCTAssertEqual(groups.map(\.title), ["上海 · 武康路", "杭州 · 西湖"])
        XCTAssertEqual(groups.first?.assetIds, ["near-1", "near-2"])
        XCTAssertEqual(groups.last?.assetIds, ["far"])
        XCTAssertFalse(groups.flatMap(\.assetIds).contains("no-location"))
    }

    func testPlaceCollectionGroupsFallBackToGenericNearbyLabelWhenResolverFails() async {
        let assets = [
            makeAsset(id: "local", location: .init(latitude: 31.2304, longitude: 121.4737))
        ]

        let groups = await PhotoCollectionGroupingEngine().placeGroups(
            from: assets,
            resolver: FakePlaceLabelResolver(labels: [:])
        )

        XCTAssertEqual(groups.first?.title, "附近地点")
        XCTAssertFalse(groups.first?.title.contains("31.23") ?? true)
        XCTAssertEqual(groups.first?.representativeLocation?.latitude ?? 0, 31.2304, accuracy: 0.001)
    }

    func testPlaceCollectionGroupsTryAssetLocationsBeforeRepresentativeLocation() async {
        let assets = [
            makeAsset(id: "point-1", location: .init(latitude: 31.2304, longitude: 121.4737)),
            makeAsset(id: "point-2", location: .init(latitude: 31.2310, longitude: 121.4740))
        ]

        let groups = await PhotoCollectionGroupingEngine().placeGroups(
            from: assets,
            resolver: FakePlaceLabelResolver(
                labels: ["31.2304,121.4737": "上海 · 武康路"],
                allowsNearbyMatch: false
            )
        )

        XCTAssertEqual(groups.first?.title, "上海 · 武康路")
        XCTAssertEqual(groups.first?.representativeLocation?.latitude ?? 0, 31.2307, accuracy: 0.001)
    }

    func testPlaceCollectionGroupsUseLocalRegionFallbackBeforeCoordinates() async {
        let assets = [
            makeAsset(id: "iceland", location: .init(latitude: 63.53, longitude: -19.51))
        ]

        let groups = await PhotoCollectionGroupingEngine().placeGroups(
            from: assets,
            resolver: FakePlaceLabelResolver(labels: [:])
        )

        XCTAssertEqual(groups.first?.title, "冰岛南部")
    }

    func testPlaceCollectionGroupsUseCaliforniaRegionFallbackBeforeCoordinates() async {
        let assets = [
            makeAsset(id: "point-reyes", location: .init(latitude: 38.04, longitude: -122.80))
        ]

        let groups = await PhotoCollectionGroupingEngine().placeGroups(
            from: assets,
            resolver: FakePlaceLabelResolver(labels: [:])
        )

        XCTAssertEqual(groups.first?.title, "加州 · 马林县")
    }

}

private extension PickoCoreTests {
    func date(year: Int, month: Int, day: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 10))!
    }

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

private struct FakePlaceLabelResolver: PlaceLabelResolving {
    var labels: [String: String]
    var allowsNearbyMatch = true

    func label(for location: PhotoAsset.Location) async -> String? {
        if let exact = labels[String(format: "%.4f,%.4f", location.latitude, location.longitude)] {
            return exact
        }

        guard allowsNearbyMatch else {
            return nil
        }

        return labels
            .compactMap { key, label -> (distance: Double, label: String)? in
                let parts = key.split(separator: ",").compactMap(Double.init)
                guard parts.count == 2 else {
                    return nil
                }
                let distance = abs(parts[0] - location.latitude) + abs(parts[1] - location.longitude)
                return (distance, label)
            }
            .filter { $0.distance < 0.001 }
            .min { $0.distance < $1.distance }?
            .label
    }
}
