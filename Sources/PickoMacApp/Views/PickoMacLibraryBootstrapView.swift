import PickoApp
import PickoPhotos
import SwiftUI

public struct PickoMacLibraryBootstrapView: View {
    @State private var phase: Phase = .loading
    private let makeBootstrapper: () throws -> PhotoLibraryBootstrapper
    private let onModelLoaded: ((PickoMacWorkbenchModel) -> Void)?

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
        },
        onModelLoaded: ((PickoMacWorkbenchModel) -> Void)? = nil
    ) {
        self.makeBootstrapper = makeBootstrapper
        self.onModelLoaded = onModelLoaded
    }

    public var body: some View {
        Group {
            switch phase {
            case .loading:
                VStack(spacing: PickoMacDesign.Spacing.md) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(PickoMacDesign.ColorToken.primary)

                    VStack(spacing: 6) {
                        Text("Loading photo library...")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(PickoMacDesign.ColorToken.primary)
                        Text("Picko is preparing a local review workspace.")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)
                    }
                }
                    .frame(minWidth: 640, minHeight: 420)
                    .background(PickoMacDesign.ColorToken.background)
            case .loaded(let model):
                PickoMacRootView(model: model)
            case .failed:
                VStack(spacing: PickoMacDesign.Spacing.md) {
                    PickoMacEmptyStateView(
                        title: "Photo library access is needed to review your library.",
                        message: "Use the sample library to inspect Picko's review workflow without changing Photos.",
                        systemImage: "photo.on.rectangle.angled"
                    )

                    Button("Review Sample Library") {
                        phase = .loaded(.preview())
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(minWidth: 640, minHeight: 420)
                .background(PickoMacDesign.ColorToken.background)
            }
        }
        .tint(PickoMacDesign.ColorToken.primary)
        .task {
            await load()
        }
    }

    @MainActor
    private func load() async {
        do {
            let bootstrapper = try makeBootstrapper()
            let appModel = try await bootstrapper.loadModel()
            let model = PickoMacWorkbenchModel(appModel: appModel)
            onModelLoaded?(model)
            phase = .loaded(model)
        } catch {
            phase = .failed
        }
    }
}

private enum Phase {
    case loading
    case loaded(PickoMacWorkbenchModel)
    case failed
}

#Preview {
    PickoMacLibraryBootstrapView(
        makeBootstrapper: {
            PhotoLibraryBootstrapper(
                authorizer: PreviewPhotoLibraryAuthorizer(),
                indexer: PreviewPhotoAssetIndexer(),
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
