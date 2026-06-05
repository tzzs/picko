import SwiftUI

struct PickoMacSidebarView: View {
    @Bindable var model: PickoMacWorkbenchModel

    var body: some View {
        List(selection: $model.sidebarSelection) {
            Section("Tasks") {
                ForEach(model.sidebarRows) { row in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                            Text(row.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: row.systemImage)
                    }
                    .tag(row.selection)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Picko")
    }
}
