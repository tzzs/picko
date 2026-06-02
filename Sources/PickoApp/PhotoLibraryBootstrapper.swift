import Foundation
import PickoPhotos

public enum PhotoLibraryBootstrapError: Error, Equatable {
    case accessUnavailable(PhotoLibraryAuthorizationStatus)
}

public final class PhotoLibraryBootstrapper {
    private let authorizer: any PhotoLibraryAuthorizing
    private let indexer: any PhotoAssetIndexing
    private let deleter: (any PhotoDeleting)?
    private let thumbnailProvider: (any PhotoThumbnailProviding)?
    private let decisionStore: ReviewDecisionStore?

    public init(
        authorizer: any PhotoLibraryAuthorizing,
        indexer: any PhotoAssetIndexing,
        deleter: (any PhotoDeleting)? = nil,
        thumbnailProvider: (any PhotoThumbnailProviding)? = nil,
        decisionStore: ReviewDecisionStore?
    ) {
        self.authorizer = authorizer
        self.indexer = indexer
        self.deleter = deleter
        self.thumbnailProvider = thumbnailProvider
        self.decisionStore = decisionStore
    }

    public func loadModel() async throws -> PickoAppModel {
        let status = await resolvedAuthorizationStatus()

        guard status.allowsLibraryRead else {
            throw PhotoLibraryBootstrapError.accessUnavailable(status)
        }

        return try await PickoAppModel.loadingFromPhotoLibrary(
            indexer: indexer,
            decisionStore: decisionStore,
            photoDeleter: deleter,
            thumbnailProvider: thumbnailProvider
        )
    }

    private func resolvedAuthorizationStatus() async -> PhotoLibraryAuthorizationStatus {
        let currentStatus = authorizer.authorizationStatus()

        if currentStatus == .notDetermined {
            return await authorizer.requestAuthorization()
        }

        return currentStatus
    }
}

private extension PhotoLibraryAuthorizationStatus {
    var allowsLibraryRead: Bool {
        switch self {
        case .authorized, .limited:
            return true
        case .notDetermined, .restricted, .denied:
            return false
        }
    }
}
