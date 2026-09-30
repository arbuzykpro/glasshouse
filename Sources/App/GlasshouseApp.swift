import SwiftUI

@main
struct GlasshouseApp: App {
    @State private var store = ThemeStoreController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    if url.scheme == "glasshouse", url.host == "activity" {
                        store.selectTab(.studio)
                    }
                }
        }
    }
}

enum AppTab: Hashable { case studio, themes, guide }

@Observable
final class ThemeStoreController {
    var themes: [GlassTheme] = ThemeStore.load()
    var selectedID: UUID?
    var tab: AppTab = .studio

    var selected: GlassTheme? {
        themes.first { $0.id == selectedID } ?? themes.first
    }

    func selectTab(_ t: AppTab) { tab = t }

    func select(_ theme: GlassTheme) { selectedID = theme.id }

    func update(_ theme: GlassTheme) {
        guard let i = themes.firstIndex(where: { $0.id == theme.id }) else { return }
        themes[i] = theme
        persist()
    }

    func resetToStarters() {
        themes = GlassTheme.starters
        selectedID = themes.first?.id
        persist()
    }

    private func persist() { ThemeStore.save(themes) }
}
