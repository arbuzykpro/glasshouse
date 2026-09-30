import Photos
import SwiftUI

struct ThemesView: View {
    @Environment(ThemeStoreController.self) private var store
    @State private var draft = GlassTheme.starters[0]
    @State private var saveState: SaveState = .idle

    enum SaveState: Equatable {
        case idle, saving, done, denied(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Saved") {
                    ForEach(store.themes) { theme in
                        Button {
                            store.select(theme)
                            draft = theme
                        } label: {
                            row(theme)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { store.themes.remove(atOffsets: $0); ThemeStore.save(store.themes) }
                }

                Section("Editor") {
                    TextField("Name", text: $draft.name)

                    LabeledContent("Accent") {
                        ColorPicker("", selection: Binding(
                            get: { draft.accent },
                            set: { draft.accentHex = $0.hexString() }
                        ), supportsOpacity: false)
                        .labelsHidden()
                    }
                    LabeledContent("Secondary") {
                        ColorPicker("", selection: Binding(
                            get: { draft.secondary },
                            set: { draft.secondaryHex = $0.hexString() }
                        ), supportsOpacity: false)
                        .labelsHidden()
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            // Labels match the iOS 27 Liquid Glass slider ends.
                            Text("Tinted")
                            Slider(value: $draft.glassLevel, in: 0...1)
                            Text("Ultraclear")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Picker("Wallpaper", selection: $draft.wallpaper) {
                        ForEach(GlassTheme.WallpaperStyle.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }

                    Button("Save to this theme") {
                        store.update(draft)
                    }
                }

                Section {
                    Button {
                        exportWallpaper()
                    } label: {
                        HStack {
                            Label("Export wallpaper", systemImage: "square.and.arrow.down")
                            Spacer()
                            switch saveState {
                            case .saving: ProgressView()
                            case .done: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            case .denied: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                            case .idle: EmptyView()
                            }
                        }
                    }
                    .disabled(saveState == .saving)

                    if case .denied(let msg) = saveState {
                        Text(msg).font(.caption).foregroundStyle(.red)
                    }
                } footer: {
                    Text("Saves a 1290×2796 PNG to Photos. Set it via Settings › Wallpaper › Choose New Wallpaper.")
                }

                Section {
                    Button("Reset to starters", role: .destructive) {
                        store.resetToStarters()
                    }
                }
            }
            .navigationTitle("Themes")
        }
        .onAppear {
            if let s = store.selected { draft = s }
        }
    }

    private func row(_ theme: GlassTheme) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(colors: [theme.accent, theme.secondary],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(theme.name).font(.body)
                Text("\(theme.wallpaper.displayName) · glass \(Int(theme.glassLevel * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if store.selectedID == theme.id || store.selected?.id == theme.id {
                Image(systemName: "checkmark").foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: Export

    private func exportWallpaper() {
        saveState = .saving
        let view = WallpaperCanvas(theme: draft)
            .frame(width: 1290, height: 2796)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.proposedSize = .init(width: 1290, height: 2796)

        guard let image = renderer.uiImage, let data = image.pngData() else {
            saveState = .denied("Render failed.")
            return
        }

        // write-only access: adding a wallpaper never needs read access to the
        // user's library, so this asks for the narrowest possible permission.
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    saveState = .denied("Photos access denied. Enable it in Settings.")
                    return
                }
                // `creationRequestForAsset(from:)` takes a UIImage, not Data.
                // Decoding here also lets us report a genuinely bad PNG rather
                // than failing later inside Photos.
                guard let image = UIImage(data: data) else {
                    saveState = .denied("Rendered image could not be decoded.")
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { ok, err in
                    DispatchQueue.main.async {
                        saveState = ok ? .done : .denied(err?.localizedDescription ?? "Save failed.")
                    }
                }
            }
        }
    }
}

/// Fixed-size render target. The `.background` must be the outermost modifier
/// or `ImageRenderer` produces a transparent PNG.
private struct WallpaperCanvas: View {
    let theme: GlassTheme

    var body: some View {
        ZStack {
            theme.wallpaperBackground
            Circle()
                .fill(theme.accent.opacity(0.35))
                .frame(width: 900, height: 900)
                .blur(radius: 120)
                .offset(x: -320, y: -820)
            Circle()
                .fill(theme.secondary.opacity(0.30))
                .frame(width: 800, height: 800)
                .blur(radius: 130)
                .offset(x: 380, y: 900)
        }
        .clipped()
    }
}
