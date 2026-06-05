import SwiftUI

public struct HomeView: View {
    @Bindable private var model: PickoAppModel
    @State private var isConfirmingClearState = false

    public init(model: PickoAppModel) {
        self.model = model
    }

    public var body: some View {
        let presentation = PickoHomePresentation(model: model)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(presentation.heroTitle)
                        .font(.largeTitle.bold())
                    Text(presentation.heroSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                    ForEach(presentation.metricRows, id: \.label) { metric in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(metric.value)
                                .font(.title2.bold())
                            Text(metric.label)
                                .font(.caption.weight(.semibold))
                            Text(metric.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Start")
                        .font(.headline)

                    ForEach(Array(presentation.taskRows.enumerated()), id: \.element.title) { index, task in
                        Button {
                            openTask(at: index)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: task.systemImage)
                                    .font(.title3)
                                    .foregroundStyle(task.tintColor)
                                    .frame(width: 32, height: 32)
                                    .background(task.tintColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(task.title)
                                        .font(.headline)
                                    Text(task.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(12)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                Button {
                    isConfirmingClearState = true
                } label: {
                    Label("Clear Picko review state", systemImage: "arrow.counterclockwise.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                Text(presentation.privacyFootnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
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

    private func openTask(at index: Int) {
        switch index {
        case 0:
            model.selectedTab = .review
        case 1:
            model.selectedTab = .similar
        case 2:
            model.selectedTab = .basket
        default:
            model.selectedTab = .home
        }
    }
}

private extension PickoTaskPresentation {
    var tintColor: Color {
        switch tintRole {
        case .keep:
            Color.green
        case .review:
            Color.blue
        case .time:
            Color.orange
        case .basket:
            Color.red
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(model: .preview())
    }
}
