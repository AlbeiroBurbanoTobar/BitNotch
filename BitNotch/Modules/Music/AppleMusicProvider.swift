import Foundation

struct AppleMusicProvider: NowPlayingProvider {
    let id = "apple-music"
    let name = "Music"
    let bundleIdentifier = "com.apple.Music"
    let playbackNotification = Notification.Name("com.apple.Music.playerInfo")

    // `current track` fails for some radio streams, which is treated as stopped. The first statement
    // stays outside the `try` so a denied Automation permission still reaches BitNotch as an error.
    private static let nowPlayingScript = """
        tell application id "com.apple.Music"
            set currentState to player state as string
            if currentState is "stopped" then return {currentState}
            try
                set currentTrack to current track
                return {currentState, name of currentTrack, artist of currentTrack, album of currentTrack, ¬
                    duration of currentTrack, player position}
            on error
                return {"stopped"}
            end try
        end tell
        """

    private static let artworkScript = """
        tell application id "com.apple.Music"
            try
                return raw data of artwork 1 of current track
            on error
                return missing value
            end try
        end tell
        """

    func fetchNowPlaying() async throws -> NowPlayingInfo? {
        try await AppleScriptRunner.shared.run(Self.nowPlayingScript) {
            NowPlayingInfo(appleScriptList: $0.listItems)
        }
    }

    func fetchArtwork(for info: NowPlayingInfo) async -> Data? {
        let data = try? await AppleScriptRunner.shared.run(Self.artworkScript) { $0.data }
        return data?.isEmpty == false ? data : nil
    }
}
