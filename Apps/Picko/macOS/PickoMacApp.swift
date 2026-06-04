import PickoMacApp
import PickoApp
import PickoPhotos
import SwiftUI

@main
struct PickoMacOSApp: App {
    @State private var commandModel = PickoMacWorkbenchModel.preview()

    var body: some Scene {
        WindowGroup {
            rootView
                .frame(minWidth: 980, minHeight: 640)
        }
        .commands {
            CommandMenu("Review") {
                Button("Keep") {
                    commandModel.keepSelectedAsset()
                }
                .keyboardShortcut("k", modifiers: [])

                Button("Review Later") {
                    commandModel.preDeleteSelectedAsset()
                }
                .keyboardShortcut("d", modifiers: [])

                Button("Undo") {
                    commandModel.undo()
                }
                .keyboardShortcut("z", modifiers: [])

                Button("Preview") {
                    commandModel.previewSelectedAsset()
                }
                .keyboardShortcut(.space, modifiers: [])

                Divider()

                Button("Keep 1 From Group") {
                    commandModel.sidebarSelection = .similar
                }
                .keyboardShortcut("1", modifiers: [])
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("--picko-use-sample-library") {
            PickoMacRootView(model: commandModel)
        } else if arguments.contains("--picko-use-denied-library") {
            PickoMacLibraryBootstrapView(makeBootstrapper: deniedLibraryBootstrapper)
        } else {
            PickoMacLibraryBootstrapView(onModelLoaded: { loadedModel in
                commandModel = loadedModel
            })
        }
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
