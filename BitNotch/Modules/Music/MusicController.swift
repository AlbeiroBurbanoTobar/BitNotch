import AppKit
import Observation

/// Tracks what Spotify or Music is playing and forwards playback commands to that app.
@MainActor
@Observable
final class MusicController {
    struct Session {
        let providerID: String
        let providerName: String
        var info: NowPlayingInfo
        var artwork: NSImage?
        /// When `info.position` was read; the position advances from here while playing.
        var updatedAt: Date
    }

    /// Players post notifications on track and state changes; this re-sync catches seeks and missed events.
    private static let resyncInterval: Duration = .seconds(3)

    private(set) var session: Session?
    /// Name of a running player that refused BitNotch Automation access, if any.
    private(set) var deniedProviderName: String?

    @ObservationIgnored private let providers: [any NowPlayingProvider] = [SpotifyProvider(), AppleMusicProvider()]
    /// The player that most recently reported a change wins when several are playing.
    @ObservationIgnored private var preferredProviderID: String?
    @ObservationIgnored private var isRefreshing = false
    @ObservationIgnored private var needsAnotherRefresh = false
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var resyncTask: Task<Void, Never>?

    init() {
        observePlayers()
        resyncTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: Self.resyncInterval)
            }
        }
    }

    var isPlaying: Bool { session?.info.isPlaying ?? false }

    /// Playback position at `date`, advanced from the last reading while playing.
    func position(at date: Date) -> TimeInterval {
        guard let session else { return 0 }
        let elapsed = session.info.isPlaying ? date.timeIntervalSince(session.updatedAt) : 0
        let position = session.info.position + elapsed
        return session.info.duration > 0 ? min(position, session.info.duration) : position
    }

    func send(_ command: PlayerCommand) {
        guard let current = session,
              let provider = providers.first(where: { $0.id == current.providerID }) else { return }

        // Update the UI right away; the refresh below confirms the player's real state.
        switch command {
        case .playPause:
            // Read the position before writing: `position(at:)` reads `session`, which would overlap
            // the write access and trip Swift's exclusivity check.
            let currentPosition = position(at: .now)
            session?.info.position = currentPosition
            session?.info.isPlaying.toggle()
            session?.updatedAt = .now
        case .seek(let position):
            session?.info.position = position
            session?.updatedAt = .now
        case .nextTrack, .previousTrack:
            break
        }

        Task {
            try? await provider.send(command)
            await refresh()
        }
    }

    func refresh() async {
        // Coalesce overlapping requests into one more pass after the current one.
        guard !isRefreshing else {
            needsAnotherRefresh = true
            return
        }
        isRefreshing = true
        repeat {
            needsAnotherRefresh = false
            await refreshOnce()
        } while needsAnotherRefresh
        isRefreshing = false
    }

    // MARK: - Private

    private func refreshOnce() async {
        var candidates: [(provider: any NowPlayingProvider, info: NowPlayingInfo)] = []
        var deniedName: String?

        // Only query running players: sending an Apple Event to a closed app would launch it.
        for provider in providers where provider.isRunning {
            do {
                if let info = try await provider.fetchNowPlaying() {
                    candidates.append((provider, info))
                }
            } catch let error as AppleScriptError where error.isNotPermitted {
                deniedName = provider.name
            } catch {
                // The player is quitting or busy; the next refresh tries again.
            }
        }

        deniedProviderName = deniedName
        let best = candidates.max { rank($0.provider, $0.info) < rank($1.provider, $1.info) }
        apply(best?.info, from: best?.provider)
    }

    private func rank(_ provider: any NowPlayingProvider, _ info: NowPlayingInfo) -> Int {
        (info.isPlaying ? 2 : 0) + (provider.id == preferredProviderID ? 1 : 0)
    }

    private func apply(_ info: NowPlayingInfo?, from provider: (any NowPlayingProvider)?) {
        guard let info, let provider else {
            session = nil
            return
        }
        let isSameTrack = session?.providerID == provider.id && session?.info.trackKey == info.trackKey
        session = Session(
            providerID: provider.id,
            providerName: provider.name,
            info: info,
            artwork: isSameTrack ? session?.artwork : nil,
            updatedAt: .now
        )
        if !isSameTrack {
            loadArtwork(for: info, from: provider)
        }
    }

    private func loadArtwork(for info: NowPlayingInfo, from provider: any NowPlayingProvider) {
        Task {
            guard let data = await provider.fetchArtwork(for: info),
                  let image = NSImage(data: data) else { return }
            // The track may have changed while the artwork was loading.
            guard session?.providerID == provider.id, session?.info.trackKey == info.trackKey else { return }
            session?.artwork = image
        }
    }

    private func observePlayers() {
        let distributedCenter = DistributedNotificationCenter.default()
        for provider in providers {
            let providerID = provider.id
            observers.append(distributedCenter.addObserver(
                forName: provider.playbackNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.preferredProviderID = providerID
                    self?.scheduleRefresh()
                }
            })
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
            observers.append(workspaceCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.scheduleRefresh() }
            })
        }
    }

    private func scheduleRefresh() {
        Task { await refresh() }
    }
}
