# AskPercent

AskPercent is a native iOS SwiftUI MVP for deterministic natural-language percentage calculations.

## What It Does
- Local-only parsing and calculation (no backend, no AI API)
- Natural-language percentage intents (e.g. `25% of 167`, `from 80 to 96`, `markup 40 on cost 120`)
- Supports both English and German query phrasing (e.g. `25% von 167`, `von 80 auf 96`, `85 plus 19% MwSt`)
- App language setting: switch full UI and result text between English and German
- Number format setting: `System`, `US`, `European`
- Live debounced parsing + result updates
- Ambiguity handling with ranked alternative interpretations
- Result card quick actions:
  - copy icon (copies full details)
  - long-press context menu (`Copy Result`, `Copy Full Details`)
- History, favorites, and settings persisted with `UserDefaults` + `Codable`
- History grouped by day sections (`Today/Yesterday/date`)
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
2. Numeric token extraction (comma/dot decimal support, grouped number support)
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

## Extended Pattern Coverage
In addition to core intents, parser coverage includes:
- reverse-percent variants:
  - `if 30% is 45 what is 100%`
  - `20 is 115%`
  - `20 sind 115%`
  - `10% sind 5 - wie groß ist der Gesamtwert?`
- increase/decrease-by phrasing:
  - `increase 100 by 20%`
  - `decrease 100 by 20%`
- now/then variants:
  - `before 100 now 120`
  - `was 80 now 96`
  - `vorher 100 jetzt 120`
  - `war 80 jetzt 96`
- grouped and decimal number formats:
  - `12.5% of 1'234.56`
  - `12,5% von 1 234,56`
- VAT inclusive shorthand:
  - `price incl. 19% VAT`
  - `preis inkl. 19% mwst`
- margin synonyms:
  - `gross margin`
  - `Bruttomarge`
  - `Handelsspanne`
- ambiguous shorthand handling:
  - `25% on 167`
  - `25 on 167`

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
- grouped-number parsing (`1 234,56`, `1'234.56`)
- reverse-percent variant phrasing (EN + DE)
- increase/decrease-by phrasing
- now/then phrasing variants
- formula correctness
- divide-by-zero edge cases

## Project Structure
```text
AskPercent/
  AppStoreAssets/
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
