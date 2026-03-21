import Foundation

enum ParseFailureReason: Equatable {
    case numbersMissing
    case lowConfidence
}

struct ParseCandidate: Identifiable, Equatable {
    let id: UUID
    let intent: CalculationIntent
    let confidence: Double
    let interpretation: String

    init(id: UUID = UUID(), intent: CalculationIntent, confidence: Double, interpretation: String) {
        self.id = id
        self.intent = intent
        self.confidence = confidence
        self.interpretation = interpretation
    }
}

struct ParseOutcome {
    let normalizedQuery: String
    let candidates: [ParseCandidate]
    let failureReason: ParseFailureReason?
    let failureMessage: String?

    var isAmbiguous: Bool {
        guard candidates.count > 1 else { return false }
        return (candidates[0].confidence - candidates[1].confidence) < 0.15
    }
}
