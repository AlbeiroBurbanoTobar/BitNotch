import ServiceManagement
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            ModulesSettingsView()
                .tabItem { Label("Modules", systemImage: "square.grid.2x2") }
        }
        .frame(width: 440, height: 260)
        .onAppear {
            // BitNotch has no Dock icon, so bring the Settings window to the front explicitly.
            NSApp.activate()
        }
    }
}

private struct GeneralSettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            Toggle("Open BitNotch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, isOn in
                    updateLaunchAtLogin(isOn)
                }
            if let launchAtLoginError {
                Text(launchAtLoginError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
    }

    private func updateLaunchAtLogin(_ isOn: Bool) {
        do {
            if isOn {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

private struct ModulesSettingsView: View {
    @Environment(ModuleRegistry.self) private var registry

    var body: some View {
        Form {
            ForEach(registry.allModules, id: \.id) { module in
                Toggle(isOn: Binding(
                    get: { registry.isEnabled(module.id) },
                    set: { registry.setEnabled($0, for: module.id) }
                )) {
                    Label(module.title, systemImage: module.systemImage)
                }
            }
        }
        .formStyle(.grouped)
    }
}
