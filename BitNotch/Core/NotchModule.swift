import SwiftUI

/// A feature that shows up as a tab inside the open notch (music, clipboard, shelf, ...).
@MainActor
protocol NotchModule {
    /// Stable identifier, also used to persist whether the module is enabled.
    var id: String { get }
    var title: String { get }
    var systemImage: String { get }

    func makeView() -> AnyView
}

/// Every available module, and which ones the user has turned on.
@MainActor
@Observable
final class ModuleRegistry {
    private static let disabledModulesKey = "disabledModuleIDs"

    let allModules: [any NotchModule] = [
        MusicModule(),
        ShelfModule(),
    ]

    private(set) var disabledIDs: Set<String>

    init() {
        disabledIDs = Set(UserDefaults.standard.stringArray(forKey: Self.disabledModulesKey) ?? [])
    }

    var enabledModules: [any NotchModule] {
        allModules.filter { !disabledIDs.contains($0.id) }
    }

    func isEnabled(_ id: String) -> Bool {
        !disabledIDs.contains(id)
    }

    func setEnabled(_ isEnabled: Bool, for id: String) {
        if isEnabled {
            disabledIDs.remove(id)
        } else {
            disabledIDs.insert(id)
        }
        UserDefaults.standard.set(Array(disabledIDs).sorted(), forKey: Self.disabledModulesKey)
    }
}
