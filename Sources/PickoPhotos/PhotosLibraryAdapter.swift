#if canImport(Photos)
import CoreGraphics
import Foundation
import Photos
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public protocol PhotoAssetIndexing {
    func fetchAssetSnapshots() async throws -> [PhotoAssetSnapshot]
}

public protocol PhotoDeleting {
    func requestDeletion(assetIds: [String]) async throws
}

public final class PhotosLibraryAdapter: PhotoLibraryAuthorizing, PhotoAssetIndexing, PhotoDeleting, PhotoThumbnailProviding {
    private let mapper = PHAssetSnapshotMapper()
    private let fetchLimit: Int?

    public init(fetchLimit: Int? = nil) {
        self.fetchLimit = fetchLimit
    }

    public func authorizationStatus() -> PhotoLibraryAuthorizationStatus {
        PhotoLibraryAuthorizationStatus(platformStatus: PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    public func requestAuthorization() async -> PhotoLibraryAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: PhotoLibraryAuthorizationStatus(platformStatus: status))
            }
        }
    }

    public func fetchAssetSnapshots() async throws -> [PhotoAssetSnapshot] {
        let fetchResult = PHAsset.fetchAssets(with: nil)
        var snapshots: [PhotoAssetSnapshot] = []
        snapshots.reserveCapacity(fetchResult.count)
        let limit = fetchLimit

        fetchResult.enumerateObjects { asset, _, stop in
            if let limit, snapshots.count >= limit {
                stop.pointee = true
                return
            }

            snapshots.append(self.mapper.snapshot(from: asset))
        }

        return snapshots
    }

    public func requestDeletion(assetIds: [String]) async throws {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(fetchResult)
        }
    }

    public func thumbnailData(for request: PhotoThumbnailRequest) async throws -> Data? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [request.assetId], options: nil)
        guard let asset = fetchResult.firstObject else {
            return nil
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false

        let targetSize = CGSize(
            width: max(1, request.targetPixelWidth),
            height: max(1, request.targetPixelHeight)
        )

        return await withCheckedContinuation { continuation in
            var didResume = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if didResume {
                    return
                }

                if let isCancelled = info?[PHImageCancelledKey] as? Bool, isCancelled {
                    didResume = true
                    continuation.resume(returning: nil)
                    return
                }

                if info?[PHImageErrorKey] is Error {
                    didResume = true
                    continuation.resume(returning: nil)
                    return
                }

                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    return
                }

                didResume = true
                continuation.resume(returning: image.flatMap(Self.data(from:)))
            }
        }
    }

    #if canImport(UIKit)
    private static func data(from image: UIImage) -> Data? {
        image.jpegData(compressionQuality: 0.82) ?? image.pngData()
    }
    #elseif canImport(AppKit)
    private static func data(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) ??
            bitmap.representation(using: .png, properties: [:])
    }
    #endif
}

private struct PHAssetSnapshotMapper {
    func snapshot(from asset: PHAsset) -> PhotoAssetSnapshot {
        PhotoAssetSnapshot(
            localIdentifier: asset.localIdentifier,
            mediaType: mediaType(from: asset),
            creationDate: asset.creationDate ?? Date(timeIntervalSince1970: 0),
            latitude: asset.location?.coordinate.latitude,
            longitude: asset.location?.coordinate.longitude,
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            fileSizeBytes: estimatedFileSizeBytes(for: asset),
            isFavorite: asset.isFavorite,
            isEdited: asset.hasAdjustments,
            isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot),
            duration: asset.mediaType == .video ? asset.duration : nil,
            thumbnailHash: nil,
            perceptualHash: nil
        )
    }

    private func mediaType(from asset: PHAsset) -> PhotoAssetSnapshot.MediaType {
        if asset.mediaSubtypes.contains(.photoScreenshot) {
            return .screenshot
        }

        if asset.mediaSubtypes.contains(.photoLive) {
            return .livePhoto
        }

        switch asset.mediaType {
        case .image:
            return .image
        case .video:
            return .video
        default:
            return .image
        }
    }

    private func estimatedFileSizeBytes(for asset: PHAsset) -> Int64 {
        PHAssetResource.assetResources(for: asset).reduce(Int64(0)) { total, resource in
            let fileSize = resource.value(forKey: "fileSize") as? CLongLong
            return total + Int64(fileSize ?? 0)
        }
    }
}
#endif
