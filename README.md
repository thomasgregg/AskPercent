# AskPercent

AskPercent is a native iOS SwiftUI MVP for deterministic natural-language percentage calculations.

## What It Does
- Local-only parsing and calculation (no backend, no AI API)
- Deterministic natural-language percentage intents (e.g. `25% of 167`, `from 80 to 96`, `markup 40 on cost 120`)
- Supports both English and German query phrasing (e.g. `25% von 167`, `von 80 auf 96`, `85 plus 19% MwSt`)
- App language setting with `System (Device)`, `English`, `Deutsch` (full UI + result text localization)
- Number format setting: `System`, `US`, `European`
- Live debounced parsing + result updates
- Ambiguity handling with ranked alternative interpretations
- Home input quality-of-life:
  - autofocus when app opens / returning to Home
  - trailing clear `x` button
  - keyboard dismiss by tapping outside
  - quick symbol chips (`%`, `+`, `-`, `,`, `.`) while editing
- Result card quick actions:
  - copy icon (copies full details)
  - long-press context menu (`Copy Result`, `Copy Full Details`)
- History, favorites, and settings persisted with `UserDefaults` + `Codable`
- History grouped by day sections (`Today/Yesterday/date`)
- Home tab order: `Home`, `Favorites`, `History`, `Settings`
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

## Query Examples You Can Use
English:
- `25% of 167`
- `167 plus 25%`
- `899 minus 12%`
- `from 80 to 96`
- `I paid 134 instead of 179, what percent discount is that?`
- `41.75 is what percent of 167`
- `240 with 15% tip`
- `85 plus 19% VAT`
- `what margin is 40 on 120`
- `what markup is 40 on cost 120`
- `if 30% is 45 what is 100%`
- `if 30% is 45 what is 50%`
- `if 40 is 10% what is 50` (returns a percent)
- `if 40 is 10% what percent is 50` (returns a percent)

German:
- `25% von 167`
- `167 plus 25 prozent`
- `899 minus 12 prozent`
- `von 80 auf 96`
- `ich habe 134 statt 179 bezahlt`
- `41,75 sind wie viel prozent von 167`
- `240 mit 15% trinkgeld`
- `85 plus 19% mwst`
- `was ist die marge 40 auf 120`
- `was ist der aufschlag 40 auf kosten 120`
- `wenn 30 prozent sind 45 was sind 100 prozent`
- `wenn 30 prozent sind 45 was sind 50 prozent`
- `wenn 40 sind 10 prozent was sind 50` (returns a percent)

## Extended Pattern Coverage
In addition to core intents, parser coverage includes:
- reverse-percent variants:
  - `if 30% is 45 what is 100%`
  - `if 30% is 45 what is 90%`
  - `if 10% is 50 what is 50%` (returns a number)
  - `if 40 is 10% what is 50` (returns a percent)
  - `if 40 is 10% what percent is 50`
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
- `reversePercentTarget = (knownPart / (knownPercent / 100)) * (targetPercent / 100)`
- `reversePercentFindPercent = (targetPart * knownPercent) / knownPart`
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
- reverse-percent variant phrasing (EN + DE), including:
  - target-percent output (`if 10% is 50 what is 50%`)
  - target-part-to-percent output (`if 40 is 10% what is 50`)
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
