import SwiftUI

/// Music tab of the open notch.
struct MusicPlayerView: View {
    let controller: MusicController

    var body: some View {
        if let session = controller.session {
            NowPlayingView(controller: controller, session: session)
        } else if let deniedName = controller.deniedProviderName {
            AutomationPermissionView(appName: deniedName)
        } else {
            PlaceholderModuleView(
                systemImage: "music.note",
                title: "Nothing playing",
                message: "Play something in Spotify or Music."
            )
        }
    }
}

private struct NowPlayingView: View {
    let controller: MusicController
    let session: MusicController.Session

    var body: some View {
        HStack(spacing: 18) {
            ArtworkView(image: session.artwork, cornerRadius: 12)
                .frame(width: 128, height: 128)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(session.info.title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(session.providerName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Text(session.info.artist)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)

                Spacer(minLength: 8)

                PlaybackProgressView(controller: controller, duration: session.info.duration)

                PlaybackControlsView(controller: controller, isPlaying: session.info.isPlaying)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct PlaybackProgressView: View {
    let controller: MusicController
    let duration: TimeInterval

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let position = controller.position(at: context.date)
            VStack(spacing: 4) {
                SeekBar(progress: duration > 0 ? position / duration : 0) { fraction in
                    controller.send(.seek(to: fraction * duration))
                }
                .disabled(duration <= 0)

                HStack {
                    Text(Self.format(position))
                    Spacer()
                    Text(Self.format(duration))
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private static func format(_ seconds: TimeInterval) -> String {
        Duration.seconds(max(seconds, 0)).formatted(.time(pattern: .minuteSecond))
    }
}

/// Thin progress bar that seeks to wherever it is clicked or dragged.
private struct SeekBar: View {
    let progress: Double
    let onSeek: (Double) -> Void

    @State private var dragProgress: Double?

    var body: some View {
        GeometryReader { geometry in
            let shown = min(max(dragProgress ?? progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.2))
                Capsule().fill(.white).frame(width: geometry.size.width * shown)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { dragProgress = $0.location.x / geometry.size.width }
                    .onEnded { value in
                        onSeek(min(max(value.location.x / geometry.size.width, 0), 1))
                        dragProgress = nil
                    }
            )
        }
        .frame(height: 4)
        .padding(.vertical, 4)
    }
}

private struct PlaybackControlsView: View {
    let controller: MusicController
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 28) {
            button("backward.fill", size: 16) { controller.send(.previousTrack) }
            button(isPlaying ? "pause.fill" : "play.fill", size: 24) { controller.send(.playPause) }
            button("forward.fill", size: 16) { controller.send(.nextTrack) }
        }
    }

    private func button(_ systemImage: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct AutomationPermissionView: View {
    let appName: String

    private static let automationSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
    )!

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 24))
            Text("BitNotch needs permission to control \(appName).")
                .font(.headline)
            Text("Turn on \(appName) for BitNotch in Privacy & Security › Automation.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.6))
            Button("Open Automation Settings") {
                NSWorkspace.shared.open(Self.automationSettingsURL)
            }
        }
        .multilineTextAlignment(.center)
    }
}
