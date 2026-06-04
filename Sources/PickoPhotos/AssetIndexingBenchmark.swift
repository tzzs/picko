#if canImport(Photos)
import Foundation

public struct AssetIndexingBenchmarkResult: Equatable {
    public var assetCount: Int
    public var elapsedSeconds: TimeInterval
    public var assetsPerSecond: Double {
        guard elapsedSeconds > 0 else {
            return 0
        }

        return Double(assetCount) / elapsedSeconds
    }

    public init(assetCount: Int, elapsedSeconds: TimeInterval) {
        self.assetCount = assetCount
        self.elapsedSeconds = elapsedSeconds
    }
}

public struct AssetIndexingBenchmarkReport: Codable, Equatable {
    public struct Row: Codable, Equatable {
        public var assetCount: Int
        public var elapsedSeconds: Double
        public var assetsPerSecond: Double

        public init(result: AssetIndexingBenchmarkResult) {
            assetCount = result.assetCount
            elapsedSeconds = result.elapsedSeconds
            assetsPerSecond = result.assetsPerSecond
        }
    }

    public var mode: String
    public var rows: [Row]

    public init(mode: String, results: [AssetIndexingBenchmarkResult]) {
        self.mode = mode
        rows = results.map(Row.init)
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

public struct AssetIndexingBenchmark {
    private let indexer: any PhotoAssetIndexing
    private let dateProvider: () -> Date

    public init(
        indexer: any PhotoAssetIndexing,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.indexer = indexer
        self.dateProvider = dateProvider
    }

    public func measure() async throws -> AssetIndexingBenchmarkResult {
        let start = dateProvider()
        let snapshots = try await indexer.fetchAssetSnapshots()
        let elapsed = dateProvider().timeIntervalSince(start)

        return AssetIndexingBenchmarkResult(
            assetCount: snapshots.count,
            elapsedSeconds: max(0, elapsed)
        )
    }
}

public struct AssetIndexingBenchmarkRunner {
    public init() {}

    public func runSynthetic(assetCounts: [Int]) async throws -> [AssetIndexingBenchmarkResult] {
        try await run(assetCounts: assetCounts) { assetCount in
            SyntheticPhotoAssetIndexer(assetCount: assetCount)
        }
    }

    public func runPhotos(assetCounts: [Int]) async throws -> [AssetIndexingBenchmarkResult] {
        try await run(assetCounts: assetCounts) { assetCount in
            PhotosLibraryAdapter(fetchLimit: assetCount)
        }
    }

    private func run(
        assetCounts: [Int],
        makeIndexer: (Int) -> any PhotoAssetIndexing
    ) async throws -> [AssetIndexingBenchmarkResult] {
        var results: [AssetIndexingBenchmarkResult] = []
        results.reserveCapacity(assetCounts.count)

        for assetCount in assetCounts where assetCount > 0 {
            let benchmark = AssetIndexingBenchmark(indexer: makeIndexer(assetCount))
            results.append(try await benchmark.measure())
        }

        return results
    }
}
#endif
