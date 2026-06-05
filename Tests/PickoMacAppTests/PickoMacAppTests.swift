import XCTest
import PickoApp
import PickoCore
import PickoPhotos
@testable import PickoMacApp

final class PickoMacAppTests: XCTestCase {
    func testSelectingAssetUpdatesInspectorSelection() {
        let model = PickoMacWorkbenchModel.preview()

        model.selectAsset(id: "preview-2")

        XCTAssertEqual(model.selectedAsset?.id, "preview-2")
    }

    func testMacRootViewCanBeConstructed() {
        let view = PickoMacRootView(model: .preview())

        XCTAssertNotNil(view)
    }

    func testMacBootstrapViewCanBeConstructed() {
        let view = PickoMacLibraryBootstrapView()

        XCTAssertNotNil(view)
    }

    func testMacDeniedBootstrapViewCanBeConstructed() {
        let view = PickoMacLibraryBootstrapView(
            makeBootstrapper: {
                PhotoLibraryBootstrapper(
                    authorizer: DeniedPhotoLibraryAuthorizer(),
                    indexer: EmptyPhotoAssetIndexer(),
                    decisionStore: nil
                )
            }
        )

        XCTAssertNotNil(view)
    }

    func testSelectedAssetActionsUseAppModelPersistence() throws {
        let decisionStore = try ReviewDecisionStore.inMemory()
        let appModel = PickoAppModel(
            store: ReviewStateStore(assets: [
                makeAsset(id: "a1"),
                makeAsset(id: "a2")
            ]),
            decisionStore: decisionStore
        )
        let model = PickoMacWorkbenchModel(appModel: appModel, selectedAssetId: "a2")

        model.preDeleteSelectedAsset()

        XCTAssertEqual(try decisionStore.status(for: "a2"), .preDeleted)
        XCTAssertEqual(try decisionStore.basketItems().map(\.assetId), ["a2"])
    }

    func testClearingLocalReviewStateKeepsMacSelectionUsable() {
        let appModel = PickoAppModel(
            store: ReviewStateStore(assets: [
                makeAsset(id: "a1"),
                makeAsset(id: "a2")
            ])
        )
        let model = PickoMacWorkbenchModel(appModel: appModel, selectedAssetId: "a2")
        model.preDeleteSelectedAsset()

        model.clearLocalReviewState()

        XCTAssertEqual(model.assets.map(\.status), [.unreviewed, .unreviewed])
        XCTAssertEqual(model.deletionQueueCount, 0)
        XCTAssertEqual(model.selectedAssetId, "a1")
        XCTAssertEqual(model.selectedAsset?.id, "a1")
    }

    func testMacBasketViewCanBeConstructed() {
        let model = PickoMacWorkbenchModel.preview()
        model.preDeleteSelectedAsset()

        let view = PickoMacBasketView(model: model)

        XCTAssertNotNil(view)
    }

    func testMacBasketViewCanBeConstructedWithThumbnailProvider() {
        let appModel = PickoAppModel.preview()
        appModel.thumbnailProvider = FakeThumbnailProvider()
        let model = PickoMacWorkbenchModel(appModel: appModel)
        model.preDeleteSelectedAsset()

        let view = PickoMacBasketView(model: model)

        XCTAssertNotNil(view)
    }

    func testMacSimilarGroupsViewCanBeConstructedWithThumbnailProvider() {
        let appModel = PickoAppModel.preview()
        appModel.thumbnailProvider = FakeThumbnailProvider()
        let model = PickoMacWorkbenchModel(appModel: appModel)

        let view = PickoMacSimilarGroupsView(model: model)

        XCTAssertNotNil(view)
    }

    func testMacConfirmPreDeleteBasketUsesQueuedAssetIds() async throws {
        let appModel = PickoAppModel(
            store: ReviewStateStore(assets: [
                makeAsset(id: "a1"),
                makeAsset(id: "a2")
            ])
        )
        let model = PickoMacWorkbenchModel(appModel: appModel, selectedAssetId: "a2")
        let deleter = FakePhotoDeleter()
        model.preDeleteSelectedAsset()

        let deletedIds = try await model.confirmPreDeleteBasket(deleter: deleter)

        XCTAssertEqual(deletedIds, ["a2"])
        XCTAssertEqual(deleter.requestedAssetIds, ["a2"])
        XCTAssertEqual(model.deletionQueueCount, 0)
    }

    func testMacSidebarRowsSummarizeReviewTasks() {
        let model = PickoMacWorkbenchModel.preview()

        model.preDeleteSelectedAsset()

        let rows = model.sidebarRows

        XCTAssertEqual(rows.map(\.title), ["Review", "Similar", "Time", "Location", "Basket"])
        XCTAssertEqual(rows.first { $0.selection == .home }?.detail, "3 assets · 1 waiting")
        XCTAssertEqual(rows.first { $0.selection == .similar }?.detail, "1 group · keep 1")
        XCTAssertEqual(rows.first { $0.selection == .time }?.detail, "Timeline review")
        XCTAssertEqual(rows.first { $0.selection == .location }?.detail, "Places and trips")
        XCTAssertEqual(rows.first { $0.selection == .basket }?.detail, "1 item · 3.9 MB")
    }

    func testMacAssetPresentationExposesStatusLabels() {
        let model = PickoMacWorkbenchModel(
            appModel: PickoAppModel(
                store: ReviewStateStore(assets: [
                    makeAsset(id: "new", status: .unreviewed),
                    makeAsset(id: "kept", status: .kept),
                    makeAsset(id: "basket", status: .preDeleted),
                    makeAsset(id: "skipped", status: .skipped)
                ])
            )
        )

        XCTAssertEqual(model.assetPresentation(for: model.assets[0]).statusLabel, "Unreviewed")
        XCTAssertEqual(model.assetPresentation(for: model.assets[1]).statusLabel, "Kept")
        XCTAssertEqual(model.assetPresentation(for: model.assets[2]).statusLabel, "In basket")
        XCTAssertEqual(model.assetPresentation(for: model.assets[3]).statusLabel, "Skipped")
    }

    func testMacSimilarGroupPresentationExplainsRecommendation() {
        let model = PickoMacWorkbenchModel.preview()

        let presentation = model.similarGroupPresentation(for: model.groups[0])

        XCTAssertEqual(presentation.title, "group-1")
        XCTAssertEqual(presentation.summary, "2 similar items · keep 1")
        XCTAssertEqual(presentation.recommendation, "Suggested keep: preview-1")
        XCTAssertEqual(presentation.context, "Shanghai · 80% confidence")
    }

    func testMacInspectorPresentationIncludesDecisionCuesAndShortcuts() throws {
        let model = PickoMacWorkbenchModel.preview()
        model.selectAsset(id: "preview-1")

        let presentation = try XCTUnwrap(model.inspectorPresentation)

        XCTAssertEqual(presentation.statusLabel, "Unreviewed")
        XCTAssertEqual(presentation.recommendationLabel, "Suggested keep in group-1")
        XCTAssertEqual(presentation.shortcutHints.map(\.label), ["K Keep", "D Review Later", "Space Preview", "Z Undo"])
    }

    private func makeAsset(
        id: String,
        status: PhotoAsset.ReviewStatus = .unreviewed
    ) -> PhotoAsset {
        PhotoAsset(
            id: id,
            mediaType: .photo,
            creationDate: Date(timeIntervalSince1970: 0),
            location: nil,
            pixelWidth: 1,
            pixelHeight: 1,
            fileSizeBytes: 10,
            isFavorite: false,
            isEdited: false,
            isScreenshot: false,
            duration: nil,
            thumbnailHash: nil,
            perceptualHash: nil,
            status: status
        )
    }
}

private final class FakePhotoDeleter: PhotoDeleting {
    private(set) var requestedAssetIds: [String] = []

    func requestDeletion(assetIds: [String]) async throws {
        requestedAssetIds = assetIds
    }
}

private final class FakeThumbnailProvider: PhotoThumbnailProviding {
    func thumbnailData(for request: PhotoThumbnailRequest) async throws -> Data? {
        Data([1])
    }
}

private struct DeniedPhotoLibraryAuthorizer: PhotoLibraryAuthorizing {
    func authorizationStatus() -> PhotoLibraryAuthorizationStatus {
        .denied
    }

    func requestAuthorization() async -> PhotoLibraryAuthorizationStatus {
        .denied
    }
}

private struct EmptyPhotoAssetIndexer: PhotoAssetIndexing {
    func fetchAssetSnapshots() async throws -> [PhotoAssetSnapshot] {
        []
    }
}
