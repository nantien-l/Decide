import SwiftData
import SwiftUI

struct SavedDecisionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let savedDecisions: [SavedDecision]
    let onOpen: (SavedDecision) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                DecideBackground()

                if savedDecisions.isEmpty {
                    ContentUnavailableView(
                        "No Saved Decisions",
                        systemImage: "bookmark",
                        description: Text("Save a question and its options to reuse it later.")
                    )
                } else {
                    List {
                        ForEach(savedDecisions) { decision in
                            Button {
                                onOpen(decision)
                            } label: {
                                SavedDecisionRow(decision: decision)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteSavedDecisions)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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

private struct SavedDecisionRow: View {
    let decision: SavedDecision

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(decision.title)
                .font(.decideHeadline)
                .foregroundStyle(DecidePalette.ink)
                .lineLimit(2)

            Text(decision.options.joined(separator: " • "))
                .font(.decideSubheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 10)
    }
}
