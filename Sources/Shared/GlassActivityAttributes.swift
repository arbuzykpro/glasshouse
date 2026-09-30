import ActivityKit
import Foundation

/// Shared between the app and the widget extension. This file must be a member
/// of BOTH targets (see `project.yml`) or the extension will not see the type
/// and `ActivityConfiguration` will fail to compile.
///
/// The attribute payload is fixed for the lifetime of the activity — it is set
/// once at `request` time. Everything that changes afterwards travels in
/// `ContentState`.
struct GlassActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        /// Primary line, shown in the Lock Screen header and island center.
        var title: String
        /// Secondary line, Lock Screen body only.
        var detail: String
        /// Trailing metric, e.g. "72°" or "4/12".
        var value: String
        /// 0...1, drives the Lock Screen bar and the circular island gauge.
        var progress: Double
        /// SF Symbol name shown on the left of the Lock Screen card.
        var symbol: String
        /// Secondary symbol shown in the compact island trailing slot.
        var symbolAlt: String

        init(
            title: String = "Glasshouse",
            detail: String = "Live Activity running",
            value: String = "0%",
            progress: Double = 0.5,
            symbol: String = "sparkles",
            symbolAlt: String = "bolt.fill"
        ) {
            self.title = title
            self.detail = detail
            self.value = value
            self.progress = progress
            self.symbol = symbol
            self.symbolAlt = symbolAlt
        }
    }

    /// Which visual preset the user picked in the Studio. The extension switches
    /// its Lock Screen layout on this.
    var preset: GlassActivityPreset

    /// Accent color as `#RRGGBB`, so the island tints to the theme.
    var accentHex: String

    /// 0 = fully tinted, 1 = ultraclear. Mirrors the iOS 27 Liquid Glass slider.
    var glassLevel: Double
}

/// The three Lock Screen layouts. Island geometry is fixed by ActivityKit —
/// only the Lock Screen card and the island's content slots are ours.
enum GlassActivityPreset: String, Codable, Hashable, CaseIterable, Identifiable {
    case minimal
    case progress
    case stats

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .progress: return "Progress"
        case .stats: return "Stats"
        }
    }

    var blurb: String {
        switch self {
        case .minimal: return "Single line. Most room on the Lock Screen."
        case .progress: return "Bar plus caption. Good for timers and tasks."
        case .stats: return "Three metrics. Denser, uses the full card."
        }
    }
}
