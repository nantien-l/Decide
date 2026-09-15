import Foundation

struct DecisionSelector {
    func select(from options: [String]) -> String? {
        let trimmedOptions = options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return trimmedOptions.randomElement()
    }
}
