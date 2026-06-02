import Foundation
import PickoPhotos

@main
struct PickoBenchmarks {
    static func main() async throws {
        #if canImport(Photos)
        let counts = benchmarkCounts(from: CommandLine.arguments.dropFirst())
        let usePhotos = CommandLine.arguments.contains("--photos")
        let useJSON = CommandLine.arguments.contains("--json")
        let runner = AssetIndexingBenchmarkRunner()
        let results = if usePhotos {
            try await runner.runPhotos(assetCounts: counts)
        } else {
            try await runner.runSynthetic(assetCounts: counts)
        }
        let mode = usePhotos ? "Photos fetch limit" : "Synthetic fixture"

        if useJSON {
            let report = AssetIndexingBenchmarkReport(mode: mode, results: results)
            FileHandle.standardOutput.write(try report.jsonData())
            FileHandle.standardOutput.write(Data("\n".utf8))
            return
        }

        print("# Picko Metadata Indexing Benchmark")
        print("Mode: \(mode)")
        print("")
        print("| Asset count | Elapsed seconds | Assets / second |")
        print("| ---: | ---: | ---: |")

        for result in results {
            print("| \(result.assetCount) | \(format(result.elapsedSeconds)) | \(format(result.assetsPerSecond)) |")
        }
        #else
        print("Picko metadata indexing benchmarks require Apple Photos support.")
        #endif
    }
}

#if canImport(Photos)
func benchmarkCounts<S: Sequence>(from arguments: S) -> [Int] where S.Element == String {
    let parsed = arguments
        .filter { !$0.hasPrefix("--") }
        .compactMap(Int.init)
        .filter { $0 > 0 }
    return parsed.isEmpty ? [1_000, 10_000, 50_000] : parsed
}

func format(_ value: Double) -> String {
    String(format: "%.4f", value)
}
#endif
