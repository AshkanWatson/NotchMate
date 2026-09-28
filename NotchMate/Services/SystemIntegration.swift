import AppKit
import ServiceManagement

/// Registers NotchMate as a login item using the modern Service Management API.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

enum Haptics {
    /// A subtle trackpad tick, like the one macOS uses when snapping windows.
    @MainActor
    static func tick() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
}
