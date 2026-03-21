import XCTest
@testable import AskPercent

final class CandidateRankingTests: XCTestCase {
    private let parser = PercentQueryParser()

    func testSpecificPatternRanksHighest() {
        let outcome = parser.parse("25% of 167")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOf)

        if outcome.candidates.count > 1 {
            XCTAssertGreaterThanOrEqual(outcome.candidates[0].confidence, outcome.candidates[1].confidence)
        }
    }

    func testDiscountPatternRanksAbovePercentChangeCandidates() {
        let outcome = parser.parse("134 instead of 179 what percent discount")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .discountPercent)
    }
}
