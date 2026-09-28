import Foundation

/// A media player NotchMate can read and control through Apple Events.
public enum MediaPlayer: String, CaseIterable, Sendable {
    case music = "com.apple.Music"
    case spotify = "com.spotify.client"

    public var bundleIdentifier: String { rawValue }

    /// The application name used in AppleScript `tell application` blocks.
    public var scriptName: String {
        switch self {
        case .music: return "Music"
        case .spotify: return "Spotify"
        }
    }

    public var displayName: String { scriptName }

    /// Script returning `state<US>title<US>artist` (US = unit separator, U+001F).
    public var statusScript: String {
        """
        tell application "\(scriptName)"
            if player state is stopped then return "stopped"
            set s to (player state as text)
            return s & (ASCII character 31) & (name of current track) & (ASCII character 31) & (artist of current track)
        end tell
        """
    }

    public func commandScript(_ command: MediaCommand) -> String {
        "tell application \"\(scriptName)\" to \(command.appleScriptVerb)"
    }
}

public enum MediaCommand: Sendable {
    case playPause
    case nextTrack
    case previousTrack

    var appleScriptVerb: String {
        switch self {
        case .playPause: return "playpause"
        case .nextTrack: return "next track"
        case .previousTrack: return "previous track"
        }
    }
}

public struct NowPlayingInfo: Equatable, Sendable {
    public var player: MediaPlayer
    public var title: String
    public var artist: String
    public var isPlaying: Bool

    public init(player: MediaPlayer, title: String, artist: String, isPlaying: Bool) {
        self.player = player
        self.title = title
        self.artist = artist
        self.isPlaying = isPlaying
    }

    /// Parses the output of `MediaPlayer.statusScript`. Returns `nil` when stopped or malformed.
    public static func parse(_ output: String, player: MediaPlayer) -> NowPlayingInfo? {
        let parts = output.split(separator: "\u{1F}", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 3 else { return nil }
        let state = parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard state == "playing" || state == "paused" else { return nil }
        let title = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        let artist = parts[2...].joined(separator: "\u{1F}").trimmingCharacters(in: .whitespacesAndNewlines)
        return NowPlayingInfo(player: player, title: title, artist: artist, isPlaying: state == "playing")
    }

    /// Picks what to show when several players report a track: a playing one wins over paused ones.
    public static func preferred(_ candidates: [NowPlayingInfo]) -> NowPlayingInfo? {
        candidates.first(where: \.isPlaying) ?? candidates.first
    }
}
