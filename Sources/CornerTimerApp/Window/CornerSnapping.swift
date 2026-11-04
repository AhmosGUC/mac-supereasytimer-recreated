import CoreGraphics

/// A screen corner the floating panel can park in.
enum PanelCorner: String, CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
}

/// Where the panel lives: parked in a corner, or at a user-chosen free position.
enum PanelPlacement: Equatable {
    case corner(PanelCorner)
    case free(origin: CGPoint)
}

/// Pure geometry for corner snapping. All frames use AppKit coordinates (origin bottom-left,
/// y grows upwards) and `visibleFrame` is the screen area without menu bar and Dock.
enum CornerSnapping {
    static let defaultInset: CGFloat = 16

    /// The corner of `visibleFrame` closest to the center of `panelFrame`.
    static func nearestCorner(for panelFrame: CGRect, in visibleFrame: CGRect) -> PanelCorner {
        let isLeft = panelFrame.midX < visibleFrame.midX
        let isTop = panelFrame.midY >= visibleFrame.midY
        switch (isLeft, isTop) {
        case (true, true): return .topLeft
        case (false, true): return .topRight
        case (true, false): return .bottomLeft
        case (false, false): return .bottomRight
        }
    }

    /// The panel origin that places a panel of `panelSize` in `corner`, `inset` points from the edges.
    static func origin(
        for visibleFrame: CGRect,
        corner: PanelCorner,
        panelSize: CGSize,
        inset: CGFloat = defaultInset
    ) -> CGPoint {
        let left = visibleFrame.minX + inset
        let right = visibleFrame.maxX - inset - panelSize.width
        let bottom = visibleFrame.minY + inset
        let top = visibleFrame.maxY - inset - panelSize.height
        switch corner {
        case .topLeft: return CGPoint(x: left, y: top)
        case .topRight: return CGPoint(x: right, y: top)
        case .bottomLeft: return CGPoint(x: left, y: bottom)
        case .bottomRight: return CGPoint(x: right, y: bottom)
        }
    }

    /// `frame` moved the shortest distance so it lies inside `visibleFrame`.
    /// If the frame is larger than the area, its top-left corner stays visible.
    static func clamped(_ frame: CGRect, in visibleFrame: CGRect) -> CGRect {
        let x = max(visibleFrame.minX, min(frame.minX, visibleFrame.maxX - frame.width))
        let y = min(visibleFrame.maxY - frame.height, max(frame.minY, visibleFrame.minY))
        return CGRect(origin: CGPoint(x: x, y: y), size: frame.size)
    }
}
