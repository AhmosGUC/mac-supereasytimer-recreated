import AppKit
import SwiftUI

/// Owns the floating panel: size, corner snapping, position persistence, visibility and opacity.
@MainActor
final class FloatingPanelController: NSObject, NSWindowDelegate {
    private enum Key {
        static let corner = "panel.corner"
        static let originX = "panel.originX"
        static let originY = "panel.originY"
        static let screenName = "panel.screenName"
        static let screenFrame = "panel.screenFrame"
        static let hidden = "panel.hidden"
    }

    private static let cornerRadius: CGFloat = 14
    private static let snapDuration: TimeInterval = 0.18
    private static let settleDelay: Duration = .milliseconds(120)

    private let defaults: UserDefaults
    private let panel: FloatingTimerPanel
    private let hostingView: NSHostingView<PlaceholderTimerView>
    private var placement: PanelPlacement = .corner(.topRight)
    private var screenName: String?
    private var screenFrame: CGRect?
    private var isPlacing = false
    private var isHovering = false
    private var settleTask: Task<Void, Never>?

    /// Called with the new state whenever the panel is shown or hidden.
    var onVisibilityChange: ((Bool) -> Void)?
    /// Called by `focusInput()` after the panel is key; the timer view (#8) focuses its text field here.
    var onFocusInput: (() -> Void)?

    var size: PanelSize {
        didSet {
            guard size != oldValue else { return }
            hostingView.rootView = PlaceholderTimerView(size: size)
            place(animated: false)
        }
    }

    /// Resting opacity, 0.4...1.0. The panel is fully opaque while the pointer hovers it.
    var opacity: Double = 1 {
        didSet {
            opacity = min(max(opacity, 0.4), 1)
            applyOpacity()
        }
    }

    var isVisible: Bool { panel.isVisible }

    init(size: PanelSize = .medium, defaults: UserDefaults = .standard) {
        self.size = size
        self.defaults = defaults
        panel = FloatingTimerPanel(size: size.dimensions)
        hostingView = NSHostingView(rootView: PlaceholderTimerView(size: size))
        super.init()

        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = Self.cornerRadius
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true
        panel.contentView = hostingView
        panel.delegate = self
        hostingView.addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    /// Restores the saved placement and shows the panel unless it was hidden last time.
    func start() {
        loadPlacement()
        place(animated: false)
        if !defaults.bool(forKey: Key.hidden) { show() }
    }

    // MARK: Visibility

    func show() {
        setVisible(true)
    }

    func hide() {
        setVisible(false)
    }

    func toggleVisibility() {
        setVisible(!isVisible)
    }

    /// Shows the panel and makes it key so typing goes to the timer, without activating the app.
    func focusInput() {
        show()
        panel.makeKey()
        onFocusInput?()
    }

    /// Hands keyboard focus back after the text field finishes editing (Return/Escape).
    func endInput() {
        panel.makeFirstResponder(nil)
        panel.resignKey()
    }

    private func setVisible(_ visible: Bool) {
        let changed = visible != isVisible
        if visible {
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
        defaults.set(!visible, forKey: Key.hidden)
        if changed { onVisibilityChange?(visible) }
    }

    // MARK: Opacity

    private func applyOpacity() {
        panel.alphaValue = isHovering ? 1 : opacity
    }

    @objc func mouseEntered(with event: NSEvent) {
        isHovering = true
        applyOpacity()
    }

    @objc func mouseExited(with event: NSEvent) {
        isHovering = false
        applyOpacity()
    }

    // MARK: Placement

    /// Moves the panel to where `placement` says, on the saved screen if connected, else the main screen.
    private func place(animated: Bool) {
        guard let screen = savedScreen() ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let panelSize = size.dimensions
        let target: CGRect
        switch placement {
        case .corner(let corner):
            let origin = CornerSnapping.origin(for: visible, corner: corner, panelSize: panelSize)
            target = CGRect(origin: origin, size: panelSize)
        case .free(let origin):
            target = CornerSnapping.clamped(CGRect(origin: origin, size: panelSize), in: visible)
        }
        setFrame(target, animated: animated)
    }

    private func setFrame(_ frame: CGRect, animated: Bool) {
        isPlacing = true
        guard animated else {
            panel.setFrame(frame, display: true)
            isPlacing = false
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.snapDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(frame, display: true)
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated { self?.isPlacing = false }
        }
    }

    private func savedScreen() -> NSScreen? {
        NSScreen.screens.first { $0.localizedName == screenName }
    }

    @objc private func screenParametersChanged() {
        place(animated: false)
    }

    // MARK: Dragging

    func windowDidMove(_ notification: Notification) {
        guard !isPlacing else { return }
        scheduleSettle()
    }

    private func scheduleSettle() {
        settleTask?.cancel()
        settleTask = Task { [weak self] in
            try? await Task.sleep(for: Self.settleDelay)
            guard !Task.isCancelled else { return }
            self?.settleAfterDrag()
        }
    }

    /// Runs once the panel stopped moving: waits for mouse-up, then snaps (or stays free with ⌥).
    private func settleAfterDrag() {
        if NSEvent.pressedMouseButtons & 1 != 0 {
            scheduleSettle()
            return
        }
        let frame = panel.frame
        let center = CGPoint(x: frame.midX, y: frame.midY)
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(center) }) ?? NSScreen.main else { return }
        screenName = screen.localizedName
        screenFrame = screen.frame
        if NSEvent.modifierFlags.contains(.option) {
            placement = .free(origin: frame.origin)
        } else {
            placement = .corner(CornerSnapping.nearestCorner(for: frame, in: screen.visibleFrame))
        }
        place(animated: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        savePlacement()
    }

    // MARK: Persistence

    private func savePlacement() {
        switch placement {
        case .corner(let corner):
            defaults.set(corner.rawValue, forKey: Key.corner)
            defaults.removeObject(forKey: Key.originX)
            defaults.removeObject(forKey: Key.originY)
        case .free(let origin):
            defaults.removeObject(forKey: Key.corner)
            defaults.set(origin.x, forKey: Key.originX)
            defaults.set(origin.y, forKey: Key.originY)
        }
        defaults.set(screenName, forKey: Key.screenName)
        defaults.set(screenFrame.map(NSStringFromRect), forKey: Key.screenFrame)
    }

    private func loadPlacement() {
        screenName = defaults.string(forKey: Key.screenName)
        screenFrame = defaults.string(forKey: Key.screenFrame).map(NSRectFromString)
        if let raw = defaults.string(forKey: Key.corner), let corner = PanelCorner(rawValue: raw) {
            placement = .corner(corner)
        } else if let x = defaults.object(forKey: Key.originX) as? Double,
                  let y = defaults.object(forKey: Key.originY) as? Double {
            placement = .free(origin: relocatedOrigin(CGPoint(x: x, y: y)))
        } else {
            placement = .corner(.topRight)
        }
    }

    /// A saved free origin, shifted by however far the saved screen has moved since.
    private func relocatedOrigin(_ origin: CGPoint) -> CGPoint {
        guard let saved = screenFrame, let current = savedScreen()?.frame else { return origin }
        return CGPoint(x: origin.x + current.minX - saved.minX, y: origin.y + current.minY - saved.minY)
    }
}
