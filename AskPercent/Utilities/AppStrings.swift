import Foundation

struct AppStrings {
    private let language: ResolvedAppLanguage

    init(language: AppLanguage) {
        self.language = language.resolved
    }

    var appTitle: String { "AskPercent" }

    var homeTab: String {
        switch language {
        case .english: return "Home"
        case .german: return "Home"
        }
    }

    var historyTab: String {
        switch language {
        case .english: return "History"
        case .german: return "Verlauf"
        }
    }

    var favoritesTab: String {
        switch language {
        case .english: return "Favorites"
        case .german: return "Favoriten"
        }
    }

    var settingsTab: String {
        switch language {
        case .english: return "Settings"
        case .german: return "Einstellungen"
        }
    }

    var headerTitle: String {
        switch language {
        case .english: return "Ask your percentage question"
        case .german: return "Stelle deine Prozentfrage"
        }
    }

    var headerSubtitle: String {
        switch language {
        case .english: return "Type naturally. The parser runs locally and updates live."
        case .german: return "Stell deine Frage einfach in natürlicher Sprache. Der Parser läuft lokal und aktualisiert live."
        }
    }

    var queryPlaceholder: String {
        switch language {
        case .english: return "e.g. 240 with 15% tip"
        case .german: return "z. B. 240 mit 15% Trinkgeld"
        }
    }

    var ambiguityHint: String {
        switch language {
        case .english: return "Interpretation is ambiguous. Review alternatives below."
        case .german: return "Mehrdeutige Eingabe. Die untenstehenden Alternativen prüfen."
        }
    }

    var alternativesTitle: String {
        switch language {
        case .english: return "Alternative interpretations"
        case .german: return "Alternative Interpretationen"
        }
    }

    var emptyStateTitle: String {
        switch language {
        case .english: return "Try one of the examples above"
        case .german: return "Probiere eins der Beispiele oben"
        }
    }

    var emptyStateBody: String {
        switch language {
        case .english:
            return "Examples: '25% of 167', 'from 80 to 96', '41.75 is what percent of 167'."
        case .german:
            return "Beispiele: '25% von 167', 'von 80 auf 96', '41,75 sind wie viel Prozent von 167'."
        }
    }

    var addFavoriteAccessibility: String {
        switch language {
        case .english: return "Add favorite"
        case .german: return "Zu Favoriten hinzufügen"
        }
    }

    var removeFavoriteAccessibility: String {
        switch language {
        case .english: return "Remove favorite"
        case .german: return "Aus Favoriten entfernen"
        }
    }

    var clearQueryAccessibility: String {
        switch language {
        case .english: return "Clear query"
        case .german: return "Eingabe löschen"
        }
    }

    var copyResultAction: String {
        switch language {
        case .english: return "Copy Result"
        case .german: return "Ergebnis kopieren"
        }
    }

    var copyFullDetailsAction: String {
        switch language {
        case .english: return "Copy Full Details"
        case .german: return "Alle Details kopieren"
        }
    }

    var copyQuestionLabel: String {
        switch language {
        case .english: return "Question"
        case .german: return "Frage"
        }
    }

    var copyExplanationLabel: String {
        switch language {
        case .english: return "Explanation"
        case .german: return "Erklärung"
        }
    }

    var copyBreakdownLabel: String {
        switch language {
        case .english: return "Breakdown"
        case .german: return "Aufschlüsselung"
        }
    }

    var formulaLabel: String {
        switch language {
        case .english: return "Formula"
        case .german: return "Formel"
        }
    }

    var confidencePrefix: String {
        switch language {
        case .english: return "Confidence"
        case .german: return "Sicherheit"
        }
    }

    var historyTitle: String {
        switch language {
        case .english: return "History"
        case .german: return "Verlauf"
        }
    }

    var historyTodaySection: String {
        switch language {
        case .english: return "Today"
        case .german: return "Heute"
        }
    }

    var historyYesterdaySection: String {
        switch language {
        case .english: return "Yesterday"
        case .german: return "Gestern"
        }
    }

    var historyEmptyTitle: String {
        switch language {
        case .english: return "No History Yet"
        case .german: return "Noch kein Verlauf"
        }
    }

    var historyEmptyBody: String {
        switch language {
        case .english: return "Your solved percentage questions appear here."
        case .german: return "Hier erscheinen deine berechneten Prozentfragen."
        }
    }

    var favoritesTitle: String {
        switch language {
        case .english: return "Favorites"
        case .german: return "Favoriten"
        }
    }

    var favoritesEmptyTitle: String {
        switch language {
        case .english: return "No Favorites"
        case .german: return "Keine Favoriten"
        }
    }

    var favoritesEmptyBody: String {
        switch language {
        case .english: return "Save calculations from the Home screen for quick access."
        case .german: return "Speichere Berechnungen auf der Startseite für schnellen Zugriff."
        }
    }

    var settingsTitle: String {
        switch language {
        case .english: return "Settings"
        case .german: return "Einstellungen"
        }
    }

    var settingsCalculationSection: String {
        switch language {
        case .english: return "Calculation"
        case .german: return "Berechnung"
        }
    }

    var settingsLanguageFormatSection: String {
        switch language {
        case .english: return "Language & Format"
        case .german: return "Sprache & Format"
        }
    }

    var settingsDataSection: String {
        switch language {
        case .english: return "Data"
        case .german: return "Daten"
        }
    }

    var settingsLanguageLabel: String {
        switch language {
        case .english: return "Language"
        case .german: return "Sprache"
        }
    }

    var settingsPrecisionLabel: String {
        switch language {
        case .english: return "Decimal precision"
        case .german: return "Dezimalstellen"
        }
    }

    var settingsNumberFormatLabel: String {
        switch language {
        case .english: return "Number format"
        case .german: return "Zahlenformat"
        }
    }

    var settingsShowFormulaLabel: String {
        switch language {
        case .english: return "Show formula"
        case .german: return "Formel anzeigen"
        }
    }

    var settingsHapticsLabel: String {
        switch language {
        case .english: return "Haptics"
        case .german: return "Haptik"
        }
    }

    var settingsClearHistoryButton: String {
        switch language {
        case .english: return "Clear History"
        case .german: return "Verlauf löschen"
        }
    }

    var settingsClearFavoritesButton: String {
        switch language {
        case .english: return "Clear Favorites"
        case .german: return "Favoriten löschen"
        }
    }

    var settingsClearHistoryTitle: String {
        switch language {
        case .english: return "Clear all history?"
        case .german: return "Gesamten Verlauf löschen?"
        }
    }

    var settingsClearFavoritesTitle: String {
        switch language {
        case .english: return "Clear all favorites?"
        case .german: return "Alle Favoriten löschen?"
        }
    }

    var settingsClearHistoryMessage: String {
        switch language {
        case .english: return "This removes all stored calculations."
        case .german: return "Dadurch werden alle gespeicherten Berechnungen entfernt."
        }
    }

    var settingsClearFavoritesMessage: String {
        switch language {
        case .english: return "This removes all saved favorites."
        case .german: return "Dadurch werden alle gespeicherten Favoriten entfernt."
        }
    }

    var cancelButton: String {
        switch language {
        case .english: return "Cancel"
        case .german: return "Abbrechen"
        }
    }

    var clearButton: String {
        switch language {
        case .english: return "Clear"
        case .german: return "Löschen"
        }
    }

    var invalidMathMessage: String {
        switch language {
        case .english:
            return "I found a pattern, but the math is invalid (for example, division by zero)."
        case .german:
            return "Ich habe ein Muster erkannt, aber die Rechnung ist ungültig (z. B. Division durch null)."
        }
    }

    var parseFailureNoNumbers: String {
        switch language {
        case .english:
            return "I couldn't find the numbers in that question. Try something like '25% of 167'."
        case .german:
            return "Ich konnte keine Zahlen in der Frage erkennen. Probiere z. B. '25% von 167'."
        }
    }

    var parseFailureLowConfidence: String {
        switch language {
        case .english:
            return "I couldn't confidently parse that. Try examples like '25% of 167' or 'from 80 to 96'."
        case .german:
            return "Ich konnte das nicht sicher interpretieren. Probiere z. B. '25% von 167' oder 'von 80 auf 96'."
        }
    }

    var examplePrompts: [String] {
        switch language {
        case .english:
            return [
                "25% of 167",
                "167 plus 25%",
                "899 minus 12%",
                "from 80 to 96",
                "if 30% is 45 what is 100%",
                "240 with 15% tip",
                "85 plus 19% VAT",
                "41.75 is what percent of 167",
                "what margin is 40 on 120",
                "what markup is 40 on cost 120"
            ]
        case .german:
            return [
                "25% von 167",
                "167 plus 25 prozent",
                "899 minus 12 prozent",
                "von 80 auf 96",
                "wenn 30 prozent sind 45 was sind 100 prozent",
                "240 mit 15% trinkgeld",
                "85 plus 19% mwst",
                "41,75 sind wie viel prozent von 167",
                "was ist die marge 40 auf 120",
                "was ist der aufschlag 40 auf kosten 120"
            ]
        }
    }

    func label(for intentType: CalculationIntentType) -> String {
        switch (language, intentType) {
        case (.english, .percentOf): return "Percent of"
        case (.english, .addPercent): return "Add percent"
        case (.english, .subtractPercent): return "Subtract percent"
        case (.english, .percentChange): return "Percent change"
        case (.english, .discountPercent): return "Discount"
        case (.english, .reversePercent): return "Reverse percent"
        case (.english, .percentOfRelation): return "Percent relation"
        case (.english, .tip): return "Tip"
        case (.english, .tax): return "Tax"
        case (.english, .vat): return "VAT"
        case (.english, .margin): return "Margin"
        case (.english, .markup): return "Markup"
        case (.german, .percentOf): return "Prozent von"
        case (.german, .addPercent): return "Prozent addieren"
        case (.german, .subtractPercent): return "Prozent abziehen"
        case (.german, .percentChange): return "Prozentänderung"
        case (.german, .discountPercent): return "Rabatt"
        case (.german, .reversePercent): return "Rückrechnung"
        case (.german, .percentOfRelation): return "Prozentanteil"
        case (.german, .tip): return "Trinkgeld"
        case (.german, .tax): return "Steuer"
        case (.german, .vat): return "MwSt"
        case (.german, .margin): return "Marge"
        case (.german, .markup): return "Aufschlag"
        }
    }

    func alternativeInterpretation(for intent: CalculationIntent) -> String {
        switch intent {
        case let .percentOf(percent, base):
            return language == .german ? "\(compact(percent))% von \(compact(base))" : "\(compact(percent))% of \(compact(base))"
        case let .addPercent(base, percent):
            return language == .german ? "\(compact(base)) plus \(compact(percent))%" : "\(compact(base)) plus \(compact(percent))%"
        case let .subtractPercent(base, percent):
            return language == .german ? "\(compact(base)) minus \(compact(percent))%" : "\(compact(base)) minus \(compact(percent))%"
        case let .percentChange(old, new):
            return language == .german ? "Prozentänderung von \(compact(old)) auf \(compact(new))" : "percent change from \(compact(old)) to \(compact(new))"
        case let .discountPercent(original, new):
            return language == .german ? "Rabatt von \(compact(original)) auf \(compact(new))" : "discount from \(compact(original)) to \(compact(new))"
        case let .reversePercent(percent, partial):
            return language == .german ? "Wenn \(compact(percent))% \(compact(partial)) sind, was sind 100%?" : "if \(compact(percent))% is \(compact(partial)), what is 100%"
        case let .percentOfRelation(part, whole):
            return language == .german ? "Wie viel Prozent sind \(compact(part)) von \(compact(whole))?" : "what percent is \(compact(part)) of \(compact(whole))"
        case let .tip(base, percent):
            return language == .german ? "\(compact(base)) mit \(compact(percent))% Trinkgeld" : "\(compact(base)) with \(compact(percent))% tip"
        case let .tax(base, percent):
            return language == .german ? "\(compact(base)) mit \(compact(percent))% Steuer" : "\(compact(base)) with \(compact(percent))% tax"
        case let .vat(base, percent):
            return language == .german ? "\(compact(base)) mit \(compact(percent))% MwSt" : "\(compact(base)) with \(compact(percent))% VAT"
        case let .margin(profit, revenue):
            return language == .german ? "Marge \(compact(profit)) auf \(compact(revenue))" : "margin \(compact(profit)) on \(compact(revenue))"
        case let .markup(profit, cost):
            return language == .german ? "Aufschlag \(compact(profit)) auf Kosten \(compact(cost))" : "markup \(compact(profit)) on cost \(compact(cost))"
        }
    }

    private func compact(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.6f", value)
            .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
    }
}
