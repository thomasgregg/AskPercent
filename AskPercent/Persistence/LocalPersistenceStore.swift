import Combine
import Foundation

@MainActor
final class LocalPersistenceStore: ObservableObject {
    @Published var history: [HistoryItem]
    @Published var favorites: [FavoriteItem]
    @Published var settings: UserSettings

    private let defaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    private enum Keys {
        static let history = "askpercent.history"
        static let favorites = "askpercent.favorites"
        static let settings = "askpercent.settings"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.history = Self.load([HistoryItem].self, from: Keys.history, defaults: defaults) ?? []
        self.favorites = Self.load([FavoriteItem].self, from: Keys.favorites, defaults: defaults) ?? []
        self.settings = Self.load(UserSettings.self, from: Keys.settings, defaults: defaults) ?? .default
        bindPersistence()
    }

    func addHistory(
        query: String,
        normalizedQuery: String,
        result: CalculationResult
    ) {
        guard !normalizedQuery.isEmpty else { return }

        let item = HistoryItem(
            query: query,
            normalizedQuery: normalizedQuery,
            intentType: result.intentType,
            value: result.value,
            isPercentValue: result.isPercentValue,
            summary: result.explanation
        )

        if let first = history.first,
           first.normalizedQuery == item.normalizedQuery,
           first.intentType == item.intentType,
           abs(first.value - item.value) < 0.000_001 {
            return
        }

        history.insert(item, at: 0)
        if history.count > 200 {
            history = Array(history.prefix(200))
        }
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
    }

    func clearHistory() {
        history.removeAll()
    }

    func toggleFavorite(
        query: String,
        normalizedQuery: String,
        result: CalculationResult
    ) {
        if let index = favorites.firstIndex(where: { $0.normalizedQuery == normalizedQuery }) {
            favorites.remove(at: index)
            return
        }

        favorites.insert(
            FavoriteItem(
                query: query,
                normalizedQuery: normalizedQuery,
                intentType: result.intentType,
                value: result.value,
                isPercentValue: result.isPercentValue,
                summary: result.explanation
            ),
            at: 0
        )
    }

    func deleteFavorite(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
    }

    func clearFavorites() {
        favorites.removeAll()
    }

    func isFavorite(normalizedQuery: String) -> Bool {
        favorites.contains(where: { $0.normalizedQuery == normalizedQuery })
    }

    private func bindPersistence() {
        $history
            .sink { [weak self] items in
                self?.save(items, key: Keys.history)
            }
            .store(in: &cancellables)

        $favorites
            .sink { [weak self] items in
                self?.save(items, key: Keys.favorites)
            }
            .store(in: &cancellables)

        $settings
            .sink { [weak self] settings in
                self?.save(settings, key: Keys.settings)
            }
            .store(in: &cancellables)
    }

    private static func load<T: Decodable>(_ type: T.Type, from key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
