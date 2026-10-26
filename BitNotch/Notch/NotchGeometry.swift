import AppKit

/// Size of the physical notch, or of a stand-in drawn under the menu bar on screens without one.
struct NotchGeometry: Equatable {
    static let fallbackWidth: CGFloat = 200
    static let minimumHeight: CGFloat = 24

    var notchSize: CGSize
    var hasNotch: Bool

    init(screen: NSScreen) {
        if screen.safeAreaInsets.top > 0,
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            notchSize = CGSize(
                width: screen.frame.width - left.width - right.width,
                height: screen.safeAreaInsets.top
            )
            hasNotch = true
        } else {
            let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
            notchSize = CGSize(width: Self.fallbackWidth, height: max(menuBarHeight, Self.minimumHeight))
            hasNotch = false
        }
    }
}

extension NSScreen {
    /// The built-in notched display when present, otherwise the screen that holds the menu bar.
    static var notchScreen: NSScreen? {
        screens.first { $0.safeAreaInsets.top > 0 } ?? screens.first
    }
}
