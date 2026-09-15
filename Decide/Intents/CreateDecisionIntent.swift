import AppIntents

struct CreateDecisionIntent: AppIntent {
    static let title: LocalizedStringResource = "Create a Decision"
    static let description = IntentDescription("Open Decide with a prepared question and any supplied options.")
    static let openAppWhenRun = true

    @Parameter(title: "Decision")
    var question: String

    @Parameter(title: "Options", default: [])
    var options: [String]

    static var parameterSummary: some ParameterSummary {
        Summary("Create a decision for \\.$question")
    }

    func perform() async throws -> some IntentResult {
        let cleanedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedOptions = options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        PendingDecisionStore.save(question: cleanedQuestion, options: cleanedOptions)
        return .result()
    }
}

struct DecideAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateDecisionIntent(),
            phrases: [
                "Create a decision in \(.applicationName)",
                "Help me decide with \(.applicationName)",
                "Start a decision in \(.applicationName)"
            ],
            shortTitle: "Create Decision",
            systemImageName: "sparkles"
        )
    }
}
