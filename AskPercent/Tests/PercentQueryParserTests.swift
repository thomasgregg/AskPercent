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

    func testTopIntentSubtractPercentWithWords() throws {
        let subtract = parser.parse("100 subtract 10%")
        XCTAssertEqual(subtract.candidates.first?.intent.type, .subtractPercent)
        guard let subtractIntent = subtract.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for 'subtract' wording")
        }
        XCTAssertEqual(try calculator.calculate(intent: subtractIntent).value, 90, accuracy: 0.000_001)

        let substract = parser.parse("100 substract 10%")
        XCTAssertEqual(substract.candidates.first?.intent.type, .subtractPercent)
        guard let substractIntent = substract.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for 'substract' wording")
        }
        XCTAssertEqual(try calculator.calculate(intent: substractIntent).value, 90, accuracy: 0.000_001)
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

    func testEnglishDiscountFromToPhrase() throws {
        let outcome = parser.parse("what is the discount from 179 to 134")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .discountPercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected discount candidate for explicit discount from-to phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 25.139_664, accuracy: 0.000_01)
    }

    func testEnglishDiscountRatePhrases() throws {
        let withDiscount = parser.parse("100 with 20% discount")
        XCTAssertEqual(withDiscount.candidates.first?.intent.type, .subtractPercent)
        guard let withDiscountIntent = withDiscount.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for 'with discount' phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: withDiscountIntent).value, 80, accuracy: 0.000_001)

        let percentFirst = parser.parse("20% discount on 100")
        XCTAssertEqual(percentFirst.candidates.first?.intent.type, .subtractPercent)
        guard let percentFirstIntent = percentFirst.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for percent-first discount phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: percentFirstIntent).value, 80, accuracy: 0.000_001)
    }

    func testTopIntentReversePercent() {
        let outcome = parser.parse("if 30% is 45 what is 100%")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)
    }

    func testReversePercentWithTargetPercentEnglish() throws {
        let outcome = parser.parse("if 30% is 45 what is 50%")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected reverse-percent target candidate")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 75, accuracy: 0.000_001)
    }

    func testReversePercentWithTargetPercentEnglishReturnsNumber() throws {
        let outcome = parser.parse("if 10% is 50 what is 50%")
        XCTAssertFalse(outcome.isAmbiguous)
        XCTAssertEqual(outcome.candidates.count, 1)
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected reverse-percent target candidate")
        }

        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 250, accuracy: 0.000_001)
        XCTAssertFalse(result.isPercentValue)
    }

    func testReversePercentWithTargetPercentPartFirstEnglish() throws {
        let outcome = parser.parse("if 40 is 10% what is 50%")
        XCTAssertFalse(outcome.isAmbiguous)
        XCTAssertEqual(outcome.candidates.count, 1)
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected reverse-percent target candidate for part-first English phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 200, accuracy: 0.000_001)
    }

    func testReversePercentFindPercentPartFirstEnglish() throws {
        let outcome = parser.parse("if 40 is 10% what is 50")
        XCTAssertFalse(outcome.isAmbiguous)
        XCTAssertEqual(outcome.candidates.count, 1)
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected reverse-percent find-percent candidate")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 12.5, accuracy: 0.000_001)
        XCTAssertTrue(result.isPercentValue)
    }

    func testReversePercentFindPercentExplicitPercentQuestionEnglish() throws {
        let outcome = parser.parse("if 40 is 10% what percent is 50")
        XCTAssertFalse(outcome.isAmbiguous)
        XCTAssertEqual(outcome.candidates.count, 1)
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected reverse-percent find-percent candidate for explicit percent question")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 12.5, accuracy: 0.000_001)
    }

    func testReversePercentWithExplicitTargetIsNotAmbiguous() {
        let outcome = parser.parse("if 30% is 45 what is 90%")
        XCTAssertFalse(outcome.isAmbiguous)
        XCTAssertEqual(outcome.candidates.count, 1)
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)
    }

    func testReversePercentWithExplicitHundredDoesNotDuplicate() {
        let outcome = parser.parse("if 30% is 45 what is 100%")
        XCTAssertFalse(outcome.isAmbiguous)
        XCTAssertEqual(outcome.candidates.count, 1)
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)
    }

    func testReversePercentSwappedOrderEnglish() throws {
        let outcome = parser.parse("20 is 115%")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected reverse-percent candidate for swapped English order")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 17.391_304, accuracy: 0.000_001)
    }

    func testEnglishReversePercentNaturalWholePhrases() throws {
        let cases: [(query: String, expected: Double)] = [
            ("10% is 5 - what is the total value?", 50),
            ("25% is 50 - what is the whole?", 200),
            ("20% are 40 - how much is 100%?", 200),
            ("5% is 10 - what is the base value?", 200)
        ]

        for test in cases {
            let outcome = parser.parse(test.query)
            XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent, "Unexpected intent for: \(test.query)")

            guard let intent = outcome.candidates.first?.intent else {
                return XCTFail("Expected reverse-percent candidate for: \(test.query)")
            }

            let result = try calculator.calculate(intent: intent)
            XCTAssertEqual(result.value, test.expected, accuracy: 0.000_001, "Unexpected result for: \(test.query)")
        }
    }

    func testTopIntentRelation() {
        let outcome = parser.parse("41.75 is what percent of 167")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOfRelation)
    }

    func testEnglishRelationWithPercentSymbol() throws {
        let outcome = parser.parse("100 is what % of 1000")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOfRelation)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected relation candidate for English '%' phrasing")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 10, accuracy: 0.000_001)
        XCTAssertTrue(result.isPercentValue)
    }

    func testTopIntentRelationShorthand() throws {
        let outcome = parser.parse("100 of 200")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOfRelation)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected relation candidate for shorthand phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 50, accuracy: 0.000_001)
    }

    func testTopIntentTip() {
        let outcome = parser.parse("240 with 15% tip")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .tip)
    }

    func testTopIntentVat() {
        let outcome = parser.parse("85 plus 19% VAT")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .vat)
    }

    func testEnglishFinancialTaxContextPhrases() throws {
        let netVat = parser.parse("100 net plus 19% vat")
        XCTAssertEqual(netVat.candidates.first?.intent.type, .vat)
        guard let netVatIntent = netVat.candidates.first?.intent else {
            return XCTFail("Expected VAT candidate for net + VAT phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: netVatIntent).value, 119, accuracy: 0.000_001)

        let beforeTax = parser.parse("100 before tax plus 20% tax")
        XCTAssertEqual(beforeTax.candidates.first?.intent.type, .tax)
        guard let beforeTaxIntent = beforeTax.candidates.first?.intent else {
            return XCTFail("Expected tax candidate for before-tax phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: beforeTaxIntent).value, 120, accuracy: 0.000_001)

        let afterTaxMinus = parser.parse("120 after tax minus 20% tax")
        XCTAssertEqual(afterTaxMinus.candidates.first?.intent.type, .subtractPercent)
        guard let afterTaxMinusIntent = afterTaxMinus.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent candidate for after-tax minus phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: afterTaxMinusIntent).value, 96, accuracy: 0.000_001)
    }

    func testTaxAbbreviationCoverage() throws {
        let salesTax = parser.parse("100 plus 7% sales tax")
        XCTAssertEqual(salesTax.candidates.first?.intent.type, .tax)
        guard let salesTaxIntent = salesTax.candidates.first?.intent else {
            return XCTFail("Expected sales tax candidate")
        }
        XCTAssertEqual(try calculator.calculate(intent: salesTaxIntent).value, 107, accuracy: 0.000_001)

        let gst = parser.parse("100 plus 7% gst")
        XCTAssertEqual(gst.candidates.first?.intent.type, .vat)
        guard let gstIntent = gst.candidates.first?.intent else {
            return XCTFail("Expected GST candidate")
        }
        XCTAssertEqual(try calculator.calculate(intent: gstIntent).value, 107, accuracy: 0.000_001)

        let iva = parser.parse("100 plus 7% iva")
        XCTAssertEqual(iva.candidates.first?.intent.type, .vat)
        guard let ivaIntent = iva.candidates.first?.intent else {
            return XCTFail("Expected IVA candidate")
        }
        XCTAssertEqual(try calculator.calculate(intent: ivaIntent).value, 107, accuracy: 0.000_001)

        let addTax = parser.parse("100 add 10% tax")
        XCTAssertEqual(addTax.candidates.first?.intent.type, .tax)
        guard let addTaxIntent = addTax.candidates.first?.intent else {
            return XCTFail("Expected tax candidate for add connector")
        }
        XCTAssertEqual(try calculator.calculate(intent: addTaxIntent).value, 110, accuracy: 0.000_001)
    }

    func testTaxPresetWithoutExplicitRateEnglish() throws {
        let presetParser = PercentQueryParser(defaultTaxPercent: 19)

        let plusTax = presetParser.parse("100 plus tax")
        XCTAssertEqual(plusTax.candidates.first?.intent.type, .tax)
        guard let plusTaxIntent = plusTax.candidates.first?.intent else {
            return XCTFail("Expected tax candidate using preset")
        }
        XCTAssertEqual(try calculator.calculate(intent: plusTaxIntent).value, 119, accuracy: 0.000_001)

        let minusTax = presetParser.parse("100 minus tax")
        XCTAssertEqual(minusTax.candidates.first?.intent.type, .subtractPercent)
        guard let minusTaxIntent = minusTax.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent candidate using preset")
        }
        XCTAssertEqual(try calculator.calculate(intent: minusTaxIntent).value, 81, accuracy: 0.000_001)

        let incVat = presetParser.parse("100 inc vat")
        XCTAssertEqual(incVat.candidates.first?.intent.type, .vat)
        guard let incVatIntent = incVat.candidates.first?.intent else {
            return XCTFail("Expected VAT candidate for inc VAT using preset")
        }
        XCTAssertEqual(try calculator.calculate(intent: incVatIntent).value, 119, accuracy: 0.000_001)

        let addTax = presetParser.parse("100 add tax")
        XCTAssertEqual(addTax.candidates.first?.intent.type, .tax)
        guard let addTaxIntent = addTax.candidates.first?.intent else {
            return XCTFail("Expected tax candidate for add-tax using preset")
        }
        XCTAssertEqual(try calculator.calculate(intent: addTaxIntent).value, 119, accuracy: 0.000_001)

        let plusSymbolTax = presetParser.parse("100 + tax")
        XCTAssertEqual(plusSymbolTax.candidates.first?.intent.type, .tax)
        guard let plusSymbolTaxIntent = plusSymbolTax.candidates.first?.intent else {
            return XCTFail("Expected tax candidate for plus-symbol tax using preset")
        }
        XCTAssertEqual(try calculator.calculate(intent: plusSymbolTaxIntent).value, 119, accuracy: 0.000_001)

        let minusSymbolTax = presetParser.parse("100 - tax")
        XCTAssertEqual(minusSymbolTax.candidates.first?.intent.type, .subtractPercent)
        guard let minusSymbolTaxIntent = minusSymbolTax.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent candidate for minus-symbol tax using preset")
        }
        XCTAssertEqual(try calculator.calculate(intent: minusSymbolTaxIntent).value, 81, accuracy: 0.000_001)

        let reduceTax = presetParser.parse("100 reduce tax")
        XCTAssertEqual(reduceTax.candidates.first?.intent.type, .subtractPercent)
        guard let reduceTaxIntent = reduceTax.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent candidate for reduce-tax using preset")
        }
        XCTAssertEqual(try calculator.calculate(intent: reduceTaxIntent).value, 81, accuracy: 0.000_001)
    }

    func testTaxPresetWithoutExplicitRateGerman() throws {
        let presetParser = PercentQueryParser(defaultTaxPercent: 19)

        let plusMwst = presetParser.parse("100 zzgl mwst")
        XCTAssertEqual(plusMwst.candidates.first?.intent.type, .vat)
        guard let plusMwstIntent = plusMwst.candidates.first?.intent else {
            return XCTFail("Expected VAT candidate using preset for German query")
        }
        XCTAssertEqual(try calculator.calculate(intent: plusMwstIntent).value, 119, accuracy: 0.000_001)

        let minusSteuer = presetParser.parse("120 brutto ohne steuer")
        XCTAssertEqual(minusSteuer.candidates.first?.intent.type, .subtractPercent)
        guard let minusSteuerIntent = minusSteuer.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent candidate using preset for German query")
        }
        XCTAssertEqual(try calculator.calculate(intent: minusSteuerIntent).value, 97.2, accuracy: 0.000_001)
    }

    func testTaxWordWithoutPresetDoesNotInferRate() {
        let noPresetParser = PercentQueryParser(defaultTaxPercent: nil)
        let samples = [
            "100 plus tax",
            "100 add tax",
            "100 minus tax",
            "100 reduce tax",
            "100 + tax",
            "100 - tax"
        ]

        for sample in samples {
            let outcome = noPresetParser.parse(sample)
            XCTAssertTrue(outcome.candidates.isEmpty, "Expected no candidates for: \(sample)")
            XCTAssertEqual(outcome.failureReason, .taxPresetMissing, "Expected tax preset missing for: \(sample)")
        }
    }

    func testTopIntentMarginAndMarkup() {
        XCTAssertEqual(parser.parse("what margin is 40 on 120").candidates.first?.intent.type, .margin)
        XCTAssertEqual(parser.parse("what markup is 40 on cost 120").candidates.first?.intent.type, .markup)
    }

    func testEnglishMarginAndMarkupNaturalPhrasing() {
        XCTAssertEqual(parser.parse("what is the margin 40 on 120").candidates.first?.intent.type, .margin)
        XCTAssertEqual(parser.parse("what is the markup 40 on cost 120").candidates.first?.intent.type, .markup)
    }

    func testEnglishMarkupWithCostOfPhrase() {
        XCTAssertEqual(parser.parse("what markup is 40 on cost of 120").candidates.first?.intent.type, .markup)
    }

    func testEnglishMarkupRatePhrases() throws {
        let withMarkup = parser.parse("100 with 20% markup")
        XCTAssertEqual(withMarkup.candidates.first?.intent.type, .addPercent)
        guard let withMarkupIntent = withMarkup.candidates.first?.intent else {
            return XCTFail("Expected add-percent for 'with markup' phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: withMarkupIntent).value, 120, accuracy: 0.000_001)

        let percentFirst = parser.parse("20% markup on 100")
        XCTAssertEqual(percentFirst.candidates.first?.intent.type, .addPercent)
        guard let percentFirstIntent = percentFirst.candidates.first?.intent else {
            return XCTFail("Expected add-percent for percent-first markup phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: percentFirstIntent).value, 120, accuracy: 0.000_001)
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

    func testGermanRabattVonAufPhrase() throws {
        let outcome = parser.parse("wie hoch ist der rabatt von 179 auf 134")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .discountPercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected discount candidate for explicit rabatt-von-auf phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 25.139_664, accuracy: 0.000_01)
    }

    func testGermanDiscountRatePhrases() throws {
        let mitRabatt = parser.parse("100 mit 20% rabatt")
        XCTAssertEqual(mitRabatt.candidates.first?.intent.type, .subtractPercent)
        guard let mitRabattIntent = mitRabatt.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for German rabatt phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: mitRabattIntent).value, 80, accuracy: 0.000_001)

        let percentFirst = parser.parse("20% rabatt auf 100")
        XCTAssertEqual(percentFirst.candidates.first?.intent.type, .subtractPercent)
        guard let percentFirstIntent = percentFirst.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for German percent-first rabatt phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: percentFirstIntent).value, 80, accuracy: 0.000_001)
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

    func testReversePercentWithTargetPercentGerman() throws {
        let outcome = parser.parse("wenn 30 prozent sind 45 was sind 50 prozent")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected reverse-percent target candidate for German phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 75, accuracy: 0.000_001)
    }

    func testReversePercentFindPercentPartFirstGerman() throws {
        let outcome = parser.parse("wenn 40 sind 10 prozent was sind 50")
        XCTAssertFalse(outcome.isAmbiguous)
        XCTAssertEqual(outcome.candidates.count, 1)
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected reverse-percent find-percent candidate for German phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 12.5, accuracy: 0.000_001)
        XCTAssertTrue(result.isPercentValue)
    }

    func testReversePercentSwappedOrderGerman() throws {
        let outcome = parser.parse("20 sind 115%")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected reverse-percent candidate for swapped German order")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 17.391_304, accuracy: 0.000_001)
    }

    func testGermanReversePercentNaturalWholePhrases() throws {
        let cases: [(query: String, expected: Double)] = [
            ("10 % sind 5 – wie groß ist der Gesamtwert?", 50),
            ("25 % sind 50 – wie groß ist das Ganze?", 200),
            ("20 % sind 40 – wie viel sind 100 %?", 200),
            ("5 % sind 10 – wie groß ist der Grundwert?", 200)
        ]

        for test in cases {
            let outcome = parser.parse(test.query)
            XCTAssertEqual(outcome.candidates.first?.intent.type, .reversePercent, "Unexpected intent for: \(test.query)")

            guard let intent = outcome.candidates.first?.intent else {
                return XCTFail("Expected reverse-percent candidate for: \(test.query)")
            }

            let result = try calculator.calculate(intent: intent)
            XCTAssertEqual(result.value, test.expected, accuracy: 0.000_001, "Unexpected result for: \(test.query)")
        }
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

    func testGermanRelationWithPercentSymbol() throws {
        let outcome = parser.parse("100 ist wieviel % von 1000")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOfRelation)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected relation candidate for German '%' phrasing")
        }

        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 10, accuracy: 0.000_001)
        XCTAssertTrue(result.isPercentValue)
    }

    func testGermanRelationShorthand() throws {
        let outcome = parser.parse("100 von 200")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentOfRelation)

        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected German relation candidate for shorthand phrase")
        }
        let result = try calculator.calculate(intent: intent)
        XCTAssertEqual(result.value, 50, accuracy: 0.000_001)
    }

    func testGermanTipAndVat() {
        XCTAssertEqual(parser.parse("240 mit 15% trinkgeld").candidates.first?.intent.type, .tip)
        XCTAssertEqual(parser.parse("85 plus 19% mwst").candidates.first?.intent.type, .vat)
    }

    func testGermanFinancialTaxContextPhrases() throws {
        let nettoUst = parser.parse("100 netto zzgl 19% ust")
        XCTAssertEqual(nettoUst.candidates.first?.intent.type, .vat)
        guard let nettoUstIntent = nettoUst.candidates.first?.intent else {
            return XCTFail("Expected VAT candidate for netto + USt phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: nettoUstIntent).value, 119, accuracy: 0.000_001)

        let vorSteuer = parser.parse("100 vor steuer plus 10% steuer")
        XCTAssertEqual(vorSteuer.candidates.first?.intent.type, .tax)
        guard let vorSteuerIntent = vorSteuer.candidates.first?.intent else {
            return XCTFail("Expected tax candidate for vor steuer phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: vorSteuerIntent).value, 110, accuracy: 0.000_001)

        let bruttoMinus = parser.parse("120 brutto minus 20% steuer")
        XCTAssertEqual(bruttoMinus.candidates.first?.intent.type, .subtractPercent)
        guard let bruttoMinusIntent = bruttoMinus.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent candidate for brutto minus phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: bruttoMinusIntent).value, 96, accuracy: 0.000_001)
    }

    func testGermanMarginAndMarkup() {
        XCTAssertEqual(parser.parse("was ist marge 40 auf 120").candidates.first?.intent.type, .margin)
        XCTAssertEqual(parser.parse("was ist aufschlag 40 auf kosten 120").candidates.first?.intent.type, .markup)
    }

    func testGermanMarginAndMarkupWithArticles() {
        XCTAssertEqual(parser.parse("was ist die marge 40 auf 120").candidates.first?.intent.type, .margin)
        XCTAssertEqual(parser.parse("was ist der aufschlag 40 auf kosten 120").candidates.first?.intent.type, .markup)
    }

    func testGermanMarkupWithKostenVonPhrase() {
        XCTAssertEqual(parser.parse("was ist der aufschlag 40 auf kosten von 120").candidates.first?.intent.type, .markup)
    }

    func testGermanAufschlagRatePhrases() throws {
        let mitAufschlag = parser.parse("100 mit 20% aufschlag")
        XCTAssertEqual(mitAufschlag.candidates.first?.intent.type, .addPercent)
        guard let mitAufschlagIntent = mitAufschlag.candidates.first?.intent else {
            return XCTFail("Expected add-percent for German aufschlag phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: mitAufschlagIntent).value, 120, accuracy: 0.000_001)

        let percentFirst = parser.parse("20% aufschlag auf 100")
        XCTAssertEqual(percentFirst.candidates.first?.intent.type, .addPercent)
        guard let percentFirstIntent = percentFirst.candidates.first?.intent else {
            return XCTFail("Expected add-percent for German percent-first aufschlag phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: percentFirstIntent).value, 120, accuracy: 0.000_001)
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

    func testParserSupportsGroupedNumberFormats() throws {
        let english = parser.parse("12.5% of 1'234.56")
        XCTAssertEqual(english.candidates.first?.intent.type, .percentOf)
        guard let englishIntent = english.candidates.first?.intent else {
            return XCTFail("Expected English grouped-number percent-of candidate")
        }
        let englishResult = try calculator.calculate(intent: englishIntent)
        XCTAssertEqual(englishResult.value, 154.32, accuracy: 0.000_001)

        let german = parser.parse("12,5% von 1 234,56")
        XCTAssertEqual(german.candidates.first?.intent.type, .percentOf)
        guard let germanIntent = german.candidates.first?.intent else {
            return XCTFail("Expected German grouped-number percent-of candidate")
        }
        let germanResult = try calculator.calculate(intent: germanIntent)
        XCTAssertEqual(germanResult.value, 154.32, accuracy: 0.000_001)
    }

    func testDecimalPercentInputs() throws {
        let dotOutcome = parser.parse("12.5% of 200")
        XCTAssertEqual(dotOutcome.candidates.first?.intent.type, .percentOf)
        guard let dotIntent = dotOutcome.candidates.first?.intent else {
            return XCTFail("Expected decimal-dot percent candidate")
        }
        XCTAssertEqual(try calculator.calculate(intent: dotIntent).value, 25, accuracy: 0.000_001)

        let commaOutcome = parser.parse("12,5% von 200")
        XCTAssertEqual(commaOutcome.candidates.first?.intent.type, .percentOf)
        guard let commaIntent = commaOutcome.candidates.first?.intent else {
            return XCTFail("Expected decimal-comma percent candidate")
        }
        XCTAssertEqual(try calculator.calculate(intent: commaIntent).value, 25, accuracy: 0.000_001)
    }

    func testNegativeAndZeroPercentValues() throws {
        let negativeOutcome = parser.parse("-20% of 50")
        XCTAssertEqual(negativeOutcome.candidates.first?.intent.type, .percentOf)
        guard let negativeIntent = negativeOutcome.candidates.first?.intent else {
            return XCTFail("Expected negative percent-of candidate")
        }
        XCTAssertEqual(try calculator.calculate(intent: negativeIntent).value, -10, accuracy: 0.000_001)

        let zeroOutcome = parser.parse("0% of 900")
        XCTAssertEqual(zeroOutcome.candidates.first?.intent.type, .percentOf)
        guard let zeroIntent = zeroOutcome.candidates.first?.intent else {
            return XCTFail("Expected zero percent-of candidate")
        }
        XCTAssertEqual(try calculator.calculate(intent: zeroIntent).value, 0, accuracy: 0.000_001)
    }

    func testDivideByZeroSurfaceForPercentChange() {
        let outcome = parser.parse("from 0 to 10")
        XCTAssertEqual(outcome.candidates.first?.intent.type, .percentChange)
        guard let intent = outcome.candidates.first?.intent else {
            return XCTFail("Expected percent-change candidate")
        }
        XCTAssertThrowsError(try calculator.calculate(intent: intent))
    }

    func testIncreaseDecreaseByPatterns() throws {
        let increase = parser.parse("increase 100 by 20%")
        XCTAssertEqual(increase.candidates.first?.intent.type, .addPercent)
        guard let increaseIntent = increase.candidates.first?.intent else {
            return XCTFail("Expected add-percent candidate for increase by")
        }
        XCTAssertEqual(try calculator.calculate(intent: increaseIntent).value, 120, accuracy: 0.000_001)

        let decrease = parser.parse("decrease 100 by 20%")
        XCTAssertEqual(decrease.candidates.first?.intent.type, .subtractPercent)
        guard let decreaseIntent = decrease.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent candidate for decrease by")
        }
        XCTAssertEqual(try calculator.calculate(intent: decreaseIntent).value, 80, accuracy: 0.000_001)
    }

    func testNowThenPercentChangeVariants() throws {
        let english = parser.parse("was 80 now 96")
        XCTAssertEqual(english.candidates.first?.intent.type, .percentChange)
        guard let englishIntent = english.candidates.first?.intent else {
            return XCTFail("Expected percent-change candidate for 'was ... now ...'")
        }
        XCTAssertEqual(try calculator.calculate(intent: englishIntent).value, 20, accuracy: 0.000_001)

        let german = parser.parse("war 80 jetzt 96")
        XCTAssertEqual(german.candidates.first?.intent.type, .percentChange)
        guard let germanIntent = german.candidates.first?.intent else {
            return XCTFail("Expected percent-change candidate for 'war ... jetzt ...'")
        }
        XCTAssertEqual(try calculator.calculate(intent: germanIntent).value, 20, accuracy: 0.000_001)
    }

    func testReversePercentWholeSynonyms() {
        XCTAssertEqual(parser.parse("20% is 30 what is the original amount").candidates.first?.intent.type, .reversePercent)
        XCTAssertEqual(parser.parse("20% sind 30 wie groß ist der grundbetrag").candidates.first?.intent.type, .reversePercent)
    }

    func testVatInclusivePhrasing() {
        XCTAssertEqual(parser.parse("price incl. 19% VAT").candidates.first?.intent.type, .vat)
        XCTAssertEqual(parser.parse("preis inkl. 19% mwst").candidates.first?.intent.type, .vat)
    }

    func testMarginNounVariants() {
        XCTAssertEqual(parser.parse("gross margin 40 on 120").candidates.first?.intent.type, .margin)
        XCTAssertEqual(parser.parse("bruttomarge 40 auf 120").candidates.first?.intent.type, .margin)
        XCTAssertEqual(parser.parse("handelsspanne 40 auf 120").candidates.first?.intent.type, .margin)
    }

    func testAmbiguousOnPatternWithoutPercentSymbol() {
        let outcome = parser.parse("25 on 167")
        XCTAssertTrue(outcome.isAmbiguous)
        XCTAssertGreaterThanOrEqual(outcome.candidates.count, 2)

        let types = outcome.candidates.map { $0.intent.type }
        XCTAssertTrue(types.contains(.percentOf))
        XCTAssertTrue(types.contains(.addPercent))
    }

    func testEnglishDiscountRateKeywordFirstAndConnectorKeywordForms() throws {
        let keywordFirst = parser.parse("discount 10% on 100")
        XCTAssertEqual(keywordFirst.candidates.first?.intent.type, .subtractPercent)
        guard let keywordFirstIntent = keywordFirst.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for keyword-first discount phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: keywordFirstIntent).value, 90, accuracy: 0.000_001)

        let connectorKeyword = parser.parse("100 with discount 10%")
        XCTAssertEqual(connectorKeyword.candidates.first?.intent.type, .subtractPercent)
        guard let connectorKeywordIntent = connectorKeyword.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for connector+keyword discount phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: connectorKeywordIntent).value, 90, accuracy: 0.000_001)
    }

    func testEnglishMarkupRateKeywordFirstAndConnectorKeywordForms() throws {
        let keywordFirst = parser.parse("markup 10% on 100")
        XCTAssertEqual(keywordFirst.candidates.first?.intent.type, .addPercent)
        guard let keywordFirstIntent = keywordFirst.candidates.first?.intent else {
            return XCTFail("Expected add-percent for keyword-first markup phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: keywordFirstIntent).value, 110, accuracy: 0.000_001)

        let connectorKeyword = parser.parse("100 with markup 10%")
        XCTAssertEqual(connectorKeyword.candidates.first?.intent.type, .addPercent)
        guard let connectorKeywordIntent = connectorKeyword.candidates.first?.intent else {
            return XCTFail("Expected add-percent for connector+keyword markup phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: connectorKeywordIntent).value, 110, accuracy: 0.000_001)
    }

    func testGermanDiscountRateKeywordFirstAndConnectorKeywordForms() throws {
        let keywordFirst = parser.parse("rabatt 10% auf 100")
        XCTAssertEqual(keywordFirst.candidates.first?.intent.type, .subtractPercent)
        guard let keywordFirstIntent = keywordFirst.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for German keyword-first rabatt phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: keywordFirstIntent).value, 90, accuracy: 0.000_001)

        let connectorKeyword = parser.parse("100 mit rabatt 10%")
        XCTAssertEqual(connectorKeyword.candidates.first?.intent.type, .subtractPercent)
        guard let connectorKeywordIntent = connectorKeyword.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for German connector+keyword rabatt phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: connectorKeywordIntent).value, 90, accuracy: 0.000_001)
    }

    func testGermanAufschlagRateKeywordFirstAndConnectorKeywordForms() throws {
        let keywordFirst = parser.parse("aufschlag 10% auf 100")
        XCTAssertEqual(keywordFirst.candidates.first?.intent.type, .addPercent)
        guard let keywordFirstIntent = keywordFirst.candidates.first?.intent else {
            return XCTFail("Expected add-percent for German keyword-first aufschlag phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: keywordFirstIntent).value, 110, accuracy: 0.000_001)

        let connectorKeyword = parser.parse("100 mit aufschlag 10%")
        XCTAssertEqual(connectorKeyword.candidates.first?.intent.type, .addPercent)
        guard let connectorKeywordIntent = connectorKeyword.candidates.first?.intent else {
            return XCTFail("Expected add-percent for German connector+keyword aufschlag phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: connectorKeywordIntent).value, 110, accuracy: 0.000_001)
    }

    func testRelationOutOfAndAusPatterns() throws {
        let outOf = parser.parse("100 out of 200")
        XCTAssertEqual(outOf.candidates.first?.intent.type, .percentOfRelation)
        guard let outOfIntent = outOf.candidates.first?.intent else {
            return XCTFail("Expected relation candidate for out-of phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: outOfIntent).value, 50, accuracy: 0.000_001)

        let aus = parser.parse("100 aus 200")
        XCTAssertEqual(aus.candidates.first?.intent.type, .percentOfRelation)
        guard let ausIntent = aus.candidates.first?.intent else {
            return XCTFail("Expected relation candidate for aus phrase")
        }
        XCTAssertEqual(try calculator.calculate(intent: ausIntent).value, 50, accuracy: 0.000_001)
    }

    func testTaxIncludeConnectors() throws {
        let includeTax = parser.parse("100 include 10% tax")
        XCTAssertEqual(includeTax.candidates.first?.intent.type, .tax)
        guard let includeTaxIntent = includeTax.candidates.first?.intent else {
            return XCTFail("Expected tax candidate for include connector")
        }
        XCTAssertEqual(try calculator.calculate(intent: includeTaxIntent).value, 110, accuracy: 0.000_001)

        let includedTax = parser.parse("100 included 10% tax")
        XCTAssertEqual(includedTax.candidates.first?.intent.type, .tax)
        guard let includedTaxIntent = includedTax.candidates.first?.intent else {
            return XCTFail("Expected tax candidate for included connector")
        }
        XCTAssertEqual(try calculator.calculate(intent: includedTaxIntent).value, 110, accuracy: 0.000_001)
    }

    func testTaxPresetIncludeWithoutRate() throws {
        let presetParser = PercentQueryParser(defaultTaxPercent: 19)
        let inclVat = presetParser.parse("100 incl vat")
        XCTAssertEqual(inclVat.candidates.first?.intent.type, .vat)
        guard let inclVatIntent = inclVat.candidates.first?.intent else {
            return XCTFail("Expected VAT candidate for incl VAT using preset")
        }
        XCTAssertEqual(try calculator.calculate(intent: inclVatIntent).value, 119, accuracy: 0.000_001)

        let includeTax = presetParser.parse("100 include tax")
        XCTAssertEqual(includeTax.candidates.first?.intent.type, .tax)
        guard let includeTaxIntent = includeTax.candidates.first?.intent else {
            return XCTFail("Expected tax candidate for include tax using preset")
        }
        XCTAssertEqual(try calculator.calculate(intent: includeTaxIntent).value, 119, accuracy: 0.000_001)
    }

    func testCommandAndByFirstOrderPatterns() throws {
        let addTo = parser.parse("add 10% to 100")
        XCTAssertEqual(addTo.candidates.first?.intent.type, .addPercent)
        guard let addToIntent = addTo.candidates.first?.intent else {
            return XCTFail("Expected add-percent for command add-to wording")
        }
        XCTAssertEqual(try calculator.calculate(intent: addToIntent).value, 110, accuracy: 0.000_001)

        let subtractFrom = parser.parse("subtract 10% from 100")
        XCTAssertEqual(subtractFrom.candidates.first?.intent.type, .subtractPercent)
        guard let subtractFromIntent = subtractFrom.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for command subtract-from wording")
        }
        XCTAssertEqual(try calculator.calculate(intent: subtractFromIntent).value, 90, accuracy: 0.000_001)

        let substractFrom = parser.parse("substract 10% from 100")
        XCTAssertEqual(substractFrom.candidates.first?.intent.type, .subtractPercent)
        guard let substractFromIntent = substractFrom.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for command substract-from wording")
        }
        XCTAssertEqual(try calculator.calculate(intent: substractFromIntent).value, 90, accuracy: 0.000_001)

        let increaseByFirst = parser.parse("increase by 10% 100")
        XCTAssertEqual(increaseByFirst.candidates.first?.intent.type, .addPercent)
        guard let increaseByFirstIntent = increaseByFirst.candidates.first?.intent else {
            return XCTFail("Expected add-percent for increase-by-first wording")
        }
        XCTAssertEqual(try calculator.calculate(intent: increaseByFirstIntent).value, 110, accuracy: 0.000_001)

        let decreaseByFirst = parser.parse("decrease by 10% 100")
        XCTAssertEqual(decreaseByFirst.candidates.first?.intent.type, .subtractPercent)
        guard let decreaseByFirstIntent = decreaseByFirst.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for decrease-by-first wording")
        }
        XCTAssertEqual(try calculator.calculate(intent: decreaseByFirstIntent).value, 90, accuracy: 0.000_001)

        let reduceByFirst = parser.parse("reduce by 10% from 100")
        XCTAssertEqual(reduceByFirst.candidates.first?.intent.type, .subtractPercent)
        guard let reduceByFirstIntent = reduceByFirst.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for reduce-by-first wording")
        }
        XCTAssertEqual(try calculator.calculate(intent: reduceByFirstIntent).value, 90, accuracy: 0.000_001)
    }

    func testGermanReduceVerbForms() throws {
        let reduziert = parser.parse("100 reduziert 10 prozent")
        XCTAssertEqual(reduziert.candidates.first?.intent.type, .subtractPercent)
        guard let reduziertIntent = reduziert.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for reduziert wording")
        }
        XCTAssertEqual(try calculator.calculate(intent: reduziertIntent).value, 90, accuracy: 0.000_001)

        let reduziere = parser.parse("reduziere 100 um 10 prozent")
        XCTAssertEqual(reduziere.candidates.first?.intent.type, .subtractPercent)
        guard let reduziereIntent = reduziere.candidates.first?.intent else {
            return XCTFail("Expected subtract-percent for reduziere-um wording")
        }
        XCTAssertEqual(try calculator.calculate(intent: reduziereIntent).value, 90, accuracy: 0.000_001)
    }
}
