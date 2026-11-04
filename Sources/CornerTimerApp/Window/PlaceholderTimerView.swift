import SwiftUI

/// Stand-in content until the real timer view lands (#8).
struct PlaceholderTimerView: View {
    let size: PanelSize

    var body: some View {
        Text("25:00")
            .font(.system(size: size.dimensions.height * 0.5, weight: .medium, design: .monospaced))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial)
    }
}
