import ActivityKit
import SwiftUI
import WidgetKit

/// The single widget. ActivityKit owns the surrounding chrome — the island's
/// pill, the Lock Screen card, the blur, and (on iOS 26/27) the Liquid Glass
/// treatment. We supply only the content.
struct GlassLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GlassActivityAttributes.self) { context in
            LockScreenCard(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color(hex: context.attributes.accentHex).opacity(0.18))
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            let accent = Color(hex: context.attributes.accentHex)
            let p = max(0, min(1, context.state.progress))

            return DynamicIsland {
                // Expanded: pill is tapped. All four regions available.
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.symbol)
                        .font(.title3)
                        .foregroundStyle(accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // Gauge needs both closures supplied. `Gauge(value:)` on
                    // its own has no currentValueLabel and renders nothing.
                    Gauge(value: p, in: 0...1) {
                        EmptyView()
                    } currentValueLabel: {
                        Text("\(Int(p * 100))")
                            .font(.caption2.monospacedDigit().bold())
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(accent)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.title)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ProgressView(value: p).tint(accent)
                        HStack {
                            Text(context.state.detail)
                            Spacer()
                            Text(context.state.value).monospacedDigit().bold()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                // Always-visible left slot. Keep to one glyph.
                Image(systemName: context.state.symbol)
                    .foregroundStyle(accent)
            } compactTrailing: {
                // Right slot. This is the scarce real estate — a gauge reads
                // better here than a number at this size.
                Gauge(value: p, in: 0...1) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(accent)
                .frame(width: 20, height: 20)
            } minimal: {
                // The bare dot shown when several activities compete.
                Image(systemName: context.state.symbolAlt)
                    .foregroundStyle(accent)
            }
            .widgetURL(URL(string: "glasshouse://activity"))
            .keylineTint(accent)
        }
    }
}

// MARK: - Lock Screen

/// The card iOS draws on the Lock Screen. Three presets, switched on the
/// attribute. Tapping anywhere opens the app.
private struct LockScreenCard: View {
    let attributes: GlassActivityAttributes
    let state: GlassActivityAttributes.ContentState

    private var accent: Color { Color(hex: attributes.accentHex) }

    /// 0 = tinted, 1 = ultraclear. Interpolates the fill behind the content.
    private var fillOpacity: Double { 0.30 * (1 - attributes.glassLevel) + 0.04 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch attributes.preset {
            case .minimal: minimal
            case .progress: progress
            case .stats: stats
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(fillOpacity))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var minimal: some View {
        HStack(spacing: 10) {
            Image(systemName: state.symbol)
                .font(.headline)
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(state.title).font(.headline).lineLimit(1)
                Text(state.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(state.value).font(.subheadline.bold()).monospacedDigit()
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(state.title, systemImage: state.symbol)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(state.value).font(.subheadline.bold()).monospacedDigit()
            }
            // .linear gives a predictable, fast-reading fill.
            ProgressView(value: max(0, min(1, state.progress)))
                .progressViewStyle(.linear)
                .tint(accent)
            Text(state.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(state.title, systemImage: state.symbol)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(state.value).font(.headline).monospacedDigit()
            }
            HStack(spacing: 8) {
                statTile("NOW", state.detail, symbol: state.symbolAlt)
                statTile("LEVEL", "\(Int(max(0, min(1, state.progress)) * 100))%", symbol: "chart.bar.fill")
            }
        }
    }

    private func statTile(_ label: String, _ value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(label, systemImage: symbol)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(accent.opacity(fillOpacity * 0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
