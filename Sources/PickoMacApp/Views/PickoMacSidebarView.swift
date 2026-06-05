import SwiftUI

struct PickoMacSidebarView: View {
    @Bindable var model: PickoMacWorkbenchModel

    var body: some View {
        List(selection: $model.sidebarSelection) {
            Section("Tasks") {
                ForEach(model.sidebarRows) { row in
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(row.title)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(PickoMacDesign.ColorToken.primary)
                            Text(row.detail)
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(PickoMacDesign.ColorToken.secondaryInk)
                        }
                    } icon: {
                        Image(systemName: row.systemImage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(PickoMacDesign.ColorToken.primary)
                    }
                    .tag(row.selection)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Picko")
        .scrollContentBackground(.hidden)
        .background(PickoMacDesign.ColorToken.surfaceLow)
        .tint(PickoMacDesign.ColorToken.primary)
    }
}
