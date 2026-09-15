import Foundation
import FoundationModels

/// Generates editable candidates only. The existing `DecisionSelector` remains
/// the sole source of the final selection.
struct DecisionSuggestionService {
    enum SuggestionError: LocalizedError {
        case unavailable(SystemLanguageModel.Availability.UnavailableReason)
        case insufficientOptions

        var errorDescription: String? {
            switch self {
            case .unavailable(let reason):
                switch reason {
                case .deviceNotEligible:
                    return "Suggestions require a device that supports Apple Intelligence."
                case .appleIntelligenceNotEnabled:
                    return "Turn on Apple Intelligence to suggest options."
                case .modelNotReady:
                    return "Apple Intelligence is still preparing. Try again shortly."
                @unknown default:
                    return "Apple Intelligence isn't available right now. Try again shortly."
                }
            case .insufficientOptions:
                return "Couldn't create enough distinct options. Try a more specific question."
            }
        }
    }

    func suggest(for prompt: String) async throws -> GeneratedDecision {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw SuggestionError.unavailable(reason)
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You turn a person's natural-language thought into an editable decision.
            Their text can mix a topic with preferences, constraints, exclusions, budget, timing, and context. Infer the decision they are trying to make without asking follow-up questions. Respect every stated constraint, especially exclusions.

            Return a concise, natural question suitable for a decision screen and 4 to 8 genuinely distinct candidate options. Option names must be short enough for cards, with no explanations, qualifiers, bullets, or categories. Never choose, rank, recommend, or imply a final winner. The person will edit the candidates and Decide will make the final selection.
            """
        )

        let response = try await session.respond(
            to: """
            Turn this thought into one clean decision and editable candidates:

            \(prompt)
            """,
            generating: GeneratedDecision.self,
            options: GenerationOptions(temperature: 0.7, maximumResponseTokens: 220)
        )

        let options = response.content.options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, option in
                if !result.contains(where: { $0.localizedCaseInsensitiveCompare(option) == .orderedSame }) {
                    result.append(option)
                }
            }

        guard options.count >= 2 else { throw SuggestionError.insufficientOptions }
        return GeneratedDecision(question: response.content.question, options: Array(options.prefix(8)))
    }
}

@Generable(description: "A prepared decision with a concise question and editable candidate options inferred from the person's complete natural-language thought.")
struct GeneratedDecision {
    @Guide(description: "A short, natural decision question that captures the person's goal, without repeating every preference or constraint.")
    var question: String

    @Guide(description: "Four to eight short, meaningfully different candidate names that satisfy the person's preferences, constraints, exclusions, budget, and context. Never choose a winner, rank candidates, or include explanations.")
    var options: [String]
}
