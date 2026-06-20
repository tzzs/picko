import SwiftUI

public struct PickoRootView: View {
    @Bindable private var model: PickoAppModel

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        TabView(selection: $model.selectedTab) {
            NavigationStack {
                HomeView(model: model)
            }
            .tabItem {
                Label(PickoCopy.Tabs.home, systemImage: "house")
            }
            .tag(PickoAppModel.Tab.home)

            NavigationStack {
                SingleReviewView(model: model)
            }
            .tabItem {
                Label(PickoCopy.Tabs.review, systemImage: "rectangle.stack")
            }
            .tag(PickoAppModel.Tab.review)

            NavigationStack {
                SimilarGroupReviewView(model: model)
            }
            .tabItem {
                Label(PickoCopy.Tabs.similar, systemImage: "square.grid.2x2")
            }
            .tag(PickoAppModel.Tab.similar)

            NavigationStack {
                PreDeleteBasketView(model: model)
            }
            .tabItem {
                Label(PickoCopy.Tabs.basket, systemImage: "tray")
            }
            .badge(model.deletionQueueCount)
            .tag(PickoAppModel.Tab.basket)
        }
    }
}

#Preview {
    PickoRootView(model: .preview())
}
