import SwiftData
import SwiftUI

@main
struct DecideApp: App {
    @State private var settings = AppSettings()

    private let modelContainer: ModelContainer

    init() {
        DecideTypography.configureAppearance()
        modelContainer = AppModelContainer.make()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(.decideBody)
                .environment(settings)
                .environment(\.locale, appLocale)
                .appTextSize(settings.textSize)
                .preferredColorScheme(settings.appearance.colorScheme)
        }
        .modelContainer(modelContainer)
    }

    private var appLocale: Locale {
        if let identifier = settings.language.localeIdentifier {
            Locale(identifier: identifier)
        } else {
            Locale.current
        }
    }
}

private extension View {
    @ViewBuilder
    func appTextSize(_ textSize: AppTextSize) -> some View {
        if let size = textSize.dynamicTypeSize {
            dynamicTypeSize(size)
        } else {
            self
        }
    }
}

private enum AppModelContainer {
    static func make() -> ModelContainer {
        do {
            return try ModelContainer(for: SavedDecision.self)
        } catch {
            print("Failed to create persistent model container: \(error)")
            return makeInMemoryFallback()
        }
    }

    private static func makeInMemoryFallback() -> ModelContainer {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: SavedDecision.self, configurations: configuration)
        } catch {
            fatalError("Failed to create fallback model container: \(error)")
        }
    }
}
