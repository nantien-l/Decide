import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("AI", systemImage: "sparkles") {
                AIDecisionView()
            }

            Tab("Manual", systemImage: "keyboard") {
                ManualDecisionView()
            }

            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentViewPreview()
}
