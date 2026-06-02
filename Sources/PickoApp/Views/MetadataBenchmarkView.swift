import PickoPhotos
import SwiftUI

public struct MetadataBenchmarkView: View {
    @State private var phase: Phase = .running
    private let configuration: BenchmarkLaunchConfiguration

    public init(configuration: BenchmarkLaunchConfiguration) {
        self.configuration = configuration
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Mode", value: modeTitle)
                    LabeledContent("Targets", value: configuration.assetCounts.map(String.init).joined(separator: ", "))
                }

                switch phase {
                case .running:
                    Section {
                        ProgressView("Running metadata benchmark")
                            .accessibilityIdentifier("metadata-benchmark-running")
                    }
                case .finished(let results):
                    let summary = MetadataBenchmarkSummary(mode: modeTitle, results: results)
                    Section("Summary") {
                        Text(summary.text)
                            .font(.footnote)
                            .textSelection(.enabled)
                            .accessibilityIdentifier("metadata-benchmark-summary")
                    }

                    Section("Results") {
                        ForEach(results, id: \.assetCount) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(result.assetCount) assets")
                                    .font(.headline)
                                    .accessibilityIdentifier("metadata-benchmark-result-\(result.assetCount)")
                                Text("\(formatted(result.elapsedSeconds)) seconds")
                                    .foregroundStyle(.secondary)
                                Text("\(formatted(result.assetsPerSecond)) assets/second")
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(summary.rowText(for: result))
                        }
                    }
                case .failed(let message):
                    Section {
                        Text(message)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("metadata-benchmark-error")
                    }
                }
            }
            .navigationTitle("Metadata Benchmark")
        }
        .task {
            await run()
        }
    }

    private var modeTitle: String {
        switch configuration.mode {
        case .synthetic:
            return "Synthetic"
        case .photos:
            return "Photos"
        }
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.4f", value)
    }

    @MainActor
    private func run() async {
        do {
            let runner = AssetIndexingBenchmarkRunner()
            let results: [AssetIndexingBenchmarkResult]

            switch configuration.mode {
            case .synthetic:
                results = try await runner.runSynthetic(assetCounts: configuration.assetCounts)
            case .photos:
                let authorizer = PhotosLibraryAdapter(fetchLimit: configuration.assetCounts.max())
                let status = authorizer.authorizationStatus()
                if status != .authorized && status != .limited {
                    let requestedStatus = await authorizer.requestAuthorization()
                    guard requestedStatus == .authorized || requestedStatus == .limited else {
                        phase = .failed(MetadataBenchmarkFailure.photosAccessNotGranted(requestedStatus).message)
                        return
                    }
                }

                results = try await runner.runPhotos(assetCounts: configuration.assetCounts)
            }

            phase = .finished(results)
        } catch {
            phase = .failed(MetadataBenchmarkFailure.benchmarkRunFailed.message)
        }
    }

}

private enum Phase {
    case running
    case finished([AssetIndexingBenchmarkResult])
    case failed(String)
}

#Preview {
    MetadataBenchmarkView(
        configuration: BenchmarkLaunchConfiguration(mode: .synthetic, assetCounts: [10, 20])
    )
}
