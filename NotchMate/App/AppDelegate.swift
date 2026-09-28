import AppKit
import NotchMateKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let options: LaunchOptions
    let settingsModel: SettingsModel
    let controller: NotchController
    private let settingsWindow = SettingsWindowController()

    override init() {
        options = LaunchOptions(processInfo: .processInfo)
        settingsModel = SettingsModel(store: UserDefaults.standard)
        if options.resetSettings {
            settingsModel.resetToDefaults()
        }
        controller = NotchController(settingsModel: settingsModel, options: options)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Unit tests are hosted inside the app; don't put a panel over the notch while they run.
        guard !options.isHostingUnitTests else { return }

        NSApp.setActivationPolicy(.accessory)
        controller.openSettings = { [weak self] in self?.showSettings() }
        controller.start()

        if options.openSettingsOnLaunch {
            showSettings()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.stop()
    }

    func showSettings() {
        settingsWindow.show(settingsModel: settingsModel, controller: controller)
    }
}
