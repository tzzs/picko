import Foundation
import PickoPhotos

public struct MetadataBenchmarkSummary: Equatable {
    public var mode: String
    public var results: [AssetIndexingBenchmarkResult]

    public init(mode: String, results: [AssetIndexingBenchmarkResult]) {
        self.mode = mode
        self.results = results
    }

    public var text: String {
        let rows = results.map { result in
            "\(result.assetCount): \(format(result.elapsedSeconds))s, \(format(result.assetsPerSecond)) assets/s"
        }

        return "Mode: \(mode); " + rows.joined(separator: "; ")
    }

    public func rowText(for result: AssetIndexingBenchmarkResult) -> String {
        "\(result.assetCount) assets | \(format(result.elapsedSeconds)) seconds | \(format(result.assetsPerSecond)) assets/second"
    }

    private func format(_ value: Double) -> String {
        String(format: "%.4f", value)
    }
}
