import Foundation

public struct BenchmarkLaunchConfiguration: Equatable {
    public enum Mode: Equatable {
        case synthetic
        case photos
    }

    public var mode: Mode
    public var assetCounts: [Int]

    public init(mode: Mode, assetCounts: [Int] = [1_000, 10_000, 50_000]) {
        self.mode = mode
        self.assetCounts = assetCounts.filter { $0 > 0 }
        if self.assetCounts.isEmpty {
            self.assetCounts = [1_000, 10_000, 50_000]
        }
    }

    public static func parse(arguments: [String]) -> BenchmarkLaunchConfiguration? {
        guard arguments.contains("--picko-run-metadata-benchmark") else {
            return nil
        }

        let mode: Mode = arguments.contains("--picko-benchmark-synthetic") ? .synthetic : .photos
        let counts = arguments.first { $0.hasPrefix("--picko-benchmark-counts=") }
            .map { argument in
                String(argument.dropFirst("--picko-benchmark-counts=".count))
                    .split(separator: ",")
                    .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            } ?? [1_000, 10_000, 50_000]

        return BenchmarkLaunchConfiguration(mode: mode, assetCounts: counts)
    }
}
