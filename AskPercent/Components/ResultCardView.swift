import SwiftUI

struct ResultCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    let result: CalculationResult
    let settings: UserSettings
    let onCopyResult: (() -> Void)?
    let onCopyFullDetails: (() -> Void)?

    private var locale: Locale {
        settings.numberFormatStyle.locale
    }

    private var strings: AppStrings {
        AppStrings(language: settings.language)
    }

    private var supportsCopyActions: Bool {
        onCopyResult != nil || onCopyFullDetails != nil
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
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Text(result.primaryLabel)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                if supportsCopyActions {
                    Button {
                        if let onCopyFullDetails {
                            onCopyFullDetails()
                        } else {
                            onCopyResult?()
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(strings.copyFullDetailsAction)
                }
            }

            Text(mainValueText)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(localizedExplanation)
                .font(.body)
                .foregroundStyle(.primary)

            if settings.showFormula {
                VStack(alignment: .leading, spacing: 8) {
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
                VStack(alignment: .leading, spacing: 12) {
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
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 1)
                )
        )
        .contextMenu {
            if let onCopyResult {
                Button(strings.copyResultAction, systemImage: "number.square") {
                    onCopyResult()
                }
            }
            if let onCopyFullDetails {
                Button(strings.copyFullDetailsAction, systemImage: "doc.on.doc") {
                    onCopyFullDetails()
                }
            }
        }
    }
}
