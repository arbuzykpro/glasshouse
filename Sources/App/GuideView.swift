import SwiftUI
import UIKit

/// The honest half. Anyone shipping a customization app has to answer "why
/// doesn't this change my Home Screen", and a guide that pretends otherwise
/// gets one-starred.
struct GuideView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    capabilityRow("Live Activity layout", "Full", .green)
                    capabilityRow("Dynamic Island content", "Full", .green)
                    capabilityRow("Lock Screen card design", "Full", .green)
                    capabilityRow("Accent + glass tint", "Full", .green)
                    capabilityRow("Wallpaper generation", "Full", .green)
                } header: {
                    Text("What this app controls")
                } footer: {
                    Text("These are surfaces iOS renders from your SwiftUI layout. It is the one part of the system UI an ordinary app still owns end to end.")
                }

                Section {
                    capabilityRow("Home Screen icon grid", "No", .red)
                    capabilityRow("Control Center modules", "No", .red)
                    capabilityRow("Status bar contents", "No", .red)
                    capabilityRow("System Liquid Glass tint", "No", .red)
                } header: {
                    Text("What it cannot touch")
                } footer: {
                    Text("SpringBoard, Control Center, and the status bar are separate system processes. A sandboxed app is not loaded into them, so no amount of code changes them.")
                }

                Section("Why") {
                    Text("""
                    iOS loads your app as its own process with a container. \
                    Altering the system UI means injecting code into SpringBoard, \
                    which needs either a jailbreak or an unpatched kernel bug.

                    Sideloading through Sideloadly, AltStore, or TrollStore does \
                    not grant this. It changes how the app is signed and \
                    installed — not what the app is permitted to touch. TrollStore's \
                    unsandboxing came from a CoreTrust bug Apple closed in 18.1, and \
                    it has stayed closed.
                    """)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                // `App-Prefs:` is not a public scheme. It is not documented,
                // it is not guaranteed, and App Review rejects apps that lean
                // on it. On a sideloaded build it usually resolves; treat any
                // failure as expected rather than a bug.
                Section {
                    settingsLink("Appearance & Liquid Glass", path: "General&path=Appearance")
                    settingsLink("Wallpaper", path: "Wallpaper")
                    settingsLink("Accessibility", path: "Accessibility")
                } header: {
                    Text("Jump to system settings")
                } footer: {
                    Text("These use an undocumented URL scheme, so they may do nothing on some builds. If a link does not open, go to Settings directly.")
                }
            }
            .navigationTitle("Guide")
        }
    }

    private func settingsLink(_ title: String, path: String) -> some View {
        Button(title) {
            guard let url = URL(string: "App-Prefs:root=\(path)") else { return }
            UIApplication.shared.open(url)
        }
    }

    private func capabilityRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }
    }
}
