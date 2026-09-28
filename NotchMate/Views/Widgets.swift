import SwiftUI
import NotchMateKit

struct ClockWidget: View {
    var body: some View {
        WidgetTile {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.date, format: .dateTime.hour().minute())
                        .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(context.date, format: .dateTime.weekday(.wide))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("notch.clock")
    }
}

struct NowPlayingWidget: View {
    @ObservedObject var service: NowPlayingService

    var body: some View {
        WidgetTile {
            HStack(spacing: 12) {
                artwork
                VStack(alignment: .leading, spacing: 3) {
                    Text(service.info?.title ?? "Nothing playing")
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if service.info != nil {
                    controls
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("notch.nowPlaying")
    }

    private var subtitle: String {
        guard let info = service.info else { return "Play something in Music or Spotify" }
        return info.artist.isEmpty ? info.player.displayName : info.artist
    }

    private var artwork: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(LinearGradient(
                colors: [Color(red: 0.98, green: 0.36, blue: 0.45), Color(red: 0.55, green: 0.36, blue: 0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 44, height: 44)
            .overlay {
                if service.info?.isPlaying == true {
                    EqualizerBars()
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
    }

    private var controls: some View {
        HStack(spacing: 14) {
            MediaButton(symbol: "backward.fill", label: "Previous track") { service.send(.previousTrack) }
            MediaButton(symbol: service.info?.isPlaying == true ? "pause.fill" : "play.fill", label: "Play or pause") {
                service.send(.playPause)
            }
            MediaButton(symbol: "forward.fill", label: "Next track") { service.send(.nextTrack) }
        }
    }
}

private struct MediaButton: View {
    let symbol: String
    let label: String
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Three bouncing bars shown while music plays; they only animate while visible.
private struct EqualizerBars: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<3) { index in
                    let phase = time * (4 + Double(index)) + Double(index) * 1.7
                    Capsule()
                        .fill(.white)
                        .frame(width: 4, height: 6 + 12 * CGFloat((sin(phase) + 1) / 2))
                }
            }
            .frame(height: 18, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}
