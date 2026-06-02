import SwiftUI

public struct HomeView: View {
    @Bindable private var model: PickoAppModel
    @State private var isConfirmingClearState = false

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ready to review")
                        .font(.title2.bold())
                    Text("\(model.assets.count) items prepared, \(model.groups.count) similar group ready.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("Start") {
                Button {
                    model.selectedTab = .review
                } label: {
                    Label("Review one by one", systemImage: "rectangle.stack")
                }

                Button {
                    model.selectedTab = .similar
                } label: {
                    Label("Review similar group", systemImage: "square.grid.2x2")
                }

                Button {
                    model.selectedTab = .basket
                } label: {
                    Label("Open pre-delete basket", systemImage: "tray")
                }
            }

            Section {
                Button(role: .destructive) {
                    isConfirmingClearState = true
                } label: {
                    Label("Clear Picko review state", systemImage: "arrow.counterclockwise.circle")
                }
            } header: {
                Text("Privacy")
            } footer: {
                Text("Clears Picko's local review decisions, sessions, group choices, and basket state. Photos are not deleted.")
            }
        }
        .navigationTitle("Picko")
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
    }
}

#Preview {
    NavigationStack {
        HomeView(model: .preview())
    }
}
