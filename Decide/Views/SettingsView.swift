import FoundationModels
import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section("Decision") {
                    Toggle("Haptic Feedback", isOn: $settings.hapticFeedbackEnabled)
                    Toggle("Decision Animation", isOn: $settings.decisionAnimationEnabled)
                }

                Section("AI") {
                    HStack {
                        Text("Apple Intelligence")

                        Spacer()

                        Label(modelAvailabilityTitle, systemImage: modelAvailabilitySymbol)
                            .foregroundStyle(modelAvailabilityColor)
                    }
                    Toggle("AI Suggestions", isOn: $settings.aiSuggestionsEnabled)
                }

                Section("Language") {
                    Picker("Display Language", selection: $settings.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title)
                                .tag(language)
                        }
                    }
                }

                Section("Text Size") {
                    Picker("Text Size", selection: $settings.textSize) {
                        ForEach(AppTextSize.allCases) { textSize in
                            Text(textSize.title)
                                .tag(textSize)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Appearance") {
                    Picker("Appearance", selection: $settings.appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title)
                                .tag(appearance)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("About") {
                    LabeledContent("Decide", value: "A small utility for making clear choices.")
                    LabeledContent("Version", value: versionString)
                    LabeledContent("Privacy", value: "Speech becomes editable text. Decisions stay on device unless system services are used.")
                    LabeledContent("Technologies", value: "SwiftUI, SwiftData, App Intents, Speech, Foundation Models")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var modelAvailabilityTitle: LocalizedStringResource {
        switch SystemLanguageModel.default.availability {
        case .available:
            "Available"
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                "Device Not Eligible"
            case .appleIntelligenceNotEnabled:
                "Not Enabled"
            case .modelNotReady:
                "Preparing"
            @unknown default:
                "Unavailable"
            }
        }
    }

    private var modelAvailabilitySymbol: String {
        switch SystemLanguageModel.default.availability {
        case .available:
            "checkmark.circle.fill"
        case .unavailable:
            "exclamationmark.circle"
        }
    }

    private var modelAvailabilityColor: Color {
        switch SystemLanguageModel.default.availability {
        case .available:
            .green
        case .unavailable:
            .secondary
        }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
