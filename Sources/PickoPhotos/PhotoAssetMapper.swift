import PickoCore

public struct PhotoAssetMapper: Equatable {
    public init() {}

    public func asset(from snapshot: PhotoAssetSnapshot) -> PhotoAsset {
        PhotoAsset(
            id: snapshot.localIdentifier,
            mediaType: mediaType(from: snapshot),
            creationDate: snapshot.creationDate,
            location: location(from: snapshot),
            pixelWidth: snapshot.pixelWidth,
            pixelHeight: snapshot.pixelHeight,
            fileSizeBytes: snapshot.fileSizeBytes,
            isFavorite: snapshot.isFavorite,
            isEdited: snapshot.isEdited,
            isScreenshot: snapshot.isScreenshot,
            duration: snapshot.duration,
            thumbnailHash: snapshot.thumbnailHash,
            perceptualHash: snapshot.perceptualHash
        )
    }

    private func mediaType(from snapshot: PhotoAssetSnapshot) -> PhotoAsset.MediaType {
        if snapshot.isScreenshot {
            return .screenshot
        }

        switch snapshot.mediaType {
        case .image:
            return .photo
        case .video:
            return .video
        case .livePhoto:
            return .livePhoto
        case .screenshot:
            return .screenshot
        }
    }

    private func location(from snapshot: PhotoAssetSnapshot) -> PhotoAsset.Location? {
        guard let latitude = snapshot.latitude, let longitude = snapshot.longitude else {
            return nil
        }

        return PhotoAsset.Location(latitude: latitude, longitude: longitude)
    }
}
