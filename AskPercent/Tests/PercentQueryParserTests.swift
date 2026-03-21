import XCTest
@testable import AskPercent

final class PercentQueryParserTests: XCTestCase {
    private let parser = PercentQueryParser()
    private let calculator = PercentCalculator()

    func testTopIntentPercentOf() {
        let outcome = parser.parse("25% of 167")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOf)
    }

    func testProfitPercentOfPhrase() {
        let outcome = parser.parse("what is 10% profit of 230")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOf)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected percent-of candidate for profit phrase")
        }
        do {
            let result = try calculator.calculate(intent: intent)
            XCTAssertEqual(result.value, 23, accuracy: 0.000_001)
        } catch {
            XCTFail("Unexpected calculation error: \(error)")
        }
    }

    func testPercentOfWithRedundantPercentWordAndLargeNumber() throws {
        let outcome = parser.parse("what is 10% percent of 87336437476")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOf)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected percent-of candidate")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 8_733_643_747.6, accuracy: 0.000_1)
    }

    func testTopIntentAddPercent() {
        let outcome = parser.parse("167 plus 25%")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .addPercent)
    }

    func testTopIntentAddPercentWithSymbol() {
        let outcome = parser.parse("167 + 10%")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .addPercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected add-percent candidate")
        }
        do {
            let result = try calculator.calculate(intent: intent)
            XCTAssertEqual(result.value, 183.7, accuracy: 0.000_001)
        } catch {
            XCTFail("Unexpected calculation error: \(error)")
        }
    }

    func testTopIntentSubtractPercent() {
        let outcome = parser.parse("899 minus 12%")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .subtractPercent)
    }

    func testTopIntentSubtractPercentWithSymbol() {
        let outcome = parser.parse("167 - 10%")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .subtractPercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent candidate")
        }
        do {
            let result = try calculator.calculate(intent: intent)
            XCTAssertEqual(result.value, 150.3, accuracy: 0.000_001)
        } catch {
            XCTFail("Unexpected calculation error: \(error)")
        }
    }

    func testTopIntentPercentChange() {
        let outcome = parser.parse("from 80 to 96 what is the percentage increase")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentChange)
    }

    func testTopIntentDiscount() {
        let outcome = parser.parse("I paid 134 instead of 179, what percent discount is that?")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .discountPercent)
    }

    func testTopIntentReversePercent() {
        let outcome = parser.parse("if 30% is 45 what is 100%")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)
    }

    func testTopIntentRelation() {
        let outcome = parser.parse("41.75 is what percent of 167")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOfRelation)
    }

    func testTopIntentTip() {
        let outcome = parser.parse("240 with 15% tip")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .tip)
    }

    func testTopIntentVat() {
        let outcome = parser.parse("85 plus 19% VAT")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .vat)
    }

    func testTopIntentMarginAndMarkup() {
        XCTAssertEqual(parser.parse("what margin is 40 on 120").candidates.first?.intent.type, .margin)
        XCTAssertEqual(parser.parse("what markup is 40 on cost 120").candidates.first?.intent.type, .markup)
    }

    func testEnglishMarginAndMarkupNaturalPhrasing() {
        XCTAssertEqual(parser.parse("what is the margin 40 on 120").candidates.first?.intent.type, .margin)
        XCTAssertEqual(parser.parse("what is the markup 40 on cost 120").candidates.first?.intent.type, .markup)
    }

    func testEnglishProfitPhraseMapsToMargin() {
        XCTAssertEqual(parser.parse("what is profit 40 on 120").candidates.first?.intent.type, .margin)
    }

    func testMarginPercentAmountPhrase() throws {
        let outcome = parser.parse("how much is 10% margin on 134")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOf)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected a parse candidate for margin amount phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 13.4, accuracy: 0.000_001)
    }

    func testProfitPercentAmountPhrase() throws {
        let outcome = parser.parse("how much is 10% profit on 134")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOf)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected a parse candidate for profit amount phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 13.4, accuracy: 0.000_001)
    }

    func testAmbiguousOnPattern() {
        let outcome = parser.parse("25% on 167")
        XCTAssertTrue(outcome.isAmbiguous)
        XCTAssertGreaterThanOrEqual(outcome.candidates.count, 2)

        let types = outcome.candidates.map { $0.intent.type }
        XCTAssertTrue(types.contains(.percentOf))
        XCTAssertTrue(types.contains(.addPercent))
    }

    func testDecimalCommaQuery() throws {
        let outcome = parser.parse("41,75 is what percent of 167")
        guard let intent = outcome.candidates.first?.intent else {
            XCTFail("Expected parse candidate")
            return
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 25, accuracy: 0.000_001)
    }

    func testUnknownInputProvidesHelpfulFailure() {
        let outcome = parser.parse("how are you today")
        XCTAssertTrue(outcome.candidates.isEmpty)
        XCTAssertNotNil(outcome.failureMessage)
    }

    func testGermanPercentOf() throws {
        let outcome = parser.parse("25% von 167")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOf)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected percent-of candidate for German input")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 41.75, accuracy: 0.000_001)
    }

    func testGermanAddPercent() {
        let outcome = parser.parse("167 plus 25 prozent")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .addPercent)
    }

    func testGermanSubtractPercent() {
        let outcome = parser.parse("899 minus 12 prozent")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .subtractPercent)
    }

    func testGermanPercentChange() throws {
        let outcome = parser.parse("von 80 auf 96")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentChange)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected percent-change candidate")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 20, accuracy: 0.000_001)
    }

    func testGermanPercentChangeVorherJetzt() throws {
        let outcome = parser.parse("vorher 100 jetzt 120")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentChange)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected percent-change candidate for 'vorher ... jetzt ...'")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 20, accuracy: 0.000_001)
    }

    func testEnglishPercentChangeBeforeNow() throws {
        let outcome = parser.parse("before 100 now 120")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentChange)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected percent-change candidate for 'before ... now ...'")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 20, accuracy: 0.000_001)
    }

    func testGermanDiscount() throws {
        let outcome = parser.parse("ich habe 134 statt 179 bezahlt")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .discountPercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected discount candidate")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 25.139_664, accuracy: 0.000_01)
    }

    func testGermanReversePercent() throws {
        let outcome = parser.parse("wenn 30 prozent sind 45 was sind 100 prozent")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected reverse-percent candidate")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 150, accuracy: 0.000_001)
    }

    func testGermanRelation() throws {
        let outcome = parser.parse("41,75 sind wie viel prozent von 167")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOfRelation)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected relation candidate")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 25, accuracy: 0.000_001)
    }

    func testGermanTipAndVat() {
        XCTAssertEqual(parser.parse("240 mit 15% trinkgeld").candidates.first?.intent.type, .tip)
        XCTAssertEqual(parser.parse("85 plus 19% mwst").candidates.first?.intent.type, .vat)
    }

    func testGermanMarginAndMarkup() {
        XCTAssertEqual(parser.parse("was ist marge 40 auf 120").candidates.first?.intent.type, .margin)
        XCTAssertEqual(parser.parse("was ist aufschlag 40 auf kosten 120").candidates.first?.intent.type, .markup)
    }

    func testGermanMarginAndMarkupWithArticles() {
        XCTAssertEqual(parser.parse("was ist die marge 40 auf 120").candidates.first?.intent.type, .margin)
        XCTAssertEqual(parser.parse("was ist der aufschlag 40 auf kosten 120").candidates.first?.intent.type, .markup)
    }

    func testGermanGewinnPhraseMapsToMargin() {
        XCTAssertEqual(parser.parse("was ist der gewinn von 40 auf 120").candidates.first?.intent.type, .margin)
    }

    func testGermanProfitPercentOfPhrase() throws {
        let outcome = parser.parse("was ist 10% gewinn von 230")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOf)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected percent-of candidate for German profit phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 23, accuracy: 0.000_001)
    }

    func testGermanMarginPercentAmountPhrase() throws {
        let outcome = parser.parse("wie viel sind 10% marge auf 134")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOf)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected percent-of candidate for German margin amount phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 13.4, accuracy: 0.000_001)
    }

    func testGermanAmbiguousAufPattern() {
        let outcome = parser.parse("25% auf 167")
        XCTAssertTrue(outcome.isAmbiguous)
        XCTAssertGreaterThanOrEqual(outcome.candidates.count, 2)

        let types = outcome.candidates.map { $0.intent.type }
        XCTAssertTrue(types.contains(.percentOf))
        XCTAssertTrue(types.contains(.addPercent))
    }
}
