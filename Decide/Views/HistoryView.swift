import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedDecision.updatedAt, order: .reverse) private var savedDecisions: [SavedDecision]

    @State private var filter: HistoryFilter = .all
    @State private var classifier = DecisionCategoryClassifier()

    private var filteredDecisions: [SavedDecision] {
        switch filter {
        case .all:
            savedDecisions
        case .recent:
            Array(savedDecisions.prefix(10))
        case .favorites:
            savedDecisions.filter(\.isFavorite)
        case .aiGenerated:
            savedDecisions.filter { $0.source == .ai }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("History Filter", selection: $filter) {
                        ForEach(HistoryFilter.allCases) { filter in
                            Label(filter.title, systemImage: filter.symbolName)
                                .tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)

                if filteredDecisions.isEmpty {
                    ContentUnavailableView(
                        "No Decisions",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Saved and completed decisions will appear here.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(groupedCategories, id: \.category) { group in
                        Section {
                            ForEach(group.decisions) { decision in
                                NavigationLink(value: decision) {
                                    HistoryDecisionRow(decision: decision)
                                }
                            }
                            .onDelete { offsets in
                                delete(group.decisions, at: offsets)
                            }
                        } header: {
                            Label(group.category.title, systemImage: group.category.symbolName)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SavedDecision.self) { decision in
                DecisionDetailView(decision: decision)
            }
            .task { await resolveUnclassifiedDecisions() }
        }
    }

    private var groupedCategories: [(category: DecisionCategory, decisions: [SavedDecision])] {
        DecisionCategory.allCases.compactMap { category in
            let decisions = filteredDecisions.filter { $0.category == category }
            return decisions.isEmpty ? nil : (category, decisions)
        }
    }

    private func delete(_ decisions: [SavedDecision], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(decisions[index])
        }
    }

    private func resolveUnclassifiedDecisions() async {
        let unresolved = savedDecisions.filter { !$0.isCategoryResolved }
        guard !unresolved.isEmpty else { return }

        for decision in unresolved {
            decision.category = await classifier.category(for: decision.question, options: decision.options)
            decision.isCategoryResolved = true
        }
    }
}

private enum HistoryFilter: String, CaseIterable, Identifiable {
    case all
    case recent
    case favorites
    case aiGenerated

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .all:
            "All"
        case .recent:
            "Recent"
        case .favorites:
            "Favorites"
        case .aiGenerated:
            "AI Generated"
        }
    }

    var symbolName: String {
        switch self {
        case .all:
            "tray.full"
        case .recent:
            "clock"
        case .favorites:
            "star"
        case .aiGenerated:
            "sparkles"
        }
    }
}

private struct HistoryDecisionRow: View {
    let decision: SavedDecision

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(decision.title)
                    .font(.decideHeadline)
                    .foregroundStyle(DecidePalette.ink)
                    .lineLimit(2)

                if decision.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }

            Text(decision.options.formatted(.list(type: .and)))
                .font(.decideSubheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Label(decision.source.title, systemImage: decision.source == .ai ? "sparkles" : "keyboard")
                if let selectedResult = decision.selectedResult {
                    Label(selectedResult, systemImage: "checkmark.circle")
                        .lineLimit(1)
                }
            }
            .font(.decideFootnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct DecisionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let decision: SavedDecision

    @State private var activeSession: DecisionSession?

    var body: some View {
        List {
            Section("Question") {
                Text(decision.question)
                    .font(.decideTitle3)
                    .foregroundStyle(DecidePalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Options") {
                ForEach(decision.options, id: \.self) { option in
                    Text(option)
                }
            }

            Section("Details") {
                LabeledContent("Chosen Result") {
                    Text(decision.selectedResult ?? "Not chosen yet")
                }
                LabeledContent("Category") {
                    Label(decision.category.title, systemImage: decision.category.symbolName)
                }
                LabeledContent("Created") {
                    Text(decision.createdAt, format: .dateTime.year().month().day())
                }
                LabeledContent("Source") {
                    Text(decision.source.title)
                }
            }

            Section {
                Button {
                    activeSession = DecisionSession(question: decision.question, options: decision.options)
                } label: {
                    Label("Decide Again", systemImage: "arrow.clockwise")
                }

                Button {
                    decision.isFavorite.toggle()
                } label: {
                    Label(decision.isFavorite ? "Unfavorite" : "Favorite", systemImage: decision.isFavorite ? "star.slash" : "star")
                }

                Button(role: .destructive) {
                    modelContext.delete(decision)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Decision")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSession) { session in
            DecisionAnimationView(
                question: session.question,
                options: session.options,
                onDone: { activeSession = nil },
                onResult: { result in decision.selectedResult = result }
            )
        }
    }
}
