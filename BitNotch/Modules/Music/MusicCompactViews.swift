import SwiftUI

/// Album artwork, or a music note on a dark tile while it loads or when there is none.
struct ArtworkView: View {
    let image: NSImage?
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.white.opacity(0.12))
            .overlay {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "music.note")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Small animated bars shown beside the closed notch while music plays. Decorative only:
/// the heights do not follow the audio.
struct PlaybackBarsView: View {
    let isPlaying: Bool

    private static let phases: [Double] = [0, 1.7, 0.9, 2.4]
    private static let speeds: [Double] = [7.1, 5.3, 8.4, 6.2]

    var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 2) {
                ForEach(Self.phases.indices, id: \.self) { index in
                    let wave = abs(sin(time * Self.speeds[index] + Self.phases[index]))
                    Capsule()
                        .fill(.white)
                        .frame(width: 3, height: isPlaying ? 4 + 10 * wave : 3)
                }
            }
            .frame(height: 14)
        }
    }
}
