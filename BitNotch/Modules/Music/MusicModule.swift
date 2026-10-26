import SwiftUI

struct MusicModule: NotchModule {
    let controller: MusicController

    let id = "music"
    let title = "Music"
    let systemImage = "music.note"

    func makeView() -> AnyView {
        AnyView(MusicPlayerView(controller: controller))
    }

    var hasCompactActivity: Bool { controller.isPlaying }

    func makeCompactLeading() -> AnyView {
        AnyView(ArtworkView(image: controller.session?.artwork, cornerRadius: 6))
    }

    func makeCompactTrailing() -> AnyView {
        AnyView(PlaybackBarsView(isPlaying: controller.isPlaying))
    }
}
