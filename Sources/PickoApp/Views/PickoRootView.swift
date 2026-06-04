import SwiftUI

public struct PickoRootView: View {
    @Bindable private var model: PickoAppModel
    @State private var isConfirmingClearState = false

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        TabView(selection: $model.selectedTab) {
            NavigationStack {
                HomeView(model: model)
                    .toolbar {
                        ToolbarItem(placement: clearReviewStateToolbarPlacement) {
                            clearReviewStateButton
                        }
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(PickoAppModel.Tab.home)

            NavigationStack {
                SingleReviewView(model: model)
                    .toolbar {
                        ToolbarItem(placement: clearReviewStateToolbarPlacement) {
                            clearReviewStateButton
                        }
                    }
            }
            .tabItem {
                Label("Review", systemImage: "rectangle.stack")
            }
            .tag(PickoAppModel.Tab.review)

            NavigationStack {
                SimilarGroupReviewView(model: model)
                    .toolbar {
                        ToolbarItem(placement: clearReviewStateToolbarPlacement) {
                            clearReviewStateButton
                        }
                    }
            }
            .tabItem {
                Label("Similar", systemImage: "square.grid.2x2")
            }
            .tag(PickoAppModel.Tab.similar)

            NavigationStack {
                PreDeleteBasketView(model: model)
                    .toolbar {
                        ToolbarItem(placement: clearReviewStateToolbarPlacement) {
                            clearReviewStateButton
                        }
                    }
            }
            .tabItem {
                Label("Basket", systemImage: "tray")
            }
            .badge(model.deletionQueueCount)
            .tag(PickoAppModel.Tab.basket)
        }
        .alert(
            "Clear Picko review state?",
            isPresented: $isConfirmingClearState,
        ) {
            Button("Clear Picko state", role: .destructive) {
                model.clearLocalReviewState()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This only resets local Picko review progress. It does not delete or modify photos.")
        }
    }

    private var clearReviewStateButton: some View {
        Button {
            isConfirmingClearState = true
        } label: {
            Label("Clear Picko State", systemImage: "arrow.counterclockwise.circle")
        }
        .accessibilityIdentifier("clear-picko-state-toolbar-button")
        .accessibilityLabel("Clear Picko State")
    }

    private var clearReviewStateToolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}

#Preview {
    PickoRootView(model: .preview())
}
