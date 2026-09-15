import SwiftData
import SwiftUI

@main
struct DecideApp: App {
    init() {
        DecideTypography.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(.decideBody)
        }
        .modelContainer(for: SavedDecision.self)
    }
}
