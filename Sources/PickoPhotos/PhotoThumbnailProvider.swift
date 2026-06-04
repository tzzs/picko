#if canImport(Photos)
import Foundation

public struct PhotoThumbnailRequest: Hashable, Sendable {
    public var assetId: String
    public var targetPixelWidth: Int
    public var targetPixelHeight: Int

    public init(assetId: String, targetPixelWidth: Int, targetPixelHeight: Int) {
        self.assetId = assetId
        self.targetPixelWidth = targetPixelWidth
        self.targetPixelHeight = targetPixelHeight
    }
}

public protocol PhotoThumbnailProviding: AnyObject {
    func thumbnailData(for request: PhotoThumbnailRequest) async throws -> Data?
}

public final class MemoryCachingPhotoThumbnailProvider: PhotoThumbnailProviding {
    private let source: any PhotoThumbnailProviding
    private var cachedDataByRequest: [PhotoThumbnailRequest: Data]

    public init(source: any PhotoThumbnailProviding) {
        self.source = source
        self.cachedDataByRequest = [:]
    }

    public func thumbnailData(for request: PhotoThumbnailRequest) async throws -> Data? {
        if let cachedData = cachedDataByRequest[request] {
            return cachedData
        }

        guard let data = try await source.thumbnailData(for: request) else {
            return nil
        }

        cachedDataByRequest[request] = data
        return data
    }
}
#endif
