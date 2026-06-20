import PickoCore
import PickoPhotos
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct PickoThumbnailView: View {
    private let asset: PhotoAsset
    private let thumbnailProvider: (any PhotoThumbnailProviding)?
    private let targetPixelWidth: Int
    private let targetPixelHeight: Int
    private let contentMode: ContentMode
    private let loadedPlaceholderOpacity: Double
    @State private var thumbnailData: Data?

    public init(
        asset: PhotoAsset,
        thumbnailProvider: (any PhotoThumbnailProviding)?,
        targetPixelWidth: Int = 600,
        targetPixelHeight: Int = 450,
        contentMode: ContentMode = .fill,
        loadedPlaceholderOpacity: Double = 1
    ) {
        self.asset = asset
        self.thumbnailProvider = thumbnailProvider
        self.targetPixelWidth = targetPixelWidth
        self.targetPixelHeight = targetPixelHeight
        self.contentMode = contentMode
        self.loadedPlaceholderOpacity = loadedPlaceholderOpacity
    }

    public var body: some View {
        ZStack {
            placeholder
                .opacity(thumbnailData == nil ? 1 : loadedPlaceholderOpacity)

            if let image = platformImage(from: thumbnailData) {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
        .clipped()
        .task(id: asset.id) {
            await loadThumbnail()
        }
        .accessibilityLabel("照片预览")
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
            .fill(
                LinearGradient(
                    colors: asset.isScreenshot
                        ? [PickoDesign.ColorToken.primarySoft.opacity(0.72), PickoDesign.ColorToken.surfaceHigh]
                        : [PickoDesign.ColorToken.surfaceContainer, PickoDesign.ColorToken.primarySoft.opacity(0.62)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: iconName)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(PickoDesign.ColorToken.primary.opacity(0.58))
            }
    }

    private var iconName: String {
        switch asset.mediaType {
        case .photo, .livePhoto:
            return "photo"
        case .video:
            return "video"
        case .screenshot:
            return "iphone"
        }
    }

    @MainActor
    private func loadThumbnail() async {
        guard let thumbnailProvider else {
            thumbnailData = nil
            return
        }

        let request = PhotoThumbnailRequest(
            assetId: asset.id,
            targetPixelWidth: targetPixelWidth,
            targetPixelHeight: targetPixelHeight
        )
        thumbnailData = try? await thumbnailProvider.thumbnailData(for: request)
    }

    private func platformImage(from data: Data?) -> Image? {
        guard let data else {
            return nil
        }

        #if canImport(UIKit)
        guard let image = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else {
            return nil
        }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }
}
