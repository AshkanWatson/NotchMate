import AppKit
import SwiftUI

/// Hosts `SettingsView` in a regular window. A custom window (instead of a SwiftUI
/// `Settings` scene) opens reliably from a menu bar–only app on every macOS version.
@MainActor
final class SettingsWindowController {
    private var window: NSWindow?

    func show(settingsModel: SettingsModel, controller: NotchController) {
        let window = self.window ?? makeWindow(settingsModel: settingsModel, controller: controller)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow(settingsModel: SettingsModel, controller: NotchController) -> NSWindow {
        let hosting = NSHostingController(rootView: SettingsView(settingsModel: settingsModel, controller: controller))
        let window = NSWindow(contentViewController: hosting)
        window.title = "NotchMate Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 480, height: 640))
        window.center()
        window.setFrameAutosaveName("NotchMateSettings")
        window.identifier = NSUserInterfaceItemIdentifier("settings.window")
        window.setAccessibilityIdentifier("settings.window")
        return window
    }
}
