import Foundation

struct FavoriteItem: Identifiable, Codable, Equatable {
    let id: UUID
    let query: String
    let normalizedQuery: String
    let intentType: CalculationIntentType
    let value: Double
    let isPercentValue: Bool
    let summary: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        query: String,
        normalizedQuery: String,
        intentType: CalculationIntentType,
        value: Double,
        isPercentValue: Bool,
        summary: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.query = query
        self.normalizedQuery = normalizedQuery
        self.intentType = intentType
        self.value = value
        self.isPercentValue = isPercentValue
        self.summary = summary
        self.createdAt = createdAt
    }
}
