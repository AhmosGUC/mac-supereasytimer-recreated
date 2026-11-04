import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: FloatingPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let controller = FloatingPanelController()
        controller.start()
        panelController = controller
        print("\(AppConstants.appName) started")
    }
}
