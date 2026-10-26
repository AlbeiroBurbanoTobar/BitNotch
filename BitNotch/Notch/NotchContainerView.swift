import SwiftUI

/// Root view of the notch panel: the black notch body, which grows into the open layout.
struct NotchContainerView: View {
    @Environment(NotchViewModel.self) private var model

    private var isOpen: Bool { model.state == .open }
    private var topRadius: CGFloat { isOpen ? 14 : 6 }
    private var bottomRadius: CGFloat { isOpen ? 28 : 12 }

    var body: some View {
        let size = model.currentSize

        ZStack(alignment: .top) {
            NotchShape(topRadius: topRadius, bottomRadius: bottomRadius)
                .fill(.black)
                .frame(width: size.width + topRadius * 2, height: size.height)
                .shadow(color: .black.opacity(isOpen ? 0.45 : 0), radius: 12, y: 6)

            if isOpen {
                NotchOpenView()
                    .frame(width: size.width, height: size.height)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            } else if let module = model.compactModule {
                NotchCompactView(module: module)
                    .frame(width: size.width, height: size.height)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: model.state)
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: model.compactModule?.id)
        .animation(.default, value: model.geometry)
        .preferredColorScheme(.dark)
    }
}

/// Open layout: module tabs in the strip beside the camera, the selected module below.
struct NotchOpenView: View {
    @Environment(NotchViewModel.self) private var model

    var body: some View {
        let modules = model.registry.enabledModules

        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(modules, id: \.id) { module in
                    ModuleTabButton(
                        module: module,
                        isSelected: module.id == model.selectedModule?.id
                    ) {
                        model.selectedModuleID = module.id
                    }
                }
                Spacer(minLength: model.geometry.notchSize.width)
            }
            .padding(.horizontal, 18)
            .frame(height: model.geometry.notchSize.height)

            Group {
                if let module = model.selectedModule {
                    module.makeView()
                } else {
                    ContentUnavailableView(
                        "No modules enabled",
                        systemImage: "square.dashed",
                        description: Text("Turn modules on in Settings.")
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 22)
            .padding(.bottom, 16)
        }
        .foregroundStyle(.white)
    }
}

/// Closed layout while a module has activity: its compact content on both sides of the camera.
struct NotchCompactView: View {
    @Environment(NotchViewModel.self) private var model
    let module: any NotchModule

    var body: some View {
        let side = NotchViewModel.compactSideWidth
        let height = model.geometry.notchSize.height
        HStack(spacing: 0) {
            module.makeCompactLeading()
                .frame(width: height - 12, height: height - 12)
                .frame(width: side)
            Spacer(minLength: model.geometry.notchSize.width)
            module.makeCompactTrailing()
                .frame(width: side)
        }
    }
}

private struct ModuleTabButton: View {
    let module: any NotchModule
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: module.systemImage)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 22)
                .background(isSelected ? .white.opacity(0.18) : .clear, in: .capsule)
                .opacity(isSelected ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .help(module.title)
    }
}
