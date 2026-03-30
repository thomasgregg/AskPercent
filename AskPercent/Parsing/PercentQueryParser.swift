import Foundation

final class PercentQueryParser {
    private let normalizer: QueryNormalizer
    var defaultTaxPercent: Double?
    var defaultTipPercent: Double?
    private let numberCapture = #"([-+]?\d+(?:[.,']\d+)*)"#
    private let percentTokenPattern = #"(?:%|percent|prozent)"#
    private let reversePercentWholeHints = [
        "100",
        "whole",
        "total",
        "total value",
        "full value",
        "base",
        "base value",
        "base amount",
        "original amount",
        "original value",
        "ganz",
        "ganzes",
        "ganze",
        "gesamt",
        "gesamtwert",
        "gesamtsumme",
        "gesamtbetrag",
        "grundwert",
        "grundbetrag"
    ]

    init(
        normalizer: QueryNormalizer = QueryNormalizer(),
        defaultTaxPercent: Double? = nil,
        defaultTipPercent: Double? = nil
    ) {
        self.normalizer = normalizer
        self.defaultTaxPercent = defaultTaxPercent
        self.defaultTipPercent = defaultTipPercent
    }

    func parse(_ query: String) -> ParseOutcome {
        let normalized = normalizer.normalize(query)
        guard !normalized.isEmpty else {
            return ParseOutcome(normalizedQuery: normalized, candidates: [], failureReason: nil, failureMessage: nil)
        }
        let numericTokens = normalizer.extractNumericTokens(from: normalized)
        guard !numericTokens.isEmpty else {
            return ParseOutcome(
                normalizedQuery: normalized,
                candidates: [],
                failureReason: .numbersMissing,
                failureMessage: "I couldn't find the numbers in that question. Try something like '25% of 167'."
            )
        }

        var candidates = [ParseCandidate]()
        candidates.append(contentsOf: parseTipTaxVat(in: normalized))
        candidates.append(contentsOf: parseDiscountRate(in: normalized))
        candidates.append(contentsOf: parseMarkupRate(in: normalized))
        candidates.append(contentsOf: parseFinancialTaxContext(in: normalized))
        candidates.append(contentsOf: parseTaxPresetNoRate(in: normalized))
        candidates.append(contentsOf: parsePercentOf(in: normalized))
        candidates.append(contentsOf: parseAddPercent(in: normalized))
        candidates.append(contentsOf: parseSubtractPercent(in: normalized))
        candidates.append(contentsOf: parseIncreaseDecreaseBy(in: normalized))
        candidates.append(contentsOf: parsePercentChange(in: normalized))
        candidates.append(contentsOf: parseDiscount(in: normalized))
        candidates.append(contentsOf: parseReversePercent(in: normalized))
        candidates.append(contentsOf: parseRelation(in: normalized))
        candidates.append(contentsOf: parseProfitPercentOf(in: normalized))
        candidates.append(contentsOf: parseMarginPercentAmount(in: normalized))
        candidates.append(contentsOf: parseMargin(in: normalized))
        candidates.append(contentsOf: parseMarkup(in: normalized))
        candidates.append(contentsOf: parseAmbiguousOnPattern(in: normalized))

        let ranked = rankAndDeduplicate(candidates: candidates, normalizedQuery: normalized, numericTokens: numericTokens)
        if ranked.isEmpty {
            if likelyMissingPreset(in: normalized) {
                return ParseOutcome(
                    normalizedQuery: normalized,
                    candidates: [],
                    failureReason: .taxPresetMissing,
                    failureMessage: nil
                )
            }
            return ParseOutcome(
                normalizedQuery: normalized,
                candidates: [],
                failureReason: .lowConfidence,
                failureMessage: "I couldn't confidently parse that. Try examples like '25% of 167' or 'from 80 to 96'."
            )
        }

        return ParseOutcome(normalizedQuery: normalized, candidates: ranked, failureReason: nil, failureMessage: nil)
    }

    private func parsePercentOf(in text: String) -> [ParseCandidate] {
        let startBoundary = #"(?<![\p{L}\d])"#
        let symbolPattern = startBoundary + #"(?:what\s+is\s+)?"# + numberCapture + #"\s*%\s*(?:percent\s*)?of\s*"# + numberCapture + #"(?![\p{L}\d])"#
        let wordPattern = startBoundary + #"(?:what\s+is\s+)?"# + numberCapture + #"\s*percent\s+of\s+"# + numberCapture + #"(?![\p{L}\d])"#

        let germanSymbolPattern = startBoundary + #"(?:(?:wie\s+viel|wieviel|was)\s+(?:sind|ist)\s+)?"# + numberCapture + #"\s*%\s*(?:prozent\s*)?von\s+"# + numberCapture + #"(?![\p{L}\d])"#
        let germanWordPattern = startBoundary + #"(?:(?:wie\s+viel|wieviel|was)\s+(?:sind|ist)\s+)?"# + numberCapture + #"\s*prozent\s+von\s+"# + numberCapture + #"(?![\p{L}\d])"#

        let symbolMatches: [[String]] = captures(symbolPattern, in: text)
        let symbolCandidates: [ParseCandidate] = symbolMatches.compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.98,
                interpretation: "\(percent)% of \(base)"
            )
        }

        let wordMatches: [[String]] = captures(wordPattern, in: text)
        let wordCandidates: [ParseCandidate] = wordMatches.compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.95,
                interpretation: "\(percent)% of \(base)"
            )
        }

        let germanSymbolMatches: [[String]] = captures(germanSymbolPattern, in: text)
        let germanSymbolCandidates: [ParseCandidate] = germanSymbolMatches.compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.98,
                interpretation: "\(percent)% von \(base)"
            )
        }

        let germanWordMatches: [[String]] = captures(germanWordPattern, in: text)
        let germanWordCandidates: [ParseCandidate] = germanWordMatches.compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.95,
                interpretation: "\(percent)% von \(base)"
            )
        }

        return symbolCandidates + wordCandidates + germanSymbolCandidates + germanWordCandidates
    }

    private func parseAddPercent(in text: String) -> [ParseCandidate] {
        let excludedKindsPattern = #"(?:tip|tax|sales\s*tax|vat|gst|iva|trinkgeld|steuer|mwst|ust|umsatzsteuer|umsatzst(?:euer)?|discount|rabatt)"#
        let connectorPattern = #"(?:plus|add|added|with|include(?:d)?|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl)"#
        let wordPattern = #"\b"# + numberCapture + #"\s*"# + connectorPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?!\s*"# + excludedKindsPattern + #")"#
        let symbolPattern = #"\b"# + numberCapture + #"\s*\+\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?!\s*"# + excludedKindsPattern + #")"#
        let commandPattern = #"\b(?:add|added)\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*(?:to|onto)\s+"# + numberCapture + #"\b"#

        let wordMatches: [[String]] = captures(wordPattern, in: text)
        let wordCandidates: [ParseCandidate] = wordMatches.compactMap { capture -> ParseCandidate? in
            guard
                let base = double(capture[0]),
                let percent = double(capture[1], treatAsPercent: true)
            else { return nil }

            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.95,
                interpretation: "\(base) plus \(percent)%"
            )
        }

        let symbolMatches: [[String]] = captures(symbolPattern, in: text)
        let symbolCandidates: [ParseCandidate] = symbolMatches.compactMap { capture -> ParseCandidate? in
            guard
                let base = double(capture[0]),
                let percent = double(capture[1], treatAsPercent: true)
            else { return nil }

            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.95,
                interpretation: "\(base) plus \(percent)%"
            )
        }

        let commandCandidates: [ParseCandidate] = captures(commandPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let percent = double(capture[0], treatAsPercent: true),
                let base = double(capture[1])
            else { return nil }

            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "\(base) plus \(percent)%"
            )
        }

        return wordCandidates + symbolCandidates + commandCandidates
    }

    private func parseDiscountRate(in text: String) -> [ParseCandidate] {
        let discountKeywordPattern = #"(?:discount|rabatt)"#
        let baseFirstConnectorPattern = #"(?:with|plus|add|added|include(?:d)?|including|incl(?:uding)?|less|minus|mit|inkl(?:usive)?|abzüglich|abzueglich)"#
        let relationConnectorPattern = #"(?:on|off|from|of|auf|von)"#

        let baseFirstPattern = #"\b"# + numberCapture + #"\s*"# + baseFirstConnectorPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + discountKeywordPattern + #"\b"#
        let baseKeywordPercentPattern = #"\b"# + numberCapture + #"\s*"# + baseFirstConnectorPattern + #"\s*"# + discountKeywordPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\b|$)"#
        let percentFirstPattern = #"\b"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + discountKeywordPattern + #"\s*"# + relationConnectorPattern + #"\s+"# + numberCapture + #"\b"#
        let keywordFirstPattern = #"\b"# + discountKeywordPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + relationConnectorPattern + #"\s+"# + numberCapture + #"\b"#

        let baseFirstCandidates = captures(baseFirstPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let base = double(capture[0]), let percent = double(capture[1], treatAsPercent: true) else { return nil }
            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.98,
                interpretation: "\(base) with \(percent)% discount"
            )
        }

        let percentFirstCandidates = captures(percentFirstPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.98,
                interpretation: "\(percent)% discount on \(base)"
            )
        }

        let baseKeywordPercentCandidates = captures(baseKeywordPercentPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let base = double(capture[0]), let percent = double(capture[1], treatAsPercent: true) else { return nil }
            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "\(base) with \(percent)% discount"
            )
        }

        let keywordFirstCandidates = captures(keywordFirstPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.98,
                interpretation: "\(percent)% discount on \(base)"
            )
        }

        return baseFirstCandidates + baseKeywordPercentCandidates + percentFirstCandidates + keywordFirstCandidates
    }

    private func parseMarkupRate(in text: String) -> [ParseCandidate] {
        let markupKeywordPattern = #"(?:markup|aufschlag)"#
        let baseFirstConnectorPattern = #"(?:with|plus|add|added|include(?:d)?|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl)"#
        let relationConnectorPattern = #"(?:on|of|auf|von)"#

        let baseFirstPattern = #"\b"# + numberCapture + #"\s*"# + baseFirstConnectorPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + markupKeywordPattern + #"\b"#
        let baseKeywordPercentPattern = #"\b"# + numberCapture + #"\s*"# + baseFirstConnectorPattern + #"\s*"# + markupKeywordPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\b|$)"#
        let percentFirstPattern = #"\b"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + markupKeywordPattern + #"\s*"# + relationConnectorPattern + #"\s+"# + numberCapture + #"\b"#
        let keywordFirstPattern = #"\b"# + markupKeywordPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + relationConnectorPattern + #"\s+"# + numberCapture + #"\b"#

        let baseFirstCandidates = captures(baseFirstPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let base = double(capture[0]), let percent = double(capture[1], treatAsPercent: true) else { return nil }
            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.98,
                interpretation: "\(base) with \(percent)% markup"
            )
        }

        let percentFirstCandidates = captures(percentFirstPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.98,
                interpretation: "\(percent)% markup on \(base)"
            )
        }

        let baseKeywordPercentCandidates = captures(baseKeywordPercentPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let base = double(capture[0]), let percent = double(capture[1], treatAsPercent: true) else { return nil }
            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "\(base) with \(percent)% markup"
            )
        }

        let keywordFirstCandidates = captures(keywordFirstPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.98,
                interpretation: "\(percent)% markup on \(base)"
            )
        }

        return baseFirstCandidates + baseKeywordPercentCandidates + percentFirstCandidates + keywordFirstCandidates
    }

    private func parseSubtractPercent(in text: String) -> [ParseCandidate] {
        let connectorPattern = #"(?:minus|less|subtract(?:ed)?|substract(?:ed)?|reduce(?:d)?|decrease(?:d)?|lower(?:ed)?|drop(?:ped)?|reduzier(?:e|en|t)|weniger|abzüglich|abzueglich)"#
        let wordPattern = #"\b"# + numberCapture + #"\s*"# + connectorPattern + #"\s*(?:by\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern
        let symbolPattern = #"\b"# + numberCapture + #"\s*-\s*"# + numberCapture + #"\s*"# + percentTokenPattern
        let commandPattern = #"\b(?:subtract(?:ed)?|substract(?:ed)?|minus|less|reduce(?:d)?|decrease(?:d)?|lower(?:ed)?|drop(?:ped)?)\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\s*(?:tax|sales\s*tax|vat|gst|iva|trinkgeld|steuer|mwst|ust|umsatzsteuer|umsatzst(?:euer)?))?\s+from\s+"# + numberCapture + #"\b"#

        let wordMatches: [[String]] = captures(wordPattern, in: text)
        let wordCandidates: [ParseCandidate] = wordMatches.compactMap { capture -> ParseCandidate? in
            guard
                let base = double(capture[0]),
                let percent = double(capture[1], treatAsPercent: true)
            else { return nil }

            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.95,
                interpretation: "\(base) minus \(percent)%"
            )
        }

        let symbolMatches: [[String]] = captures(symbolPattern, in: text)
        let symbolCandidates: [ParseCandidate] = symbolMatches.compactMap { capture -> ParseCandidate? in
            guard
                let base = double(capture[0]),
                let percent = double(capture[1], treatAsPercent: true)
            else { return nil }

            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.95,
                interpretation: "\(base) minus \(percent)%"
            )
        }

        let commandCandidates: [ParseCandidate] = captures(commandPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let percent = double(capture[0], treatAsPercent: true),
                let base = double(capture[1])
            else { return nil }

            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "\(base) minus \(percent)%"
            )
        }

        return wordCandidates + symbolCandidates + commandCandidates
    }

    private func parseIncreaseDecreaseBy(in text: String) -> [ParseCandidate] {
        let increasePattern = #"\b(?:increase|raise|grow)\s+"# + numberCapture + #"\s+by\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\b|$)"#
        let decreasePattern = #"\b(?:decrease|reduce|lower|drop)\s+"# + numberCapture + #"\s+by\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\b|$)"#
        let increaseByFirstPattern = #"\b(?:increase|raise|grow)\s+by\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s+(?:(?:on|of|for|to)\s+)?"# + numberCapture + #"(?:\b|$)"#
        let decreaseByFirstPattern = #"\b(?:decrease|reduce|lower|drop)\s+by\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s+(?:(?:on|of|for|from)\s+)?"# + numberCapture + #"(?:\b|$)"#
        let germanReducePattern = #"\b(?:reduziere|reduzier(?:en|t)|senke|verringere)\s+"# + numberCapture + #"\s+um\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\b|$)"#
        let germanReduceByFirstPattern = #"\b(?:reduziere|senke|verringere)\s+um\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s+"# + numberCapture + #"(?:\b|$)"#

        let increaseCandidates = captures(increasePattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let base = double(capture[0]), let percent = double(capture[1], treatAsPercent: true) else { return nil }
            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "increase \(base) by \(percent)%"
            )
        }

        let decreaseCandidates = captures(decreasePattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let base = double(capture[0]), let percent = double(capture[1], treatAsPercent: true) else { return nil }
            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "decrease \(base) by \(percent)%"
            )
        }

        let increaseByFirstCandidates = captures(increaseByFirstPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "increase \(base) by \(percent)%"
            )
        }

        let decreaseByFirstCandidates = captures(decreaseByFirstPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "decrease \(base) by \(percent)%"
            )
        }

        let germanReduceCandidates = captures(germanReducePattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let base = double(capture[0]), let percent = double(capture[1], treatAsPercent: true) else { return nil }
            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "\(base) minus \(percent)%"
            )
        }

        let germanReduceByFirstCandidates = captures(germanReduceByFirstPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "\(base) minus \(percent)%"
            )
        }

        return increaseCandidates
            + decreaseCandidates
            + increaseByFirstCandidates
            + decreaseByFirstCandidates
            + germanReduceCandidates
            + germanReduceByFirstCandidates
    }

    private func parsePercentChange(in text: String) -> [ParseCandidate] {
        let englishPattern = #"\b(?:from\s+)?"# + numberCapture + #"\s+to\s+"# + numberCapture + #"\b"#
        let germanPattern = #"\b(?:von\s+)?"# + numberCapture + #"\s+(?:auf|zu)\s+"# + numberCapture + #"\b"#
        let englishBeforeNowPattern = #"\b(?:before|previously)\s+"# + numberCapture + #"\s+(?:now|currently)\s+"# + numberCapture + #"\b"#
        let germanBeforeNowPattern = #"\b(?:vorher|zuvor|früher|frueher)\s+"# + numberCapture + #"\s+(?:jetzt|nun)\s+"# + numberCapture + #"\b"#
        let englishWasNowPattern = #"\b(?:was|then|earlier)\s+"# + numberCapture + #"\s+(?:now|currently)\s+"# + numberCapture + #"\b"#
        let germanWarJetztPattern = #"\b(?:war|früher|frueher)\s+"# + numberCapture + #"\s+(?:jetzt|nun)\s+"# + numberCapture + #"\b"#
        let hasProfitKeywords = text.contains("margin")
            || text.contains("gross margin")
            || text.contains("profit")
            || text.contains("marge")
            || text.contains("bruttomarge")
            || text.contains("handelsspanne")
            || text.contains("gewinnspanne")
            || text.contains("gewinn")
            || text.contains("markup")
            || text.contains("aufschlag")

        let english = captures(englishPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let old = double(capture[0]),
                let new = double(capture[1])
            else { return nil }

            var confidence = text.contains("from") ? 0.93 : 0.87
            if hasProfitKeywords {
                confidence -= 0.24
            }
            return ParseCandidate(
                intent: .percentChange(old: old, new: new),
                confidence: confidence,
                interpretation: "percent change from \(old) to \(new)"
            )
        }

        let german = captures(germanPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let old = double(capture[0]),
                let new = double(capture[1])
            else { return nil }

            var confidence = text.contains("von") ? 0.93 : 0.87
            if hasProfitKeywords {
                confidence -= 0.24
            }
            return ParseCandidate(
                intent: .percentChange(old: old, new: new),
                confidence: confidence,
                interpretation: "prozentänderung von \(old) auf \(new)"
            )
        }

        let englishBeforeNow = captures(englishBeforeNowPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let old = double(capture[0]),
                let new = double(capture[1])
            else { return nil }

            var confidence = 0.92
            if hasProfitKeywords {
                confidence -= 0.24
            }
            return ParseCandidate(
                intent: .percentChange(old: old, new: new),
                confidence: confidence,
                interpretation: "percent change from \(old) to \(new)"
            )
        }

        let germanBeforeNow = captures(germanBeforeNowPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let old = double(capture[0]),
                let new = double(capture[1])
            else { return nil }

            var confidence = 0.92
            if hasProfitKeywords {
                confidence -= 0.24
            }
            return ParseCandidate(
                intent: .percentChange(old: old, new: new),
                confidence: confidence,
                interpretation: "prozentänderung von \(old) auf \(new)"
            )
        }

        let englishWasNow = captures(englishWasNowPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let old = double(capture[0]),
                let new = double(capture[1])
            else { return nil }

            var confidence = 0.91
            if hasProfitKeywords {
                confidence -= 0.24
            }
            return ParseCandidate(
                intent: .percentChange(old: old, new: new),
                confidence: confidence,
                interpretation: "percent change from \(old) to \(new)"
            )
        }

        let germanWarJetzt = captures(germanWarJetztPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let old = double(capture[0]),
                let new = double(capture[1])
            else { return nil }

            var confidence = 0.91
            if hasProfitKeywords {
                confidence -= 0.24
            }
            return ParseCandidate(
                intent: .percentChange(old: old, new: new),
                confidence: confidence,
                interpretation: "prozentänderung von \(old) auf \(new)"
            )
        }

        return english + german + englishBeforeNow + germanBeforeNow + englishWasNow + germanWarJetzt
    }

    private func parseDiscount(in text: String) -> [ParseCandidate] {
        let englishPattern = #"\b(?:i\s+)?(?:paid\s+)?"# + numberCapture + #"\s+instead\s+of\s+"# + numberCapture + #"\b"#
        let englishDiscountFromToPattern = #"\b(?:what\s+(?:is|s)\s+(?:the\s+)?)?discount\s+(?:from\s+)?"# + numberCapture + #"\s+(?:to|down\s+to)\s+"# + numberCapture + #"\b"#
        let englishDiscountNewFromOriginalPattern = #"\b(?:what\s+(?:is|s)\s+(?:the\s+)?)?discount\s+"# + numberCapture + #"\s+from\s+"# + numberCapture + #"\b"#
        let germanPattern = #"\b(?:ich\s+)?(?:habe\s+)?(?:bezahlt\s+)?"# + numberCapture + #"\s+(?:statt|anstatt)\s+"# + numberCapture + #"\b"#
        let germanRabattVonAufPattern = #"\b(?:wie\s+(?:hoch|viel)\s+ist\s+(?:der\s+)?)?rabatt\s+von\s+"# + numberCapture + #"\s+auf\s+"# + numberCapture + #"\b"#

        let english = captures(englishPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let newValue = double(capture[0]),
                let original = double(capture[1])
            else { return nil }

            return ParseCandidate(
                intent: .discountPercent(original: original, new: newValue),
                confidence: text.contains("discount") ? 0.99 : 0.94,
                interpretation: "discount from \(original) to \(newValue)"
            )
        }

        let englishFromTo = captures(englishDiscountFromToPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let original = double(capture[0]),
                let newValue = double(capture[1])
            else { return nil }

            return ParseCandidate(
                intent: .discountPercent(original: original, new: newValue),
                confidence: 0.99,
                interpretation: "discount from \(original) to \(newValue)"
            )
        }

        let englishNewFromOriginal = captures(englishDiscountNewFromOriginalPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let newValue = double(capture[0]),
                let original = double(capture[1])
            else { return nil }

            return ParseCandidate(
                intent: .discountPercent(original: original, new: newValue),
                confidence: 0.98,
                interpretation: "discount from \(original) to \(newValue)"
            )
        }

        let german = captures(germanPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let newValue = double(capture[0]),
                let original = double(capture[1])
            else { return nil }

            return ParseCandidate(
                intent: .discountPercent(original: original, new: newValue),
                confidence: (text.contains("rabatt") || text.contains("statt") || text.contains("anstatt")) ? 0.96 : 0.9,
                interpretation: "rabatt von \(original) auf \(newValue)"
            )
        }

        let germanRabattVonAuf = captures(germanRabattVonAufPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let original = double(capture[0]),
                let newValue = double(capture[1])
            else { return nil }

            return ParseCandidate(
                intent: .discountPercent(original: original, new: newValue),
                confidence: 0.98,
                interpretation: "rabatt von \(original) auf \(newValue)"
            )
        }

        return english + englishFromTo + englishNewFromOriginal + german + germanRabattVonAuf
    }

    private func parseReversePercent(in text: String) -> [ParseCandidate] {
        let relationVerbPattern = #"(?:is|are|equals|=|sind|ist|entsprechen|betragen)"#
        let targetValueIntroPattern = #"(?:what\s+is|how\s+much\s+is|was\s+sind|was\s+ist|wie\s+viel\s+sind|wieviel\s+sind|wie\s+gro(?:ß|ss)\s+ist)"#
        let targetPercentIntroPattern = #"(?:what\s+percent\s+is|wie\s+viel\s+prozent\s+sind|wieviel\s+prozent\s+sind|wie\s+viel\s+prozent\s+ist|wieviel\s+prozent\s+ist)"#

        let percentFirstTargetPercentPattern = #"\b(?:if\s+|wenn\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + relationVerbPattern + #"\s*"# + numberCapture + #".{0,40}?"# + targetValueIntroPattern + #"\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?=\s|$|[.,])"#
        let partFirstTargetPercentPattern = #"\b(?:if\s+|wenn\s+)?"# + numberCapture + #"\s*"# + relationVerbPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #".{0,40}?"# + targetValueIntroPattern + #"\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?=\s|$|[.,])"#

        let percentFirstFindPercentPattern = #"\b(?:if\s+|wenn\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + relationVerbPattern + #"\s*"# + numberCapture + #".{0,40}?(?:"# + targetPercentIntroPattern + #"|"# + targetValueIntroPattern + #")\s+"# + numberCapture + #"(?!\s*(?:%|percent|prozent))(?:\b|$)"#
        let partFirstFindPercentPattern = #"\b(?:if\s+|wenn\s+)?"# + numberCapture + #"\s*"# + relationVerbPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #".{0,40}?(?:"# + targetPercentIntroPattern + #"|"# + targetValueIntroPattern + #")\s+"# + numberCapture + #"(?!\s*(?:%|percent|prozent))(?:\b|$)"#

        let standardPattern = #"\b(?:if\s+|wenn\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + relationVerbPattern + #"\s*"# + numberCapture + #"\b"#
        let invertedGermanPattern = #"\b(?:wenn\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + numberCapture + #"\s*(?:sind|ist)\b"#
        let swappedOrderPattern = #"\b"# + numberCapture + #"\s*"# + relationVerbPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?=\s|$|[.,])"#
        let hasWholeHint = containsAnyHint(in: text, hints: reversePercentWholeHints)

        let percentFirstTargetCandidates = captures(percentFirstTargetPercentPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let knownPercent = double(capture[0], treatAsPercent: true),
                let knownPart = double(capture[1]),
                let targetPercent = double(capture[2], treatAsPercent: true)
            else { return nil }

            if abs(targetPercent - 100) < 0.000_001 {
                return ParseCandidate(
                    intent: .reversePercent(percent: knownPercent, partial: knownPart),
                    confidence: 0.99,
                    interpretation: "if \(knownPercent)% is \(knownPart), what is 100%"
                )
            }

            return ParseCandidate(
                intent: .reversePercentTarget(knownPercent: knownPercent, knownPart: knownPart, targetPercent: targetPercent),
                confidence: 0.99,
                interpretation: "if \(knownPercent)% is \(knownPart), what is \(targetPercent)%"
            )
        }

        let partFirstTargetCandidates = captures(partFirstTargetPercentPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let knownPart = double(capture[0]),
                let knownPercent = double(capture[1], treatAsPercent: true),
                let targetPercent = double(capture[2], treatAsPercent: true)
            else { return nil }

            if abs(targetPercent - 100) < 0.000_001 {
                return ParseCandidate(
                    intent: .reversePercent(percent: knownPercent, partial: knownPart),
                    confidence: 0.99,
                    interpretation: "if \(knownPercent)% is \(knownPart), what is 100%"
                )
            }

            return ParseCandidate(
                intent: .reversePercentTarget(knownPercent: knownPercent, knownPart: knownPart, targetPercent: targetPercent),
                confidence: 0.99,
                interpretation: "if \(knownPercent)% is \(knownPart), what is \(targetPercent)%"
            )
        }

        let targetCandidates = percentFirstTargetCandidates + partFirstTargetCandidates
        if !targetCandidates.isEmpty {
            return targetCandidates
        }

        let percentFirstFindPercentCandidates = captures(percentFirstFindPercentPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let knownPercent = double(capture[0], treatAsPercent: true),
                let knownPart = double(capture[1]),
                let targetPart = double(capture[2])
            else { return nil }

            return ParseCandidate(
                intent: .reversePercentFindPercent(knownPercent: knownPercent, knownPart: knownPart, targetPart: targetPart),
                confidence: 0.99,
                interpretation: "if \(knownPercent)% is \(knownPart), what percent is \(targetPart)"
            )
        }

        let partFirstFindPercentCandidates = captures(partFirstFindPercentPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let knownPart = double(capture[0]),
                let knownPercent = double(capture[1], treatAsPercent: true),
                let targetPart = double(capture[2])
            else { return nil }

            return ParseCandidate(
                intent: .reversePercentFindPercent(knownPercent: knownPercent, knownPart: knownPart, targetPart: targetPart),
                confidence: 0.99,
                interpretation: "if \(knownPercent)% is \(knownPart), what percent is \(targetPart)"
            )
        }

        let findPercentCandidates = percentFirstFindPercentCandidates + partFirstFindPercentCandidates
        if !findPercentCandidates.isEmpty {
            return findPercentCandidates
        }

        let standard = captures(standardPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let percent = double(capture[0], treatAsPercent: true),
                let partial = double(capture[1])
            else { return nil }

            let confidence = hasWholeHint ? 0.98 : 0.88
            return ParseCandidate(
                intent: .reversePercent(percent: percent, partial: partial),
                confidence: confidence,
                interpretation: "if \(percent)% is \(partial), what is 100%"
            )
        }

        let invertedGerman = captures(invertedGermanPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let percent = double(capture[0], treatAsPercent: true),
                let partial = double(capture[1])
            else { return nil }

            let confidence = hasWholeHint ? 0.95 : 0.82
            return ParseCandidate(
                intent: .reversePercent(percent: percent, partial: partial),
                confidence: confidence,
                interpretation: "wenn \(percent)% \(partial) sind, was sind 100%"
            )
        }

        let swappedOrder = captures(swappedOrderPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let partial = double(capture[0]),
                let percent = double(capture[1], treatAsPercent: true)
            else { return nil }

            let confidence = hasWholeHint ? 0.94 : 0.86
            return ParseCandidate(
                intent: .reversePercent(percent: percent, partial: partial),
                confidence: confidence,
                interpretation: "if \(percent)% is \(partial), what is 100%"
            )
        }

        return standard + invertedGerman + swappedOrder
    }

    private func parseRelation(in text: String) -> [ParseCandidate] {
        let directPattern = #"\b"# + numberCapture + #"\s+is\s+what\s+(?:percent|%)\s+of\s+"# + numberCapture + #"\b"#
        let inversePattern = #"\bwhat\s+(?:percent|%)\s+is\s+"# + numberCapture + #"\s+of\s+"# + numberCapture + #"\b"#
        let shorthandPattern = #"\b"# + numberCapture + #"\s+of\s+"# + numberCapture + #"\b"#
        let outOfPattern = #"\b"# + numberCapture + #"\s+out\s+of\s+"# + numberCapture + #"\b"#
        let statementPattern = #"\b"# + numberCapture + #"\s+(?:is|are|equals|=)\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s+of\s+"# + numberCapture + #"\b"#

        let germanDirectPattern = #"\b"# + numberCapture + #"\s+(?:sind|ist)\s+(?:wie\s+viel|wieviel)\s+(?:prozent|%)\s+von\s+"# + numberCapture + #"\b"#
        let germanInversePattern = #"\b(?:wie\s+viel|wieviel)\s+(?:prozent|%)\s+(?:sind|ist)\s+"# + numberCapture + #"\s+von\s+"# + numberCapture + #"\b"#
        let germanShorthandPattern = #"\b"# + numberCapture + #"\s+von\s+"# + numberCapture + #"\b"#
        let germanAusPattern = #"\b"# + numberCapture + #"\s+aus\s+"# + numberCapture + #"\b"#
        let germanStatementPattern = #"\b"# + numberCapture + #"\s+(?:ist|sind|entsprechen|=)\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s+von\s+"# + numberCapture + #"\b"#

        let direct = captures(directPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let part = double(capture[0]), let whole = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOfRelation(part: part, whole: whole),
                confidence: 0.98,
                interpretation: "\(part) is what percent of \(whole)"
            )
        }

        let inverse = captures(inversePattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let part = double(capture[0]), let whole = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOfRelation(part: part, whole: whole),
                confidence: 0.97,
                interpretation: "what percent is \(part) of \(whole)"
            )
        }

        let shorthand = captures(shorthandPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let part = double(capture[0]), let whole = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOfRelation(part: part, whole: whole),
                confidence: 0.94,
                interpretation: "\(part) of \(whole)"
            )
        }

        let outOf = captures(outOfPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let part = double(capture[0]), let whole = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOfRelation(part: part, whole: whole),
                confidence: 0.96,
                interpretation: "\(part) out of \(whole)"
            )
        }

        let statement = captures(statementPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let part = double(capture[0]), let whole = double(capture[2]) else { return nil }
            return ParseCandidate(
                intent: .percentOfRelation(part: part, whole: whole),
                confidence: 0.995,
                interpretation: "\(part) is \(capture[1])% of \(whole)"
            )
        }

        let germanDirect = captures(germanDirectPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let part = double(capture[0]), let whole = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOfRelation(part: part, whole: whole),
                confidence: 0.98,
                interpretation: "\(part) sind wie viel prozent von \(whole)"
            )
        }

        let germanInverse = captures(germanInversePattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let part = double(capture[0]), let whole = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOfRelation(part: part, whole: whole),
                confidence: 0.97,
                interpretation: "wie viel prozent sind \(part) von \(whole)"
            )
        }

        let germanShorthand = captures(germanShorthandPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let part = double(capture[0]), let whole = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOfRelation(part: part, whole: whole),
                confidence: 0.94,
                interpretation: "\(part) von \(whole)"
            )
        }

        let germanAus = captures(germanAusPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let part = double(capture[0]), let whole = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOfRelation(part: part, whole: whole),
                confidence: 0.96,
                interpretation: "\(part) aus \(whole)"
            )
        }

        let germanStatement = captures(germanStatementPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let part = double(capture[0]), let whole = double(capture[2]) else { return nil }
            return ParseCandidate(
                intent: .percentOfRelation(part: part, whole: whole),
                confidence: 0.995,
                interpretation: "\(part) sind \(capture[1])% von \(whole)"
            )
        }

        return direct + inverse + shorthand + outOf + statement + germanDirect + germanInverse + germanShorthand + germanAus + germanStatement
    }

    private func parseTipTaxVat(in text: String) -> [ParseCandidate] {
        var results = [ParseCandidate]()

        let connectorPattern = #"(?:with|plus|add|added|include(?:d)?|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl)"#
        let kindPattern = #"(tip|tax|sales\s*tax|vat|gst|iva|trinkgeld|steuer|mwst|ust|umsatzsteuer|umsatzst(?:euer)?)"#
        let toConnectorPattern = #"(?:to|onto|auf|zu)"#

        let trailingKindPattern = #"\b"# + numberCapture + #"\s*"# + connectorPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + kindPattern + #"\b"#
        for capture in captures(trailingKindPattern, in: text) {
            guard
                let base = double(capture[0]),
                let percent = double(capture[1], treatAsPercent: true)
            else { continue }

            let kind = capture[2]
            results.append(candidateForKind(base: base, percent: percent, kind: kind, confidence: 0.99))
        }

        let middleKindPattern = #"\b"# + numberCapture + #"\s*"# + kindPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\b"#
        for capture in captures(middleKindPattern, in: text) {
            guard
                let base = double(capture[0]),
                let percent = double(capture[2], treatAsPercent: true)
            else { continue }

            let kind = capture[1]
            results.append(candidateForKind(base: base, percent: percent, kind: kind, confidence: 0.97))
        }

        let percentFirstPattern = #"\b"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + kindPattern + #"\s*(?:on|of|for|auf|von)\s+"# + numberCapture + #"\b"#
        for capture in captures(percentFirstPattern, in: text) {
            guard
                let percent = double(capture[0], treatAsPercent: true),
                let base = double(capture[2])
            else { continue }
            let kind = capture[1]
            results.append(candidateForKind(base: base, percent: percent, kind: kind, confidence: 0.98))
        }

        let kindFirstPattern = #"\b"# + kindPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*(?:on|of|for|auf|von)\s+"# + numberCapture + #"\b"#
        for capture in captures(kindFirstPattern, in: text) {
            guard
                let percent = double(capture[1], treatAsPercent: true),
                let base = double(capture[2])
            else { continue }
            let kind = capture[0]
            results.append(candidateForKind(base: base, percent: percent, kind: kind, confidence: 0.98))
        }

        let commandTrailingKindPattern = #"\b(?:add|added|addiere|plus|include(?:d)?|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl|füge|fuege)\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + kindPattern + #"\s*"# + toConnectorPattern + #"\s+"# + numberCapture + #"\b"#
        for capture in captures(commandTrailingKindPattern, in: text) {
            guard
                let percent = double(capture[0], treatAsPercent: true),
                let base = double(capture[2])
            else { continue }
            let kind = capture[1]
            results.append(candidateForKind(base: base, percent: percent, kind: kind, confidence: 0.98))
        }

        let commandLeadingKindPattern = #"\b(?:add|added|addiere|plus|include(?:d)?|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl|füge|fuege)\s+"# + kindPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + toConnectorPattern + #"\s+"# + numberCapture + #"\b"#
        for capture in captures(commandLeadingKindPattern, in: text) {
            guard
                let percent = double(capture[1], treatAsPercent: true),
                let base = double(capture[2])
            else { continue }
            let kind = capture[0]
            results.append(candidateForKind(base: base, percent: percent, kind: kind, confidence: 0.98))
        }

        return results
    }

    private func candidateForKind(base: Double, percent: Double, kind: String, confidence: Double) -> ParseCandidate {
        let normalizedKind = kind.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        switch normalizedKind {
        case "tip", "trinkgeld":
            return ParseCandidate(intent: .tip(base: base, percent: percent), confidence: confidence, interpretation: "\(base) with \(percent)% tip")
        case "tax", "sales tax", "steuer":
            return ParseCandidate(intent: .tax(base: base, percent: percent), confidence: confidence, interpretation: "\(base) with \(percent)% tax")
        default:
            return ParseCandidate(intent: .vat(base: base, percent: percent), confidence: confidence, interpretation: "\(base) with \(percent)% VAT")
        }
    }

    private func parseFinancialTaxContext(in text: String) -> [ParseCandidate] {
        var results = [ParseCandidate]()

        let netContext = #"(?:net|before\s+tax|netto|vor\s+steuer)"#
        let grossContext = #"(?:gross|after\s+tax|brutto|nach\s+steuer)"#
        let plusConnector = #"(?:with|plus|add|added|include(?:d)?|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl)"#
        let minusConnector = #"(?:minus|less|subtract(?:ed)?|substract(?:ed)?|reduce(?:d)?|reduzier(?:e|en|t)|excluding|excl(?:uding)?|without|abzüglich|abzueglich|ohne)"#
        let taxKeywordPattern = #"(tax|sales\s*tax|vat|gst|iva|steuer|mwst|ust|umsatzsteuer|umsatzst(?:euer)?)"#

        // Example: "100 net plus 19% vat", "100 netto zzgl 19% ust"
        let addPattern = #"\b"# + numberCapture + #"\s+"# + netContext + #"\s*"# + plusConnector + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\s+"# + taxKeywordPattern + #")?\b"#
        for capture in captures(addPattern, in: text) {
            guard
                let base = double(capture[0]),
                let percent = double(capture[1], treatAsPercent: true)
            else { continue }

            let kind = capture.count > 2 ? capture[2] : ""
            results.append(candidateForTaxKeyword(base: base, percent: percent, kind: kind, confidence: kind.isEmpty ? 0.9 : 0.97))
        }

        // Example: "120 after tax minus 20% tax", "120 brutto minus 20% steuer"
        let subtractPattern = #"\b"# + numberCapture + #"\s+"# + grossContext + #"\s*"# + minusConnector + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\s+"# + taxKeywordPattern + #")?\b"#
        for capture in captures(subtractPattern, in: text) {
            guard
                let base = double(capture[0]),
                let percent = double(capture[1], treatAsPercent: true)
            else { continue }

            results.append(
                ParseCandidate(
                    intent: .subtractPercent(base: base, percent: percent),
                    confidence: 0.95,
                    interpretation: "\(base) gross minus \(percent)%"
                )
            )
        }

        return results
    }

    private func parseTaxPresetNoRate(in text: String) -> [ParseCandidate] {
        guard (defaultTaxPercent != nil || defaultTipPercent != nil) else { return [] }
        var results = [ParseCandidate]()

        let taxKeywordPattern = #"(tax|sales\s*tax|vat|gst|iva|steuer|mwst|ust|umsatzsteuer|umsatzst(?:euer)?)"#
        let tipKeywordPattern = #"(tip|trinkgeld)"#
        let plusConnectorPattern = #"(?:with|plus|add|added|include(?:d)?|including|incl(?:uding)?|inc|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl)"#
        let minusConnectorPattern = #"(?:minus|subtract(?:ed)?|substract(?:ed)?|reduce(?:d)?|reduzier(?:e|en|t)|less|excluding|excl(?:uding)?|ex|without|abzüglich|abzueglich|ohne|abzgl)"#
        let toConnectorPattern = #"(?:to|onto|auf|zu)"#
        let fromConnectorPattern = #"(?:from|von)"#

        if let configuredTaxPercent = defaultTaxPercent, configuredTaxPercent >= 0 {
            let plusPattern = #"\b"# + numberCapture + #"\s*"# + plusConnectorPattern + #"\s*(?:the\s+)?"# + taxKeywordPattern + #"\b"#
            for capture in captures(plusPattern, in: text) {
                guard let base = double(capture[0]) else { continue }
                let kind = capture[1]
                results.append(
                    candidateForTaxKeyword(
                        base: base,
                        percent: configuredTaxPercent,
                        kind: kind,
                        confidence: 0.86
                    )
                )
            }

            let plusSymbolPattern = #"\b"# + numberCapture + #"\s*\+\s*(?:the\s+)?"# + taxKeywordPattern + #"\b"#
            for capture in captures(plusSymbolPattern, in: text) {
                guard let base = double(capture[0]) else { continue }
                let kind = capture[1]
                results.append(
                    candidateForTaxKeyword(
                        base: base,
                        percent: configuredTaxPercent,
                        kind: kind,
                        confidence: 0.89
                    )
                )
            }

            let minusPattern = #"\b"# + numberCapture + #"\s*"# + minusConnectorPattern + #"\s*(?:the\s+)?"# + taxKeywordPattern + #"\b"#
            for capture in captures(minusPattern, in: text) {
                guard let base = double(capture[0]) else { continue }
                results.append(
                    ParseCandidate(
                        intent: .subtractPercent(base: base, percent: configuredTaxPercent),
                        confidence: 0.86,
                        interpretation: "\(base) minus configured tax"
                    )
                )
            }

            let minusSymbolPattern = #"\b"# + numberCapture + #"\s*-\s*(?:the\s+)?"# + taxKeywordPattern + #"\b"#
            for capture in captures(minusSymbolPattern, in: text) {
                guard let base = double(capture[0]) else { continue }
                results.append(
                    ParseCandidate(
                        intent: .subtractPercent(base: base, percent: configuredTaxPercent),
                        confidence: 0.89,
                        interpretation: "\(base) minus configured tax"
                    )
                )
            }

            let netPlusPattern = #"\b"# + numberCapture + #"\s+(?:net|netto|before\s+tax|vor\s+steuer)\s*"# + plusConnectorPattern + #"\s*(?:the\s+)?"# + taxKeywordPattern + #"\b"#
            for capture in captures(netPlusPattern, in: text) {
                guard let base = double(capture[0]) else { continue }
                let kind = capture[1]
                results.append(
                    candidateForTaxKeyword(
                        base: base,
                        percent: configuredTaxPercent,
                        kind: kind,
                        confidence: 0.9
                    )
                )
            }

            let grossMinusPattern = #"\b"# + numberCapture + #"\s+(?:gross|brutto|after\s+tax|nach\s+steuer)\s*"# + minusConnectorPattern + #"\s*(?:the\s+)?"# + taxKeywordPattern + #"\b"#
            for capture in captures(grossMinusPattern, in: text) {
                guard let base = double(capture[0]) else { continue }
                results.append(
                    ParseCandidate(
                        intent: .subtractPercent(base: base, percent: configuredTaxPercent),
                        confidence: 0.9,
                        interpretation: "\(base) gross minus configured tax"
                    )
                )
            }

            let commandAddPattern = #"\b(?:add|added|addiere|plus|include(?:d)?|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl|füge|fuege)\s*(?:the\s+)?"# + taxKeywordPattern + #"\s*"# + toConnectorPattern + #"\s+"# + numberCapture + #"\b"#
            for capture in captures(commandAddPattern, in: text) {
                guard let base = double(capture[1]) else { continue }
                let kind = capture[0]
                results.append(
                    candidateForTaxKeyword(
                        base: base,
                        percent: configuredTaxPercent,
                        kind: kind,
                        confidence: 0.9
                    )
                )
            }

            let commandSubtractPattern = #"\b(?:subtract(?:ed)?|substract(?:ed)?|minus|less|reduce(?:d)?|decrease(?:d)?|lower(?:ed)?|drop(?:ped)?|without|abzüglich|abzueglich|ohne|abzgl)\s*(?:the\s+)?"# + taxKeywordPattern + #"\s*"# + fromConnectorPattern + #"\s+"# + numberCapture + #"\b"#
            for capture in captures(commandSubtractPattern, in: text) {
                guard let base = double(capture[1]) else { continue }
                results.append(
                    ParseCandidate(
                        intent: .subtractPercent(base: base, percent: configuredTaxPercent),
                        confidence: 0.9,
                        interpretation: "\(base) minus configured tax"
                    )
                )
            }
        }

        if let configuredTipPercent = defaultTipPercent, configuredTipPercent >= 0 {
            let plusPattern = #"\b"# + numberCapture + #"\s*"# + plusConnectorPattern + #"\s*(?:the\s+)?"# + tipKeywordPattern + #"\b"#
            for capture in captures(plusPattern, in: text) {
                guard let base = double(capture[0]) else { continue }
                results.append(
                    ParseCandidate(
                        intent: .tip(base: base, percent: configuredTipPercent),
                        confidence: 0.86,
                        interpretation: "\(base) with configured tip"
                    )
                )
            }

            let plusSymbolPattern = #"\b"# + numberCapture + #"\s*\+\s*(?:the\s+)?"# + tipKeywordPattern + #"\b"#
            for capture in captures(plusSymbolPattern, in: text) {
                guard let base = double(capture[0]) else { continue }
                results.append(
                    ParseCandidate(
                        intent: .tip(base: base, percent: configuredTipPercent),
                        confidence: 0.89,
                        interpretation: "\(base) with configured tip"
                    )
                )
            }

            let minusPattern = #"\b"# + numberCapture + #"\s*"# + minusConnectorPattern + #"\s*(?:the\s+)?"# + tipKeywordPattern + #"\b"#
            for capture in captures(minusPattern, in: text) {
                guard let base = double(capture[0]) else { continue }
                results.append(
                    ParseCandidate(
                        intent: .subtractPercent(base: base, percent: configuredTipPercent),
                        confidence: 0.86,
                        interpretation: "\(base) minus configured tip"
                    )
                )
            }

            let minusSymbolPattern = #"\b"# + numberCapture + #"\s*-\s*(?:the\s+)?"# + tipKeywordPattern + #"\b"#
            for capture in captures(minusSymbolPattern, in: text) {
                guard let base = double(capture[0]) else { continue }
                results.append(
                    ParseCandidate(
                        intent: .subtractPercent(base: base, percent: configuredTipPercent),
                        confidence: 0.89,
                        interpretation: "\(base) minus configured tip"
                    )
                )
            }

            let commandAddPattern = #"\b(?:add|added|addiere|plus|include(?:d)?|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl|füge|fuege)\s*(?:the\s+)?"# + tipKeywordPattern + #"\s*"# + toConnectorPattern + #"\s+"# + numberCapture + #"\b"#
            for capture in captures(commandAddPattern, in: text) {
                guard let base = double(capture[1]) else { continue }
                results.append(
                    ParseCandidate(
                        intent: .tip(base: base, percent: configuredTipPercent),
                        confidence: 0.9,
                        interpretation: "\(base) with configured tip"
                    )
                )
            }

            let commandSubtractPattern = #"\b(?:subtract(?:ed)?|substract(?:ed)?|minus|less|reduce(?:d)?|decrease(?:d)?|lower(?:ed)?|drop(?:ped)?|without|abzüglich|abzueglich|ohne|abzgl)\s*(?:the\s+)?"# + tipKeywordPattern + #"\s*"# + fromConnectorPattern + #"\s+"# + numberCapture + #"\b"#
            for capture in captures(commandSubtractPattern, in: text) {
                guard let base = double(capture[1]) else { continue }
                results.append(
                    ParseCandidate(
                        intent: .subtractPercent(base: base, percent: configuredTipPercent),
                        confidence: 0.9,
                        interpretation: "\(base) minus configured tip"
                    )
                )
            }
        }

        return results
    }

    private func candidateForTaxKeyword(base: Double, percent: Double, kind: String, confidence: Double) -> ParseCandidate {
        let normalizedKind = kind.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        let isVatKeyword = normalizedKind.contains("vat")
            || normalizedKind.contains("mwst")
            || normalizedKind.contains("ust")
            || normalizedKind.contains("umsatz")
            || normalizedKind.contains("gst")
            || normalizedKind.contains("iva")

        if isVatKeyword {
            return ParseCandidate(
                intent: .vat(base: base, percent: percent),
                confidence: confidence,
                interpretation: "\(base) net plus \(percent)% VAT"
            )
        }

        return ParseCandidate(
            intent: .tax(base: base, percent: percent),
            confidence: confidence,
            interpretation: "\(base) net plus \(percent)% tax"
        )
    }

    private func parseMargin(in text: String) -> [ParseCandidate] {
        let englishPattern = #"\b(?:what\s+(?:is\s+)?(?:the\s+)?)?(?:(?:gross\s+)?margin|profit)(?:\s+is)?\s*"# + numberCapture + #"\s+on\s+"# + numberCapture + #"\b"#
        let germanPattern = #"\b(?:was\s+ist\s+|welche\s+)?(?:(?:die|der|den)\s+)?(?:marge|bruttomarge|handelsspanne|gewinnspanne|gewinn)(?:\s+ist)?\s*(?:von\s+)?"# + numberCapture + #"\s+auf\s+"# + numberCapture + #"\b"#

        let english = captures(englishPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let profit = double(capture[0]), let revenue = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .margin(profit: profit, revenue: revenue),
                confidence: 0.98,
                interpretation: "margin \(profit) on \(revenue)"
            )
        }

        let german = captures(germanPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let profit = double(capture[0]), let revenue = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .margin(profit: profit, revenue: revenue),
                confidence: 0.98,
                interpretation: "marge \(profit) auf \(revenue)"
            )
        }

        return english + german
    }

    private func parseProfitPercentOf(in text: String) -> [ParseCandidate] {
        let symbolPattern = #"\b(?:what\s+is\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*profit\s+of\s+"# + numberCapture + #"\b"#
        let wordPattern = #"\b(?:what\s+is\s+)?"# + numberCapture + #"\s*percent\s+profit\s+of\s+"# + numberCapture + #"\b"#

        let germanSymbolPattern = #"\b(?:was\s+(?:ist|sind)\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*gewinn\s+von\s+"# + numberCapture + #"\b"#
        let germanWordPattern = #"\b(?:was\s+(?:ist|sind)\s+)?"# + numberCapture + #"\s*prozent\s+gewinn\s+von\s+"# + numberCapture + #"\b"#

        let symbolCandidates: [ParseCandidate] = captures(symbolPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.96,
                interpretation: "\(percent)% profit of \(base)"
            )
        }

        let wordCandidates: [ParseCandidate] = captures(wordPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.95,
                interpretation: "\(percent)% profit of \(base)"
            )
        }

        let germanSymbolCandidates: [ParseCandidate] = captures(germanSymbolPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.96,
                interpretation: "\(percent)% gewinn von \(base)"
            )
        }

        let germanWordCandidates: [ParseCandidate] = captures(germanWordPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.95,
                interpretation: "\(percent)% gewinn von \(base)"
            )
        }

        return symbolCandidates + wordCandidates + germanSymbolCandidates + germanWordCandidates
    }

    private func parseMarginPercentAmount(in text: String) -> [ParseCandidate] {
        let englishPattern = #"\b(?:how\s+much\s+is\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*(?:margin|profit)\s+on\s+"# + numberCapture + #"\b"#
        let germanPattern = #"\b(?:wie\s+viel\s+(?:sind|ist)\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*(?:marge|gewinnspanne|gewinn)\s+auf\s+"# + numberCapture + #"\b"#

        let english = captures(englishPattern, in: text).flatMap { capture -> [ParseCandidate] in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return [] }

            // "10% margin on 134" is commonly used for the margin amount,
            // but some users mean "price plus margin", so expose both.
            return [
                ParseCandidate(
                    intent: .percentOf(percent: percent, base: base),
                    confidence: 0.9,
                    interpretation: "\(percent)% margin amount on \(base)"
                ),
                ParseCandidate(
                    intent: .addPercent(base: base, percent: percent),
                    confidence: 0.62,
                    interpretation: "\(base) plus \(percent)% (price with margin)"
                )
            ]
        }

        let german = captures(germanPattern, in: text).flatMap { capture -> [ParseCandidate] in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return [] }

            return [
                ParseCandidate(
                    intent: .percentOf(percent: percent, base: base),
                    confidence: 0.9,
                    interpretation: "\(percent)% marge auf \(base)"
                ),
                ParseCandidate(
                    intent: .addPercent(base: base, percent: percent),
                    confidence: 0.62,
                    interpretation: "\(base) plus \(percent)% (preis mit marge)"
                )
            ]
        }

        return english + german
    }

    private func parseMarkup(in text: String) -> [ParseCandidate] {
        let englishPattern = #"\b(?:what\s+(?:is\s+)?(?:the\s+)?)?markup(?:\s+is)?\s*"# + numberCapture + #"\s+on\s+(?:cost(?:\s+of)?\s+)?"# + numberCapture + #"\b"#
        let germanPattern = #"\b(?:was\s+ist\s+|welcher\s+)?(?:(?:die|der|den)\s+)?aufschlag(?:\s+ist)?\s*"# + numberCapture + #"\s+auf\s+(?:kosten(?:\s+von)?\s+)?"# + numberCapture + #"\b"#

        let english = captures(englishPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let profit = double(capture[0]), let cost = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .markup(profit: profit, cost: cost),
                confidence: 0.98,
                interpretation: "markup \(profit) on cost \(cost)"
            )
        }

        let german = captures(germanPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let profit = double(capture[0]), let cost = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .markup(profit: profit, cost: cost),
                confidence: 0.98,
                interpretation: "aufschlag \(profit) auf kosten \(cost)"
            )
        }

        return english + german
    }

    private func parseAmbiguousOnPattern(in text: String) -> [ParseCandidate] {
        let percentPattern = #"\b"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s+(?:on|auf)\s+"# + numberCapture + #"\b"#
        let shorthandPattern = #"\b"# + numberCapture + #"\s+(?:on|auf)\s+"# + numberCapture + #"\b"#

        let percentCandidates = captures(percentPattern, in: text).flatMap { capture -> [ParseCandidate] in
            guard let percent = double(capture[0], treatAsPercent: true), let base = double(capture[1]) else { return [] }

            return [
                ParseCandidate(
                    intent: .percentOf(percent: percent, base: base),
                    confidence: 0.66,
                    interpretation: "\(percent)% of \(base)"
                ),
                ParseCandidate(
                    intent: .addPercent(base: base, percent: percent),
                    confidence: 0.64,
                    interpretation: "\(base) plus \(percent)%"
                )
            ]
        }

        let shorthandCandidates = captures(shorthandPattern, in: text).flatMap { capture -> [ParseCandidate] in
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return [] }

            return [
                ParseCandidate(
                    intent: .percentOf(percent: percent, base: base),
                    confidence: 0.58,
                    interpretation: "\(percent)% of \(base)"
                ),
                ParseCandidate(
                    intent: .addPercent(base: base, percent: percent),
                    confidence: 0.57,
                    interpretation: "\(base) plus \(percent)%"
                )
            ]
        }

        return percentCandidates + shorthandCandidates
    }

    private func rankAndDeduplicate(
        candidates: [ParseCandidate],
        normalizedQuery: String,
        numericTokens: [NumericToken]
    ) -> [ParseCandidate] {
        var bySignature = [String: ParseCandidate]()

        for candidate in candidates {
            var score = candidate.confidence + semanticBoost(for: candidate.intent, query: normalizedQuery)
            let expectedCount = expectedNumericTokenCount(for: candidate.intent)
            if numericTokens.count >= expectedCount {
                score += 0.01
            } else {
                score -= 0.1
            }
            score = min(max(score, 0), 1)
            let rescored = ParseCandidate(
                id: candidate.id,
                intent: candidate.intent,
                confidence: score,
                interpretation: candidate.interpretation
            )

            if let existing = bySignature[rescored.intent.signature] {
                if rescored.confidence > existing.confidence {
                    bySignature[rescored.intent.signature] = rescored
                }
            } else {
                bySignature[rescored.intent.signature] = rescored
            }
        }

        return bySignature.values.sorted { left, right in
            if abs(left.confidence - right.confidence) < 0.0001 {
                return left.interpretation < right.interpretation
            }
            return left.confidence > right.confidence
        }
    }

    private func semanticBoost(for intent: CalculationIntent, query: String) -> Double {
        switch intent {
        case .percentOf:
            let statementPenalty = isStatementRelationQuery(query) ? -0.09 : 0
            return ((query.contains("of") || query.contains("von")) ? 0.03 : 0) + statementPenalty
        case .addPercent:
            return (query.contains("plus")
                    || query.contains("with")
                    || query.contains("add")
                    || query.contains("increase")
                    || query.contains("raise")
                    || query.contains("grow")
                    || query.contains("mit")
                    || query.contains("incl")
                    || query.contains("inkl")
                    || query.contains("zzgl")
                    || query.contains("zuzüglich")
                    || query.contains("zuzueglich")) ? 0.02 : 0
        case .subtractPercent:
            return (query.contains("minus")
                    || query.contains("less")
                    || query.contains("decrease")
                    || query.contains("reduce")
                    || query.contains("lower")
                    || query.contains("drop")
                    || query.contains("weniger")
                    || query.contains("abzüglich")
                    || query.contains("abzueglich")) ? 0.02 : 0
        case .percentChange:
            return (query.contains("change") || query.contains("increase") || query.contains("decrease") || query.contains("veränderung") || query.contains("veraenderung") || query.contains("anstieg") || query.contains("rückgang") || query.contains("rueckgang")) ? 0.03 : 0
        case .discountPercent:
            return (query.contains("discount") || query.contains("rabatt") || query.contains("statt") || query.contains("anstatt")) ? 0.04 : 0
        case .reversePercent:
            return containsAnyHint(in: query, hints: reversePercentWholeHints) ? 0.03 : 0
        case .reversePercentTarget:
            return containsAnyHint(in: query, hints: reversePercentWholeHints) ? 0.03 : 0
        case .reversePercentFindPercent:
            return (query.contains("what percent")
                    || query.contains("wie viel prozent")
                    || query.contains("wieviel prozent")) ? 0.03 : 0
        case .percentOfRelation:
            let relationPromptBoost = (query.contains("what percent") || query.contains("wie viel prozent") || query.contains("wieviel prozent")) ? 0.03 : 0
            return relationPromptBoost + (isStatementRelationQuery(query) ? 0.04 : 0)
        case .tip:
            return (query.contains("tip") || query.contains("trinkgeld")) ? 0.03 : 0
        case .tax:
            return (query.contains("tax")
                    || query.contains("sales tax")
                    || query.contains("steuer")
                    || query.contains("before tax")
                    || query.contains("after tax")
                    || query.contains("vor steuer")
                    || query.contains("nach steuer")
                    || query.contains("net")
                    || query.contains("gross")
                    || query.contains("netto")
                    || query.contains("brutto")) ? 0.03 : 0
        case .vat:
            return (query.contains("vat")
                    || query.contains("mwst")
                    || query.contains("ust")
                    || query.contains("umsatzsteuer")
                    || query.contains("umsatzst")
                    || query.contains("gst")
                    || query.contains("iva")
                    || query.contains("net")
                    || query.contains("gross")
                    || query.contains("netto")
                    || query.contains("brutto")) ? 0.03 : 0
        case .margin:
            return (query.contains("margin")
                    || query.contains("gross margin")
                    || query.contains("profit")
                    || query.contains("marge")
                    || query.contains("bruttomarge")
                    || query.contains("handelsspanne")
                    || query.contains("gewinnspanne")
                    || query.contains("gewinn")) ? 0.03 : 0
        case .markup:
            return (query.contains("markup") || query.contains("aufschlag")) ? 0.03 : 0
        }
    }

    private func expectedNumericTokenCount(for intent: CalculationIntent) -> Int {
        switch intent {
        case .percentOf,
             .addPercent,
             .subtractPercent,
             .percentChange,
             .discountPercent,
             .reversePercent,
             .percentOfRelation,
             .tip,
             .tax,
             .vat,
             .margin,
             .markup:
            return 2
        case .reversePercentTarget,
             .reversePercentFindPercent:
            return 3
        }
    }

    private func captures(_ pattern: String, in text: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return (1..<match.numberOfRanges).compactMap { index in
                let nsRange = match.range(at: index)
                guard let range = Range(nsRange, in: text) else { return nil }
                return String(text[range])
            }
        }
    }

    private func double(_ text: String, treatAsPercent: Bool = false) -> Double? {
        guard treatAsPercent else {
            return QueryNormalizer.parseNumber(text)
        }

        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard !value.isEmpty else { return nil }

        let hasComma = value.contains(",")
        let hasDot = value.contains(".")
        if hasComma != hasDot {
            let separator: Character = hasComma ? "," : "."
            let parts = value.split(separator: separator, omittingEmptySubsequences: false)
            if parts.count == 2, let fractional = parts.last, fractional.count == 3 {
                if hasComma {
                    value = value.replacingOccurrences(of: ",", with: ".")
                }
                if let parsed = Double(value) {
                    return parsed
                }
            }
        }

        return QueryNormalizer.parseNumber(text)
    }

    private func containsAnyHint(in text: String, hints: [String]) -> Bool {
        hints.contains { text.contains($0) }
    }

    private func likelyMissingPreset(in text: String) -> Bool {
        if defaultTaxPercent != nil && defaultTipPercent != nil { return false }

        let hasPercentRate = text.contains("%") || text.contains("percent") || text.contains("prozent")
        if hasPercentRate { return false }

        let taxKeywords = [
            "tax", "sales tax", "vat", "gst", "iva",
            "steuer", "mwst", "ust", "umsatzsteuer", "umsatzst"
        ]
        let tipKeywords = ["tip", "trinkgeld"]
        let hasTaxKeyword = containsAnyHint(in: text, hints: taxKeywords)
        let hasTipKeyword = containsAnyHint(in: text, hints: tipKeywords)

        let missingTaxPreset = defaultTaxPercent == nil && hasTaxKeyword
        let missingTipPreset = defaultTipPercent == nil && hasTipKeyword
        guard missingTaxPreset || missingTipPreset else { return false }

        let contextHints = [
            "plus", "with", "add", "added", "include", "included", "including", "incl", "inc",
            "minus", "subtract", "subtracted", "substract", "substracted", "reduce", "reduced", "reduziere", "reduziert", "reduzieren", "less", "excluding", "excl", "ex", "without",
            "mit", "inkl", "zzgl", "zuzüglich", "zuzueglich",
            "ohne", "abzüglich", "abzueglich", "abzgl",
            "net", "gross", "netto", "brutto", "before tax", "after tax", "vor steuer", "nach steuer",
            "+", "-"
        ]
        return containsAnyHint(in: text, hints: contextHints)
    }

    private func isStatementRelationQuery(_ text: String) -> Bool {
        let pattern = #"\b[-+]?\d+(?:[.,']\d+)*\s+(?:is|are|ist|sind|equals|entsprechen|=)\s+[-+]?\d+(?:[.,']\d+)*\s*(?:%|percent|prozent)\s+(?:of|von)\s+[-+]?\d+(?:[.,']\d+)*\b"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }
}
