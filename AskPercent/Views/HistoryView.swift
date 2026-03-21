import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: LocalPersistenceStore
    @EnvironmentObject private var navigation: AppNavigationState

    private var strings: AppStrings {
        AppStrings(language: store.settings.language)
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.history.isEmpty {
                    ContentUnavailableView(strings.historyEmptyTitle, systemImage: "clock", description: Text(strings.historyEmptyBody))
                } else {
                    List {
                        ForEach(store.history) { item in
                            Button {
                                navigation.pendingQuery = item.query
                                navigation.selectedTab = 0
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.query)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)

                                    Text(valueText(for: item))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Text(item.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: store.deleteHistory)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(strings.historyTitle)
        }
    }

    private func valueText(for item: HistoryItem) -> String {
        let locale = store.settings.numberFormatStyle.locale
        let value = item.isPercentValue
        ? DisplayFormatter.percent(item.value, precision: store.settings.decimalPrecision, locale: locale)
        : DisplayFormatter.number(item.value, precision: store.settings.decimalPrecision, locale: locale)
        return "\(strings.label(for: item.intentType)): \(value)"
    }
}
