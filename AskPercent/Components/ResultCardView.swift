import SwiftUI

struct ResultCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    let result: CalculationResult
    let settings: UserSettings

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

    private var mainValueText: String {
        if result.isPercentValue {
            let signed = result.intentType == .percentChange
            return DisplayFormatter.percent(
                result.value,
                precision: settings.decimalPrecision,
                locale: locale,
                alwaysSigned: signed
            )
        }
        return DisplayFormatter.number(result.value, precision: settings.decimalPrecision, locale: locale)
    }

    private var localizedExplanation: String {
        DisplayFormatter.localizeNumericLiterals(
            in: result.explanation,
            precision: settings.decimalPrecision,
            locale: locale
        )
    }

    private var localizedFormula: String {
        DisplayFormatter.localizeNumericLiterals(
            in: result.formula,
            precision: settings.decimalPrecision,
            locale: locale
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(result.primaryLabel)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(mainValueText)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(localizedExplanation)
                .font(.body)
                .foregroundStyle(.primary)

            if settings.showFormula {
                VStack(alignment: .leading, spacing: 6) {
                    Text(strings.formulaLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(localizedFormula)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            if !result.breakdown.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(result.breakdown.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.label)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(item.isPercent
                                 ? DisplayFormatter.percent(item.value, precision: settings.decimalPrecision, locale: locale)
                                 : DisplayFormatter.number(item.value, precision: settings.decimalPrecision, locale: locale)
                            )
                            .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 1)
                )
        )
    }
}
