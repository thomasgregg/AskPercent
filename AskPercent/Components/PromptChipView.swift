import SwiftUI

struct PromptChipView: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    let action: () -> Void

    private var chipBackground: Color {
        colorScheme == .dark
        ? Color(uiColor: .secondarySystemGroupedBackground)
        : Color(uiColor: .systemBackground)
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(minHeight: 50)
                .background(
                    Capsule()
                        .fill(chipBackground)
                        .overlay(
                            Capsule()
                                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
