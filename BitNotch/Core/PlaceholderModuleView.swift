import SwiftUI

/// Stand-in content for modules whose features land in a later phase.
struct PlaceholderModuleView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .medium))
            Text(title)
                .font(.headline)
            Text(message)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
