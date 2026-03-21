import SwiftUI

@main
struct AskPercentApp: App {
    @StateObject private var store = LocalPersistenceStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
