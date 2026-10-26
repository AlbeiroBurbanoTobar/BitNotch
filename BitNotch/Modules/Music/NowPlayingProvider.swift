import AppKit

struct NowPlayingInfo: Equatable, Sendable {
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var position: TimeInterval
    var isPlaying: Bool
    var artworkURL: URL?

    /// Identifies the track, so artwork is only reloaded when it changes.
    var trackKey: String { [title, artist, album].joined(separator: "\u{1F}") }
}

extension NowPlayingInfo {
    /// Parses the list the player scripts return:
    /// `{state, name, artist, album, duration in seconds, position in seconds, artwork URL (optional)}`.
    /// A one-item list means the player is stopped.
    init?(appleScriptList items: [NSAppleEventDescriptor]) {
        guard items.count >= 6, let state = items[0].stringValue else { return nil }
        title = items[1].stringValue ?? ""
        artist = items[2].stringValue ?? ""
        album = items[3].stringValue ?? ""
        duration = items[4].doubleValue
        position = items[5].doubleValue
        isPlaying = state == "playing"
        artworkURL = items.count > 6 ? items[6].stringValue.flatMap(URL.init(string:)) : nil
    }
}

enum PlayerCommand: Sendable {
    case playPause
    case nextTrack
    case previousTrack
    case seek(to: TimeInterval)
}

/// A music app BitNotch reads Now Playing information from and sends playback commands to.
protocol NowPlayingProvider: Sendable {
    var id: String { get }
    var name: String { get }
    var bundleIdentifier: String { get }
    /// Distributed notification the app posts when playback or the track changes.
    var playbackNotification: Notification.Name { get }

    /// Current track and playback state, or `nil` when the player is stopped.
    func fetchNowPlaying() async throws -> NowPlayingInfo?
    /// Encoded artwork image for the track, if the app provides one.
    func fetchArtwork(for info: NowPlayingInfo) async -> Data?
}

extension NowPlayingProvider {
    var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }

    /// Spotify and Music share these AppleScript commands.
    func send(_ command: PlayerCommand) async throws {
        let statement = switch command {
        case .playPause: "playpause"
        case .nextTrack: "next track"
        case .previousTrack: "previous track"
        case .seek(let position): "set player position to \(String(format: "%.2f", position))"
        }
        let isOneOff = if case .seek = command { true } else { false }
        try await AppleScriptRunner.shared.run(
            "tell application id \"\(bundleIdentifier)\" to \(statement)",
            cache: !isOneOff
        )
    }
}
