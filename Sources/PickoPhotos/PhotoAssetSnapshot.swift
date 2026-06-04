import Foundation

public struct PhotoAssetSnapshot: Equatable {
    public enum MediaType: Equatable {
        case image
        case video
        case livePhoto
        case screenshot
    }

    public var localIdentifier: String
    public var mediaType: MediaType
    public var creationDate: Date
    public var latitude: Double?
    public var longitude: Double?
    public var pixelWidth: Int
    public var pixelHeight: Int
    public var fileSizeBytes: Int64
    public var isFavorite: Bool
    public var isEdited: Bool
    public var isScreenshot: Bool
    public var duration: TimeInterval?
    public var thumbnailHash: String?
    public var perceptualHash: String?

    public init(
        localIdentifier: String,
        mediaType: MediaType,
        creationDate: Date,
        latitude: Double?,
        longitude: Double?,
        pixelWidth: Int,
        pixelHeight: Int,
        fileSizeBytes: Int64,
        isFavorite: Bool,
        isEdited: Bool,
        isScreenshot: Bool,
        duration: TimeInterval?,
        thumbnailHash: String?,
        perceptualHash: String?
    ) {
        self.localIdentifier = localIdentifier
        self.mediaType = mediaType
        self.creationDate = creationDate
        self.latitude = latitude
        self.longitude = longitude
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.fileSizeBytes = fileSizeBytes
        self.isFavorite = isFavorite
        self.isEdited = isEdited
        self.isScreenshot = isScreenshot
        self.duration = duration
        self.thumbnailHash = thumbnailHash
        self.perceptualHash = perceptualHash
    }
}
