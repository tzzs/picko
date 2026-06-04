import PickoApp
import PickoPhotos
import SwiftData
import SwiftUI

@main
struct PickoIOSApp: App {
    @State private var sampleLibraryModel = PickoAppModel.preview()
    @State private var sampleBasketModel = PickoIOSApp.makeSampleBasketModel()

    var body: some Scene {
        WindowGroup {
            rootView
        }
        .modelContainer(
            for: [
                ReviewDecisionRecord.self,
                ReviewSessionRecord.self,
                GroupDecisionRecord.self,
                BasketItemRecord.self
            ]
        )
    }

    @ViewBuilder
    private var rootView: some View {
        let arguments = ProcessInfo.processInfo.arguments

        if let configuration = BenchmarkLaunchConfiguration.parse(arguments: arguments) {
            MetadataBenchmarkView(configuration: configuration)
        } else if arguments.contains("--picko-use-denied-library") {
            PickoLibraryBootstrapView(makeBootstrapper: deniedLibraryBootstrapper)
        } else if arguments.contains("--picko-use-sample-basket") {
            PickoRootView(model: sampleBasketModel)
        } else if arguments.contains("--picko-use-sample-library") {
            PickoRootView(model: sampleLibraryModel)
        } else {
            PickoLibraryBootstrapView()
        }
    }

    private static func makeSampleBasketModel() -> PickoAppModel {
        let model = PickoAppModel.preview()
        model.preDeleteCurrentAsset()
        model.selectedTab = .basket
        return model
    }

    private func deniedLibraryBootstrapper() throws -> PhotoLibraryBootstrapper {
        PhotoLibraryBootstrapper(
            authorizer: DeniedPhotoLibraryAuthorizer(),
            indexer: EmptyPhotoAssetIndexer(),
            decisionStore: nil
        )
    }
}

private struct DeniedPhotoLibraryAuthorizer: PhotoLibraryAuthorizing {
    func authorizationStatus() -> PhotoLibraryAuthorizationStatus {
        .denied
    }

    func requestAuthorization() async -> PhotoLibraryAuthorizationStatus {
        .denied
    }
}

private struct EmptyPhotoAssetIndexer: PhotoAssetIndexing {
    func fetchAssetSnapshots() async throws -> [PhotoAssetSnapshot] {
        []
    }
}
