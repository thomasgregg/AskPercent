import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var store: LocalPersistenceStore
    @EnvironmentObject private var navigation: AppNavigationState
    @Environment(\.colorScheme) private var colorScheme

    private var strings: AppStrings {
        AppStrings(language: store.settings.language)
    }

    private var pageBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    private var rowCardBackground: Color {
        colorScheme == .dark
        ? Color(uiColor: .secondarySystemGroupedBackground)
        : Color(uiColor: .systemBackground)
    }

    private var rowCardBorder: Color {
        Color(uiColor: .separator).opacity(colorScheme == .dark ? 0.5 : 0.35)
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
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(rowCardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(rowCardBorder, lineWidth: 1)
                                        )
                                )
                                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: store.deleteFavorite)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(pageBackground.ignoresSafeArea())
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
