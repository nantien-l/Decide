import Foundation
import SwiftData

@Model
final class SavedDecision {
    var id: UUID = UUID()
    var title: String = ""
    var question: String = ""
    var options: [String] = []
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var selectedResult: String?
    var sourceRawValue: String = DecisionSource.manual.rawValue
    var categoryRawValue: String = DecisionCategory.other.rawValue
    var isCategoryResolved: Bool = false
    var isFavorite: Bool = false

    init(
        id: UUID = UUID(),
        title: String,
        question: String,
        options: [String],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        selectedResult: String? = nil,
        source: DecisionSource = .manual,
        category: DecisionCategory = .other,
        isCategoryResolved: Bool = true,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.question = question
        self.options = options
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.selectedResult = selectedResult
        self.sourceRawValue = source.rawValue
        self.categoryRawValue = category.rawValue
        self.isCategoryResolved = isCategoryResolved
        self.isFavorite = isFavorite
    }
}

extension SavedDecision {
    var source: DecisionSource {
        get { DecisionSource(rawValue: sourceRawValue) ?? .manual }
        set { sourceRawValue = newValue.rawValue }
    }

    var category: DecisionCategory {
        get { DecisionCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}

enum DecisionSource: String, CaseIterable, Identifiable, Codable {
    case manual
    case ai

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .manual:
            "Manual"
        case .ai:
            "AI Generated"
        }
    }
}

enum DecisionCategory: String, CaseIterable, Identifiable, Codable {
    case food
    case study
    case work
    case shopping
    case travel
    case entertainment
    case personal
    case other

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .food:
            "Food"
        case .study:
            "Study"
        case .work:
            "Work"
        case .shopping:
            "Shopping"
        case .travel:
            "Travel"
        case .entertainment:
            "Entertainment"
        case .personal:
            "Personal"
        case .other:
            "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .food:
            "fork.knife"
        case .study:
            "book"
        case .work:
            "briefcase"
        case .shopping:
            "bag"
        case .travel:
            "airplane"
        case .entertainment:
            "sparkles.tv"
        case .personal:
            "person"
        case .other:
            "tray"
        }
    }
}
