import SwiftUI

public struct PickoMacRootView: View {
    @Bindable private var model: PickoMacWorkbenchModel
    @State private var isConfirmingClearState = false

    public init(model: PickoMacWorkbenchModel) {
        self.model = model
    }

    public var body: some View {
        NavigationSplitView {
            PickoMacSidebarView(model: model)
        } detail: {
            HStack(spacing: 0) {
                detailView
                    .navigationTitle(model.sidebarSelection.title)
                    .pickoMacScreenBackground()

                Divider()
                    .overlay(PickoMacDesign.ColorToken.outline.opacity(0.45))

                PickoMacInspectorView(model: model)
                    .frame(width: 292)
                    .background(PickoMacDesign.ColorToken.surfaceLow)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    model.keepSelectedAsset()
                } label: {
                    Label("Keep", systemImage: "checkmark.circle")
                }

                Button {
                    model.preDeleteSelectedAsset()
                } label: {
                    Label("Review Later", systemImage: "tray.and.arrow.down")
                }

                Button {
                    model.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }

                Button(role: .destructive) {
                    isConfirmingClearState = true
                } label: {
                    Label("Clear Picko State", systemImage: "arrow.counterclockwise.circle")
                }
            }
        }
        .confirmationDialog(
            "Clear Picko review state?",
            isPresented: $isConfirmingClearState,
            titleVisibility: .visible
        ) {
            Button("Clear Picko state", role: .destructive) {
                model.clearLocalReviewState()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This only resets local Picko review progress. It does not delete or modify photos.")
        }
        .tint(PickoMacDesign.ColorToken.primary)
    }

    @ViewBuilder
    private var detailView: some View {
        switch model.sidebarSelection {
        case .home:
            PickoMacGridReviewView(model: model)
        case .similar:
            PickoMacSimilarGroupsView(model: model)
        case .time:
            PickoMacTimeLocationView(title: "Time Review", systemImage: "calendar")
        case .location:
            PickoMacTimeLocationView(title: "Location Review", systemImage: "location")
        case .basket:
            PickoMacBasketView(model: model)
        }
    }
}

#Preview {
    PickoMacRootView(model: .preview())
        .frame(width: 1100, height: 720)
}
