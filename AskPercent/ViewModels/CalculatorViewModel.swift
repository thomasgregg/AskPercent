import Combine
import Foundation
import UIKit

struct CandidateResult: Identifiable, Equatable {
    let id: UUID
    let candidate: ParseCandidate
    let result: CalculationResult

    init(candidate: ParseCandidate, result: CalculationResult) {
        self.id = candidate.id
        self.candidate = candidate
        self.result = result
    }
}

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var query: String = ""

    @Published private(set) var normalizedQuery: String = ""
    @Published private(set) var current: CandidateResult?
    @Published private(set) var alternatives: [CandidateResult] = []
    @Published private(set) var parseFailureMessage: String?
    @Published private(set) var isAmbiguous: Bool = false
    @Published private(set) var isCurrentFavorite: Bool = false

    private let parser: PercentQueryParser
    private let calculator: PercentCalculator
    private var store: LocalPersistenceStore?

    private var cancellables = Set<AnyCancellable>()
    private var favoriteSubscription: AnyCancellable?
    private var settingsSubscription: AnyCancellable?
    private var selectedCandidateID: UUID?
    private var lastRecordedKey: String?

    init(
        parser: PercentQueryParser = PercentQueryParser(),
        calculator: PercentCalculator = PercentCalculator()
    ) {
        self.parser = parser
        self.calculator = calculator
        bindQuery()
    }

    func bind(store: LocalPersistenceStore) {
        guard self.store == nil else { return }
        self.store = store
        updateParserConfiguration()

        favoriteSubscription = store.$favorites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFavoriteState()
            }

        settingsSubscription = store.$settings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateParserConfiguration()
                if !self.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.evaluate(self.query)
                } else {
                    self.updateFavoriteState()
                }
            }
    }

    func applyQuery(_ text: String) {
        query = text
    }

    func chooseCandidate(_ candidate: CandidateResult) {
        selectedCandidateID = candidate.id
        current = candidate
        alternatives = allCandidatesExcept(candidate.id)
        isAmbiguous = true
        maybeRecord(candidate)
        triggerHapticIfNeeded()
    }

    func toggleFavoriteCurrent() {
        guard let current, let store else { return }
        store.toggleFavorite(query: query, normalizedQuery: normalizedQuery, result: current.result)
        updateFavoriteState()
    }

    private func bindQuery() {
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(320), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.evaluate(text)
            }
            .store(in: &cancellables)
    }

    private var candidateResultsCache: [CandidateResult] = []

    private func evaluate(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            normalizedQuery = ""
            current = nil
            alternatives = []
            parseFailureMessage = nil
            isAmbiguous = false
            selectedCandidateID = nil
            lastRecordedKey = nil
            updateFavoriteState()
            return
        }

        let outcome = parser.parse(trimmed)
        normalizedQuery = outcome.normalizedQuery

        guard outcome.failureMessage == nil else {
            candidateResultsCache = []
            current = nil
            alternatives = []
            parseFailureMessage = localizedParseFailure(from: outcome)
            isAmbiguous = false
            updateFavoriteState()
            return
        }

        if outcome.candidates.isEmpty, outcome.failureReason != nil {
            candidateResultsCache = []
            current = nil
            alternatives = []
            parseFailureMessage = localizedParseFailure(from: outcome)
            isAmbiguous = false
            updateFavoriteState()
            return
        }

        let candidateResults = outcome.candidates.compactMap { candidate -> CandidateResult? in
            guard let result = try? calculator.calculate(intent: candidate.intent, language: currentLanguage) else { return nil }
            return CandidateResult(candidate: candidate, result: result)
        }

        guard !candidateResults.isEmpty else {
            if shouldShowTaxPresetGuidance(for: outcome.normalizedQuery) {
                parseFailureMessage = AppStrings(language: currentLanguage).parseFailureTaxPresetMissing
            } else {
                parseFailureMessage = AppStrings(language: currentLanguage).invalidMathMessage
            }
            current = nil
            alternatives = []
            isAmbiguous = false
            updateFavoriteState()
            return
        }

        candidateResultsCache = candidateResults
        parseFailureMessage = nil

        let resolved = resolveSelection(from: candidateResults)
        current = resolved
        alternatives = allCandidatesExcept(resolved.id)

        let closeScores = candidateResults.count > 1 && abs(candidateResults[0].candidate.confidence - candidateResults[1].candidate.confidence) < 0.15
        isAmbiguous = outcome.isAmbiguous || closeScores

        updateFavoriteState()

        if !isAmbiguous {
            maybeRecord(resolved)
        }

        triggerHapticIfNeeded()
    }

    private func resolveSelection(from candidates: [CandidateResult]) -> CandidateResult {
        if let selectedCandidateID,
           let selected = candidates.first(where: { $0.id == selectedCandidateID }) {
            return selected
        }
        let top = candidates[0]
        selectedCandidateID = top.id
        return top
    }

    private func allCandidatesExcept(_ id: UUID) -> [CandidateResult] {
        candidateResultsCache.filter { $0.id != id }
    }

    private func updateFavoriteState() {
        guard let store else {
            isCurrentFavorite = false
            return
        }
        isCurrentFavorite = store.isFavorite(normalizedQuery: normalizedQuery)
    }

    private func maybeRecord(_ selected: CandidateResult) {
        guard let store else { return }

        let key = "\(normalizedQuery)|\(selected.result.intentType.rawValue)|\(round(selected.result.value * 1_000_000) / 1_000_000)"
        guard key != lastRecordedKey else { return }

        store.addHistory(query: query, normalizedQuery: normalizedQuery, result: selected.result)
        lastRecordedKey = key
    }

    private func triggerHapticIfNeeded() {
        guard let store, store.settings.hapticsEnabled, current != nil else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    private var currentLanguage: AppLanguage {
        store?.settings.language ?? AppLanguage.defaultLanguage
    }

    private func localizedParseFailure(from outcome: ParseOutcome) -> String {
        let strings = AppStrings(language: currentLanguage)
        switch outcome.failureReason {
        case .numbersMissing:
            return strings.parseFailureNoNumbers
        case .taxPresetMissing:
            return strings.parseFailureTaxPresetMissing
        case .lowConfidence:
            return strings.parseFailureLowConfidence
        case .none:
            return strings.parseFailureLowConfidence
        }
    }

    private func updateParserConfiguration() {
        guard let store else { return }
        if store.settings.taxPresetEnabled {
            parser.defaultTaxPercent = max(store.settings.taxPresetPercent, 0)
        } else {
            parser.defaultTaxPercent = nil
        }
    }

    private func shouldShowTaxPresetGuidance(for normalizedQuery: String) -> Bool {
        guard let store, !store.settings.taxPresetEnabled else { return false }
        guard !normalizedQuery.contains("%"),
              !normalizedQuery.contains("percent"),
              !normalizedQuery.contains("prozent") else { return false }

        let taxTerms = ["tax", "sales tax", "vat", "gst", "iva", "steuer", "mwst", "ust", "umsatzsteuer", "umsatzst"]
        let contextTerms = [
            "plus", "with", "add", "added", "include", "included", "including", "incl", "inc",
            "minus", "subtract", "subtracted", "substract", "substracted", "reduce", "reduced", "reduziere", "reduziert", "reduzieren", "less", "excluding", "excl", "ex", "without",
            "mit", "inkl", "zzgl", "zuzüglich", "zuzueglich",
            "ohne", "abzüglich", "abzueglich", "abzgl",
            "net", "gross", "netto", "brutto", "before tax", "after tax", "vor steuer", "nach steuer",
            "+", "-"
        ]

        let hasTax = taxTerms.contains { normalizedQuery.contains($0) }
        let hasContext = contextTerms.contains { normalizedQuery.contains($0) }
        return hasTax && hasContext
    }
}
