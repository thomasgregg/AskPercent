import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var store: LocalPersistenceStore
    @EnvironmentObject private var navigation: AppNavigationState

    private var strings: AppStrings {
        AppStrings(language: store.settings.language)
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.favorites.isEmpty {
                    ContentUnavailableView(strings.favoritesEmptyTitle, systemImage: "star", description: Text(strings.favoritesEmptyBody))
                } else {
                    List {
                        ForEach(store.favorites) { item in
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
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: store.deleteFavorite)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(strings.favoritesTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func valueText(for item: FavoriteItem) -> String {
        let locale = store.settings.numberFormatStyle.locale
        let value = item.isPercentValue
        ? DisplayFormatter.percent(item.value, precision: store.settings.decimalPrecision, locale: locale)
        : DisplayFormatter.number(item.value, precision: store.settings.decimalPrecision, locale: locale)
        return "\(strings.label(for: item.intentType)): \(value)"
    }
}
