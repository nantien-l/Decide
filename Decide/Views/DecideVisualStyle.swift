import SwiftUI

enum DecidePalette {
    // `primary` resolves to the correct high-contrast label color in both
    // light and dark appearances. The previous fixed near-black color became
    // unreadable against the dark system background.
    static let ink = Color.primary
    static let accent = Color.accentColor
}

struct DecideBackground: View {
    var body: some View {
        Color(.systemBackground)
            .ignoresSafeArea()
    }
}

struct BrandHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Make a clear choice")
                .font(.decideLargeTitle)
                .foregroundStyle(DecidePalette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Frame the decision, compare the options, and move on.")
                .font(.decideSubheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ContentSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.decideTitle3)
                .foregroundStyle(DecidePalette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.decideSubheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct OptionRow: View {
    @Binding var option: DecisionOption

    let canMoveUp: Bool
    let canMoveDown: Bool
    let canDelete: Bool
    let index: Int
    let moveUp: () -> Void
    let moveDown: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.decideFootnote)
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .leading)

            TextField("Option", text: $option.text)
                .font(.decideBody)
                .textFieldStyle(.plain)
                .submitLabel(.done)

            Menu {
                Button("Move Up", systemImage: "chevron.up", action: moveUp)
                    .disabled(!canMoveUp)
                Button("Move Down", systemImage: "chevron.down", action: moveDown)
                    .disabled(!canMoveDown)
                Button("Delete", systemImage: "trash", role: .destructive, action: delete)
                    .disabled(!canDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 12)
    }
}
