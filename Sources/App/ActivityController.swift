import ActivityKit
import Foundation

/// Wraps `Activity.request` / `update` / `end` so the views stay declarative.
///
/// The availability checks are not ceremony — `ActivityAuthorizationInfo` is
/// false when the user has Live Activities switched off in Settings, and
/// `request` throws rather than failing softly. Also false on iPad in some
/// configurations.
@MainActor
@Observable
final class ActivityController {
    private(set) var current: Activity<GlassActivityAttributes>?
    private(set) var lastError: String?

    /// False if the user disabled Live Activities, or the OS refused.
    var canStart: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func start(theme: GlassTheme, state: GlassActivityAttributes.ContentState) {
        guard canStart else {
            lastError = "Live Activities are off. Settings › General › Accessibility › Live Activities."
            return
        }
        // One at a time — the app is a single-activity studio. Ending any
        // stragglers also keeps the island from stacking two pills.
        endAll()

        let attributes = GlassActivityAttributes(
            preset: theme.wallpaper == .monochrome ? .stats : .progress,
            accentHex: theme.accentHex,
            glassLevel: theme.glassLevel
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            current = activity
            lastError = nil
        } catch {
            lastError = "Could not start: \(error.localizedDescription)"
        }
    }

    /// Pushes new state into the running activity. The Lock Screen card and the
    /// island both re-render; nothing else restarts.
    func update(_ state: GlassActivityAttributes.ContentState) {
        guard let current else { return }
        Task {
            await current.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    /// `.default` leaves the card on the Lock Screen for a few minutes with a
    /// strikethrough timestamp, then removes it. `.immediate` takes it now.
    func stop(dismissal: ActivityUIDismissalPolicy = .default) {
        guard let current else { return }
        Task {
            await current.end(nil, dismissalPolicy: dismissal)
        }
        self.current = nil
    }

    private func endAll() {
        for activity in Activity<GlassActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        current = nil
    }
}
