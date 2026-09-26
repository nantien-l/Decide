import SwiftUI

struct DecisionAnimationView: View {
    @Environment(AppSettings.self) private var settings

    let question: String
    let options: [String]
    let onDone: () -> Void
    let onResult: ((String) -> Void)?

    @State private var highlightedIndex = 0
    @State private var result: String?
    @State private var isRunning = false
    @State private var animationTask: Task<Void, Never>?

    private let selector = DecisionSelector()
    private let haptics = HapticPerformer()

    init(
        question: String,
        options: [String],
        onDone: @escaping () -> Void,
        onResult: ((String) -> Void)? = nil
    ) {
        self.question = question
        self.options = options
        self.onDone = onDone
        self.onResult = onResult
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DecideBackground()
                content
            }
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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

    private var content: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 24)
            resultText
            optionList
            Spacer(minLength: 24)
            tryAgainButton
        }
    }

    private var resultText: some View {
        VStack(spacing: 10) {
            Text(result == nil ? "Evaluating" : "Selected Option")
                .font(.decideSubheadline)
                .foregroundStyle(.secondary)

            Text(result ?? options[safe: highlightedIndex] ?? options.first ?? "")
                .font(.decideLargeTitle)
                .foregroundStyle(DecidePalette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.65)
                .contentTransition(.numericText())
                .scaleEffect(result == nil ? 1 : 1.05)
                .animation(.spring(response: 0.38, dampingFraction: 0.72), value: result)

            if !question.isEmpty {
                Text(question)
                    .font(.decideFootnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 28)
    }

    private var optionList: some View {
        VStack(spacing: 10) {
            ForEach(options.indices, id: \.self) { index in
                DecisionOptionCapsule(
                    title: options[index],
                    isHighlighted: index == highlightedIndex && result == nil,
                    isResult: options[index] == result
                )
            }
        }
        .padding(.horizontal, 20)
        .animation(.snappy(duration: 0.22), value: highlightedIndex)
        .animation(.spring(response: 0.4, dampingFraction: 0.78), value: result)
    }

    private var tryAgainButton: some View {
        Button(action: runAgain) {
            Label("Choose Again", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isRunning)
        .padding(.horizontal, 48)
        .padding(.bottom, 26)
        .opacity(result == nil ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: result)
    }

    private func runAgain() {
        startAnimation()
    }

    private func startAnimation() {
        guard !options.isEmpty else { return }

        animationTask?.cancel()
        result = nil
        isRunning = true

        animationTask = Task { @MainActor in
            let selected = selector.select(from: options) ?? options[0]
            let selectedIndex = options.firstIndex(of: selected) ?? 0

            guard settings.decisionAnimationEnabled else {
                highlightedIndex = selectedIndex
                finish(with: selected)
                return
            }

            // Keep the animation bounded for long manually-entered lists while
            // still landing on the selected option.
            let spinCount = min(max(options.count * 3, 12), 30)
            let hapticStride = options.count > 8 ? 2 : 1

            for step in 0...spinCount {
                guard !Task.isCancelled else { return }

                // Work backwards from the final index so the final visible frame
                // is always the selected option, without making the duration
                // depend on where it sits in a very long list.
                let remainingSteps = spinCount - step
                highlightedIndex = (selectedIndex - (remainingSteps % options.count) + options.count) % options.count
                if step.isMultiple(of: hapticStride) {
                    haptics.selectionChanged()
                }

                let progress = Double(step) / Double(max(spinCount, 1))
                let delay = 0.045 + pow(progress, 2.3) * 0.22
                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch {
                    return
                }
            }

            guard !Task.isCancelled else { return }
            highlightedIndex = selectedIndex
            finish(with: selected)
        }
    }

    private func finish(with selected: String) {
        result = selected
        isRunning = false
        haptics.decisionFinished()
        onResult?(selected)
    }
}

private struct DecisionOptionCapsule: View {
    let title: String
    let isHighlighted: Bool
    let isResult: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(isHighlighted || isResult ? .decideHeadline : .decideBody)
                .foregroundStyle(isHighlighted || isResult ? DecidePalette.ink : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            if isResult {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(
            isHighlighted || isResult ? Color.accentColor.opacity(0.14) : Color.clear,
            in: .rect(cornerRadius: 14)
        )
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
