import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \SavedDecision.updatedAt, order: .reverse) private var savedDecisions: [SavedDecision]

    @State private var question = ""
    @State private var options: [DecisionOption] = [
        DecisionOption(text: ""),
        DecisionOption(text: "")
    ]
    @State private var loadedDecision: SavedDecision?
    @State private var showingSavedDecisions = false
    @State private var activeSession: DecisionSession?
    @State private var isSuggesting = false
    @State private var suggestionError: String?

    private let suggestionService = DecisionSuggestionService()

    private var cleanedOptions: [String] {
        options
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var canDecide: Bool {
        cleanedOptions.count >= 2
    }

    private var canSave: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && canDecide
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Tell Decide what's on your mind", text: $question, axis: .vertical)
                        .font(.decideTitle2)
                        .lineLimit(2...6)
                        .padding(.vertical, 8)

                    Button(action: suggestOptions) {
                        Label(
                            isSuggesting ? "Suggesting Options…" : "Suggest Options",
                            systemImage: isSuggesting ? "sparkles" : "wand.and.stars"
                        )
                    }
                    .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSuggesting)
                } header: {
                    Text("Tell Decide what you're thinking")
                } footer: {
                    if let suggestionError {
                        Text(suggestionError)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Describe the situation, preferences, or constraints. Decide will turn it into options.")
                    }
                }

                Section {
                    ForEach(options.indices, id: \.self) { index in
                        OptionRow(
                            option: $options[index],
                            canMoveUp: index > 0,
                            canMoveDown: index < options.count - 1,
                            moveUp: { moveOption(from: index, by: -1) },
                            moveDown: { moveOption(from: index, by: 1) }
                        )
                    }
                    .onDelete(perform: deleteOptions)

                    Button(action: addOption) {
                        Label("Add Option", systemImage: "plus")
                    }
                } header: {
                    Text("Options")
                } footer: {
                    Text(canDecide ? "Use the arrows to reorder. Swipe to delete." : "Add at least two options to decide.")
                }
            }
            .listStyle(.inset)
            .navigationTitle("Decide")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingSavedDecisions = true
                    } label: {
                        Label("Saved", systemImage: "tray.full")
                    }
                }

                ToolbarItemGroup {
                    Button(action: saveDecision) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .disabled(!canSave)

                }
            }
            .safeAreaInset(edge: .bottom) {
                decideButton
            }
            .sheet(isPresented: $showingSavedDecisions) {
                SavedDecisionsView(savedDecisions: savedDecisions) { decision in
                    load(decision)
                    showingSavedDecisions = false
                }
            }
            .sheet(item: $activeSession) { session in
                DecisionAnimationView(
                    question: session.question,
                    options: session.options
                ) {
                    activeSession = nil
                }
            }
            .task {
                applyPendingDecisionIfNeeded()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    applyPendingDecisionIfNeeded()
                }
            }
        }
    }

    private var decideButton: some View {
        VStack(spacing: 8) {
            Button(action: startDecision) {
                Text("DECIDE")
                    .font(.decideHeadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canDecide)

            if !canDecide {
                Text("Two options minimum")
                    .font(.decideFootnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func addOption() {
        options.append(DecisionOption(text: ""))
        HapticPerformer().lightTap()
    }

    private func deleteOptions(at offsets: IndexSet) {
        options.remove(atOffsets: offsets)
        if options.isEmpty {
            options.append(DecisionOption(text: ""))
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

    private func saveDecision() {
        let title = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date.now

        if let loadedDecision {
            loadedDecision.title = title
            loadedDecision.question = title
            loadedDecision.options = cleanedOptions
            loadedDecision.updatedAt = now
        } else {
            let decision = SavedDecision(
                title: title,
                question: title,
                options: cleanedOptions,
                createdAt: now,
                updatedAt: now
            )
            modelContext.insert(decision)
            loadedDecision = decision
        }

        HapticPerformer().lightTap()
    }

    private func load(_ decision: SavedDecision) {
        question = decision.question
        options = decision.options.map { DecisionOption(text: $0) }
        loadedDecision = decision
    }

    private func suggestOptions() {
        let prompt = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isSuggesting else { return }

        isSuggesting = true
        suggestionError = nil

        Task {
            do {
                let suggestion = try await suggestionService.suggest(for: prompt)
                guard !Task.isCancelled else { return }
                question = suggestion.question
                options = suggestion.options.map { DecisionOption(text: $0) }
                loadedDecision = nil
                HapticPerformer().lightTap()
            } catch {
                guard !Task.isCancelled else { return }
                suggestionError = error.localizedDescription
            }
            isSuggesting = false
        }
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

private struct OptionRow: View {
    @Binding var option: DecisionOption

    let canMoveUp: Bool
    let canMoveDown: Bool
    let moveUp: () -> Void
    let moveDown: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle")
                .font(.decideFootnote)
                .foregroundStyle(.tertiary)

            TextField("Option", text: $option.text)
                .submitLabel(.done)

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Button(action: moveUp) {
                    Image(systemName: "chevron.up")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .disabled(!canMoveUp)
                .accessibilityLabel("Move option up")

                Button(action: moveDown) {
                    Image(systemName: "chevron.down")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .disabled(!canMoveDown)
                .accessibilityLabel("Move option down")
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

private struct SavedDecisionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let savedDecisions: [SavedDecision]
    let onOpen: (SavedDecision) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if savedDecisions.isEmpty {
                    ContentUnavailableView(
                        "No Saved Decisions",
                        systemImage: "tray",
                        description: Text("Save a question and its options to reuse it later.")
                    )
                } else {
                    List {
                        ForEach(savedDecisions) { decision in
                            Button {
                                onOpen(decision)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(decision.title)
                                        .font(.decideHeadline)
                                        .foregroundStyle(.primary)

                                    Text(decision.options.joined(separator: " • "))
                                        .font(.decideSubheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteSavedDecisions)
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("Saved")
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func deleteSavedDecisions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedDecisions[index])
        }
    }
}

private struct DecisionSession: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
}

private struct DecisionAnimationView: View {
    let question: String
    let options: [String]
    let onDone: () -> Void

    @State private var highlightedIndex = 0
    @State private var result: String?
    @State private var isRunning = false
    @State private var animationTask: Task<Void, Never>?

    private let selector = DecisionSelector()
    private let haptics = HapticPerformer()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Text(question.isEmpty ? "Decision" : question)
                        .font(.decideHeadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text(result ?? options[highlightedIndex])
                        .font(.decideLargeTitle)
                        .multilineTextAlignment(.center)
                        .contentTransition(.numericText())
                        .scaleEffect(result == nil ? 1 : 1.08)
                        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: result)

                    if result != nil {
                        Text("Decided.")
                            .font(.decideTitle3)
                            .foregroundStyle(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 28)

                VStack(spacing: 10) {
                    ForEach(options.indices, id: \.self) { index in
                        DecisionOptionCapsule(
                            title: options[index],
                            isHighlighted: index == highlightedIndex && result == nil,
                            isResult: options[index] == result
                        )
                    }
                }
                .padding(.horizontal)
                .animation(.snappy(duration: 0.22), value: highlightedIndex)
                .animation(.spring(response: 0.4, dampingFraction: 0.78), value: result)

                Spacer(minLength: 24)

                VStack(spacing: 12) {
                    Button(action: runAgain) {
                        Label("Decide Again", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isRunning)

                }
                .padding(.horizontal)
                .padding(.bottom, 24)
                .opacity(result == nil ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: result)
            }
            .navigationTitle("Decision")
            .toolbar {
                ToolbarItem {
                    Button("Done", action: onDone)
                        .disabled(isRunning)
                }
            }
        }
        .onAppear(perform: startAnimation)
        .onDisappear {
            animationTask?.cancel()
        }
    }

    private func runAgain() {
        startAnimation()
    }

    private func startAnimation() {
        animationTask?.cancel()
        result = nil
        isRunning = true

        animationTask = Task { @MainActor in
            let selected = selector.select(from: options) ?? options[0]
            let selectedIndex = options.firstIndex(of: selected) ?? 0
            let spinCount = (options.count * 5) + selectedIndex

            for step in 0...spinCount {
                guard !Task.isCancelled else { return }

                highlightedIndex = step % options.count
                haptics.selectionChanged()

                let progress = Double(step) / Double(max(spinCount, 1))
                let delay = 0.045 + pow(progress, 2.3) * 0.22
                try? await Task.sleep(for: .seconds(delay))
            }

            highlightedIndex = selectedIndex
            result = selected
            isRunning = false
            haptics.decisionFinished()
        }
    }
}

private struct DecisionOptionCapsule: View {
    let title: String
    let isHighlighted: Bool
    let isResult: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(isHighlighted || isResult ? .decideHeadline : .decideBody)
                .foregroundStyle(isHighlighted || isResult ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            if isResult {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHighlighted || isResult ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.08))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isHighlighted || isResult ? Color.accentColor.opacity(0.65) : Color.clear, lineWidth: 1)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedDecision.self, inMemory: true)
}
