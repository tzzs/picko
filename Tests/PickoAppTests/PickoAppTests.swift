import XCTest
import MapKit
import SwiftUI
import PickoCore
import PickoPhotos
@testable import PickoApp

final class PickoAppTests: XCTestCase {
    func testPreDeleteActionUpdatesBasketCount() {
        let model = PickoAppModel.preview()

        model.preDeleteCurrentAsset()

        XCTAssertEqual(model.deletionQueueCount, 1)
    }

    func testSwiftDataStorePersistsReviewDecision() throws {
        let store = try ReviewDecisionStore.inMemory()

        try store.save(assetId: "a1", status: .preDeleted)

        XCTAssertEqual(try store.status(for: "a1"), .preDeleted)
    }

    func testSwiftDataStoreReopensPersistentReviewDecision() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let storeURL = directory.appendingPathComponent("ReviewDecisionStore.sqlite")

        do {
            let store = try ReviewDecisionStore.persistent(storeURL: storeURL)
            try store.save(assetId: "persistent-a1", status: .kept)
        }

        let reopenedStore = try ReviewDecisionStore.persistent(storeURL: storeURL)

        XCTAssertEqual(try reopenedStore.status(for: "persistent-a1"), .kept)
    }

    func testSwiftDataStoreClearsAllLocalReviewState() throws {
        let store = try ReviewDecisionStore.inMemory()
        let session = ReviewSession(
            id: "session-clear",
            mode: .single,
            startedAt: Date(timeIntervalSince1970: 10),
            reviewedCount: 1,
            keptCount: 0,
            preDeletedCount: 1,
            skippedCount: 0,
            freedBytesEstimate: 10
        )
        let group = SimilarGroup(
            id: "group-clear",
            assetIds: ["a1", "a2"],
            groupType: .similar,
            timeRange: nil,
            locationSummary: nil,
            recommendedKeepIds: ["a1"],
            keepCount: 1,
            confidenceScore: 0.7,
            status: .reviewed
        )
        var state = ReviewStateStore(
            assets: [
                makeAsset(id: "a1", fileSizeBytes: 10),
                makeAsset(id: "a2", fileSizeBytes: 20)
            ],
            groups: [group]
        )
        state.apply(.preDelete("a2"))

        try store.save(state: state)
        try store.save(session: session)
        try store.clearAllReviewState()

        XCTAssertNil(try store.status(for: "a2"))
        XCTAssertNil(try store.reviewSession(id: "session-clear"))
        XCTAssertNil(try store.groupDecision(id: "group-clear"))
        XCTAssertTrue(try store.basketItems().isEmpty)
    }

    func testRootViewCanBeConstructedWithPreviewModel() {
        let view = PickoRootView(model: .preview())

        XCTAssertNotNil(view)
    }

    func testLibraryBootstrapViewCanBeConstructed() {
        let view = PickoLibraryBootstrapView()

        XCTAssertNotNil(view)
    }

    func testBenchmarkLaunchConfigurationParsesSyntheticCounts() {
        let configuration = BenchmarkLaunchConfiguration.parse(arguments: [
            "Picko",
            "--picko-run-metadata-benchmark",
            "--picko-benchmark-synthetic",
            "--picko-benchmark-counts=10,20,30"
        ])

        XCTAssertEqual(configuration?.mode, .synthetic)
        XCTAssertEqual(configuration?.assetCounts, [10, 20, 30])
    }

    func testBenchmarkLaunchConfigurationDefaultsToPhotosMode() {
        let configuration = BenchmarkLaunchConfiguration.parse(arguments: [
            "Picko",
            "--picko-run-metadata-benchmark"
        ])

        XCTAssertEqual(configuration?.mode, .photos)
        XCTAssertEqual(configuration?.assetCounts, [1_000, 10_000, 50_000])
    }

    func testMetadataBenchmarkViewCanBeConstructed() {
        let view = MetadataBenchmarkView(
            configuration: BenchmarkLaunchConfiguration(mode: .synthetic, assetCounts: [10])
        )

        XCTAssertNotNil(view)
    }

    func testMetadataBenchmarkSummaryFormatsStableEvidenceText() {
        let summary = MetadataBenchmarkSummary(
            mode: "Synthetic",
            results: [
                AssetIndexingBenchmarkResult(assetCount: 10, elapsedSeconds: 0.25)
            ]
        )

        XCTAssertEqual(summary.text, "Mode: Synthetic; 10: 0.2500s, 40.0000 assets/s")
        XCTAssertEqual(
            summary.rowText(for: AssetIndexingBenchmarkResult(assetCount: 10, elapsedSeconds: 0.25)),
            "10 assets | 0.2500 seconds | 40.0000 assets/second"
        )
    }

    func testMetadataBenchmarkFailureMessagesAreSafeForEvidence() {
        XCTAssertEqual(
            MetadataBenchmarkFailure.photosAccessNotGranted(.denied).message,
            "Photos benchmark could not run because photo library access is denied."
        )
        XCTAssertEqual(
            MetadataBenchmarkFailure.photosAccessNotGranted(.restricted).message,
            "Photos benchmark could not run because photo library access is restricted."
        )
        XCTAssertEqual(
            MetadataBenchmarkFailure.benchmarkRunFailed.message,
            "Metadata benchmark failed before results could be captured. Check the test library setup and retry."
        )
    }

    func testPhotosConfirmationCopyMentionsRecentlyDeletedRecovery() {
        XCTAssertTrue(ReviewCopy.photosConfirmationMessage.contains("最近删除"))
        XCTAssertTrue(ReviewCopy.photosConfirmationMessage.contains("恢复"))
    }

    func testThumbnailViewCanBeConstructedWithoutProvider() {
        let view = PickoThumbnailView(asset: makeAsset(id: "a1"), thumbnailProvider: nil)

        XCTAssertNotNil(view)
    }

    func testSimilarGroupViewCanBeConstructedWithThumbnailProvider() {
        let model = PickoAppModel.preview()
        model.thumbnailProvider = FakeThumbnailProvider()

        let view = SimilarGroupReviewView(model: model)

        XCTAssertNotNil(view)
    }

    func testBasketViewCanBeConstructedWithThumbnailProvider() {
        let model = PickoAppModel.preview()
        model.thumbnailProvider = FakeThumbnailProvider()
        model.preDeleteCurrentAsset()

        let view = PreDeleteBasketView(model: model)

        XCTAssertNotNil(view)
    }

    func testHomePresentationEmphasizesTaskSummaryAndSafeBasket() {
        let model = PickoAppModel.preview()
        model.preDeleteCurrentAsset()

        let presentation = PickoHomePresentation(model: model)

        XCTAssertEqual(presentation.heroTitle, "继续整理珍贵回忆")
        XCTAssertEqual(presentation.metricRows.map(\.label), ["图库", "相似组", "预删除篮"])
        XCTAssertEqual(presentation.taskRows.map(\.title), [
            "单张整理",
            "相似照片",
            "预删除篮复核",
            "时间与地点"
        ])
        XCTAssertTrue(presentation.privacyFootnote.contains("不会删除照片"))
    }

    func testSingleReviewPresentationKeepsPrimaryActionsPhotoFirst() throws {
        let model = PickoAppModel.preview()

        let presentation = try XCTUnwrap(PickoSingleReviewPresentation(model: model))

        XCTAssertEqual(presentation.decisionHint, "向上保留，向下放入预删除篮。")
        XCTAssertEqual(presentation.primaryActions.map(\.title), ["保留", "放入预删除篮", "跳过"])
        XCTAssertEqual(presentation.primaryActions.map(\.systemImage), [
            "checkmark.circle.fill",
            "tray.and.arrow.down",
            "forward"
        ])
        XCTAssertTrue(presentation.dateLocationText.contains("附近"))
        XCTAssertFalse(presentation.dateLocationText.contains("31.23"))
        XCTAssertFalse(presentation.dateLocationText.contains("121.47"))
        XCTAssertFalse(presentation.dateLocationText.contains("2026年5月30日 · 上海"))
        XCTAssertTrue(presentation.metadataSummary.contains("相似组"))
    }

    func testSingleReviewLayoutKeepsActionsVisibleOnSmallPhones() {
        XCTAssertEqual(SingleReviewLayout.mainImageHeight(availableHeight: 667), 373.52, accuracy: 0.01)
        XCTAssertEqual(SingleReviewLayout.mainImageHeight(availableHeight: 568), 318.08, accuracy: 0.01)
        XCTAssertEqual(SingleReviewLayout.mainImageHeight(availableHeight: 900), 430, accuracy: 0.01)
    }

    func testSingleReviewLayoutDocksActionsAboveTabBar() {
        XCTAssertEqual(SingleReviewLayout.actionDockReservedHeight, 180)
        XCTAssertEqual(SingleReviewLayout.actionDockBottomPadding, 32)
        XCTAssertEqual(SingleReviewLayout.contentTopPadding, 4)
    }

    func testSingleReviewLayoutFillsMainPhotoToAvoidLetterboxing() {
        XCTAssertEqual(SingleReviewLayout.mainImageContentMode, .fill)
    }

    func testPlaceLabelFormatterUsesCountryAndNaturalFeatureWhenCityIsMissing() {
        let label = PhotoPlaceLabelFormatter.label(
            city: nil,
            region: nil,
            country: "冰岛",
            place: nil,
            areaOfInterest: "Skogafoss",
            naturalFeature: nil
        )

        XCTAssertEqual(label, "冰岛 · Skogafoss")
    }

    func testPlaceLabelFormatterUsesNaturalFeatureBeforeCoordinateFallback() {
        let label = PhotoPlaceLabelFormatter.label(
            city: nil,
            region: "南部区",
            country: nil,
            place: nil,
            areaOfInterest: nil,
            naturalFeature: "大西洋"
        )

        XCTAssertEqual(label, "南部区 · 大西洋")
    }

    func testSimilarGroupPresentationExplainsKeepNAndEditableRecommendation() throws {
        let model = PickoAppModel.preview()

        let presentation = try XCTUnwrap(PickoSimilarGroupPresentation(model: model))

        XCTAssertEqual(presentation.modeTitles, ["保留 1 张", "保留多张"])
        XCTAssertEqual(presentation.recommendationBadge, "推荐保留")
        XCTAssertTrue(presentation.footerExplanation.contains("未选照片会进入预删除篮"))
        XCTAssertGreaterThanOrEqual(presentation.assetRows.count, 2)
    }

    func testBasketPresentationReinforcesRecoveryBeforePhotosConfirmation() {
        let model = PickoAppModel.preview()
        model.preDeleteCurrentAsset()

        let presentation = PickoBasketPresentation(model: model)

        XCTAssertEqual(presentation.summaryTitle, "1 项等待最终复核")
        XCTAssertEqual(presentation.summarySubtitle, "预计可节省：3.7 MB")
        XCTAssertEqual(presentation.primaryActionTitle, "交由系统照片确认")
        XCTAssertEqual(presentation.secondaryActionTitle, "确认前可恢复或清空")
        XCTAssertEqual(presentation.disabledReason, "当前为样例图库，无法调用系统照片确认。")
        XCTAssertTrue(presentation.recoveryMessage.contains("最近删除"))
        XCTAssertTrue(presentation.recoveryMessage.contains("恢复"))
    }

    func testBasketPresentationFormatsZeroBytesInChinese() {
        let presentation = PickoBasketPresentation(model: .preview())

        XCTAssertEqual(presentation.summarySubtitle, "预计可节省：0 字节")
        XCTAssertEqual(presentation.disabledReason, "预删除篮为空，暂无需要确认的项目。")
    }

    func testPhotoPreviewViewCanBeConstructedForReviewActions() {
        let model = PickoAppModel.preview()
        let view = PhotoPreviewView(asset: model.assets[0], model: model)

        XCTAssertNotNil(view)
    }

    func testCollectionReviewViewCanRenderTimeAndPlaceModes() {
        let model = PickoAppModel.preview()

        let timeView = CollectionReviewView(mode: .time, model: model)
        let placeView = CollectionReviewView(
            mode: .place,
            model: model,
            placeLabelResolver: FakePlaceLabelResolver(labels: [:])
        )

        XCTAssertNotNil(timeView)
        XCTAssertNotNil(placeView)
    }

    func testCollectionPreviewStripUsesReadablePhotoHeight() {
        XCTAssertGreaterThanOrEqual(CollectionPreviewStripLayout.height, 108)
        XCTAssertGreaterThanOrEqual(CollectionPreviewStripLayout.targetPixelHeight, 320)
    }

    func testPlaceMapPresentationUsesRealGroupCoordinates() {
        let groups = [
            makePlaceGroup(
                id: "shanghai",
                title: "上海 · 武康路",
                latitude: 31.2304,
                longitude: 121.4737,
                assetIds: ["a1", "a2"]
            ),
            makePlaceGroup(
                id: "hangzhou",
                title: "杭州 · 西湖",
                latitude: 30.2741,
                longitude: 120.1551,
                assetIds: ["a3"]
            )
        ]

        let presentation = PlaceMapPresentation(groups: groups)

        XCTAssertEqual(presentation.annotations.map(\.id), ["shanghai", "hangzhou"])
        XCTAssertEqual(presentation.annotations.map(\.count), [2, 1])
        XCTAssertEqual(presentation.annotations.first?.latitude ?? 0, 31.2304, accuracy: 0.0001)
        XCTAssertEqual(presentation.annotations.first?.longitude ?? 0, 121.4737, accuracy: 0.0001)
        XCTAssertEqual(presentation.region.center.latitude, 30.75225, accuracy: 0.01)
        XCTAssertEqual(presentation.region.center.longitude, 120.8144, accuracy: 0.01)
        XCTAssertGreaterThan(presentation.region.span.latitudeDelta, 0.9)
        XCTAssertGreaterThan(presentation.region.span.longitudeDelta, 1.3)
    }

    func testPlaceMapPresentationFitsAllLocationsForThumbnailAndDetailAspects() {
        let groups = [
            makePlaceGroup(id: "west", title: "西侧", latitude: 31.2304, longitude: 121.4737, assetIds: ["a1"]),
            makePlaceGroup(id: "east", title: "东侧", latitude: 31.2304, longitude: 122.4737, assetIds: ["a2"])
        ]

        let presentation = PlaceMapPresentation(groups: groups)
        let thumbnailRegion = presentation.fittingRegion(forAspectRatio: 2.0)
        let detailRegion = presentation.fittingRegion(forAspectRatio: 0.46)

        XCTAssertEqual(thumbnailRegion.center.latitude, 31.2304, accuracy: 0.0001)
        XCTAssertEqual(thumbnailRegion.center.longitude, 121.9737, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(thumbnailRegion.span.longitudeDelta, thumbnailRegion.span.latitudeDelta * 2.0)
        XCTAssertGreaterThanOrEqual(detailRegion.span.latitudeDelta, detailRegion.span.longitudeDelta / 0.46)
        XCTAssertGreaterThanOrEqual(detailRegion.span.longitudeDelta, 1.6)
    }

    func testPlaceMapPresentationKeepsThumbnailPinsAwayFromEdges() {
        let groups = [
            makePlaceGroup(id: "northwest", title: "西北", latitude: 32.0, longitude: 121.0, assetIds: ["a1"]),
            makePlaceGroup(id: "southeast", title: "东南", latitude: 31.0, longitude: 122.0, assetIds: ["a2"])
        ]

        let presentation = PlaceMapPresentation(groups: groups)
        let thumbnailRegion = presentation.thumbnailRegion(forAspectRatio: 2.0)

        XCTAssertGreaterThanOrEqual(thumbnailRegion.span.latitudeDelta, 2.4)
        XCTAssertGreaterThanOrEqual(thumbnailRegion.span.longitudeDelta, thumbnailRegion.span.latitudeDelta * 2.0)
        XCTAssertEqual(thumbnailRegion.center.latitude, 31.5, accuracy: 0.0001)
        XCTAssertEqual(thumbnailRegion.center.longitude, 121.5, accuracy: 0.0001)
    }

    func testPlaceMapPresentationThumbnailFocusesMainClusterWhenThereIsDistantOutlier() {
        let groups = [
            makePlaceGroup(id: "iceland-south", title: "冰岛南部", latitude: 63.5321, longitude: -19.5114, assetIds: ["a1"]),
            makePlaceGroup(id: "iceland-east", title: "冰岛东部", latitude: 64.2539, longitude: -15.2082, assetIds: ["a2"]),
            makePlaceGroup(id: "iceland-north", title: "冰岛北部", latitude: 65.6835, longitude: -18.0878, assetIds: ["a3"]),
            makePlaceGroup(id: "california", title: "加州 · 马林县", latitude: 37.9060, longitude: -122.5449, assetIds: ["a4"])
        ]

        let presentation = PlaceMapPresentation(groups: groups)
        let thumbnailRegion = presentation.thumbnailRegion(forAspectRatio: 2.0)

        XCTAssertEqual(thumbnailRegion.center.latitude, 64.6078, accuracy: 0.2)
        XCTAssertEqual(thumbnailRegion.center.longitude, -17.3598, accuracy: 0.5)
        XCTAssertLessThan(thumbnailRegion.span.longitudeDelta, 20)
    }

    func testPlaceMapPresentationKeepsDetailPinsAwayFromEdges() {
        let groups = [
            makePlaceGroup(id: "northwest", title: "西北", latitude: 32.0, longitude: 121.0, assetIds: ["a1"]),
            makePlaceGroup(id: "southeast", title: "东南", latitude: 31.0, longitude: 122.0, assetIds: ["a2"])
        ]

        let presentation = PlaceMapPresentation(groups: groups)
        let detailRegion = presentation.detailRegion(forAspectRatio: 0.46)

        XCTAssertGreaterThanOrEqual(detailRegion.span.latitudeDelta, detailRegion.span.longitudeDelta / 0.46)
        XCTAssertGreaterThanOrEqual(detailRegion.span.longitudeDelta, 2.4)
        XCTAssertEqual(detailRegion.center.latitude, 31.5, accuracy: 0.0001)
        XCTAssertEqual(detailRegion.center.longitude, 121.5, accuracy: 0.0001)
    }

    func testPlaceMapPresentationKeepsDetailPinsInsideVisualSafeArea() {
        let groups = [
            makePlaceGroup(id: "northwest", title: "西北", latitude: 32.0, longitude: 121.0, assetIds: ["a1"]),
            makePlaceGroup(id: "southeast", title: "东南", latitude: 31.0, longitude: 122.0, assetIds: ["a2"])
        ]

        let presentation = PlaceMapPresentation(groups: groups)
        let detailRegion = presentation.detailRegion(forAspectRatio: 0.46)
        let margins = normalizedMargins(for: presentation.annotations, in: detailRegion)

        XCTAssertGreaterThanOrEqual(margins.horizontal, 0.35)
        XCTAssertGreaterThanOrEqual(margins.vertical, 0.35)
    }

    func testPlaceMapPresentationDetailFocusesMainClusterWhenThereIsDistantOutlier() {
        let groups = [
            makePlaceGroup(id: "iceland-south", title: "冰岛南部", latitude: 63.5321, longitude: -19.5114, assetIds: ["a1"]),
            makePlaceGroup(id: "iceland-east", title: "冰岛东部", latitude: 64.2539, longitude: -15.2082, assetIds: ["a2"]),
            makePlaceGroup(id: "iceland-north", title: "冰岛北部", latitude: 65.6835, longitude: -18.0878, assetIds: ["a3"]),
            makePlaceGroup(id: "california", title: "加州 · 马林县", latitude: 37.9060, longitude: -122.5449, assetIds: ["a4"])
        ]

        let presentation = PlaceMapPresentation(groups: groups)
        let detailRegion = presentation.detailRegion(forAspectRatio: 0.46)

        XCTAssertEqual(detailRegion.center.latitude, 64.6078, accuracy: 0.2)
        XCTAssertEqual(detailRegion.center.longitude, -17.3598, accuracy: 0.5)
        XCTAssertLessThan(detailRegion.span.longitudeDelta, 20)
    }

    func testPlaceMapPresentationPrefersMapTapToExpand() {
        let presentation = PlaceMapPresentation(groups: [
            makePlaceGroup(id: "shanghai", title: "上海", latitude: 31.2304, longitude: 121.4737, assetIds: ["a1"])
        ])

        XCTAssertTrue(presentation.prefersMapTapToExpand)
    }

    func testPlaceMapPresentationAllowsPanAndZoom() {
        let presentation = PlaceMapPresentation(groups: [
            makePlaceGroup(id: "shanghai", title: "上海", latitude: 31.2304, longitude: 121.4737, assetIds: ["a1"])
        ])

        XCTAssertTrue(presentation.interactionModes.contains(MapInteractionModes.pan))
        XCTAssertTrue(presentation.interactionModes.contains(MapInteractionModes.zoom))
        XCTAssertFalse(presentation.interactionModes.contains(MapInteractionModes.rotate))
    }

    func testStartingReviewScopeLimitsCurrentAssetToSelectedUnreviewedAssets() {
        var state = ReviewStateStore(assets: [
            makeAsset(id: "outside"),
            makeAsset(id: "inside-reviewed"),
            makeAsset(id: "inside-live")
        ])
        state.apply(.keep("inside-reviewed"))
        let model = PickoAppModel(store: state)

        model.startReview(scope: .init(
            mode: .time,
            title: "今天 · 周六",
            assetIds: ["inside-reviewed", "inside-live"]
        ))

        XCTAssertEqual(model.selectedTab, .review)
        XCTAssertEqual(model.reviewScope?.assetIds, ["inside-live"])
        XCTAssertEqual(model.currentAsset?.id, "inside-live")
        XCTAssertEqual(model.currentSession.mode, .timeRange)
    }

    func testScopedReviewActionsUpdateSharedStoreAndBasket() {
        let model = PickoAppModel(store: ReviewStateStore(assets: [
            makeAsset(id: "keep-me", fileSizeBytes: 10),
            makeAsset(id: "delete-me", fileSizeBytes: 20),
            makeAsset(id: "outside", fileSizeBytes: 30)
        ]))
        model.startReview(scope: .init(
            mode: .place,
            title: "上海 · 武康路",
            assetIds: ["keep-me", "delete-me"]
        ))

        model.keepCurrentAsset()
        model.preDeleteCurrentAsset()

        XCTAssertEqual(model.store.asset(id: "keep-me")?.status, .kept)
        XCTAssertEqual(model.store.asset(id: "delete-me")?.status, .preDeleted)
        XCTAssertEqual(model.store.asset(id: "outside")?.status, .unreviewed)
        XCTAssertEqual(model.store.deletionQueue.itemIds, ["delete-me"])
        XCTAssertTrue(model.hasCompletedReviewScope)
        XCTAssertNil(model.currentAsset)
    }

    func testScopedReviewCompletionCanReturnHomeOrBasket() {
        let model = PickoAppModel(store: ReviewStateStore(assets: [
            makeAsset(id: "only", fileSizeBytes: 10)
        ]))
        model.startReview(scope: .init(
            mode: .time,
            title: "今天 · 周六",
            assetIds: ["only"]
        ))

        model.skipCurrentAsset()

        XCTAssertTrue(model.hasCompletedReviewScope)
        model.clearReviewScope()
        XCTAssertNil(model.reviewScope)
        XCTAssertEqual(model.currentAssetIndex, 0)
        XCTAssertEqual(model.currentAsset?.id, "only")
    }

    func testModelLoadsAssetsFromPhotoIndexer() async throws {
        let indexer = FakePhotoAssetIndexer(snapshots: [
            PhotoAssetSnapshot(
                localIdentifier: "real-1",
                mediaType: .image,
                creationDate: Date(timeIntervalSince1970: 10),
                latitude: nil,
                longitude: nil,
                pixelWidth: 3024,
                pixelHeight: 4032,
                fileSizeBytes: 1_500_000,
                isFavorite: true,
                isEdited: false,
                isScreenshot: false,
                duration: nil,
                thumbnailHash: "same",
                perceptualHash: "same"
            ),
            PhotoAssetSnapshot(
                localIdentifier: "real-2",
                mediaType: .image,
                creationDate: Date(timeIntervalSince1970: 12),
                latitude: nil,
                longitude: nil,
                pixelWidth: 3024,
                pixelHeight: 4032,
                fileSizeBytes: 1_400_000,
                isFavorite: false,
                isEdited: false,
                isScreenshot: false,
                duration: nil,
                thumbnailHash: "same",
                perceptualHash: "same"
            )
        ])

        let model = try await PickoAppModel.loadingFromPhotoLibrary(indexer: indexer)

        XCTAssertEqual(model.assets.map(\.id), ["real-1", "real-2"])
        XCTAssertEqual(model.groups.count, 1)
        XCTAssertEqual(model.groups.first?.recommendedKeepIds, ["real-1"])
    }

    func testSwiftDataStoreAppliesPersistedReviewState() throws {
        let store = try ReviewDecisionStore.inMemory()
        var state = ReviewStateStore(assets: [
            makeAsset(id: "a1"),
            makeAsset(id: "a2")
        ])
        state.apply(.preDelete("a1"))
        state.apply(.skip("a2"))

        try store.save(state: state)
        let restored = try store.applyingSavedDecisions(
            to: ReviewStateStore(assets: [
                makeAsset(id: "a1"),
                makeAsset(id: "a2")
            ])
        )

        XCTAssertEqual(restored.asset(id: "a1")?.status, .preDeleted)
        XCTAssertEqual(restored.asset(id: "a2")?.status, .skipped)
        XCTAssertEqual(restored.deletionQueue.itemIds, ["a1"])
    }

    func testSwiftDataStoreRestoresPersistedBasketOrder() throws {
        let store = try ReviewDecisionStore.inMemory()
        var state = ReviewStateStore(assets: [
            makeAsset(id: "a1", fileSizeBytes: 10),
            makeAsset(id: "a2", fileSizeBytes: 20),
            makeAsset(id: "a3", fileSizeBytes: 30)
        ])
        state.apply(.preDelete("a2"))
        state.apply(.preDelete("a1"))

        try store.save(state: state)
        let restored = try store.applyingSavedDecisions(
            to: ReviewStateStore(assets: [
                makeAsset(id: "a1", fileSizeBytes: 10),
                makeAsset(id: "a2", fileSizeBytes: 20),
                makeAsset(id: "a3", fileSizeBytes: 30)
            ])
        )

        XCTAssertEqual(restored.deletionQueue.itemIds, ["a2", "a1"])
        XCTAssertEqual(restored.deletionQueue.estimatedBytes, 30)
    }

    func testSwiftDataStorePersistsReviewSession() throws {
        let store = try ReviewDecisionStore.inMemory()
        let session = ReviewSession(
            id: "session-1",
            mode: .similarGroup,
            startedAt: Date(timeIntervalSince1970: 10),
            completedAt: Date(timeIntervalSince1970: 20),
            reviewedCount: 4,
            keptCount: 1,
            preDeletedCount: 2,
            skippedCount: 1,
            freedBytesEstimate: 42
        )

        try store.save(session: session)

        XCTAssertEqual(try store.reviewSession(id: "session-1"), session)
    }

    func testSwiftDataStoreReturnsLatestIncompleteReviewSession() throws {
        let store = try ReviewDecisionStore.inMemory()
        try store.save(session: ReviewSession(
            id: "older",
            mode: .single,
            startedAt: Date(timeIntervalSince1970: 10),
            reviewedCount: 1
        ))
        try store.save(session: ReviewSession(
            id: "completed",
            mode: .single,
            startedAt: Date(timeIntervalSince1970: 30),
            completedAt: Date(timeIntervalSince1970: 40),
            reviewedCount: 2
        ))
        try store.save(session: ReviewSession(
            id: "newer",
            mode: .similarGroup,
            startedAt: Date(timeIntervalSince1970: 20),
            reviewedCount: 3
        ))

        XCTAssertEqual(try store.latestIncompleteReviewSession()?.id, "newer")
    }

    func testModelPersistsCurrentSessionAfterSingleAssetAction() throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        let session = ReviewSession(
            id: "session-current",
            mode: .single,
            startedAt: Date(timeIntervalSince1970: 10)
        )
        let model = PickoAppModel(
            store: ReviewStateStore(assets: [
                makeAsset(id: "a1", fileSizeBytes: 10)
            ]),
            currentSession: session,
            decisionStore: decisionStore
        )

        model.preDeleteCurrentAsset()

        let persisted = try XCTUnwrap(decisionStore.reviewSession(id: "session-current"))
        XCTAssertEqual(persisted.reviewedCount, 1)
        XCTAssertEqual(persisted.preDeletedCount, 1)
        XCTAssertEqual(persisted.freedBytesEstimate, 10)
    }

    func testPhotoLibraryBootstrapperRestoresLatestIncompleteSession() async throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        try decisionStore.save(session: ReviewSession(
            id: "session-restore",
            mode: .single,
            startedAt: Date(timeIntervalSince1970: 10),
            reviewedCount: 4,
            keptCount: 2
        ))
        let bootstrapper = PhotoLibraryBootstrapper(
            authorizer: FakePhotoLibraryAuthorizer(status: .authorized),
            indexer: FakePhotoAssetIndexer(snapshots: [makeSnapshot(id: "real-session")]),
            decisionStore: decisionStore
        )

        let model = try await bootstrapper.loadModel()

        XCTAssertEqual(model.currentSession.id, "session-restore")
        XCTAssertEqual(model.currentSession.reviewedCount, 4)
        XCTAssertEqual(model.currentSession.keptCount, 2)
    }

    func testSwiftDataStorePersistsGroupDecision() throws {
        let store = try ReviewDecisionStore.inMemory()
        var group = SimilarGroup(
            id: "group-1",
            assetIds: ["a1", "a2", "a3"],
            groupType: .similar,
            timeRange: DateInterval(
                start: Date(timeIntervalSince1970: 10),
                end: Date(timeIntervalSince1970: 20)
            ),
            locationSummary: "Shanghai",
            recommendedKeepIds: ["a1"],
            keepCount: 1,
            confidenceScore: 0.8,
            status: .unreviewed
        )
        group.recommendedKeepIds = ["a2"]
        group.keepCount = 1
        group.status = .reviewed

        try store.save(group: group)

        XCTAssertEqual(try store.groupDecision(id: "group-1"), group)
    }

    func testSwiftDataStorePersistsOrderedBasketItems() throws {
        let store = try ReviewDecisionStore.inMemory()
        var state = ReviewStateStore(assets: [
            makeAsset(id: "a1", fileSizeBytes: 10),
            makeAsset(id: "a2", fileSizeBytes: 20),
            makeAsset(id: "a3", fileSizeBytes: 30)
        ])
        state.apply(.preDelete("a2"))
        state.apply(.preDelete("a1"))

        try store.saveBasket(from: state)

        XCTAssertEqual(try store.basketItems().map(\.assetId), ["a2", "a1"])
        XCTAssertEqual(try store.basketItems().map(\.fileSizeBytes), [20, 10])
    }

    func testSavingReviewStatePersistsGroupDecisionAndBasketOrder() throws {
        let store = try ReviewDecisionStore.inMemory()
        let group = SimilarGroup(
            id: "group-state",
            assetIds: ["a1", "a2"],
            groupType: .similar,
            timeRange: nil,
            locationSummary: nil,
            recommendedKeepIds: ["a1"],
            keepCount: 1,
            confidenceScore: 0.6,
            status: .unreviewed
        )
        var state = ReviewStateStore(
            assets: [
                makeAsset(id: "a1", fileSizeBytes: 10),
                makeAsset(id: "a2", fileSizeBytes: 20)
            ],
            groups: [group]
        )
        state.apply(.keepOnly(assetIds: ["a1"], inGroup: group.id))

        try store.save(state: state)

        XCTAssertEqual(try store.groupDecision(id: "group-state")?.status, .reviewed)
        XCTAssertEqual(try store.basketItems().map(\.assetId), ["a2"])
    }

    func testModelPersistsStateAfterSingleAssetAction() throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        let model = PickoAppModel(
            store: ReviewStateStore(assets: [
                makeAsset(id: "a1", fileSizeBytes: 10),
                makeAsset(id: "a2", fileSizeBytes: 20)
            ]),
            decisionStore: decisionStore
        )

        model.preDeleteCurrentAsset()

        XCTAssertEqual(try decisionStore.status(for: "a1"), .preDeleted)
        XCTAssertEqual(try decisionStore.basketItems().map(\.assetId), ["a1"])
    }

    func testModelPersistsStateAfterSimilarGroupAction() throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        let group = SimilarGroup(
            id: "group-auto",
            assetIds: ["a1", "a2"],
            groupType: .similar,
            timeRange: nil,
            locationSummary: nil,
            recommendedKeepIds: ["a1"],
            keepCount: 1,
            confidenceScore: 0.7,
            status: .unreviewed
        )
        let model = PickoAppModel(
            store: ReviewStateStore(
                assets: [
                    makeAsset(id: "a1", fileSizeBytes: 10),
                    makeAsset(id: "a2", fileSizeBytes: 20)
                ],
                groups: [group]
            ),
            decisionStore: decisionStore
        )

        model.keep(assetIds: ["a1"], in: group)

        XCTAssertEqual(try decisionStore.groupDecision(id: "group-auto")?.status, .reviewed)
        XCTAssertEqual(try decisionStore.basketItems().map(\.assetId), ["a2"])
    }

    func testModelClearsLocalReviewStateFromMemoryAndPersistence() throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        let group = SimilarGroup(
            id: "group-reset",
            assetIds: ["a1", "a2"],
            groupType: .similar,
            timeRange: nil,
            locationSummary: nil,
            recommendedKeepIds: ["a1"],
            keepCount: 1,
            confidenceScore: 0.6,
            status: .unreviewed
        )
        let model = PickoAppModel(
            store: ReviewStateStore(
                assets: [
                    makeAsset(id: "a1", fileSizeBytes: 10),
                    makeAsset(id: "a2", fileSizeBytes: 20)
                ],
                groups: [group]
            ),
            decisionStore: decisionStore
        )
        model.keep(assetIds: ["a1"], in: group)

        model.clearLocalReviewState()

        XCTAssertEqual(model.assets.map(\.status), [.unreviewed, .unreviewed])
        XCTAssertEqual(model.groups.first?.status, .unreviewed)
        XCTAssertEqual(model.deletionQueueCount, 0)
        XCTAssertEqual(model.currentAssetIndex, 0)
        XCTAssertNil(try decisionStore.status(for: "a2"))
        XCTAssertNil(try decisionStore.groupDecision(id: "group-reset"))
        XCTAssertTrue(try decisionStore.basketItems().isEmpty)
    }

    func testPhotoLibraryBootstrapperLoadsAuthorizedLibraryAndAppliesSavedDecisions() async throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        try decisionStore.save(assetId: "real-1", status: .preDeleted)
        let bootstrapper = PhotoLibraryBootstrapper(
            authorizer: FakePhotoLibraryAuthorizer(status: .authorized),
            indexer: FakePhotoAssetIndexer(snapshots: [makeSnapshot(id: "real-1")]),
            decisionStore: decisionStore
        )

        let model = try await bootstrapper.loadModel()

        XCTAssertEqual(model.assets.map(\.id), ["real-1"])
        XCTAssertEqual(model.assets.first?.status, .preDeleted)
        XCTAssertEqual(model.deletionQueueCount, 1)
    }

    func testPhotoLibraryBootstrapperRestoresSavedGroupDecision() async throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        let savedGroup = SimilarGroup(
            id: "similar-1",
            assetIds: ["real-1", "real-2"],
            groupType: .similar,
            timeRange: nil,
            locationSummary: "Saved group",
            recommendedKeepIds: ["real-2"],
            keepCount: 1,
            confidenceScore: 0.9,
            status: .reviewed
        )
        try decisionStore.save(group: savedGroup)
        let bootstrapper = PhotoLibraryBootstrapper(
            authorizer: FakePhotoLibraryAuthorizer(status: .authorized),
            indexer: FakePhotoAssetIndexer(snapshots: [
                makeSnapshot(id: "real-1", thumbnailHash: "same", perceptualHash: "same"),
                makeSnapshot(id: "real-2", thumbnailHash: "same", perceptualHash: "same")
            ]),
            decisionStore: decisionStore
        )

        let model = try await bootstrapper.loadModel()

        let group = try XCTUnwrap(model.groups.first)
        XCTAssertEqual(group.id, savedGroup.id)
        XCTAssertEqual(group.recommendedKeepIds, ["real-2"])
        XCTAssertEqual(group.keepCount, 1)
        XCTAssertEqual(group.status, .reviewed)
    }

    func testPhotoLibraryBootstrapperLoadedModelPersistsFutureActions() async throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        let bootstrapper = PhotoLibraryBootstrapper(
            authorizer: FakePhotoLibraryAuthorizer(status: .authorized),
            indexer: FakePhotoAssetIndexer(snapshots: [makeSnapshot(id: "real-2")]),
            decisionStore: decisionStore
        )
        let model = try await bootstrapper.loadModel()

        model.preDeleteCurrentAsset()

        XCTAssertEqual(try decisionStore.status(for: "real-2"), .preDeleted)
        XCTAssertEqual(try decisionStore.basketItems().map(\.assetId), ["real-2"])
    }

    func testPhotoLibraryBootstrapperLoadedModelKeepsThumbnailProvider() async throws {
        let thumbnailProvider = FakeThumbnailProvider()
        let bootstrapper = PhotoLibraryBootstrapper(
            authorizer: FakePhotoLibraryAuthorizer(status: .authorized),
            indexer: FakePhotoAssetIndexer(snapshots: [makeSnapshot(id: "real-thumb")]),
            thumbnailProvider: thumbnailProvider,
            decisionStore: nil
        )

        let model = try await bootstrapper.loadModel()

        XCTAssertTrue(model.thumbnailProvider === thumbnailProvider)
    }

    func testPhotoLibraryBootstrapperRequestsAuthorizationBeforeLoading() async throws {
        let authorizer = FakePhotoLibraryAuthorizer(status: .notDetermined, requestedStatus: .limited)
        let bootstrapper = PhotoLibraryBootstrapper(
            authorizer: authorizer,
            indexer: FakePhotoAssetIndexer(snapshots: [makeSnapshot(id: "limited-1")]),
            decisionStore: nil
        )

        let model = try await bootstrapper.loadModel()

        XCTAssertEqual(authorizer.requestCount, 1)
        XCTAssertEqual(model.assets.map(\.id), ["limited-1"])
    }

    func testPhotoLibraryBootstrapperStopsWhenAccessIsDenied() async {
        let bootstrapper = PhotoLibraryBootstrapper(
            authorizer: FakePhotoLibraryAuthorizer(status: .denied),
            indexer: FakePhotoAssetIndexer(snapshots: [makeSnapshot(id: "blocked")]),
            decisionStore: nil
        )

        do {
            _ = try await bootstrapper.loadModel()
            XCTFail("Expected photo library access to stop before indexing")
        } catch PhotoLibraryBootstrapError.accessUnavailable(let status) {
            XCTAssertEqual(status, .denied)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testConfirmPreDeleteBasketRequestsDeletionOnlyForQueuedAssets() async throws {
        let model = PickoAppModel.preview()
        let firstId = try XCTUnwrap(model.currentAsset?.id)
        model.preDeleteCurrentAsset()
        model.skipCurrentAsset()
        let deleter = FakePhotoDeleter()

        let deletedIds = try await model.confirmPreDeleteBasket(deleter: deleter)

        XCTAssertEqual(deletedIds, [firstId])
        XCTAssertEqual(deleter.requestedAssetIds, [firstId])
        XCTAssertEqual(model.deletionQueueCount, 0)
    }

    func testConfirmPreDeleteBasketPersistsClearedBasketAfterSuccessfulDeletion() async throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        let model = PickoAppModel(
            store: ReviewStateStore(assets: [
                makeAsset(id: "delete-1", fileSizeBytes: 10)
            ]),
            decisionStore: decisionStore
        )
        model.preDeleteCurrentAsset()
        XCTAssertEqual(try decisionStore.basketItems().map(\.assetId), ["delete-1"])

        _ = try await model.confirmPreDeleteBasket(deleter: FakePhotoDeleter())

        XCTAssertEqual(model.deletionQueueCount, 0)
        XCTAssertEqual(try decisionStore.basketItems().map(\.assetId), [])
        XCTAssertNotEqual(try decisionStore.status(for: "delete-1"), .preDeleted)
    }

    func testConfirmPreDeleteBasketKeepsQueuedStateWhenDeletionFails() async throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        let model = PickoAppModel(
            store: ReviewStateStore(assets: [
                makeAsset(id: "delete-failure", fileSizeBytes: 10)
            ]),
            decisionStore: decisionStore
        )
        model.preDeleteCurrentAsset()

        do {
            _ = try await model.confirmPreDeleteBasket(deleter: FakePhotoDeleter(error: DeletionError.requestFailed))
            XCTFail("Expected deletion failure")
        } catch DeletionError.requestFailed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(model.deletionQueueCount, 1)
        XCTAssertEqual(try decisionStore.basketItems().map(\.assetId), ["delete-failure"])
        XCTAssertEqual(try decisionStore.status(for: "delete-failure"), .preDeleted)
    }

    private func makeAsset(id: String, fileSizeBytes: Int64 = 10) -> PhotoAsset {
        PhotoAsset(
            id: id,
            mediaType: .photo,
            creationDate: Date(timeIntervalSince1970: 0),
            location: nil,
            pixelWidth: 1,
            pixelHeight: 1,
            fileSizeBytes: fileSizeBytes,
            isFavorite: false,
            isEdited: false,
            isScreenshot: false,
            duration: nil,
            thumbnailHash: nil,
            perceptualHash: nil
        )
    }

    private func normalizedMargins(
        for annotations: [PlaceMapPresentation.Annotation],
        in region: MKCoordinateRegion
    ) -> (horizontal: Double, vertical: Double) {
        let minLatitude = annotations.map(\.latitude).min() ?? region.center.latitude
        let maxLatitude = annotations.map(\.latitude).max() ?? region.center.latitude
        let minLongitude = annotations.map(\.longitude).min() ?? region.center.longitude
        let maxLongitude = annotations.map(\.longitude).max() ?? region.center.longitude
        let latitudeRange = max(maxLatitude - minLatitude, 0)
        let longitudeRange = max(maxLongitude - minLongitude, 0)
        let verticalMargin = (region.span.latitudeDelta - latitudeRange) / (region.span.latitudeDelta * 2)
        let horizontalMargin = (region.span.longitudeDelta - longitudeRange) / (region.span.longitudeDelta * 2)

        return (horizontal: horizontalMargin, vertical: verticalMargin)
    }

    private func makePlaceGroup(
        id: String,
        title: String,
        latitude: Double,
        longitude: Double,
        assetIds: [PhotoAsset.ID]
    ) -> PhotoCollectionGroup {
        PhotoCollectionGroup(
            id: id,
            kind: .place,
            title: title,
            subtitle: "\(assetIds.count) 张 · 0 组相似",
            assetIds: assetIds,
            previewAssetIds: assetIds,
            similarGroupCount: 0,
            sortDate: Date(timeIntervalSince1970: 0),
            representativeLocation: .init(latitude: latitude, longitude: longitude)
        )
    }

    private func makeSnapshot(
        id: String,
        thumbnailHash: String? = nil,
        perceptualHash: String? = nil
    ) -> PhotoAssetSnapshot {
        PhotoAssetSnapshot(
            localIdentifier: id,
            mediaType: .image,
            creationDate: Date(timeIntervalSince1970: 0),
            latitude: nil,
            longitude: nil,
            pixelWidth: 1,
            pixelHeight: 1,
            fileSizeBytes: 10,
            isFavorite: false,
            isEdited: false,
            isScreenshot: false,
            duration: nil,
            thumbnailHash: thumbnailHash,
            perceptualHash: perceptualHash
        )
    }
}

private struct FakePhotoAssetIndexer: PhotoAssetIndexing {
    var snapshots: [PhotoAssetSnapshot]

    func fetchAssetSnapshots() async throws -> [PhotoAssetSnapshot] {
        snapshots
    }
}

private final class FakePhotoLibraryAuthorizer: PhotoLibraryAuthorizing {
    private let statusValue: PhotoLibraryAuthorizationStatus
    private let requestedStatus: PhotoLibraryAuthorizationStatus
    private(set) var requestCount = 0

    init(
        status: PhotoLibraryAuthorizationStatus,
        requestedStatus: PhotoLibraryAuthorizationStatus = .authorized
    ) {
        self.statusValue = status
        self.requestedStatus = requestedStatus
    }

    func authorizationStatus() -> PhotoLibraryAuthorizationStatus {
        statusValue
    }

    func requestAuthorization() async -> PhotoLibraryAuthorizationStatus {
        requestCount += 1
        return requestedStatus
    }
}

private final class FakePhotoDeleter: PhotoDeleting {
    var error: Error?
    private(set) var requestedAssetIds: [String] = []

    init(error: Error? = nil) {
        self.error = error
    }

    func requestDeletion(assetIds: [String]) async throws {
        if let error {
            throw error
        }
        requestedAssetIds = assetIds
    }
}

private final class FakeThumbnailProvider: PhotoThumbnailProviding {
    func thumbnailData(for request: PhotoThumbnailRequest) async throws -> Data? {
        Data([1])
    }
}

private struct FakePlaceLabelResolver: PlaceLabelResolving {
    var labels: [String: String]

    func label(for location: PhotoAsset.Location) async -> String? {
        labels[String(format: "%.4f,%.4f", location.latitude, location.longitude)]
    }
}

private enum DeletionError: Error {
    case requestFailed
}
