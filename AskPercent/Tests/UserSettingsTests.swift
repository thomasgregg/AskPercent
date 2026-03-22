import XCTest
@testable import AskPercent

final class UserSettingsTests: XCTestCase {
    func testDefaultLanguageUsesSystem() {
        XCTAssertEqual(UserSettings.default.language, .system)
        XCTAssertFalse(UserSettings.default.taxPresetEnabled)
        XCTAssertEqual(UserSettings.default.taxPresetPercent, 19, accuracy: 0.000_001)
    }

    func testExplicitLanguageResolution() {
        XCTAssertEqual(AppLanguage.english.resolved, .english)
        XCTAssertEqual(AppLanguage.german.resolved, .german)
        XCTAssertEqual(AppLanguage.system.resolved, AppLanguage.localeResolvedLanguage)
    }

    func testDecodeLegacySettingsWithoutLanguageFallsBackToSystem() throws {
        let json = """
        {
          "decimalPrecision": 3,
          "showFormula": true,
          "hapticsEnabled": false,
          "numberFormatStyle": "us"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(UserSettings.self, from: json)
        XCTAssertEqual(decoded.language, .system)
        XCTAssertEqual(decoded.decimalPrecision, 3)
        XCTAssertEqual(decoded.numberFormatStyle, .us)
        XCTAssertFalse(decoded.taxPresetEnabled)
        XCTAssertEqual(decoded.taxPresetPercent, 19, accuracy: 0.000_001)
    }
}
