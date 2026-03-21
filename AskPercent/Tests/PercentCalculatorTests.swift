import XCTest
@testable import AskPercent

final class PercentCalculatorTests: XCTestCase {
    private let calculator = PercentCalculator()

    func testPercentOf() throws {
        let result = try calculator.calculate(intent: .percentOf(percent: 25, base: 167))
        XCTAssertEqual(result.value, 41.75, accuracy: 0.000_001)
    }

    func testAddPercent() throws {
        let result = try calculator.calculate(intent: .addPercent(base: 167, percent: 25))
        XCTAssertEqual(result.value, 208.75, accuracy: 0.000_001)
    }

    func testSubtractPercent() throws {
        let result = try calculator.calculate(intent: .subtractPercent(base: 899, percent: 12))
        XCTAssertEqual(result.value, 791.12, accuracy: 0.000_001)
    }

    func testPercentChangeIncrease() throws {
        let result = try calculator.calculate(intent: .percentChange(old: 80, new: 96))
        XCTAssertEqual(result.value, 20, accuracy: 0.000_001)
    }

    func testPercentChangeDecrease() throws {
        let result = try calculator.calculate(intent: .percentChange(old: 96, new: 80))
        XCTAssertEqual(result.value, -16.666_666, accuracy: 0.000_01)
    }

    func testDiscountPercent() throws {
        let result = try calculator.calculate(intent: .discountPercent(original: 179, new: 134))
        XCTAssertEqual(result.value, 25.139_664, accuracy: 0.000_01)
    }

    func testReversePercent() throws {
        let result = try calculator.calculate(intent: .reversePercent(percent: 30, partial: 45))
        XCTAssertEqual(result.value, 150, accuracy: 0.000_001)
    }

    func testPercentOfRelation() throws {
        let result = try calculator.calculate(intent: .percentOfRelation(part: 41.75, whole: 167))
        XCTAssertEqual(result.value, 25, accuracy: 0.000_001)
    }

    func testMargin() throws {
        let result = try calculator.calculate(intent: .margin(profit: 40, revenue: 120))
        XCTAssertEqual(result.value, 33.333_333, accuracy: 0.000_01)
    }

    func testMarkup() throws {
        let result = try calculator.calculate(intent: .markup(profit: 40, cost: 120))
        XCTAssertEqual(result.value, 33.333_333, accuracy: 0.000_01)
    }

    func testDivideByZeroSafety() {
        XCTAssertThrowsError(try calculator.calculate(intent: .reversePercent(percent: 0, partial: 45)))
        XCTAssertThrowsError(try calculator.calculate(intent: .percentChange(old: 0, new: 4)))
        XCTAssertThrowsError(try calculator.calculate(intent: .percentOfRelation(part: 5, whole: 0)))
    }
}
