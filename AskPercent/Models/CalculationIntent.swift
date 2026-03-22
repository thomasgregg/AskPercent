import Foundation

enum CalculationIntentType: String, Codable, CaseIterable {
    case percentOf
    case addPercent
    case subtractPercent
    case percentChange
    case discountPercent
    case reversePercent
    case percentOfRelation
    case tip
    case tax
    case vat
    case margin
    case markup
}

enum CalculationIntent: Equatable {
    case percentOf(percent: Double, base: Double)
    case addPercent(base: Double, percent: Double)
    case subtractPercent(base: Double, percent: Double)
    case percentChange(old: Double, new: Double)
    case discountPercent(original: Double, new: Double)
    case reversePercent(percent: Double, partial: Double)
    case reversePercentTarget(knownPercent: Double, knownPart: Double, targetPercent: Double)
    case reversePercentFindPercent(knownPercent: Double, knownPart: Double, targetPart: Double)
    case percentOfRelation(part: Double, whole: Double)
    case tip(base: Double, percent: Double)
    case tax(base: Double, percent: Double)
    case vat(base: Double, percent: Double)
    case margin(profit: Double, revenue: Double)
    case markup(profit: Double, cost: Double)

    var type: CalculationIntentType {
        switch self {
        case .percentOf:
            return .percentOf
        case .addPercent:
            return .addPercent
        case .subtractPercent:
            return .subtractPercent
        case .percentChange:
            return .percentChange
        case .discountPercent:
            return .discountPercent
        case .reversePercent:
            return .reversePercent
        case .reversePercentTarget:
            return .reversePercent
        case .reversePercentFindPercent:
            return .reversePercent
        case .percentOfRelation:
            return .percentOfRelation
        case .tip:
            return .tip
        case .tax:
            return .tax
        case .vat:
            return .vat
        case .margin:
            return .margin
        case .markup:
            return .markup
        }
    }

    var signature: String {
        switch self {
        case let .percentOf(percent, base):
            return "percentOf|\(percent)|\(base)"
        case let .addPercent(base, percent):
            return "addPercent|\(base)|\(percent)"
        case let .subtractPercent(base, percent):
            return "subtractPercent|\(base)|\(percent)"
        case let .percentChange(old, new):
            return "percentChange|\(old)|\(new)"
        case let .discountPercent(original, new):
            return "discountPercent|\(original)|\(new)"
        case let .reversePercent(percent, partial):
            return "reversePercent|\(percent)|\(partial)"
        case let .reversePercentTarget(knownPercent, knownPart, targetPercent):
            return "reversePercentTarget|\(knownPercent)|\(knownPart)|\(targetPercent)"
        case let .reversePercentFindPercent(knownPercent, knownPart, targetPart):
            return "reversePercentFindPercent|\(knownPercent)|\(knownPart)|\(targetPart)"
        case let .percentOfRelation(part, whole):
            return "percentOfRelation|\(part)|\(whole)"
        case let .tip(base, percent):
            return "tip|\(base)|\(percent)"
        case let .tax(base, percent):
            return "tax|\(base)|\(percent)"
        case let .vat(base, percent):
            return "vat|\(base)|\(percent)"
        case let .margin(profit, revenue):
            return "margin|\(profit)|\(revenue)"
        case let .markup(profit, cost):
            return "markup|\(profit)|\(cost)"
        }
    }
}
