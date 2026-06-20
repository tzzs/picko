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
                ScrollView {
                    VStack(spacing: PickoDesign.Spacing.lg) {
                        OnboardingView()
                        HStack(spacing: PickoDesign.Spacing.gutter) {
                            ProgressView()
                                .tint(PickoDesign.ColorToken.primary)
                            Text("正在准备本地相册索引")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                        }
                        .padding(PickoDesign.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                        .overlay {
                            RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                                .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
                        }
                        .padding(.horizontal, PickoDesign.Spacing.page)
                        .padding(.bottom, PickoDesign.Spacing.lg)
                    }
                }
                .pickoScreenBackground()
            case .loaded(let model):
                PickoRootView(model: model)
            case .failed:
                ScrollView {
                    VStack(spacing: PickoDesign.Spacing.lg) {
                        OnboardingView()

                        VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                            HStack(alignment: .top, spacing: PickoDesign.Spacing.gutter) {
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(PickoDesign.ColorToken.gold)
                                Text(PickoCopy.LibraryAccess.deniedTitle)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(PickoDesign.ColorToken.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Text(PickoCopy.LibraryAccess.deniedMessage)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(PickoDesign.ColorToken.secondaryInk)

                            Button(PickoCopy.LibraryAccess.sampleLibrary) {
                                phase = .loaded(.preview())
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(PickoDesign.ColorToken.primary, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                            .foregroundStyle(PickoDesign.ColorToken.primarySoft)
                            .buttonStyle(.plain)
                        }
                        .padding(PickoDesign.Spacing.page)
                        .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                        .overlay {
                            RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                                .stroke(PickoDesign.ColorToken.outline.opacity(0.5), lineWidth: 1)
                        }
                        .padding(.horizontal, PickoDesign.Spacing.page)
                        .padding(.bottom, PickoDesign.Spacing.lg)
                    }
                }
                .pickoScreenBackground()
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
