import Foundation
import FoundationModels

struct DecisionCategoryClassifier {
    func category(for question: String, options: [String]) async -> DecisionCategory {
        let text = ([question] + options).joined(separator: " ")
        if let heuristic = heuristicCategory(for: text) {
            return heuristic
        }

        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return .other
        }

        do {
            let session = LanguageModelSession(
                model: model,
                instructions: "Classify a saved decision into exactly one simple category. Return only the category enum value that best fits the user's decision."
            )
            let response = try await session.respond(
                to: "Question: \(question)\nOptions: \(options.joined(separator: ", "))",
                generating: GeneratedDecisionCategory.self,
                options: GenerationOptions(temperature: 0.1, maximumResponseTokens: 20)
            )
            return DecisionCategory(rawValue: response.content.category) ?? .other
        } catch {
            return .other
        }
    }

    private func heuristicCategory(for text: String) -> DecisionCategory? {
        let lowercased = text.lowercased()
        let checks: [(DecisionCategory, [String])] = [
            (.food, ["eat", "dinner", "lunch", "breakfast", "restaurant", "ramen", "sushi", "coffee", "food", "餐", "吃", "咖啡"]),
            (.study, ["study", "class", "exam", "homework", "learn", "practice", "violin", "讀", "學", "考", "練習"]),
            (.work, ["work", "job", "offer", "meeting", "project", "client", "office", "工作", "會議", "專案"]),
            (.shopping, ["buy", "purchase", "gift", "shop", "order", "budget", "買", "購", "禮物"]),
            (.travel, ["trip", "travel", "flight", "hotel", "book", "旅", "機票", "飯店"]),
            (.entertainment, ["movie", "game", "show", "concert", "museum", "bookstore", "電影", "遊戲", "展", "演唱"]),
            (.personal, ["rest", "health", "friend", "family", "weekend", "reset", "休息", "朋友", "家人", "健康"])
        ]

        return checks.first { _, keywords in
            keywords.contains { lowercased.contains($0) }
        }?.0
    }
}

@Generable(description: "A single semantic category for a saved decision.")
struct GeneratedDecisionCategory {
    @Guide(description: "One of: food, study, work, shopping, travel, entertainment, personal, other.")
    var category: String
}
