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
    private let lock = NSLock()
    private var cachedDataByRequest: [PhotoThumbnailRequest: Data]
    private var inFlightTasksByRequest: [PhotoThumbnailRequest: Task<Data?, Error>]

    public init(source: any PhotoThumbnailProviding) {
        self.source = source
        self.cachedDataByRequest = [:]
        self.inFlightTasksByRequest = [:]
    }

    public func thumbnailData(for request: PhotoThumbnailRequest) async throws -> Data? {
        if let cachedData = cachedData(for: request) {
            return cachedData
        }

        let task = inFlightTask(for: request)

        do {
            let data = try await task.value
            store(data, for: request)
            return data
        } catch {
            clearInFlightTask(for: request)
            throw error
        }
    }

    private func cachedData(for request: PhotoThumbnailRequest) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return cachedDataByRequest[request]
    }

    private func inFlightTask(for request: PhotoThumbnailRequest) -> Task<Data?, Error> {
        lock.lock()
        defer { lock.unlock() }

        if let task = inFlightTasksByRequest[request] {
            return task
        }

        let task = Task { [source] in
            try await source.thumbnailData(for: request)
        }
        inFlightTasksByRequest[request] = task
        return task
    }

    private func store(_ data: Data?, for request: PhotoThumbnailRequest) {
        lock.lock()
        defer { lock.unlock() }

        if let data {
            cachedDataByRequest[request] = data
        }
        inFlightTasksByRequest[request] = nil
    }

    private func clearInFlightTask(for request: PhotoThumbnailRequest) {
        lock.lock()
        defer { lock.unlock() }
        inFlightTasksByRequest[request] = nil
    }
}
#endif
