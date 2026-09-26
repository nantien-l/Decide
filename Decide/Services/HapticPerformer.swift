#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct HapticPerformer {
    #if canImport(UIKit)
    // Feedback generators are relatively expensive to create. Keeping them alive
    // avoids allocating one for every frame of the decision animation.
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    #endif

    func selectionChanged() {
        guard AppSettings.hapticsEnabled else { return }
        #if canImport(UIKit)
        Self.selectionGenerator.selectionChanged()
        Self.selectionGenerator.prepare()
        #endif
    }

    func decisionFinished() {
        guard AppSettings.hapticsEnabled else { return }
        #if canImport(UIKit)
        Self.notificationGenerator.notificationOccurred(.success)
        Self.notificationGenerator.prepare()
        #endif
    }

    func lightTap() {
        guard AppSettings.hapticsEnabled else { return }
        #if canImport(UIKit)
        Self.impactGenerator.impactOccurred()
        Self.impactGenerator.prepare()
        #endif
    }
}
