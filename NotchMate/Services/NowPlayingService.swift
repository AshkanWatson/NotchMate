import AppKit
import NotchMateKit

/// Reads and controls Music and Spotify through Apple Events.
///
/// It only polls while the panel is expanded, and never launches a player: apps
/// that are not already running are skipped. The first request triggers macOS's
/// Automation permission prompt for that player.
@MainActor
final class NowPlayingService: ObservableObject {
    @Published private(set) var info: NowPlayingInfo?

    /// Disabled in UI tests so no permission prompt can block the test run.
    var isEnabled = true

    private var timer: Timer?
    private let queue = DispatchQueue(label: "NotchMate.NowPlaying", qos: .userInitiated)

    func setActive(_ active: Bool) {
        timer?.invalidate()
        timer = nil
        guard active, isEnabled else { return }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    func refresh() {
        guard isEnabled else { return }
        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        let players = MediaPlayer.allCases.filter { running.contains($0.bundleIdentifier) }
        guard !players.isEmpty else {
            info = nil
            return
        }
        queue.async { [weak self] in
            let results = players.compactMap { player -> NowPlayingInfo? in
                guard let output = Self.run(player.statusScript) else { return nil }
                return NowPlayingInfo.parse(output, player: player)
            }
            let preferred = NowPlayingInfo.preferred(results)
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self?.info = preferred }
            }
        }
    }

    func send(_ command: MediaCommand) {
        guard isEnabled, let player = info?.player else { return }
        queue.async { [weak self] in
            _ = Self.run(player.commandScript(command))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
    }

    private nonisolated static func run(_ source: String) -> String? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        guard error == nil else { return nil }
        return result?.stringValue
    }
}
