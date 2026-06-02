import SwiftUI

public struct OnboardingView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.blue)

            Text("Picko")
                .font(.largeTitle.bold())

            Text("Review similar moments, keep the photos that matter, and confirm changes only after checking your basket.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
