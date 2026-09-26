import SwiftData
import SwiftUI

struct ManualDecisionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var question = ""
    @State private var options: [DecisionOption] = [DecisionOption(text: ""), DecisionOption(text: "")]
    @State private var loadedDecision: SavedDecision?
    @State private var activeSession: DecisionSession?
    @State private var isSaving = false

    private let persistence = DecisionPersistence()

    private var cleanedOptions: [String] {
        options
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var canDecide: Bool { cleanedOptions.count >= 2 }
    private var canSave: Bool { !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && canDecide }

    var body: some View {
        NavigationStack {
            ZStack {
                DecideBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        QuestionSectionView(
                            question: $question,
                            isSuggesting: false,
                            suggestionError: nil,
                            suggestOptions: {},
                            surpriseMe: surpriseMe,
                            showsSuggestionControls: false
                        )

                        OptionsSectionView(
                            options: $options,
                            optionCount: cleanedOptions.count,
                            canDecide: canDecide,
                            addOption: addOption,
                            moveOption: moveOption,
                            deleteOption: deleteOption
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 150)
                    .frame(maxWidth: 430, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Manual")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                BottomActionBarView(canDecide: canDecide, startDecision: startDecision)
            }
            .sheet(item: $activeSession) { session in
                DecisionAnimationView(
                    question: session.question,
                    options: session.options,
                    onDone: { activeSession = nil },
                    onResult: recordResult
                )
            }
            .task { applyPendingDecisionIfNeeded() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    applyPendingDecisionIfNeeded()
                }
            }
        }
    }

    private func addOption() {
        options.append(DecisionOption(text: ""))
        HapticPerformer().lightTap()
    }

    private func deleteOption(at index: Int) {
        guard options.indices.contains(index), options.count > 1 else { return }
        withAnimation(.snappy(duration: 0.2)) {
            _ = options.remove(at: index)
        }
    }

    private func moveOption(from index: Int, by offset: Int) {
        let newIndex = index + offset
        guard options.indices.contains(index), options.indices.contains(newIndex) else { return }

        withAnimation(.snappy(duration: 0.2)) {
            options.swapAt(index, newIndex)
        }

        HapticPerformer().lightTap()
    }

    private func startDecision() {
        activeSession = DecisionSession(
            question: question.trimmingCharacters(in: .whitespacesAndNewlines),
            options: cleanedOptions
        )
    }

    private func saveDecision(selectedResult: String? = nil) async {
        isSaving = true
        defer { isSaving = false }

        let saved = await persistence.save(
            question: question,
            options: cleanedOptions,
            source: .manual,
            selectedResult: selectedResult,
            existingDecision: loadedDecision,
            in: modelContext
        )

        if let saved {
            loadedDecision = saved
            HapticPerformer().lightTap()
        }
    }

    private func recordResult(_ result: String) {
        // A manual decision has no existing model on its first run. Persist it at
        // selection time so it reliably appears in History.
        Task { @MainActor in
            await saveDecision(selectedResult: result)
        }
    }

    private func surpriseMe() {
        let examples: [(question: String, options: [String])] = [
            ("A low-effort dinner that still feels special", ["Neighborhood ramen", "Cook fresh pasta", "Order sushi", "Try a wine bar"]),
            ("A quiet weekend reset", ["Bookstore and coffee", "Morning hike", "Museum afternoon", "Stay home and cook"]),
            ("A thoughtful gift under budget", ["A nice book", "Specialty coffee beans", "Handwritten letter", "Shared experience"])
        ]
        guard let example = examples.randomElement() else { return }

        withAnimation(.snappy(duration: 0.25)) {
            question = example.question
            options = example.options.map { DecisionOption(text: $0) }
            loadedDecision = nil
        }

        HapticPerformer().lightTap()
    }

    private func applyPendingDecisionIfNeeded() {
        guard let prepared = PendingDecisionStore.take() else { return }
        question = prepared.question
        if !prepared.options.isEmpty {
            options = prepared.options.map { DecisionOption(text: $0) }
        }
        loadedDecision = nil
    }
}
