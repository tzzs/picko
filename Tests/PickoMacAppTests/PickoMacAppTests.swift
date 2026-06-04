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

    private func makeAsset(id: String) -> PhotoAsset {
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
            perceptualHash: nil
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
