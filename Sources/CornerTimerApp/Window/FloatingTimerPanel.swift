import AppKit

/// Borderless panel that floats above other windows without activating the app.
final class FloatingTimerPanel: NSPanel {
    init(size: CGSize) {
        super.init(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        // `.floating` is the starting point; the owner must verify it stays above a full-screen
        // slideshow (#17). If it does not, switch to `.statusBar` and document why here.
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        hasShadow = true
        backgroundColor = .clear
        isOpaque = false
        isMovableByWindowBackground = true
    }

    /// Key so the text field can receive typing; the non-activating style keeps the app inactive.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    #if DEBUG
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "none"
            print("panel click: frontmost app is \(front)")
        }
        super.sendEvent(event)
    }
    #endif
}
