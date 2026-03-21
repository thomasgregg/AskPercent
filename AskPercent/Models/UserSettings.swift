import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system
    case english
    case german

    var id: String { rawValue }

    static var defaultLanguage: AppLanguage {
        .system
    }

    static var localeResolvedLanguage: ResolvedAppLanguage {
        let locale = Locale.current.identifier.lowercased()
        return locale.hasPrefix("de") ? .german : .english
    }

    var resolved: ResolvedAppLanguage {
        switch self {
        case .system:
            return Self.localeResolvedLanguage
        case .english:
            return .english
        case .german:
            return .german
        }
    }

    func displayName(interfaceLanguage: ResolvedAppLanguage) -> String {
        switch (self, interfaceLanguage) {
        case (.system, .english):
            return "System"
        case (.system, .german):
            return "System"
        case (.english, _):
            return "English"
        case (.german, _):
            return "Deutsch"
        }
    }
}

enum ResolvedAppLanguage {
    case english
    case german
}

enum NumberFormatStyle: String, Codable, CaseIterable, Identifiable {
    case system
    case us
    case european

    var id: String { rawValue }

    func displayName(language: AppLanguage) -> String {
        switch (self, language.resolved) {
        case (.system, .english):
            return "System"
        case (.system, .german):
            return "System"
        case (.us, .english):
            return "US (1,234.56)"
        case (.us, .german):
            return "US (1,234.56)"
        case (.european, .english):
            return "European (1.234,56)"
        case (.european, .german):
            return "Europäisch (1.234,56)"
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            return .current
        case .us:
            return Locale(identifier: "en_US_POSIX")
        case .european:
            return Locale(identifier: "de_DE")
        }
    }
}

struct UserSettings: Codable, Equatable {
    var language: AppLanguage
    var decimalPrecision: Int
    var showFormula: Bool
    var hapticsEnabled: Bool
    var numberFormatStyle: NumberFormatStyle

    static let `default` = UserSettings(
        language: AppLanguage.defaultLanguage,
        decimalPrecision: 2,
        showFormula: true,
        hapticsEnabled: true,
        numberFormatStyle: .system
    )

    init(
        language: AppLanguage,
        decimalPrecision: Int,
        showFormula: Bool,
        hapticsEnabled: Bool,
        numberFormatStyle: NumberFormatStyle
    ) {
        self.language = language
        self.decimalPrecision = decimalPrecision
        self.showFormula = showFormula
        self.hapticsEnabled = hapticsEnabled
        self.numberFormatStyle = numberFormatStyle
    }

    private enum CodingKeys: String, CodingKey {
        case language
        case decimalPrecision
        case showFormula
        case hapticsEnabled
        case numberFormatStyle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? AppLanguage.defaultLanguage
        decimalPrecision = try container.decodeIfPresent(Int.self, forKey: .decimalPrecision) ?? 2
        showFormula = try container.decodeIfPresent(Bool.self, forKey: .showFormula) ?? true
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        numberFormatStyle = try container.decodeIfPresent(NumberFormatStyle.self, forKey: .numberFormatStyle) ?? .system
    }
}
