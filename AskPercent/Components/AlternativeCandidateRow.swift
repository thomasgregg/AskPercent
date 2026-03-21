import SwiftUI

struct AlternativeCandidateRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let candidate: CandidateResult
    let settings: UserSettings
    let action: () -> Void

    private var locale: Locale {
        settings.numberFormatStyle.locale
    }

    private var strings: AppStrings {
        AppStrings(language: settings.language)
    }

    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(uiColor: .secondarySystemGroupedBackground)
        : Color(uiColor: .systemBackground)
    }

    private var interpretationText: String {
        let raw = strings.alternativeInterpretation(for: candidate.candidate.intent)
        return DisplayFormatter.localizeNumericLiterals(
            in: raw,
            precision: settings.decimalPrecision,
            locale: locale
        )
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(interpretationText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("\(strings.confidencePrefix): \(Int(candidate.candidate.confidence * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(candidate.result.isPercentValue
                     ? DisplayFormatter.percent(candidate.result.value, precision: settings.decimalPrecision, locale: locale)
                     : DisplayFormatter.number(candidate.result.value, precision: settings.decimalPrecision, locale: locale)
                )
                .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
