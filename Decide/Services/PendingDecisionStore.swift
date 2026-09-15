import Foundation

nonisolated struct PreparedDecision: Codable, Sendable {
    let question: String
    let options: [String]
}

/// A lightweight handoff used when an App Intent launches the main app.
enum PendingDecisionStore {
    nonisolated private static let key = "pendingPreparedDecision"

    nonisolated static func save(question: String, options: [String]) {
        let prepared = PreparedDecision(question: question, options: options)
        guard let data = try? JSONEncoder().encode(prepared) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    nonisolated static func take() -> PreparedDecision? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        UserDefaults.standard.removeObject(forKey: key)
        return try? JSONDecoder().decode(PreparedDecision.self, from: data)
    }
}
