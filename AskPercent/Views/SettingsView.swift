import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: LocalPersistenceStore
    @State private var showClearHistoryAlert = false
    @State private var showClearFavoritesAlert = false

    private var strings: AppStrings {
        AppStrings(language: store.settings.language)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(strings.settingsCalculationSection) {
                    Picker(strings.settingsLanguageLabel, selection: languageBinding) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName(interfaceLanguage: store.settings.language.resolved)).tag(language)
                        }
                    }

                    Stepper(value: decimalPrecisionBinding, in: 0...6) {
                        HStack {
                            Text(strings.settingsPrecisionLabel)
                            Spacer()
                            Text("\(store.settings.decimalPrecision)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker(strings.settingsNumberFormatLabel, selection: numberFormatBinding) {
                        ForEach(NumberFormatStyle.allCases) { style in
                            Text(style.displayName(language: store.settings.language)).tag(style)
                        }
                    }

                    Toggle(strings.settingsShowFormulaLabel, isOn: showFormulaBinding)
                    Toggle(strings.settingsHapticsLabel, isOn: hapticsBinding)
                }

                Section(strings.settingsDataSection) {
                    Button(strings.settingsClearHistoryButton, role: .destructive) {
                        showClearHistoryAlert = true
                    }
                    Button(strings.settingsClearFavoritesButton, role: .destructive) {
                        showClearFavoritesAlert = true
                    }
                }
            }
            .navigationTitle(strings.settingsTitle)
            .alert(strings.settingsClearHistoryTitle, isPresented: $showClearHistoryAlert) {
                Button(strings.cancelButton, role: .cancel) {}
                Button(strings.clearButton, role: .destructive) {
                    store.clearHistory()
                }
            } message: {
                Text(strings.settingsClearHistoryMessage)
            }
            .alert(strings.settingsClearFavoritesTitle, isPresented: $showClearFavoritesAlert) {
                Button(strings.cancelButton, role: .cancel) {}
                Button(strings.clearButton, role: .destructive) {
                    store.clearFavorites()
                }
            } message: {
                Text(strings.settingsClearFavoritesMessage)
            }
        }
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { store.settings.language },
            set: { store.settings.language = $0 }
        )
    }

    private var decimalPrecisionBinding: Binding<Int> {
        Binding(
            get: { store.settings.decimalPrecision },
            set: { store.settings.decimalPrecision = min(max($0, 0), 6) }
        )
    }

    private var showFormulaBinding: Binding<Bool> {
        Binding(
            get: { store.settings.showFormula },
            set: { store.settings.showFormula = $0 }
        )
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { store.settings.hapticsEnabled },
            set: { store.settings.hapticsEnabled = $0 }
        )
    }

    private var numberFormatBinding: Binding<NumberFormatStyle> {
        Binding(
            get: { store.settings.numberFormatStyle },
            set: { store.settings.numberFormatStyle = $0 }
        )
    }
}
