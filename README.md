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
- reverse percent / find other target percent value
- reverse percent / find percent for a target part
- what percent is X of Y
- tip / tax / VAT
- margin
- markup

Supported in both English and German with deterministic regex/pattern rules.

## Supported Query Scenarios (with examples)
Use these directly in the input field.

- Percent of a base value:
  - EN: `25% of 167`, `what is 10% percent of 87336437476`
  - DE: `25% von 167`, `wie viel sind 12,5% von 200`
- Add percent to a value:
  - EN: `167 plus 25%`, `167 + 10%`, `increase 100 by 20%`
  - DE: `167 plus 25 prozent`
- Subtract percent from a value:
  - EN: `899 minus 12%`, `167 - 10%`, `decrease 100 by 20%`
  - DE: `899 minus 12 prozent`
- Percent change (old to new):
  - EN: `from 80 to 96`, `before 100 now 120`, `was 80 now 96`
  - DE: `von 80 auf 96`, `vorher 100 jetzt 120`, `war 80 jetzt 96`
- Discount percent:
  - EN: `I paid 134 instead of 179, what percent discount is that?`
  - DE: `ich habe 134 statt 179 bezahlt`
- What percent is X of Y (relation):
  - EN: `41.75 is what percent of 167`, `100 of 200`
  - DE: `41,75 sind wie viel prozent von 167`, `100 von 200`
- Tip / tax / VAT with explicit rate:
  - EN: `240 with 15% tip`, `85 plus 19% VAT`, `100 plus 7% sales tax`, `100 plus 7% gst`
  - DE: `240 mit 15% trinkgeld`, `85 plus 19% mwst`, `preis inkl. 19% mwst`
- Financial tax context (net/gross, before/after tax):
  - EN: `100 net plus 19% vat`, `100 before tax plus 20% tax`, `120 after tax minus 20% tax`
  - DE: `100 netto zzgl 19% ust`, `100 vor steuer plus 10% steuer`, `120 brutto minus 20% steuer`
- Tax preset queries (when tax preset is enabled in Settings):
  - EN: `100 plus tax`, `100 minus tax`, `100 inc vat`
  - DE: `100 zzgl mwst`, `120 brutto ohne steuer`
- Reverse percent: find the 100% value:
  - EN: `if 30% is 45 what is 100%`, `10% is 5 - what is the total value?`, `20% is 30 what is the original amount`
  - DE: `wenn 30 prozent sind 45 was sind 100 prozent`, `10 % sind 5 – wie groß ist der Gesamtwert?`, `20% sind 30 wie groß ist der grundbetrag`
- Reverse percent: find another target percent value:
  - EN: `if 30% is 45 what is 50%`, `if 30% is 45 what is 90%`, `if 10% is 50 what is 50%`
  - DE: `wenn 30 prozent sind 45 was sind 50 prozent`
- Reverse percent: find which percent a target part is:
  - EN: `if 40 is 10% what is 50`, `if 40 is 10% what percent is 50`
  - DE: `wenn 40 sind 10 prozent was sind 50`
- Swapped reverse shorthand:
  - EN: `20 is 115%`
  - DE: `20 sind 115%`
- Margin and markup:
  - EN: `what margin is 40 on 120`, `what is the margin 40 on 120`, `what markup is 40 on cost 120`, `what is profit 40 on 120`
  - DE: `was ist die marge 40 auf 120`, `was ist der aufschlag 40 auf kosten 120`, `was ist der gewinn von 40 auf 120`
- Margin/profit amount phrasing:
  - EN: `how much is 10% margin on 134`, `how much is 10% profit on 134`, `what is 10% profit of 230`
  - DE: `wie viel sind 10% marge auf 134`, `was ist 10% gewinn von 230`
- Ambiguous shorthand (app shows alternatives):
  - EN: `25% on 167`, `25 on 167`
  - DE: `25% auf 167`
- Decimal/grouped number formats:
  - EN: `12.5% of 200`, `12.5% of 1'234.56`
  - DE: `12,5% von 200`, `12,5% von 1 234,56`
- Negative and zero percent inputs:
  - EN: `-20% of 50`, `0% of 900`
  - DE: `-20% von 50`, `0% von 900`

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
- `settings` (language, decimal precision, formula visibility, haptics, number format, tax preset enabled/rate)

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
