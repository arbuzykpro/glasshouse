import SwiftUI

/// A saved look. `Codable` so it round-trips through `UserDefaults` as JSON.
struct GlassTheme: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var accentHex: String
    var secondaryHex: String
    /// 0...1 → 1 is fully tinted, 0 is ultraclear. Fed into the widget so the
    /// generated card matches the iOS 27 slider.
    var glassLevel: Double
    var wallpaper: WallpaperStyle
    var useCustomWallpaper: Bool = false

    var accent: Color { Color(hex: accentHex) }
    var secondary: Color { Color(hex: secondaryHex) }

    enum WallpaperStyle: String, Codable, Hashable, CaseIterable, Identifiable {
        case aurora
        case mesh
        case monochrome
        case ember

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .aurora: return "Aurora"
            case .mesh: return "Mesh"
            case .monochrome: return "Mono"
            case .ember: return "Ember"
            }
        }

        /// The SwiftUI background used for both the in-app preview and the
        /// exported wallpaper PNG. Colors are passed in because a `case` has no
        /// enclosing `GlassTheme` instance to read `accentHex` from.
        @ViewBuilder
        func background(accent: Color, secondary: Color) -> some View {
            switch self {
            case .aurora:
                LinearGradient(
                    colors: [accent, secondary, .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .mesh:
                RadialGradient(colors: [accent, .clear], center: .topLeading, startRadius: 20, endRadius: 420)
                    .background(RadialGradient(colors: [secondary, .clear], center: .bottomTrailing, startRadius: 20, endRadius: 460))
                    .background(Color.black)
            case .monochrome:
                LinearGradient(
                    colors: [.black, accent.opacity(0.5), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .ember:
                LinearGradient(
                    colors: [.black, secondary, accent, .black],
                    startPoint: .bottom,
                    endPoint: .top
                )
            }
        }
    }

    /// Convenience so call sites do not thread both colors through.
    var wallpaperBackground: some View {
        wallpaper.background(accent: accent, secondary: secondary)
    }
}

/// Starter set. Everything is editable in the Themes tab.
extension GlassTheme {
    static let starters: [GlassTheme] = [
        GlassTheme(name: "Ultramarine", accentHex: "#2B5CFF", secondaryHex: "#7A3CFF", glassLevel: 0.25, wallpaper: .aurora),
        GlassTheme(name: "Ember", accentHex: "#FF6B35", secondaryHex: "#FFB627", glassLevel: 0.55, wallpaper: .ember),
        GlassTheme(name: "Mint", accentHex: "#00D68F", secondaryHex: "#00A3FF", glassLevel: 0.10, wallpaper: .mesh),
        GlassTheme(name: "Graphite", accentHex: "#8E8E93", secondaryHex: "#1C1C1E", glassLevel: 0.70, wallpaper: .monochrome)
    ]
}

/// JSON persistence in `UserDefaults`. Small enough that a file store would be
/// more code than it saves.
enum ThemeStore {
    private static let key = "glasshouse.themes.v1"

    static func load() -> [GlassTheme] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([GlassTheme].self, from: data),
              !decoded.isEmpty else {
            return GlassTheme.starters
        }
        return decoded
    }

    static func save(_ themes: [GlassTheme]) {
        guard let data = try? JSONEncoder().encode(themes) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
