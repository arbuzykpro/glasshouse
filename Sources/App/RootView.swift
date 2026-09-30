import SwiftUI

struct RootView: View {
    @Environment(ThemeStoreController.self) private var store

    var body: some View {
        @Bindable var store = store

        TabView(selection: $store.tab) {
            // .tabItem rather than the `Tab` builder — that one is iOS 18+.
            StudioView()
                .tabItem { Label("Studio", systemImage: "sparkles.rectangle.stack") }
                .tag(AppTab.studio)

            ThemesView()
                .tabItem { Label("Themes", systemImage: "paintpalette") }
                .tag(AppTab.themes)

            GuideView()
                .tabItem { Label("Guide", systemImage: "info.circle") }
                .tag(AppTab.guide)
        }
        .tint(store.selected?.accent ?? .accentColor)
    }
}
