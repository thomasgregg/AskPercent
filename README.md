# AskPercent

AskPercent is a native iOS SwiftUI MVP for deterministic natural-language percentage calculations.

## What It Does
- Local-only parsing and calculation (no backend, no AI API)
- Natural-language percentage intents (e.g. `25% of 167`, `from 80 to 96`, `markup 40 on cost 120`)
- Supports both English and German query phrasing (e.g. `25% von 167`, `von 80 auf 96`, `85 plus 19% MwSt`)
- App language setting: switch full UI and result text between English and German
- Live debounced parsing + result updates
- Ambiguity handling with ranked alternative interpretations
- History, favorites, and settings persisted with `UserDefaults` + `Codable`
- Light and dark mode support

## Architecture
- `AskPercent/Parsing`: deterministic parser pipeline
- `AskPercent/Engine`: formula engine
- `AskPercent/ViewModels`: MVVM orchestration (`CalculatorViewModel`)
- `AskPercent/Views` + `AskPercent/Components`: SwiftUI UI
- `AskPercent/Persistence`: local store for history/favorites/settings
- `AskPercent/Tests`: unit tests for parser, normalization, ranking, and formulas

## Deterministic Parser Pipeline
`PercentQueryParser` uses:
1. Normalization (`QueryNormalizer`)
2. Numeric token extraction (comma/dot decimal support)
3. Regex/pattern matching per intent
4. Candidate scoring + semantic boosts
5. Confidence-ranked candidate list
6. Ambiguity flag when top candidates are close

If confidence is low or patterns fail, the app returns a helpful message instead of silently guessing.

## Supported Intents
- percent of a number
- add percent to a number
- subtract percent from a number
- percent change from old to new
- discount percent between original and new
- reverse percent / find whole
- what percent is X of Y
- tip / tax / VAT
- margin
- markup

Supported in both English and German with deterministic regex/pattern rules.

## Formula Engine
Implemented formulas:
- `percentOf = percent / 100 * base`
- `addPercent = base * (1 + percent / 100)`
- `subtractPercent = base * (1 - percent / 100)`
- `percentChange = (new - old) / old * 100`
- `discountPercent = (original - new) / original * 100`
- `reversePercent = partial / (percent / 100)`
- `percentOfRelation = part / whole * 100`
- `margin = profit / revenue * 100`
- `markup = profit / cost * 100`

## Persistence
`LocalPersistenceStore` persists:
- `history`
- `favorites`
- `settings` (language, decimal precision, formula visibility, haptics, number format)

## Testing
Run from terminal:

```bash
xcodebuild test -scheme AskPercent -project AskPercent.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17'
```

Current test coverage includes:
- normalization
- number extraction
- each parser intent
- candidate ranking
- ambiguity behavior
- decimal comma inputs
- formula correctness
- divide-by-zero edge cases

## Project Structure
```text
AskPercent/
  App/
  Models/
  Parsing/
  Engine/
  Persistence/
  ViewModels/
  Views/
  Components/
  Utilities/
  Resources/
  Tests/
```
