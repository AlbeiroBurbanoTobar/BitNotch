import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let registry = ModuleRegistry()
    private var notchController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.notchScreen else { return }
        let viewModel = NotchViewModel(registry: registry, geometry: NotchGeometry(screen: screen))
        notchController = NotchWindowController(viewModel: viewModel)
    }
}
