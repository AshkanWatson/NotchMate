import SwiftUI
import NotchMateKit

/// The content shown when the notch is expanded.
///
/// The top row is exactly as tall as the notch and flanks it, like extra menu bar
/// space; widgets live below it.
struct ExpandedContentView: View {
    let notchSize: CGSize
    let sideInset: CGFloat
    let settings: NotchSettings
    let battery: BatteryInfo?
    @ObservedObject var nowPlaying: NowPlayingService
    let openSettings: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                DateLabel()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: notchSize.width)
                HStack(spacing: 10) {
                    if settings.showBattery, let battery {
                        BatteryLabel(info: battery)
                    }
                    Button(action: openSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("NotchMate Settings")
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("notch.settingsButton")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: notchSize.height)

            HStack(spacing: 12) {
                if settings.showClock {
                    ClockWidget()
                }
                if settings.showNowPlaying {
                    NowPlayingWidget(service: nowPlaying)
                }
                if !settings.showClock && !settings.showNowPlaying {
                    Text("All widgets are turned off in Settings.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.top, 6)
            .padding(.bottom, 14)
        }
        .padding(.horizontal, sideInset + 14)
        .foregroundStyle(.primary)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("notch.content")
    }
}

private struct DateLabel: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            Text(context.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityIdentifier("notch.date")
    }
}

private struct BatteryLabel: View {
    let info: BatteryInfo

    var body: some View {
        HStack(spacing: 4) {
            Text(verbatim: "\(info.percentage)%")
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
            Image(systemName: info.symbolName)
                .font(.system(size: 14))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(info.isLow ? Color.red : info.isCharging ? Color.green : Color.primary)
        }
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Battery \(info.percentage) percent\(info.isCharging ? ", charging" : "")")
        .accessibilityIdentifier("notch.battery")
    }
}

/// A rounded tile used by all widgets.
struct WidgetTile<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(12)
            .frame(maxHeight: .infinity)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
