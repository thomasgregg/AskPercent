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
                Section(strings.settingsLanguageFormatSection) {
                    Picker(strings.settingsLanguageLabel, selection: languageBinding) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName(interfaceLanguage: store.settings.language.resolved)).tag(language)
                        }
                    }

                    Picker(strings.settingsNumberFormatLabel, selection: numberFormatBinding) {
                        ForEach(NumberFormatStyle.allCases) { style in
                            Text(style.displayName(language: store.settings.language)).tag(style)
                        }
                    }
                }

                Section(strings.settingsCalculationSection) {
                    Stepper(value: decimalPrecisionBinding, in: 0...6) {
                        HStack {
                            Text(strings.settingsPrecisionLabel)
                            Spacer()
                            Text("\(store.settings.decimalPrecision)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(strings.settingsShowFormulaLabel, isOn: showFormulaBinding)
                    Toggle(strings.settingsHapticsLabel, isOn: hapticsBinding)
                }

                Section(strings.settingsTaxSection) {
                    Toggle(strings.settingsTaxPresetToggleLabel, isOn: taxPresetEnabledBinding)

                    if store.settings.taxPresetEnabled {
                        Stepper(value: taxPresetPercentBinding, in: 0...100, step: 0.5) {
                            HStack {
                                Text(strings.settingsTaxPresetPercentLabel)
                                Spacer()
                                Text(DisplayFormatter.percent(
                                    store.settings.taxPresetPercent,
                                    precision: 1,
                                    locale: store.settings.numberFormatStyle.locale
                                ))
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
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
            .navigationBarTitleDisplayMode(.large)
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

    private var taxPresetEnabledBinding: Binding<Bool> {
        Binding(
            get: { store.settings.taxPresetEnabled },
            set: { store.settings.taxPresetEnabled = $0 }
        )
    }

    private var taxPresetPercentBinding: Binding<Double> {
        Binding(
            get: { store.settings.taxPresetPercent },
            set: { store.settings.taxPresetPercent = min(max($0, 0), 100) }
        )
    }
}
