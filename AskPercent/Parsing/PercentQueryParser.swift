import Foundation

final class PercentQueryParser {
    private let normalizer: QueryNormalizer
    private let numberCapture = #"([-+]?\d+(?:[.,]\d+)?)"#
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

    init(normalizer: QueryNormalizer = QueryNormalizer()) {
        self.normalizer = normalizer
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
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.98,
                interpretation: "\(percent)% of \(base)"
            )
        }

        let wordMatches: [[String]] = captures(wordPattern, in: text)
        let wordCandidates: [ParseCandidate] = wordMatches.compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.95,
                interpretation: "\(percent)% of \(base)"
            )
        }

        let germanSymbolMatches: [[String]] = captures(germanSymbolPattern, in: text)
        let germanSymbolCandidates: [ParseCandidate] = germanSymbolMatches.compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.98,
                interpretation: "\(percent)% von \(base)"
            )
        }

        let germanWordMatches: [[String]] = captures(germanWordPattern, in: text)
        let germanWordCandidates: [ParseCandidate] = germanWordMatches.compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.95,
                interpretation: "\(percent)% von \(base)"
            )
        }

        return symbolCandidates + wordCandidates + germanSymbolCandidates + germanWordCandidates
    }

    private func parseAddPercent(in text: String) -> [ParseCandidate] {
        let excludedKindsPattern = #"(?:tip|tax|vat|trinkgeld|steuer|mwst|ust|umsatzsteuer)"#
        let connectorPattern = #"(?:plus|add|added|with|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl)"#
        let wordPattern = #"\b"# + numberCapture + #"\s*"# + connectorPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?!\s*"# + excludedKindsPattern + #")"#
        let symbolPattern = #"\b"# + numberCapture + #"\s*\+\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?!\s*"# + excludedKindsPattern + #")"#

        let wordMatches: [[String]] = captures(wordPattern, in: text)
        let wordCandidates: [ParseCandidate] = wordMatches.compactMap { capture -> ParseCandidate? in
            guard
                let base = double(capture[0]),
                let percent = double(capture[1])
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
                let percent = double(capture[1])
            else { return nil }

            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.95,
                interpretation: "\(base) plus \(percent)%"
            )
        }

        return wordCandidates + symbolCandidates
    }

    private func parseSubtractPercent(in text: String) -> [ParseCandidate] {
        let connectorPattern = #"(?:minus|less|reduce(?:d)?|weniger|abzüglich|abzueglich)"#
        let wordPattern = #"\b"# + numberCapture + #"\s*"# + connectorPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern
        let symbolPattern = #"\b"# + numberCapture + #"\s*-\s*"# + numberCapture + #"\s*"# + percentTokenPattern

        let wordMatches: [[String]] = captures(wordPattern, in: text)
        let wordCandidates: [ParseCandidate] = wordMatches.compactMap { capture -> ParseCandidate? in
            guard
                let base = double(capture[0]),
                let percent = double(capture[1])
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
                let percent = double(capture[1])
            else { return nil }

            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.95,
                interpretation: "\(base) minus \(percent)%"
            )
        }

        return wordCandidates + symbolCandidates
    }

    private func parseIncreaseDecreaseBy(in text: String) -> [ParseCandidate] {
        let increasePattern = #"\b(?:increase|raise|grow)\s+"# + numberCapture + #"\s+by\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\b|$)"#
        let decreasePattern = #"\b(?:decrease|reduce|lower|drop)\s+"# + numberCapture + #"\s+by\s+"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\b|$)"#

        let increaseCandidates = captures(increasePattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let base = double(capture[0]), let percent = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .addPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "increase \(base) by \(percent)%"
            )
        }

        let decreaseCandidates = captures(decreasePattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let base = double(capture[0]), let percent = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .subtractPercent(base: base, percent: percent),
                confidence: 0.97,
                interpretation: "decrease \(base) by \(percent)%"
            )
        }

        return increaseCandidates + decreaseCandidates
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
        let germanPattern = #"\b(?:ich\s+)?(?:habe\s+)?(?:bezahlt\s+)?"# + numberCapture + #"\s+(?:statt|anstatt)\s+"# + numberCapture + #"\b"#

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

        return english + german
    }

    private func parseReversePercent(in text: String) -> [ParseCandidate] {
        let standardPattern = #"\b(?:if\s+|wenn\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*(?:is|are|equals|=|sind|ist|entsprechen|betragen)\s*"# + numberCapture + #"\b"#
        let invertedGermanPattern = #"\b(?:wenn\s+)?"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + numberCapture + #"\s*(?:sind|ist)\b"#
        let swappedOrderPattern = #"\b"# + numberCapture + #"\s*(?:is|are|equals|=|sind|ist|entsprechen|betragen)\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"(?:\b|$)"#
        let hasWholeHint = containsAnyHint(in: text, hints: reversePercentWholeHints)

        let standard = captures(standardPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard
                let percent = double(capture[0]),
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
                let percent = double(capture[0]),
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
                let percent = double(capture[1])
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
        let directPattern = #"\b"# + numberCapture + #"\s+is\s+what\s+percent\s+of\s+"# + numberCapture + #"\b"#
        let inversePattern = #"\bwhat\s+percent\s+is\s+"# + numberCapture + #"\s+of\s+"# + numberCapture + #"\b"#
        let shorthandPattern = #"\b"# + numberCapture + #"\s+of\s+"# + numberCapture + #"\b"#

        let germanDirectPattern = #"\b"# + numberCapture + #"\s+(?:sind|ist)\s+(?:wie\s+viel|wieviel)\s+prozent\s+von\s+"# + numberCapture + #"\b"#
        let germanInversePattern = #"\b(?:wie\s+viel|wieviel)\s+prozent\s+(?:sind|ist)\s+"# + numberCapture + #"\s+von\s+"# + numberCapture + #"\b"#
        let germanShorthandPattern = #"\b"# + numberCapture + #"\s+von\s+"# + numberCapture + #"\b"#

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

        return direct + inverse + shorthand + germanDirect + germanInverse + germanShorthand
    }

    private func parseTipTaxVat(in text: String) -> [ParseCandidate] {
        var results = [ParseCandidate]()

        let connectorPattern = #"(?:with|plus|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl)"#
        let kindPattern = #"(tip|tax|vat|trinkgeld|steuer|mwst|ust|umsatzsteuer)"#

        let trailingKindPattern = #"\b"# + numberCapture + #"\s*"# + connectorPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + kindPattern + #"\b"#
        for capture in captures(trailingKindPattern, in: text) {
            guard
                let base = double(capture[0]),
                let percent = double(capture[1])
            else { continue }

            let kind = capture[2]
            results.append(candidateForKind(base: base, percent: percent, kind: kind, confidence: 0.99))
        }

        let middleKindPattern = #"\b"# + numberCapture + #"\s*"# + kindPattern + #"\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\b"#
        for capture in captures(middleKindPattern, in: text) {
            guard
                let base = double(capture[0]),
                let percent = double(capture[2])
            else { continue }

            let kind = capture[1]
            results.append(candidateForKind(base: base, percent: percent, kind: kind, confidence: 0.97))
        }

        let rateOnlyPattern = #"\b(?:price|preis)?\s*(?:with|plus|including|incl(?:uding)?|mit|inkl(?:usive)?|zuzüglich|zuzueglich|zzgl)\s*"# + numberCapture + #"\s*"# + percentTokenPattern + #"\s*"# + kindPattern + #"\b"#
        for capture in captures(rateOnlyPattern, in: text) {
            guard let percent = double(capture[0]) else { continue }
            let kind = capture[1]
            results.append(candidateForKind(base: 100, percent: percent, kind: kind, confidence: 0.55))
        }

        return results
    }

    private func candidateForKind(base: Double, percent: Double, kind: String, confidence: Double) -> ParseCandidate {
        switch kind {
        case "tip", "trinkgeld":
            return ParseCandidate(intent: .tip(base: base, percent: percent), confidence: confidence, interpretation: "\(base) with \(percent)% tip")
        case "tax", "steuer":
            return ParseCandidate(intent: .tax(base: base, percent: percent), confidence: confidence, interpretation: "\(base) with \(percent)% tax")
        default:
            return ParseCandidate(intent: .vat(base: base, percent: percent), confidence: confidence, interpretation: "\(base) with \(percent)% VAT")
        }
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
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.96,
                interpretation: "\(percent)% profit of \(base)"
            )
        }

        let wordCandidates: [ParseCandidate] = captures(wordPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.95,
                interpretation: "\(percent)% profit of \(base)"
            )
        }

        let germanSymbolCandidates: [ParseCandidate] = captures(germanSymbolPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return nil }
            return ParseCandidate(
                intent: .percentOf(percent: percent, base: base),
                confidence: 0.96,
                interpretation: "\(percent)% gewinn von \(base)"
            )
        }

        let germanWordCandidates: [ParseCandidate] = captures(germanWordPattern, in: text).compactMap { capture -> ParseCandidate? in
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return nil }
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
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return [] }

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
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return [] }

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
            guard let percent = double(capture[0]), let base = double(capture[1]) else { return [] }

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
            return (query.contains("of") || query.contains("von")) ? 0.03 : 0
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
        case .percentOfRelation:
            return (query.contains("what percent") || query.contains("wie viel prozent") || query.contains("wieviel prozent")) ? 0.03 : 0
        case .tip:
            return (query.contains("tip") || query.contains("trinkgeld")) ? 0.03 : 0
        case .tax:
            return (query.contains("tax") || query.contains("steuer")) ? 0.03 : 0
        case .vat:
            return (query.contains("vat") || query.contains("mwst") || query.contains("ust") || query.contains("umsatzsteuer")) ? 0.03 : 0
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

    private func double(_ text: String) -> Double? {
        QueryNormalizer.parseNumber(text)
    }

    private func containsAnyHint(in text: String, hints: [String]) -> Bool {
        hints.contains { text.contains($0) }
    }
}
