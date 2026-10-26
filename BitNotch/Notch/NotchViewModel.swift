import SwiftUI

enum NotchState {
    case closed
    case open
}

@MainActor
@Observable
final class NotchViewModel {
    static let openSize = CGSize(width: 580, height: 230)
    /// Width added on each side of the closed notch while a module shows compact activity.
    static let compactSideWidth: CGFloat = 44

    let registry: ModuleRegistry
    var state: NotchState = .closed
    var geometry: NotchGeometry
    var selectedModuleID: String?

    init(registry: ModuleRegistry, geometry: NotchGeometry) {
        self.registry = registry
        self.geometry = geometry
    }

    /// Size of the black notch body for the current state.
    var currentSize: CGSize {
        switch state {
        case .closed:
            let extraWidth = compactModule == nil ? 0 : Self.compactSideWidth * 2
            return CGSize(width: geometry.notchSize.width + extraWidth, height: geometry.notchSize.height)
        case .open:
            return Self.openSize
        }
    }

    /// The first enabled module with something to show beside the closed notch.
    var compactModule: (any NotchModule)? {
        registry.enabledModules.first { $0.hasCompactActivity }
    }

    var selectedModule: (any NotchModule)? {
        let modules = registry.enabledModules
        return modules.first { $0.id == selectedModuleID } ?? modules.first
    }
}
