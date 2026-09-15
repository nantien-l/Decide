import Foundation
import SwiftData

@Model
final class SavedDecision {
    var id: UUID
    var title: String
    var question: String
    var options: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        question: String,
        options: [String],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.question = question
        self.options = options
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
