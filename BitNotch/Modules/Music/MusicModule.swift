import SwiftUI

struct MusicModule: NotchModule {
    let id = "music"
    let title = "Music"
    let systemImage = "music.note"

    func makeView() -> AnyView {
        AnyView(PlaceholderModuleView(
            systemImage: systemImage,
            title: title,
            message: "Now Playing and playback controls arrive in phase 2."
        ))
    }
}
