import SwiftUI

struct PickoMacSidebarView: View {
    @Bindable var model: PickoMacWorkbenchModel

    var body: some View {
        List(selection: $model.sidebarSelection) {
            Section("Library") {
                ForEach(PickoMacWorkbenchModel.SidebarSelection.allCases) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Picko")
    }
}
