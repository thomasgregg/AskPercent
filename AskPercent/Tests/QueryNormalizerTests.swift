import XCTest
@testable import AskPercent

final class QueryNormalizerTests: XCTestCase {
    private let normalizer = QueryNormalizer()

    func testNormalizationLowercasesAndTrimsPunctuation() {
        let input = "  41,75 is WHAT percent of 167?  "
        let normalized = normalizer.normalize(input)
        XCTAssertEqual(normalized, "41,75 is what percent of 167")
    }

    func testNumberExtractionSupportsDecimalCommaAndPoint() {
        let query = normalizer.normalize("41,75 is what percent of 167 and 25.5%")
        let tokens = normalizer.extractNumericTokens(from: query)

        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0].value, 41.75, accuracy: 0.000_001)
        XCTAssertEqual(tokens[1].value, 167, accuracy: 0.000_001)
        XCTAssertEqual(tokens[2].value, 25.5, accuracy: 0.000_001)
        XCTAssertTrue(tokens[2].isPercent)
    }

    func testParseNumberForCommaAndDot() {
        guard let comma = QueryNormalizer.parseNumber("41,75") else {
            return XCTFail("Expected decimal comma parsing")
        }
        guard let dot = QueryNormalizer.parseNumber("41.75") else {
            return XCTFail("Expected decimal point parsing")
        }
        guard let grouped = QueryNormalizer.parseNumber("1,234") else {
            return XCTFail("Expected grouped number parsing")
        }

        XCTAssertEqual(comma, 41.75, accuracy: 0.000_001)
        XCTAssertEqual(dot, 41.75, accuracy: 0.000_001)
        XCTAssertEqual(grouped, 1234, accuracy: 0.000_001)
    }
}
