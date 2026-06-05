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
            ScrollView {
                VStack(alignment: .leading, spacing: PickoDesign.Spacing.lg) {
                    VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                        PickoSectionLabel(title: "Metadata Benchmark")
                        Text("索引性能证据")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(PickoDesign.ColorToken.primary)
                        Text("用于验证 Picko 在不同图库规模下的 metadata indexing baseline。")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                    }

                    VStack(spacing: PickoDesign.Spacing.gutter) {
                        benchmarkMetric(label: "Mode", value: modeTitle)
                        benchmarkMetric(label: "Targets", value: configuration.assetCounts.map(String.init).joined(separator: ", "))
                    }

                switch phase {
                case .running:
                    VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                        ProgressView()
                            .tint(PickoDesign.ColorToken.primary)
                        Text("Running metadata benchmark")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .accessibilityIdentifier("metadata-benchmark-running")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(PickoDesign.Spacing.page)
                    .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                case .finished(let results):
                    let summary = MetadataBenchmarkSummary(mode: modeTitle, results: results)
                    VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                        PickoSectionLabel(title: "Summary")
                        Text(summary.text)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                            .textSelection(.enabled)
                            .accessibilityIdentifier("metadata-benchmark-summary")
                    }
                    .padding(PickoDesign.Spacing.page)
                    .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))

                    VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                        PickoSectionLabel(title: "Results")
                        ForEach(results, id: \.assetCount) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(result.assetCount) assets")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(PickoDesign.ColorToken.primary)
                                    .accessibilityIdentifier("metadata-benchmark-result-\(result.assetCount)")
                                Text("\(formatted(result.elapsedSeconds)) seconds")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                                Text("\(formatted(result.assetsPerSecond)) assets/second")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(PickoDesign.Spacing.md)
                            .background(PickoDesign.ColorToken.surfaceLow, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(summary.rowText(for: result))
                        }
                    }
                case .failed(let message):
                    Text(message)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                        .padding(PickoDesign.Spacing.page)
                        .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.xl))
                        .accessibilityIdentifier("metadata-benchmark-error")
                }
                }
                .padding(PickoDesign.Spacing.page)
            }
            .navigationTitle("Metadata Benchmark")
            .pickoScreenBackground()
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

    private func benchmarkMetric(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(PickoDesign.ColorToken.primary)
        }
        .padding(PickoDesign.Spacing.md)
        .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
        }
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
