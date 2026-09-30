import SwiftUI

struct RootView: View {
    @Environment(ThemeStoreController.self) private var store

    var body: some View {
        @Bindable var store = store

        TabView(selection: $store.tab) {
            Tab("Studio", systemImage: "sparkles.rectangle.stack", value: .studio) {
                StudioView()
            }
            Tab("Themes", systemImage: "paintpalette", value: .themes) {
                ThemesView()
            }
            Tab("Guide", systemImage: "info.circle", value: .guide) {
                GuideView()
            }
        }
        .tint(store.selected?.accent ?? .accentColor)
    }
}
