import SwiftUI

struct ReviewGestureSettingsView: View {
    @AppStorage(ReviewGesturePreference.storageKey) private var selectedPreferenceRawValue = ReviewGesturePreference.keepOnUp.rawValue
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: PickoDesign.Spacing.lg) {
                VStack(alignment: .leading, spacing: PickoDesign.Spacing.gutter) {
                    PickoSectionLabel(title: "复核手势")
                    Text("选择保留动作对应的上下滑方向。另一个方向会放入预删除篮。")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                }

                VStack(spacing: PickoDesign.Spacing.gutter) {
                    ForEach(ReviewGesturePreference.allCases) { preference in
                        Button {
                            selectedPreferenceRawValue = preference.rawValue
                        } label: {
                            HStack(spacing: PickoDesign.Spacing.md) {
                                Image(systemName: preference == selectedPreference ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 21, weight: .semibold))
                                    .foregroundStyle(preference == selectedPreference ? PickoDesign.ColorToken.gold : PickoDesign.ColorToken.outline)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preference.title)
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundStyle(PickoDesign.ColorToken.primary)
                                    Text(preference.subtitle)
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                                }

                                Spacer()
                            }
                            .padding(PickoDesign.Spacing.md)
                            .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                            .overlay {
                                RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                                    .stroke(
                                        preference == selectedPreference ? PickoDesign.ColorToken.gold.opacity(0.65) : PickoDesign.ColorToken.outline.opacity(0.45),
                                        lineWidth: 1
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(PickoDesign.Spacing.page)
            .navigationTitle("设置")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("完成") {
                        dismiss()
                    }
                }
                #endif
            }
            .pickoScreenBackground()
        }
    }

    private var selectedPreference: ReviewGesturePreference {
        ReviewGesturePreference.resolved(rawValue: selectedPreferenceRawValue)
    }
}

#Preview {
    ReviewGestureSettingsView()
}
