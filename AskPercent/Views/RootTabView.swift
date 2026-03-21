import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var store: LocalPersistenceStore
    @StateObject private var navigation = AppNavigationState()

    private var strings: AppStrings {
        AppStrings(language: store.settings.language)
    }

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(strings.homeTab, systemImage: "percent")
            }
            .tag(0)

            FavoritesView()
                .tabItem {
                    Label(strings.favoritesTab, systemImage: "star")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label(strings.historyTab, systemImage: "clock.arrow.circlepath")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label(strings.settingsTab, systemImage: "gear")
                }
                .tag(3)
        }
        .environmentObject(navigation)
    }
}
