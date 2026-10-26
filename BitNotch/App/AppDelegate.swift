import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let music = MusicController()
    lazy var registry = ModuleRegistry(modules: [
        MusicModule(controller: music),
        ShelfModule(),
    ])
    private var notchController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.notchScreen else { return }
        let viewModel = NotchViewModel(registry: registry, geometry: NotchGeometry(screen: screen))
        notchController = NotchWindowController(viewModel: viewModel)
    }
}
