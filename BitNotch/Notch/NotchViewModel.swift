import SwiftUI

enum NotchState {
    case closed
    case open
}

@MainActor
@Observable
final class NotchViewModel {
    static let openSize = CGSize(width: 580, height: 230)

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
        case .closed: geometry.notchSize
        case .open: Self.openSize
        }
    }

    var selectedModule: (any NotchModule)? {
        let modules = registry.enabledModules
        return modules.first { $0.id == selectedModuleID } ?? modules.first
    }
}
