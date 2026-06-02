import Observation
import PickoApp
import PickoCore
import PickoPhotos

@Observable
public final class PickoMacWorkbenchModel {
    public enum SidebarSelection: String, CaseIterable, Identifiable {
        case home
        case similar
        case time
        case location
        case basket

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .home:
                return "Review"
            case .similar:
                return "Similar"
            case .time:
                return "Time"
            case .location:
                return "Location"
            case .basket:
                return "Basket"
            }
        }

        public var systemImage: String {
            switch self {
            case .home:
                return "rectangle.grid.2x2"
            case .similar:
                return "square.grid.2x2"
            case .time:
                return "calendar"
            case .location:
                return "location"
            case .basket:
                return "tray"
            }
        }
    }

    public var appModel: PickoAppModel
    public var sidebarSelection: SidebarSelection
    public var selectedAssetId: PhotoAsset.ID?

    public init(
        appModel: PickoAppModel,
        sidebarSelection: SidebarSelection = .home,
        selectedAssetId: PhotoAsset.ID? = nil
    ) {
        self.appModel = appModel
        self.sidebarSelection = sidebarSelection
        self.selectedAssetId = selectedAssetId ?? appModel.assets.first?.id
    }

    public static func preview() -> PickoMacWorkbenchModel {
        PickoMacWorkbenchModel(appModel: .preview())
    }

    public var assets: [PhotoAsset] {
        appModel.assets
    }

    public var groups: [SimilarGroup] {
        appModel.groups
    }

    public var selectedAsset: PhotoAsset? {
        guard let selectedAssetId else {
            return nil
        }
        return assets.first { $0.id == selectedAssetId }
    }

    public var deletionQueueCount: Int {
        appModel.deletionQueueCount
    }

    public var estimatedPreDeleteBytes: Int64 {
        appModel.estimatedPreDeleteBytes
    }

    public var thumbnailProvider: (any PhotoThumbnailProviding)? {
        appModel.thumbnailProvider
    }

    public func selectAsset(id: PhotoAsset.ID) {
        selectedAssetId = id
    }

    public func keepSelectedAsset() {
        guard let selectedAssetId else {
            return
        }
        appModel.keep(assetId: selectedAssetId)
    }

    public func preDeleteSelectedAsset() {
        guard let selectedAssetId else {
            return
        }
        appModel.preDelete(assetId: selectedAssetId)
    }

    @discardableResult
    public func confirmPreDeleteBasket(deleter: any PhotoDeleting) async throws -> [PhotoAsset.ID] {
        try await appModel.confirmPreDeleteBasket(deleter: deleter)
    }

    @discardableResult
    public func confirmPreDeleteBasket() async throws -> [PhotoAsset.ID] {
        try await appModel.confirmPreDeleteBasket()
    }

    public func undo() {
        appModel.undo()
    }

    public func clearLocalReviewState() {
        appModel.clearLocalReviewState()
        selectedAssetId = assets.first?.id
    }

    public func previewSelectedAsset() {
        if selectedAssetId == nil {
            selectedAssetId = assets.first?.id
        }
    }
}
