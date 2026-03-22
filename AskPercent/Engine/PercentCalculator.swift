import Foundation

enum CalculationError: LocalizedError, Equatable {
    case divideByZero
    case invalidInput(String)

    var errorDescription: String? {
        switch self {
        case .divideByZero:
            return "Cannot divide by zero."
        case let .invalidInput(message):
            return message
        }
    }
}

struct PercentCalculator {
    func calculate(intent: CalculationIntent, language: AppLanguage = .english) throws -> CalculationResult {
        let resolvedLanguage = language.resolved
        switch intent {
        case let .percentOf(percent, base):
            let value = percent / 100 * base
            return CalculationResult(
                intentType: .percentOf,
                primaryLabel: labelResult(resolvedLanguage),
                value: value,
                isPercentValue: false,
                explanation: resolvedLanguage == .german
                ? "\(compact(percent))% von \(compact(base)) sind \(compact(value))."
                : "\(compact(percent))% of \(compact(base)) is \(compact(value)).",
                formula: "(\(compact(percent)) / 100) × \(compact(base))",
                breakdown: [
                    ResultBreakdownItem(label: labelPercent(resolvedLanguage), value: percent, isPercent: true),
                    ResultBreakdownItem(label: labelBase(resolvedLanguage), value: base)
                ]
            )

        case let .addPercent(base, percent):
            let value = base * (1 + percent / 100)
            let delta = base * percent / 100
            return CalculationResult(
                intentType: .addPercent,
                primaryLabel: labelTotal(resolvedLanguage),
                value: value,
                isPercentValue: false,
                explanation: resolvedLanguage == .german
                ? "\(compact(percent))% von \(compact(base)) sind \(compact(delta)), also ist das Gesamt \(compact(value))."
                : "\(compact(percent))% of \(compact(base)) is \(compact(delta)), so the total is \(compact(value)).",
                formula: "\(compact(base)) × (1 + (\(compact(percent)) / 100))",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Hinzugefügter Betrag" : "Added amount", value: delta),
                    ResultBreakdownItem(label: labelBase(resolvedLanguage), value: base)
                ]
            )

        case let .subtractPercent(base, percent):
            let value = base * (1 - percent / 100)
            let delta = base * percent / 100
            return CalculationResult(
                intentType: .subtractPercent,
                primaryLabel: labelTotal(resolvedLanguage),
                value: value,
                isPercentValue: false,
                explanation: resolvedLanguage == .german
                ? "\(compact(percent))% von \(compact(base)) sind \(compact(delta)), also ist das Ergebnis \(compact(value))."
                : "\(compact(percent))% of \(compact(base)) is \(compact(delta)), so the result is \(compact(value)).",
                formula: "\(compact(base)) × (1 - (\(compact(percent)) / 100))",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Abgezogener Betrag" : "Subtracted amount", value: delta),
                    ResultBreakdownItem(label: labelBase(resolvedLanguage), value: base)
                ]
            )

        case let .percentChange(old, new):
            guard old != 0 else { throw CalculationError.divideByZero }
            let value = (new - old) / old * 100
            return CalculationResult(
                intentType: .percentChange,
                primaryLabel: resolvedLanguage == .german ? "Veränderung" : "Change",
                value: value,
                isPercentValue: true,
                explanation: resolvedLanguage == .german
                ? "\(compact(new)) sind \(compact(value))% relativ zu \(compact(old))."
                : "\(compact(new)) is \(compact(value))% relative to \(compact(old)).",
                formula: "((\(compact(new)) - \(compact(old))) / \(compact(old))) × 100",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Alter Wert" : "Old value", value: old),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Neuer Wert" : "New value", value: new)
                ]
            )

        case let .discountPercent(original, new):
            guard original != 0 else { throw CalculationError.divideByZero }
            let value = (original - new) / original * 100
            let saved = original - new
            return CalculationResult(
                intentType: .discountPercent,
                primaryLabel: resolvedLanguage == .german ? "Rabatt" : "Discount",
                value: value,
                isPercentValue: true,
                explanation: resolvedLanguage == .german
                ? "Du sparst \(compact(saved)) von \(compact(original)), das sind \(compact(value))% Rabatt."
                : "You saved \(compact(saved)) from \(compact(original)), which is \(compact(value))% discount.",
                formula: "((\(compact(original)) - \(compact(new))) / \(compact(original))) × 100",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Original" : "Original", value: original),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Bezahlt" : "Paid", value: new),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Gespart" : "Saved", value: saved)
                ]
            )

        case let .reversePercent(percent, partial):
            guard percent != 0 else { throw CalculationError.divideByZero }
            let value = partial / (percent / 100)
            return CalculationResult(
                intentType: .reversePercent,
                primaryLabel: resolvedLanguage == .german ? "100%-Wert" : "100% value",
                value: value,
                isPercentValue: false,
                explanation: resolvedLanguage == .german
                ? "Wenn \(compact(percent))% \(compact(partial)) sind, dann sind 100% \(compact(value))."
                : "If \(compact(percent))% is \(compact(partial)), then 100% is \(compact(value)).",
                formula: "\(compact(partial)) / (\(compact(percent)) / 100)",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Bekannter Anteil" : "Known part", value: partial),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Bekannter Prozentsatz" : "Known percent", value: percent, isPercent: true)
                ]
            )

        case let .reversePercentTarget(knownPercent, knownPart, targetPercent):
            guard knownPercent != 0 else { throw CalculationError.divideByZero }
            let whole = knownPart / (knownPercent / 100)
            let value = whole * (targetPercent / 100)
            let primaryLabel = resolvedLanguage == .german
            ? "\(compact(targetPercent))%-Wert"
            : "\(compact(targetPercent))% value"
            return CalculationResult(
                intentType: .reversePercent,
                primaryLabel: primaryLabel,
                value: value,
                isPercentValue: false,
                explanation: resolvedLanguage == .german
                ? "Wenn \(compact(knownPercent))% \(compact(knownPart)) sind, dann sind \(compact(targetPercent))% \(compact(value))."
                : "If \(compact(knownPercent))% is \(compact(knownPart)), then \(compact(targetPercent))% is \(compact(value)).",
                formula: "(\(compact(knownPart)) / (\(compact(knownPercent)) / 100)) × (\(compact(targetPercent)) / 100)",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Bekannter Anteil" : "Known part", value: knownPart),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Bekannter Prozentsatz" : "Known percent", value: knownPercent, isPercent: true),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Gesuchter Prozentsatz" : "Target percent", value: targetPercent, isPercent: true)
                ]
            )

        case let .reversePercentFindPercent(knownPercent, knownPart, targetPart):
            guard knownPart != 0 else { throw CalculationError.divideByZero }
            let value = targetPart * knownPercent / knownPart
            return CalculationResult(
                intentType: .reversePercent,
                primaryLabel: resolvedLanguage == .german ? "Prozent" : "Percent",
                value: value,
                isPercentValue: true,
                explanation: resolvedLanguage == .german
                ? "Wenn \(compact(knownPart)) \(compact(knownPercent))% sind, dann sind \(compact(targetPart)) \(compact(value))%."
                : "If \(compact(knownPart)) is \(compact(knownPercent))%, then \(compact(targetPart)) is \(compact(value))%.",
                formula: "(\(compact(targetPart)) × \(compact(knownPercent))) / \(compact(knownPart))",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Bekannter Anteil" : "Known part", value: knownPart),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Bekannter Prozentsatz" : "Known percent", value: knownPercent, isPercent: true),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Gesuchter Anteil" : "Target part", value: targetPart)
                ]
            )

        case let .percentOfRelation(part, whole):
            guard whole != 0 else { throw CalculationError.divideByZero }
            let value = part / whole * 100
            return CalculationResult(
                intentType: .percentOfRelation,
                primaryLabel: resolvedLanguage == .german ? "Prozent" : "Percent",
                value: value,
                isPercentValue: true,
                explanation: resolvedLanguage == .german
                ? "\(compact(part)) sind \(compact(value))% von \(compact(whole))."
                : "\(compact(part)) is \(compact(value))% of \(compact(whole)).",
                formula: "(\(compact(part)) / \(compact(whole))) × 100",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Anteil" : "Part", value: part),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Ganzes" : "Whole", value: whole)
                ]
            )

        case let .tip(base, percent):
            let tip = percent / 100 * base
            let total = base + tip
            return CalculationResult(
                intentType: .tip,
                primaryLabel: labelTotal(resolvedLanguage),
                value: total,
                isPercentValue: false,
                explanation: resolvedLanguage == .german
                ? "\(compact(percent))% von \(compact(base)) sind \(compact(tip)), also ist die Summe \(compact(total))."
                : "\(compact(percent))% of \(compact(base)) is \(compact(tip)), so the total is \(compact(total)).",
                formula: "\(compact(base)) × (1 + (\(compact(percent)) / 100))",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Trinkgeld" : "Tip amount", value: tip),
                    ResultBreakdownItem(label: labelBase(resolvedLanguage), value: base)
                ]
            )

        case let .tax(base, percent):
            let tax = percent / 100 * base
            let total = base + tax
            return CalculationResult(
                intentType: .tax,
                primaryLabel: labelTotal(resolvedLanguage),
                value: total,
                isPercentValue: false,
                explanation: resolvedLanguage == .german
                ? "\(compact(percent))% Steuer auf \(compact(base)) sind \(compact(tax)), Gesamt \(compact(total))."
                : "\(compact(percent))% tax on \(compact(base)) is \(compact(tax)), total \(compact(total)).",
                formula: "\(compact(base)) × (1 + (\(compact(percent)) / 100))",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Steuerbetrag" : "Tax amount", value: tax),
                    ResultBreakdownItem(label: labelBase(resolvedLanguage), value: base)
                ]
            )

        case let .vat(base, percent):
            let vat = percent / 100 * base
            let total = base + vat
            return CalculationResult(
                intentType: .vat,
                primaryLabel: labelTotal(resolvedLanguage),
                value: total,
                isPercentValue: false,
                explanation: resolvedLanguage == .german
                ? "\(compact(percent))% MwSt auf \(compact(base)) sind \(compact(vat)), Gesamt \(compact(total))."
                : "\(compact(percent))% VAT on \(compact(base)) is \(compact(vat)), total \(compact(total)).",
                formula: "\(compact(base)) × (1 + (\(compact(percent)) / 100))",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "MwSt-Betrag" : "VAT amount", value: vat),
                    ResultBreakdownItem(label: labelBase(resolvedLanguage), value: base)
                ]
            )

        case let .margin(profit, revenue):
            guard revenue != 0 else { throw CalculationError.divideByZero }
            let value = profit / revenue * 100
            return CalculationResult(
                intentType: .margin,
                primaryLabel: resolvedLanguage == .german ? "Marge" : "Margin",
                value: value,
                isPercentValue: true,
                explanation: resolvedLanguage == .german
                ? "Marge ist Gewinn geteilt durch Umsatz: \(compact(value))%."
                : "Margin is profit divided by revenue: \(compact(value))%.",
                formula: "(\(compact(profit)) / \(compact(revenue))) × 100",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Gewinn" : "Profit", value: profit),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Umsatz" : "Revenue", value: revenue)
                ]
            )

        case let .markup(profit, cost):
            guard cost != 0 else { throw CalculationError.divideByZero }
            let value = profit / cost * 100
            return CalculationResult(
                intentType: .markup,
                primaryLabel: resolvedLanguage == .german ? "Aufschlag" : "Markup",
                value: value,
                isPercentValue: true,
                explanation: resolvedLanguage == .german
                ? "Aufschlag ist Gewinn geteilt durch Kosten: \(compact(value))%."
                : "Markup is profit divided by cost: \(compact(value))%.",
                formula: "(\(compact(profit)) / \(compact(cost))) × 100",
                breakdown: [
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Gewinn" : "Profit", value: profit),
                    ResultBreakdownItem(label: resolvedLanguage == .german ? "Kosten" : "Cost", value: cost)
                ]
            )
        }
    }

    private func labelResult(_ language: ResolvedAppLanguage) -> String {
        language == .german ? "Ergebnis" : "Result"
    }

    private func labelTotal(_ language: ResolvedAppLanguage) -> String {
        language == .german ? "Gesamt" : "Total"
    }

    private func labelPercent(_ language: ResolvedAppLanguage) -> String {
        language == .german ? "Prozent" : "Percent"
    }

    private func labelBase(_ language: ResolvedAppLanguage) -> String {
        language == .german ? "Basis" : "Base"
    }

    private func compact(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.6f", value).replacingOccurrences(of: "0+$", with: "", options: .regularExpression).replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
    }
}
