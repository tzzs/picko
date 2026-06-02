import Foundation

public struct PhotoAsset: Equatable, Identifiable {
    public enum MediaType: Equatable {
        case photo
        case video
        case livePhoto
        case screenshot
    }

    public enum ReviewStatus: Equatable {
        case unreviewed
        case kept
        case preDeleted
        case skipped
    }

    public struct Location: Equatable {
        public var latitude: Double
        public var longitude: Double

        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }

    public var id: String
    public var mediaType: MediaType
    public var creationDate: Date
    public var location: Location?
    public var pixelWidth: Int
    public var pixelHeight: Int
    public var fileSizeBytes: Int64
    public var isFavorite: Bool
    public var isEdited: Bool
    public var isScreenshot: Bool
    public var duration: TimeInterval?
    public var thumbnailHash: String?
    public var perceptualHash: String?
    public var status: ReviewStatus

    public init(
        id: String,
        mediaType: MediaType,
        creationDate: Date,
        location: Location?,
        pixelWidth: Int,
        pixelHeight: Int,
        fileSizeBytes: Int64,
        isFavorite: Bool,
        isEdited: Bool,
        isScreenshot: Bool,
        duration: TimeInterval?,
        thumbnailHash: String?,
        perceptualHash: String?,
        status: ReviewStatus = .unreviewed
    ) {
        self.id = id
        self.mediaType = mediaType
        self.creationDate = creationDate
        self.location = location
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.fileSizeBytes = fileSizeBytes
        self.isFavorite = isFavorite
        self.isEdited = isEdited
        self.isScreenshot = isScreenshot
        self.duration = duration
        self.thumbnailHash = thumbnailHash
        self.perceptualHash = perceptualHash
        self.status = status
    }
}

public struct ReviewSession: Equatable, Identifiable {
    public enum Mode: Equatable {
        case single
        case similarGroup
        case timeRange
        case location
    }

    public var id: String
    public var mode: Mode
    public var startedAt: Date
    public var completedAt: Date?
    public var reviewedCount: Int
    public var keptCount: Int
    public var preDeletedCount: Int
    public var skippedCount: Int
    public var freedBytesEstimate: Int64

    public init(
        id: String,
        mode: Mode,
        startedAt: Date,
        completedAt: Date? = nil,
        reviewedCount: Int = 0,
        keptCount: Int = 0,
        preDeletedCount: Int = 0,
        skippedCount: Int = 0,
        freedBytesEstimate: Int64 = 0
    ) {
        self.id = id
        self.mode = mode
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.reviewedCount = reviewedCount
        self.keptCount = keptCount
        self.preDeletedCount = preDeletedCount
        self.skippedCount = skippedCount
        self.freedBytesEstimate = freedBytesEstimate
    }
}
