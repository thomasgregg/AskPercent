import Foundation

enum DisplayFormatter {
    static func number(_ value: Double, precision: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = precision
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func percent(_ value: Double, precision: Int, locale: Locale = .current, alwaysSigned: Bool = false) -> String {
        let formatted = number(value, precision: precision, locale: locale)
        if alwaysSigned {
            if value > 0 {
                return "+\(formatted)%"
            }
            if value < 0 {
                return "\(formatted)%"
            }
            return "0%"
        }
        return "\(formatted)%"
    }

    static func localizeNumericLiterals(in text: String, precision: Int, locale: Locale = .current) -> String {
        let pattern = #"(?<![\p{L}\d])[-+]?\d+(?:[.,]\d+)?(?![\p{L}\d])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }

        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: fullRange)
        guard !matches.isEmpty else { return text }

        var output = text
        for match in matches.reversed() {
            guard let range = Range(match.range, in: output) else { continue }
            let raw = String(output[range])
            guard let value = QueryNormalizer.parseNumber(raw) else { continue }
            let formatted = number(value, precision: precision, locale: locale)
            output.replaceSubrange(range, with: formatted)
        }
        return output
    }
}
