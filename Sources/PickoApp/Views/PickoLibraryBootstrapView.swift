import PickoPhotos
import SwiftUI

public struct PickoLibraryBootstrapView: View {
    @State private var phase: Phase = .loading
    private let makeBootstrapper: () throws -> PhotoLibraryBootstrapper

    public init(
        makeBootstrapper: @escaping () throws -> PhotoLibraryBootstrapper = {
            let adapter = PhotosLibraryAdapter()
            return PhotoLibraryBootstrapper(
                authorizer: adapter,
                indexer: adapter,
                deleter: adapter,
                thumbnailProvider: MemoryCachingPhotoThumbnailProvider(source: adapter),
                decisionStore: try ReviewDecisionStore.persistent()
            )
        }
    ) {
        self.makeBootstrapper = makeBootstrapper
    }

    public var body: some View {
        Group {
            switch phase {
            case .loading:
                VStack(spacing: 16) {
                    OnboardingView()
                    ProgressView()
                }
            case .loaded(let model):
                PickoRootView(model: model)
            case .failed:
                VStack(spacing: 16) {
                    OnboardingView()
                    Text("Photo library access is needed to review your library.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Review Sample Library") {
                        phase = .loaded(.preview())
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task {
            await load()
        }
    }

    @MainActor
    private func load() async {
        do {
            let bootstrapper = try makeBootstrapper()
            phase = .loaded(try await bootstrapper.loadModel())
        } catch {
            phase = .failed
        }
    }
}

private enum Phase {
    case loading
    case loaded(PickoAppModel)
    case failed
}

#Preview {
    PickoLibraryBootstrapView(
        makeBootstrapper: {
            PhotoLibraryBootstrapper(
                authorizer: PreviewPhotoLibraryAuthorizer(),
                indexer: PreviewPhotoAssetIndexer(),
                deleter: nil,
                thumbnailProvider: nil,
                decisionStore: nil
            )
        }
    )
}

private struct PreviewPhotoLibraryAuthorizer: PhotoLibraryAuthorizing {
    func authorizationStatus() -> PhotoLibraryAuthorizationStatus {
        .authorized
    }

    func requestAuthorization() async -> PhotoLibraryAuthorizationStatus {
        .authorized
    }
}

private struct PreviewPhotoAssetIndexer: PhotoAssetIndexing {
    func fetchAssetSnapshots() async throws -> [PhotoAssetSnapshot] {
        PickoPreviewFixtures.assets.map { asset in
            PhotoAssetSnapshot(
                localIdentifier: asset.id,
                mediaType: .image,
                creationDate: asset.creationDate,
                latitude: asset.location?.latitude,
                longitude: asset.location?.longitude,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                fileSizeBytes: asset.fileSizeBytes,
                isFavorite: asset.isFavorite,
                isEdited: asset.isEdited,
                isScreenshot: asset.isScreenshot,
                duration: asset.duration,
                thumbnailHash: asset.thumbnailHash,
                perceptualHash: asset.perceptualHash
            )
        }
    }
}
