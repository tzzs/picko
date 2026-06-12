import SwiftUI

struct PickoMacTimeLocationView: View {
    let title: String
    let systemImage: String

    var body: some View {
        PickoMacEmptyStateView(
            title: title,
            message: "This view will use the same review state after real photo indexing is connected.",
            systemImage: systemImage
        )
    }
}
