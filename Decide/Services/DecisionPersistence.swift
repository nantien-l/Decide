import Foundation
import SwiftData

struct DecisionPersistence {
    private let classifier = DecisionCategoryClassifier()

    func save(
        question: String,
        options: [String],
        source: DecisionSource,
        selectedResult: String? = nil,
        existingDecision: SavedDecision? = nil,
        in modelContext: ModelContext
    ) async -> SavedDecision? {
        let title = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedOptions = options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !title.isEmpty, cleanedOptions.count >= 2 else { return nil }

        let category = await classifier.category(for: title, options: cleanedOptions)
        let now = Date.now

        if let existingDecision {
            existingDecision.title = title
            existingDecision.question = title
            existingDecision.options = cleanedOptions
            existingDecision.updatedAt = now
            existingDecision.selectedResult = selectedResult ?? existingDecision.selectedResult
            existingDecision.source = source
            existingDecision.category = category
            existingDecision.isCategoryResolved = true
            return existingDecision
        }

        let decision = SavedDecision(
            title: title,
            question: title,
            options: cleanedOptions,
            createdAt: now,
            updatedAt: now,
            selectedResult: selectedResult,
            source: source,
            category: category,
            isCategoryResolved: true
        )
        modelContext.insert(decision)
        return decision
    }
}
