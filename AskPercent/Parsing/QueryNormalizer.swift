import Foundation

struct NumericToken: Equatable {
    let raw: String
    let value: Double
    let isPercent: Bool
    let range: NSRange
}

struct QueryNormalizer {
    private let punctuationPattern = #"[?=!;:]"#
    private let spacesPattern = #"\s+"#

    func normalize(_ query: String) -> String {
        var normalized = query.lowercased()
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "+", with: " plus ")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "%", with: " % ")
            .replacingOccurrences(of: "incl.", with: "incl")
            .replacingOccurrences(of: "inkl.", with: "inkl")

        normalized = normalized.replacingOccurrences(of: punctuationPattern, with: " ", options: .regularExpression)
        normalized = normalized.replacingOccurrences(of: #"(?<=\d)[’'](?=\d)"#, with: "", options: .regularExpression)
        normalized = normalized.replacingOccurrences(of: #"(?<=\d)\s(?=\d{3}(?:\D|$))"#, with: "", options: .regularExpression)
        normalized = normalized.replacingOccurrences(of: spacesPattern, with: " ", options: .regularExpression)
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func extractNumericTokens(from text: String) -> [NumericToken] {
        let pattern = #"[-+]?\d+(?:[.,]\d+)?(?:\s*%)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)

        return regex.matches(in: text, range: fullRange).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            let raw = String(text[range])
            let cleanedRaw = raw.replacingOccurrences(of: " ", with: "")
            let isPercent = cleanedRaw.contains("%")
            guard let value = Self.parseNumber(cleanedRaw.replacingOccurrences(of: "%", with: "")) else {
                return nil
            }
            return NumericToken(raw: cleanedRaw, value: value, isPercent: isPercent, range: match.range)
        }
    }

    static func parseNumber(_ raw: String) -> Double? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        value = value
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: " ", with: "")

        let hasComma = value.contains(",")
        let hasDot = value.contains(".")

        if hasComma && hasDot {
            let lastComma = value.lastIndex(of: ",")!
            let lastDot = value.lastIndex(of: ".")!
            if lastComma > lastDot {
                value = value.replacingOccurrences(of: ".", with: "")
                value = value.replacingOccurrences(of: ",", with: ".")
            } else {
                value = value.replacingOccurrences(of: ",", with: "")
            }
        } else if hasComma {
            let parts = value.split(separator: ",")
            if parts.count > 2 {
                value = parts.joined()
            } else if parts.count == 2, let last = parts.last, last.count == 3 {
                value = value.replacingOccurrences(of: ",", with: "")
            } else {
                value = value.replacingOccurrences(of: ",", with: ".")
            }
        } else if hasDot {
            let parts = value.split(separator: ".")
            if parts.count > 2 {
                if let last = parts.last, last.count <= 2 {
                    let integer = parts.dropLast().joined()
                    value = integer + "." + last
                } else {
                    value = parts.joined()
                }
            }
        }

        return Double(value)
    }
}
