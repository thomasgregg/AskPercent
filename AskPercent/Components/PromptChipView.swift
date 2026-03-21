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
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
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
