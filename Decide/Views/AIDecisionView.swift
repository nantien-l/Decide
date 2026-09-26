import SwiftData
import SwiftUI

struct AIDecisionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @State private var prompt = ""
    @State private var generatedQuestion = ""
    @State private var options: [DecisionOption] = []
    @State private var activeSession: DecisionSession?
    @State private var isGenerating = false
    @State private var isShowingGeneratedDecision = false
    @State private var generationError: String?
    @State private var savedGeneratedDecision: SavedDecision?
    @State private var speechTranscriber = SpeechTranscriber()

    private let suggestionService = DecisionSuggestionService()
    private let persistence = DecisionPersistence()

    private var cleanedOptions: [String] {
        options
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating && settings.aiSuggestionsEnabled
    }

    private var canChoose: Bool {
        !generatedQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && cleanedOptions.count >= 2
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DecideBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        promptArea
                        suggestionChips
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 120)
                    .frame(maxWidth: 520, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("AI")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isShowingGeneratedDecision) {
                GeneratedDecisionView(
                    question: $generatedQuestion,
                    options: $options,
                    isGenerating: isGenerating,
                    generationError: generationError,
                    canGenerate: canGenerate,
                    canChoose: canChoose,
                    regenerate: { Task { await generateDecision(navigateOnSuccess: false) } },
                    choose: startDecision,
                    addOption: addOption,
                    moveOption: moveOption,
                    deleteOption: deleteOption
                )
            }
            .sheet(item: $activeSession) { session in
                DecisionAnimationView(
                    question: session.question,
                    options: session.options,
                    onDone: { activeSession = nil },
                    onResult: recordGeneratedResult
                )
            }
            .onChange(of: speechTranscriber.transcript) { _, transcript in
                prompt = transcript
            }
            .onDisappear {
                // A tab switch or sheet dismissal must not leave the audio engine
                // recording in the background.
                speechTranscriber.stop()
            }
        }
    }

    private var promptArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What do you want to decide?")
                .font(.decideLargeTitle)
                .foregroundStyle(DecidePalette.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                TextField(
                    "I have three hours tonight and can't decide whether to study, practice violin, or rest...",
                    text: $prompt,
                    axis: .vertical
                )
                .font(.decideBody)
                .lineLimit(7...12)
                .textFieldStyle(.plain)
                .frame(minHeight: 150, alignment: .topLeading)
                .disabled(isGenerating)

                Divider()

                promptControls

                if isGenerating {
                    ThinkingStatusView()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.snappy(duration: 0.2), value: isGenerating)
            .padding(16)
            .background(.thinMaterial, in: .rect(cornerRadius: 18))

            if let generationError, !isShowingGeneratedDecision {
                Label(generationError, systemImage: "exclamationmark.triangle")
                    .font(.decideFootnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var promptControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                microphoneButton
                microphoneStatusLabel
                Spacer()
            }

            generateButton
                .frame(maxWidth: .infinity)
        }
    }

    private var microphoneStatusLabel: some View {
        Text(microphoneStatusText)
            .font(.decideFootnote)
            .foregroundStyle(microphoneStatusStyle)
            .lineLimit(2)
    }

    private var generateButton: some View {
        Button {
            Task { await generateDecision(navigateOnSuccess: true) }
        } label: {
            if isGenerating {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating")
                }
            } else {
                Label("Generate", systemImage: "sparkles")
            }
        }
        .buttonStyle(.borderedProminent)
        .lineLimit(1)
        .disabled(!canGenerate)
    }

    private var microphoneButton: some View {
        Button {
            Task { await toggleListening() }
        } label: {
            Image(systemName: speechTranscriber.state.isListening ? "stop.fill" : "mic.fill")
                .frame(width: 34, height: 34)
                .contentShape(.rect)
        }
        .buttonStyle(.bordered)
        .tint(speechTranscriber.state.isListening ? .red : .accentColor)
        .disabled(isGenerating)
        .accessibilityLabel(speechTranscriber.state.isListening ? "Stop Listening" : "Start Dictation")
    }

    private var microphoneStatusText: LocalizedStringResource {
        switch speechTranscriber.state {
        case .idle:
            "Tap to speak"
        case .listening:
            "Listening"
        case .stopped:
            "Ready to edit"
        case .error:
            "Speech unavailable"
        }
    }

    private var microphoneStatusStyle: Color {
        switch speechTranscriber.state {
        case .listening:
            .red
        case .error:
            .secondary
        default:
            .secondary
        }
    }

    private var suggestionChips: some View {
        FlowLayout(spacing: 8) {
            ForEach(SuggestionChip.allCases) { chip in
                Button {
                    apply(chip)
                } label: {
                    Label(chip.title, systemImage: chip.symbolName)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isGenerating)
            }
        }
    }

    private func toggleListening() async {
        if speechTranscriber.state.isListening {
            speechTranscriber.stop()
        } else {
            speechTranscriber.transcript = prompt
            await speechTranscriber.start(localeIdentifier: settings.language.localeIdentifier)
        }
    }

    private func generateDecision(navigateOnSuccess: Bool) async {
        let input = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !isGenerating else { return }

        isGenerating = true
        generationError = nil

        do {
            let suggestion = try await suggestionService.suggest(for: input, language: settings.language)
            generatedQuestion = suggestion.question
            options = suggestion.options.map { DecisionOption(text: $0) }
            savedGeneratedDecision = nil
            HapticPerformer().lightTap()

            if navigateOnSuccess {
                isShowingGeneratedDecision = true
            }
        } catch {
            generationError = error.localizedDescription
        }

        isGenerating = false
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
            question: generatedQuestion.trimmingCharacters(in: .whitespacesAndNewlines),
            options: cleanedOptions
        )
    }

    private func recordGeneratedResult(_ result: String) {
        Task { @MainActor in
            savedGeneratedDecision = await persistence.save(
                question: generatedQuestion,
                options: cleanedOptions,
                source: .ai,
                selectedResult: result,
                existingDecision: savedGeneratedDecision,
                in: modelContext
            )
        }
    }

    private func apply(_ chip: SuggestionChip) {
        prompt = chip.prompt
        if chip == .surpriseMe {
            Task { await generateDecision(navigateOnSuccess: true) }
        }
    }
}

private struct GeneratedDecisionView: View {
    @Binding var question: String
    @Binding var options: [DecisionOption]

    let isGenerating: Bool
    let generationError: String?
    let canGenerate: Bool
    let canChoose: Bool
    let regenerate: @Sendable () -> Void
    let choose: @Sendable () -> Void
    let addOption: @Sendable () -> Void
    let moveOption: @Sendable (Int, Int) -> Void
    let deleteOption: @Sendable (Int) -> Void

    private var optionCount: Int {
        options
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count
    }

    var body: some View {
        ZStack {
            DecideBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ContentSection {
                        SectionTitle(title: "Generated Decision", subtitle: "Review and adjust before choosing.")

                        TextField("Question", text: $question, axis: .vertical)
                            .font(.decideTitle3)
                            .textFieldStyle(.plain)
                            .lineLimit(2...5)
                            .padding(.vertical, 8)
                            .overlay(alignment: .bottom) { Divider() }
                    }

                    OptionsSectionView(
                        options: $options,
                        optionCount: optionCount,
                        canDecide: canChoose,
                        addOption: { addOption() },
                        moveOption: { index, offset in moveOption(index, offset) },
                        deleteOption: { index in deleteOption(index) }
                    )

                    if isGenerating {
                        ThinkingStatusView()
                    }

                    if let generationError {
                        Label(generationError, systemImage: "exclamationmark.triangle")
                            .font(.decideFootnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 120)
                .frame(maxWidth: 520, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Generated Decision")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button(action: regenerate) {
                if isGenerating {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Regenerating")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label("Regenerate", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(!canGenerate)

            Button(action: choose) {
                Text("Choose")
                    .font(.decideHeadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canChoose || isGenerating)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.bar)
    }
}

private enum SuggestionChip: String, CaseIterable, Identifiable {
    case food
    case activity
    case shopping
    case surpriseMe

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .food:
            "Where to eat"
        case .activity:
            "What to do"
        case .shopping:
            "What to buy"
        case .surpriseMe:
            "Surprise me"
        }
    }

    var symbolName: String {
        switch self {
        case .food:
            "fork.knife"
        case .activity:
            "figure.walk"
        case .shopping:
            "bag"
        case .surpriseMe:
            "shuffle"
        }
    }

    var prompt: String {
        switch self {
        case .food:
            "Help me decide where to eat based on what sounds good right now."
        case .activity:
            "Help me decide what to do with my available time today."
        case .shopping:
            "Help me decide what to buy while staying practical about budget and usefulness."
        case .surpriseMe:
            "Create a fun, realistic everyday decision with useful options."
        }
    }
}

private struct ThinkingStatusView: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()

            Text("Thinking through the options")
                .font(.decideFootnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .accessibilityLabel("Thinking through the options")
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) { content }
            VStack(alignment: .leading, spacing: spacing) { content }
        }
    }
}
