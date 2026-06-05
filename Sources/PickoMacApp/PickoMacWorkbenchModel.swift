import Foundation
import Observation
import PickoApp
import PickoCore
import PickoPhotos

@Observable
public final class PickoMacWorkbenchModel {
    public struct SidebarRow: Equatable, Identifiable {
        public var selection: SidebarSelection
        public var title: String
        public var detail: String
        public var systemImage: String

        public var id: SidebarSelection { selection }
    }

    public struct AssetPresentation: Equatable {
        public var statusLabel: String
        public var statusSystemImage: String
        public var metadataSummary: String
    }

    public struct SimilarGroupPresentation: Equatable {
        public var title: String
        public var summary: String
        public var recommendation: String
        public var context: String
        public var statusLabel: String
    }

    public struct InspectorPresentation: Equatable {
        public var assetId: String
        public var mediaTypeLabel: String
        public var dimensionsLabel: String
        public var fileSizeLabel: String
        public var statusLabel: String
        public var recommendationLabel: String
        public var shortcutHints: [ShortcutHint]
    }

    public struct ShortcutHint: Equatable, Identifiable {
        public var key: String
        public var title: String

        public var id: String { "\(key)-\(title)" }
        public var label: String { "\(key) \(title)" }
    }

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

    public var sidebarRows: [SidebarRow] {
        SidebarSelection.allCases.map { selection in
            SidebarRow(
                selection: selection,
                title: selection.title,
                detail: sidebarDetail(for: selection),
                systemImage: selection.systemImage
            )
        }
    }

    public var inspectorPresentation: InspectorPresentation? {
        guard let asset = selectedAsset else {
            return nil
        }

        return InspectorPresentation(
            assetId: asset.id,
            mediaTypeLabel: mediaTypeText(asset.mediaType),
            dimensionsLabel: "\(asset.pixelWidth)x\(asset.pixelHeight)",
            fileSizeLabel: byteCount(asset.fileSizeBytes),
            statusLabel: assetPresentation(for: asset).statusLabel,
            recommendationLabel: recommendationLabel(for: asset),
            shortcutHints: [
                ShortcutHint(key: "K", title: "Keep"),
                ShortcutHint(key: "D", title: "Review Later"),
                ShortcutHint(key: "Space", title: "Preview"),
                ShortcutHint(key: "Z", title: "Undo")
            ]
        )
    }

    public func assetPresentation(for asset: PhotoAsset) -> AssetPresentation {
        AssetPresentation(
            statusLabel: statusText(asset.status),
            statusSystemImage: statusSystemImage(asset.status),
            metadataSummary: "\(mediaTypeText(asset.mediaType)) · \(byteCount(asset.fileSizeBytes))"
        )
    }

    public func similarGroupPresentation(for group: SimilarGroup) -> SimilarGroupPresentation {
        SimilarGroupPresentation(
            title: group.id,
            summary: "\(group.assetIds.count) similar items · keep \(group.keepCount)",
            recommendation: recommendationText(for: group),
            context: similarGroupContext(for: group),
            statusLabel: similarGroupStatusText(group.status)
        )
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

    private func sidebarDetail(for selection: SidebarSelection) -> String {
        switch selection {
        case .home:
            return "\(assets.count) assets · \(deletionQueueCount) waiting"
        case .similar:
            let keepTotal = groups.reduce(0) { $0 + $1.keepCount }
            return "\(groups.count) group\(groups.count == 1 ? "" : "s") · keep \(keepTotal)"
        case .time:
            return "Timeline review"
        case .location:
            return "Places and trips"
        case .basket:
            return "\(deletionQueueCount) item\(deletionQueueCount == 1 ? "" : "s") · \(byteCount(estimatedPreDeleteBytes))"
        }
    }

    private func recommendationLabel(for asset: PhotoAsset) -> String {
        guard let group = groups.first(where: { $0.recommendedKeepIds.contains(asset.id) }) else {
            return "No recommendation yet"
        }

        return "Suggested keep in \(group.id)"
    }

    private func recommendationText(for group: SimilarGroup) -> String {
        guard !group.recommendedKeepIds.isEmpty else {
            return "No suggested keep yet"
        }

        return "Suggested keep: \(group.recommendedKeepIds.joined(separator: ", "))"
    }

    private func similarGroupContext(for group: SimilarGroup) -> String {
        var parts: [String] = []
        if let locationSummary = group.locationSummary {
            parts.append(locationSummary)
        }
        parts.append("\(Int((group.confidenceScore * 100).rounded()))% confidence")
        return parts.joined(separator: " · ")
    }

    private func statusText(_ status: PhotoAsset.ReviewStatus) -> String {
        switch status {
        case .unreviewed:
            return "Unreviewed"
        case .kept:
            return "Kept"
        case .preDeleted:
            return "In basket"
        case .skipped:
            return "Skipped"
        }
    }

    private func statusSystemImage(_ status: PhotoAsset.ReviewStatus) -> String {
        switch status {
        case .unreviewed:
            return "circle"
        case .kept:
            return "checkmark.circle.fill"
        case .preDeleted:
            return "tray.fill"
        case .skipped:
            return "forward.circle.fill"
        }
    }

    private func similarGroupStatusText(_ status: SimilarGroup.ReviewStatus) -> String {
        switch status {
        case .unreviewed:
            return "Needs review"
        case .reviewed:
            return "Reviewed"
        case .skipped:
            return "Skipped"
        }
    }

    private func mediaTypeText(_ mediaType: PhotoAsset.MediaType) -> String {
        switch mediaType {
        case .photo:
            return "Photo"
        case .video:
            return "Video"
        case .livePhoto:
            return "Live Photo"
        case .screenshot:
            return "Screenshot"
        }
    }

    private func byteCount(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
            .replacingOccurrences(of: "\u{2006}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
    }
}
