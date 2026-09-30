import ActivityKit
import SwiftUI

struct StudioView: View {
    @Environment(ThemeStoreController.self) private var store
    @State private var activity = ActivityController()

    @State private var title = "Focus"
    @State private var detail = "Deep work block"
    @State private var value = "24:00"
    @State private var progress = 0.42
    @State private var symbol = "brain.head.profile"
    @State private var symbolAlt = "flame.fill"

    private var theme: GlassTheme { store.selected ?? GlassTheme.starters[0] }

    private var state: GlassActivityAttributes.ContentState {
        GlassActivityAttributes.ContentState(
            title: title,
            detail: detail,
            value: value,
            progress: progress,
            symbol: symbol,
            symbolAlt: symbolAlt
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                contentSection
                symbolSection
                runSection
            }
            .navigationTitle("Studio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ThemesView()
                    } label: {
                        Label("Theme", systemImage: "paintpalette")
                    }
                }
            }
        }
    }

    // MARK: Preview

    private var previewSection: some View {
        Section {
            ZStack {
                theme.wallpaperBackground
                // Approximates the Lock Screen card. The real one is drawn by
                // the extension with system glass applied on top.
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: symbol)
                            .foregroundStyle(theme.accent)
                        Text(title.isEmpty ? "Title" : title)
                            .font(.headline)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(value).font(.subheadline.bold()).monospacedDigit()
                    }
                    ProgressView(value: progress).tint(theme.accent)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(14)
                .background(theme.accent.opacity(0.30 * (1 - theme.glassLevel) + 0.04))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding()
            }
            .frame(height: 170)
            .listRowInsets(EdgeInsets())

            Text("Accent \(theme.accentHex) · glass \(Int(theme.glassLevel * 100))%")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Content

    private var contentSection: some View {
        Section("Content") {
            TextField("Title", text: $title)
            TextField("Detail", text: $detail)
            TextField("Value", text: $value)
                .monospacedDigit()

            VStack(alignment: .leading) {
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $progress, in: 0...1)
                    .tint(theme.accent)
            }
        }
    }

    private var symbolSection: some View {
        Section("Symbols") {
            LabeledContent("Primary") {
                Text(symbol).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            // SF Symbols are free to ship; the picker avoids a typo producing
            // a blank island.
            SymbolPicker(label: "Leading", selection: $symbol)
            SymbolPicker(label: "Minimal", selection: $symbolAlt)
        }
    }

    // MARK: Run

    @ViewBuilder
    private var runSection: some View {
        Section {
            if activity.canStart {
                Button {
                    activity.start(theme: theme, state: state)
                } label: {
                    Label("Start Live Activity", systemImage: "play.fill")
                }

                if activity.current != nil {
                    Button {
                        activity.update(state)
                    } label: {
                        Label("Push Update", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button(role: .destructive) {
                        activity.stop()
                    } label: {
                        Label("End", systemImage: "stop.fill")
                    }
                }
            } else {
                Label(
                    "Live Activities are disabled. Turn them on in Settings › Accessibility › Live Activities.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                // Deep-links to this app's own settings page, which is a
                // supported public URL. There is no public deep link that opens
                // the Accessibility > Live Activities pane directly.
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link("Open Settings", destination: url)
                }
            }

            if let err = activity.lastError {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Text("Lock the device to see it. The island shows while unlocked.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

/// Grid of SF Symbols that writes back a valid name.
private struct SymbolPicker: View {
    let label: String
    @Binding var selection: String

    private let names = [
        "sparkles", "flame.fill", "bolt.fill", "brain.head.profile",
        "heart.fill", "timer", "figure.run", "moon.stars.fill",
        "drop.fill", "leaf.fill", "cpu.fill", "chart.bar.fill",
        "cup.and.saucer.fill", "book.fill", "camera.fill", "location.fill"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                ForEach(names, id: \.self) { name in
                    Button {
                        selection = name
                    } label: {
                        Image(systemName: name)
                            .font(.system(size: 15))
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(selection == name ? Color.accentColor : Color.secondary.opacity(0.12))
                            )
                            .foregroundStyle(selection == name ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
