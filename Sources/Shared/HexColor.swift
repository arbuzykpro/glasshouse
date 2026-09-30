import SwiftUI
import UIKit

extension Color {
    /// Builds a `Color` from a `#RRGGBB` or `#RRGGBBAA` string.
    /// Returns `.gray` if the string is not parseable, so a bad value in a
    /// saved theme degrades instead of trapping.
    init(hex: String) {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") { raw.removeFirst() }
        guard raw.count == 6 || raw.count == 8,
              let value = UInt64(raw, radix: 16) else {
            self = .gray
            return
        }
        let hasAlpha = raw.count == 8
        let r, g, b, a: Double
        if hasAlpha {
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        } else {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// `#RRGGBB` string for a color. Used when persisting a theme.
    func hexString() -> String {
        let comps = UIColor(self).rgbaComponents
        func hex(_ v: Double) -> String {
            let i = Int((v * 255).rounded())
            return String(format: "%02X", max(0, min(255, i)))
        }
        return "#" + hex(comps.r) + hex(comps.g) + hex(comps.b)
    }
}

extension UIColor {
    private var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
