import SwiftData
import SwiftUI

struct ContentViewPreview: View {
    var body: some View {
        ContentView()
            .modelContainer(PreviewData.modelContainer)
    }
}

private enum PreviewData {
    static let modelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: SavedDecision.self, configurations: configuration)
            container.mainContext.insert(Self.sampleDecision)
            return container
        } catch {
            fatalError("Failed to create preview model container: \(error)")
        }
    }()

    private static var sampleDecision: SavedDecision {
        SavedDecision(
            title: "Dinner tonight",
            question: "Dinner tonight",
            options: ["Ramen", "Pasta", "Sushi"],
            createdAt: .now,
            updatedAt: .now
        )
    }
}
