import CoreGraphics

/// The three panel sizes offered in Settings.
enum PanelSize: String, CaseIterable {
    case small, medium, large

    var dimensions: CGSize {
        switch self {
        case .small: CGSize(width: 180, height: 56)
        case .medium: CGSize(width: 240, height: 76)
        case .large: CGSize(width: 340, height: 108)
        }
    }
}
