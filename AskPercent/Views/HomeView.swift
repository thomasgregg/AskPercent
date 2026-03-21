import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: LocalPersistenceStore
    @EnvironmentObject private var navigation: AppNavigationState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = CalculatorViewModel()
    @FocusState private var isInputFocused: Bool

    private var strings: AppStrings {
        AppStrings(language: store.settings.language)
    }

    private var pageBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(uiColor: .secondarySystemGroupedBackground)
        : Color(uiColor: .systemBackground)
    }

    private var cardBorder: Color {
        Color(uiColor: .separator).opacity(colorScheme == .dark ? 0.55 : 0.35)
    }

    private var shouldShowExampleChips: Bool {
        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                brandTitle
                header
                inputField
                if shouldShowExampleChips {
                    chips
                }

                if let message = viewModel.parseFailureMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                if let current = viewModel.current {
                    ResultCardView(
                        result: current.result,
                        settings: store.settings,
                        onCopyResult: {
                            copyResultToClipboard(current.result)
                        },
                        onCopyFullDetails: {
                            copyFullDetailsToClipboard(current.result)
                        }
                    )
                        .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))

                    if viewModel.isAmbiguous, !viewModel.alternatives.isEmpty {
                        ambiguitySection
                    }
                } else {
                    emptyState
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 20)
            .padding(.top, 62)
            .padding(.bottom, 24)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .topTrailing) {
            if viewModel.current != nil {
                favoriteOverlayButton
            }
        }
        .onAppear {
            viewModel.bind(store: store)
            requestInputFocus()
        }
        .onChange(of: navigation.selectedTab) { _, newValue in
            if newValue == 0 {
                requestInputFocus()
            } else {
                isInputFocused = false
            }
        }
        .onChange(of: navigation.pendingQuery) { _, newValue in
            guard let newValue else { return }
            viewModel.applyQuery(newValue)
            requestInputFocus()
            navigation.pendingQuery = nil
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: viewModel.current?.id)
    }

    private var favoriteOverlayButton: some View {
        Button {
            viewModel.toggleFavoriteCurrent()
        } label: {
            Image(systemName: viewModel.isCurrentFavorite ? "star.fill" : "star")
                .font(.system(size: 22, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(viewModel.isCurrentFavorite ? Color.accentColor : .primary)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(cardBackground)
                )
                .overlay(
                    Circle()
                        .stroke(cardBorder, lineWidth: 1)
                )
        }
        .padding(.trailing, 20)
        .padding(.top, 4)
        .accessibilityLabel(viewModel.isCurrentFavorite ? strings.removeFavoriteAccessibility : strings.addFavoriteAccessibility)
    }

    private var brandTitle: some View {
        HStack(spacing: 10) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1)
                )
                .accessibilityHidden(true)

            Text(strings.appTitle)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
        }
        .padding(.bottom, 2)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(strings.headerTitle)
                .font(.title3.weight(.semibold))
            Text(strings.headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var inputField: some View {
        VStack(spacing: 8) {
            TextField(strings.queryPlaceholder, text: $viewModel.query, axis: .vertical)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isInputFocused)
                .padding(.trailing, viewModel.query.isEmpty ? 16 : 44)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1)
                )
                .overlay(alignment: .trailing) {
                    if !viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            viewModel.applyQuery("")
                            isInputFocused = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.trailing, 14)
                        .accessibilityLabel(strings.clearQueryAccessibility)
                    }
                }

            if viewModel.isAmbiguous {
                Text(strings.ambiguityHint)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(strings.examplePrompts, id: \.self) { prompt in
                    PromptChipView(text: prompt) {
                        viewModel.applyQuery(prompt)
                        isInputFocused = false
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var ambiguitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.alternativesTitle)
                .font(.headline)

            ForEach(viewModel.alternatives) { candidate in
                AlternativeCandidateRow(candidate: candidate, settings: store.settings) {
                    viewModel.chooseCandidate(candidate)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.emptyStateTitle)
                .font(.headline)
            Text(strings.emptyStateBody)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1)
                )
        )
    }

    private func requestInputFocus() {
        DispatchQueue.main.async {
            isInputFocused = true
        }
    }

    private func copyResultToClipboard(_ result: CalculationResult) {
        UIPasteboard.general.string = formattedPrimaryValue(for: result)
    }

    private func copyFullDetailsToClipboard(_ result: CalculationResult) {
        let trimmedQuery = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
        var lines: [String] = [
            "\(strings.copyQuestionLabel): \(trimmedQuery)",
            "\(result.primaryLabel): \(formattedPrimaryValue(for: result))",
            "\(strings.copyExplanationLabel): \(localizedExplanation(for: result))",
            "\(strings.formulaLabel): \(localizedFormula(for: result))"
        ]

        if !result.breakdown.isEmpty {
            lines.append("\(strings.copyBreakdownLabel):")
            lines.append(contentsOf: result.breakdown.map { item in
                let value = item.isPercent
                ? DisplayFormatter.percent(item.value, precision: store.settings.decimalPrecision, locale: store.settings.numberFormatStyle.locale)
                : DisplayFormatter.number(item.value, precision: store.settings.decimalPrecision, locale: store.settings.numberFormatStyle.locale)
                return "- \(item.label): \(value)"
            })
        }

        UIPasteboard.general.string = lines.joined(separator: "\n")
    }

    private func formattedPrimaryValue(for result: CalculationResult) -> String {
        let locale = store.settings.numberFormatStyle.locale
        if result.isPercentValue {
            let signed = result.intentType == .percentChange
            return DisplayFormatter.percent(
                result.value,
                precision: store.settings.decimalPrecision,
                locale: locale,
                alwaysSigned: signed
            )
        }
        return DisplayFormatter.number(
            result.value,
            precision: store.settings.decimalPrecision,
            locale: locale
        )
    }

    private func localizedExplanation(for result: CalculationResult) -> String {
        DisplayFormatter.localizeNumericLiterals(
            in: result.explanation,
            precision: store.settings.decimalPrecision,
            locale: store.settings.numberFormatStyle.locale
        )
    }

    private func localizedFormula(for result: CalculationResult) -> String {
        DisplayFormatter.localizeNumericLiterals(
            in: result.formula,
            precision: store.settings.decimalPrecision,
            locale: store.settings.numberFormatStyle.locale
        )
    }
}
