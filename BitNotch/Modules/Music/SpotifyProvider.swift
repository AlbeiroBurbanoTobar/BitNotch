import Foundation

struct SpotifyProvider: NowPlayingProvider {
    let id = "spotify"
    let name = "Spotify"
    let bundleIdentifier = "com.spotify.client"
    let playbackNotification = Notification.Name("com.spotify.client.PlaybackStateChanged")

    // Spotify reports duration in milliseconds and position in seconds.
    private static let nowPlayingScript = """
        tell application id "com.spotify.client"
            set currentState to player state as string
            if currentState is "stopped" then return {currentState}
            set currentTrack to current track
            return {currentState, name of currentTrack, artist of currentTrack, album of currentTrack, ¬
                (duration of currentTrack) / 1000, player position, artwork url of currentTrack}
        end tell
        """

    func fetchNowPlaying() async throws -> NowPlayingInfo? {
        try await AppleScriptRunner.shared.run(Self.nowPlayingScript) {
            NowPlayingInfo(appleScriptList: $0.listItems)
        }
    }

    func fetchArtwork(for info: NowPlayingInfo) async -> Data? {
        guard let url = info.artworkURL else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }
}
