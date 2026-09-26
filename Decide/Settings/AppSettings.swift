import Foundation
import SwiftUI

@Observable
final class AppSettings {
    enum Key {
        static let language = "settings.language"
        static let appearance = "settings.appearance"
        static let textSize = "settings.textSize"
        static let hapticFeedback = "settings.hapticFeedback"
        static let decisionAnimation = "settings.decisionAnimation"
        static let aiSuggestions = "settings.aiSuggestions"
    }

    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Key.language) }
    }

    var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Key.appearance) }
    }

    var textSize: AppTextSize {
        didSet { UserDefaults.standard.set(textSize.rawValue, forKey: Key.textSize) }
    }

    var hapticFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticFeedbackEnabled, forKey: Key.hapticFeedback) }
    }

    var decisionAnimationEnabled: Bool {
        didSet { UserDefaults.standard.set(decisionAnimationEnabled, forKey: Key.decisionAnimation) }
    }

    var aiSuggestionsEnabled: Bool {
        didSet { UserDefaults.standard.set(aiSuggestionsEnabled, forKey: Key.aiSuggestions) }
    }

    init(defaults: UserDefaults = .standard) {
        let languageValue = defaults.string(forKey: Key.language) ?? AppLanguage.system.rawValue
        language = AppLanguage(rawValue: languageValue) ?? .system

        let appearanceValue = defaults.string(forKey: Key.appearance) ?? AppAppearance.system.rawValue
        appearance = AppAppearance(rawValue: appearanceValue) ?? .system

        let textSizeValue = defaults.string(forKey: Key.textSize) ?? AppTextSize.system.rawValue
        textSize = AppTextSize(rawValue: textSizeValue) ?? .system

        hapticFeedbackEnabled = defaults.object(forKey: Key.hapticFeedback) as? Bool ?? true
        decisionAnimationEnabled = defaults.object(forKey: Key.decisionAnimation) as? Bool ?? true
        aiSuggestionsEnabled = defaults.object(forKey: Key.aiSuggestions) as? Bool ?? true
    }

    static var hapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: Key.hapticFeedback) as? Bool ?? true
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case traditionalChinese

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .system:
            "System Default"
        case .english:
            "English"
        case .traditionalChinese:
            "Traditional Chinese"
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system:
            nil
        case .english:
            "en"
        case .traditionalChinese:
            "zh-Hant"
        }
    }

    var foundationModelInstruction: String {
        switch self {
        case .system:
            return "Use the person's input language for the question and option text."
        case .english:
            return "Write the question and option text in English."
        case .traditionalChinese:
            return "Write the question and option text in Traditional Chinese."
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .system:
            "Follow System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

enum AppTextSize: String, CaseIterable, Identifiable {
    case system
    case large
    case extraLarge
    case accessibility

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .system:
            "Follow System"
        case .large:
            "Large"
        case .extraLarge:
            "Extra Large"
        case .accessibility:
            "Accessibility"
        }
    }

    var dynamicTypeSize: DynamicTypeSize? {
        switch self {
        case .system:
            nil
        case .large:
            .xLarge
        case .extraLarge:
            .xxxLarge
        case .accessibility:
            .accessibility1
        }
    }
}
