import SwiftUI

struct ShelfModule: NotchModule {
    let id = "shelf"
    let title = "Shelf"
    let systemImage = "tray"

    func makeView() -> AnyView {
        AnyView(PlaceholderModuleView(
            systemImage: systemImage,
            title: title,
            message: "Drop files here and share them with AirDrop in phase 4."
        ))
    }
}
