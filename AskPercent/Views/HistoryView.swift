import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: LocalPersistenceStore
    @EnvironmentObject private var navigation: AppNavigationState

    private var strings: AppStrings {
        AppStrings(language: store.settings.language)
    }

    private var groupedHistory: [(day: Date, items: [HistoryItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.history) { item in
            calendar.startOfDay(for: item.createdAt)
        }

        return grouped
            .map { (day: $0.key, items: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.history.isEmpty {
                    ContentUnavailableView(strings.historyEmptyTitle, systemImage: "clock", description: Text(strings.historyEmptyBody))
                } else {
                    List {
                        ForEach(groupedHistory, id: \.day) { section in
                            Section {
                                ForEach(section.items) { item in
                                    Button {
                                        navigation.pendingQuery = item.query
                                        navigation.selectedTab = 0
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(item.query)
                                                    .font(.body.weight(.medium))
                                                    .foregroundStyle(.primary)

                                                Text(valueText(for: item))
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)

                                                Text(item.createdAt, style: .time)
                                                    .font(.caption)
                                                    .foregroundStyle(.tertiary)
                                            }
                                            Spacer(minLength: 0)
                                        }
                                        .padding(.vertical, 4)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    let ids: Set<UUID> = Set(offsets.compactMap { index in
                                        guard section.items.indices.contains(index) else { return nil }
                                        return section.items[index].id
                                    })
                                    store.deleteHistory(ids: ids)
                                }
                            }
                            header: {
                                Text(sectionTitle(for: section.day))
                                    .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(strings.historyTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func valueText(for item: HistoryItem) -> String {
        let locale = store.settings.numberFormatStyle.locale
        let value = item.isPercentValue
        ? DisplayFormatter.percent(item.value, precision: store.settings.decimalPrecision, locale: locale)
        : DisplayFormatter.number(item.value, precision: store.settings.decimalPrecision, locale: locale)
        return "\(strings.label(for: item.intentType)): \(value)"
    }

    private func sectionTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) {
            return strings.historyTodaySection
        }
        if calendar.isDateInYesterday(day) {
            return strings.historyYesterdaySection
        }

        let formatter = DateFormatter()
        formatter.locale = interfaceLocale
        formatter.setLocalizedDateFormatFromTemplate("MMMM d")
        return formatter.string(from: day)
    }

    private var interfaceLocale: Locale {
        switch store.settings.language.resolved {
        case .english:
            return Locale(identifier: "en_US")
        case .german:
            return Locale(identifier: "de_DE")
        }
    }
}
