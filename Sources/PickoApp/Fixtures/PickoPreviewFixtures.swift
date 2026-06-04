import Foundation
import PickoCore

public enum PickoPreviewFixtures {
    public static let assets: [PhotoAsset] = [
        PhotoAsset(
            id: "preview-1",
            mediaType: .photo,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            location: .init(latitude: 31.2304, longitude: 121.4737),
            pixelWidth: 4032,
            pixelHeight: 3024,
            fileSizeBytes: 3_900_000,
            isFavorite: true,
            isEdited: false,
            isScreenshot: false,
            duration: nil,
            thumbnailHash: "trip-a",
            perceptualHash: "trip-a"
        ),
        PhotoAsset(
            id: "preview-2",
            mediaType: .photo,
            creationDate: Date(timeIntervalSince1970: 1_700_000_012),
            location: .init(latitude: 31.2305, longitude: 121.4738),
            pixelWidth: 4032,
            pixelHeight: 3024,
            fileSizeBytes: 3_600_000,
            isFavorite: false,
            isEdited: false,
            isScreenshot: false,
            duration: nil,
            thumbnailHash: "trip-a",
            perceptualHash: "trip-a"
        ),
        PhotoAsset(
            id: "preview-3",
            mediaType: .screenshot,
            creationDate: Date(timeIntervalSince1970: 1_700_086_400),
            location: nil,
            pixelWidth: 1290,
            pixelHeight: 2796,
            fileSizeBytes: 900_000,
            isFavorite: false,
            isEdited: false,
            isScreenshot: true,
            duration: nil,
            thumbnailHash: "screen",
            perceptualHash: "screen"
        )
    ]

    public static let groups: [SimilarGroup] = [
        SimilarGroup(
            id: "group-1",
            assetIds: ["preview-1", "preview-2"],
            groupType: .similar,
            timeRange: DateInterval(
                start: Date(timeIntervalSince1970: 1_700_000_000),
                end: Date(timeIntervalSince1970: 1_700_000_012)
            ),
            locationSummary: "Shanghai",
            recommendedKeepIds: ["preview-1"],
            keepCount: 1,
            confidenceScore: 0.8,
            status: .unreviewed
        )
    ]
}
