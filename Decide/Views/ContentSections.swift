import SwiftUI

struct QuestionSectionView: View {
    @Binding var question: String

    let isSuggesting: Bool
    let suggestionError: String?
    let suggestOptions: @Sendable () -> Void
    let surpriseMe: @Sendable () -> Void
    var showsSuggestionControls = true

    private var canSuggest: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSuggesting
    }

    var body: some View {
        ContentSection {
            SectionTitle(
                title: "Decision",
                subtitle: "State the choice you need to make."
            )

            TextField("Should I accept this offer, book this trip, choose this plan...", text: $question, axis: .vertical)
                .font(.decideBody)
                .lineLimit(5...8)
                .textFieldStyle(.plain)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 136, alignment: .topLeading)
                .overlay(alignment: .bottom) {
                    Divider()
                }

            if showsSuggestionControls {
                suggestionButtons
            }

            if let suggestionError {
                Label(suggestionError, systemImage: "exclamationmark.triangle")
                    .font(.decideFootnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var suggestionButtons: some View {
        HStack(spacing: 12) {
            Button(action: suggestOptions) {
                Label(isSuggesting ? "Drafting" : "Draft Options", systemImage: "lightbulb")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .disabled(!canSuggest)

            Button(action: surpriseMe) {
                Label("Use Sample", systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
        }
        .controlSize(.large)
    }
}

struct OptionsSectionView: View {
    @Binding var options: [DecisionOption]

    let optionCount: Int
    let canDecide: Bool
    let addOption: @Sendable () -> Void
    let moveOption: @Sendable (Int, Int) -> Void
    let deleteOption: @Sendable (Int) -> Void

    var body: some View {
        ContentSection {
            header
            rows
            addButton
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            SectionTitle(
                title: "Options",
                subtitle: canDecide ? "Refine the list before choosing." : "Add at least two options."
            )

            Spacer()

            Text("\(optionCount)")
                .font(.decideSubheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    private var rows: some View {
        VStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                row(at: index)

                if index < options.count - 1 {
                    Divider()
                }
            }
        }
    }

    private func row(at index: Int) -> some View {
        OptionRow(
            option: $options[index],
            canMoveUp: index > 0,
            canMoveDown: index < options.count - 1,
            canDelete: options.count > 1,
            index: index,
            moveUp: { moveOption(index, -1) },
            moveDown: { moveOption(index, 1) },
            delete: { deleteOption(index) }
        )
    }

    private var addButton: some View {
        Button(action: addOption) {
            Label("Add Option", systemImage: "plus.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderless)
        .controlSize(.large)
    }
}

struct BottomActionBarView: View {
    let canDecide: Bool
    let startDecision: @Sendable () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: startDecision) {
                Text("Choose")
                    .font(.decideHeadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canDecide)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.bar)
    }
}
