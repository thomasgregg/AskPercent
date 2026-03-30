import SwiftUI
import UIKit

private struct CursorTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    @Binding var selection: NSRange
    @Binding var isFocused: Bool
    var onSubmit: (() -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.borderStyle = .none
        textField.font = .preferredFont(forTextStyle: .body)
        textField.textColor = .label
        textField.placeholder = placeholder
        textField.text = text
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .never
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self

        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }

        if uiView.text != text {
            uiView.text = text
        }

        let clamped = clampedSelection(for: uiView)
        if context.coordinator.currentSelection(in: uiView) != clamped {
            context.coordinator.setSelection(clamped, in: uiView)
        }

        if isFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func clampedSelection(for textField: UITextField) -> NSRange {
        let textLength = (textField.text ?? "").utf16.count
        let location = min(max(0, selection.location), textLength)
        let maxLength = textLength - location
        let length = min(max(0, selection.length), maxLength)
        return NSRange(location: location, length: length)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CursorTextField

        init(parent: CursorTextField) {
            self.parent = parent
        }

        @objc
        func textDidChange(_ textField: UITextField) {
            let updatedText = textField.text ?? ""
            if parent.text != updatedText {
                parent.text = updatedText
            }
            parent.selection = currentSelection(in: textField)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
            parent.selection = currentSelection(in: textField)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
            parent.selection = currentSelection(in: textField)
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.selection = currentSelection(in: textField)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.isFocused = false
            parent.onSubmit?()
            return true
        }

        func currentSelection(in textField: UITextField) -> NSRange {
            guard let selectedRange = textField.selectedTextRange else {
                let end = (textField.text ?? "").utf16.count
                return NSRange(location: end, length: 0)
            }

            let beginning = textField.beginningOfDocument
            let location = textField.offset(from: beginning, to: selectedRange.start)
            let length = textField.offset(from: selectedRange.start, to: selectedRange.end)
            return NSRange(location: max(0, location), length: max(0, length))
        }

        func setSelection(_ range: NSRange, in textField: UITextField) {
            guard
                let start = textField.position(from: textField.beginningOfDocument, offset: range.location),
                let end = textField.position(from: start, offset: range.length),
                let textRange = textField.textRange(from: start, to: end)
            else {
                return
            }
            textField.selectedTextRange = textRange
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: LocalPersistenceStore
    @EnvironmentObject private var navigation: AppNavigationState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = CalculatorViewModel()
    @State private var isInputFocused: Bool = false
    @State private var inputSelection: NSRange = NSRange(location: 0, length: 0)
    private let keyboardTokens = ["%", "+", "-", ",", "."]

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
                } else if viewModel.parseFailureMessage == nil {
                    emptyState
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 20)
            .padding(.top, 62)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            if isInputFocused {
                isInputFocused = false
            }
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
            inputSelection = NSRange(location: (newValue as NSString).length, length: 0)
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
            CursorTextField(
                placeholder: strings.queryPlaceholder,
                text: $viewModel.query,
                selection: $inputSelection,
                isFocused: $isInputFocused
            ) {
                isInputFocused = false
            }
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
                            inputSelection = NSRange(location: 0, length: 0)
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

            if isInputFocused {
                quickTokenRow
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if viewModel.isAmbiguous {
                Text(strings.ambiguityHint)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var quickTokenRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(keyboardTokens, id: \.self) { token in
                    keyboardTokenButton(token)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(strings.examplePrompts, id: \.self) { prompt in
                    PromptChipView(text: prompt) {
                        viewModel.applyQuery(prompt)
                        inputSelection = NSRange(location: (prompt as NSString).length, length: 0)
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
            let end = (viewModel.query as NSString).length
            inputSelection = NSRange(location: end, length: 0)
            isInputFocused = true
        }
    }

    @ViewBuilder
    private func keyboardTokenButton(_ token: String) -> some View {
        Button {
            insertKeyboardToken(token)
            isInputFocused = true
        } label: {
            Text(token)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(cardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Insert \(token)")
    }

    private func insertKeyboardToken(_ token: String) {
        let currentText = viewModel.query
        let nsText = currentText as NSString
        let replacementRange = clampedSelection(in: nsText.length)

        switch token {
        case "+", "-":
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return
            }
            let insertion = operatorInsertion(token: token, text: nsText, range: replacementRange)
            let updated = nsText.replacingCharacters(in: replacementRange, with: insertion)
            viewModel.applyQuery(updated)
            inputSelection = NSRange(location: replacementRange.location + (insertion as NSString).length, length: 0)
        default:
            let updated = nsText.replacingCharacters(in: replacementRange, with: token)
            viewModel.applyQuery(updated)
            inputSelection = NSRange(location: replacementRange.location + (token as NSString).length, length: 0)
        }
    }

    private func clampedSelection(in textLength: Int) -> NSRange {
        let location = min(max(0, inputSelection.location), textLength)
        let maxLength = textLength - location
        let length = min(max(0, inputSelection.length), maxLength)
        return NSRange(location: location, length: length)
    }

    private func operatorInsertion(token: String, text: NSString, range: NSRange) -> String {
        let leftIndex = range.location - 1
        let rightIndex = range.location + range.length

        let left = leftIndex >= 0 ? text.substring(with: NSRange(location: leftIndex, length: 1)) : nil
        let right = rightIndex < text.length ? text.substring(with: NSRange(location: rightIndex, length: 1)) : nil

        let whitespace = CharacterSet.whitespacesAndNewlines
        let needsLeadingSpace = left != nil && left?.rangeOfCharacter(from: whitespace) == nil
        let needsTrailingSpace = right == nil || right?.rangeOfCharacter(from: whitespace) == nil

        return (needsLeadingSpace ? " " : "") + token + (needsTrailingSpace ? " " : "")
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
