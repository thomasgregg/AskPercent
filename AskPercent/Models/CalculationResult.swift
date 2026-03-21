import Foundation

struct ResultBreakdownItem: Equatable {
    let label: String
    let value: Double
    let isPercent: Bool

    init(label: String, value: Double, isPercent: Bool = false) {
        self.label = label
        self.value = value
        self.isPercent = isPercent
    }
}

struct CalculationResult: Equatable {
    let intentType: CalculationIntentType
    let primaryLabel: String
    let value: Double
    let isPercentValue: Bool
    let explanation: String
    let formula: String
    let breakdown: [ResultBreakdownItem]
}
