import Foundation

/// Command-line switches, mainly for UI tests and screenshots.
///
/// | Argument                  | Effect                                                           |
/// |---------------------------|------------------------------------------------------------------|
/// | `--ui-testing`            | Disables haptics and Apple Events (no permission prompts).       |
/// | `--reset-settings`        | Starts from default settings.                                    |
/// | `--simulate-notch WxH`    | Pretends the menu bar display has a notch of W×H points.         |
/// | `--simulate-no-notch`     | Pretends no display has a notch.                                 |
/// | `--start-expanded`        | Opens the panel right after launch.                              |
/// | `--open-settings`         | Opens the Settings window right after launch.                    |
///
/// Individual settings can also be overridden with `-<settingKey> <value>`, e.g. `-expandOnHover NO`.
struct LaunchOptions: Equatable {
    var isUITesting = false
    var isHostingUnitTests = false
    var resetSettings = false
    var simulatedNotchSize: CGSize?
    var simulateNoNotch = false
    var startExpanded = false
    var openSettingsOnLaunch = false

    init(arguments: [String] = [], environment: [String: String] = [:]) {
        isUITesting = arguments.contains("--ui-testing")
        isHostingUnitTests = environment["XCTestConfigurationFilePath"] != nil && !isUITesting
        resetSettings = arguments.contains("--reset-settings")
        simulateNoNotch = arguments.contains("--simulate-no-notch")
        startExpanded = arguments.contains("--start-expanded")
        openSettingsOnLaunch = arguments.contains("--open-settings")
        if let index = arguments.firstIndex(of: "--simulate-notch"), arguments.indices.contains(index + 1) {
            simulatedNotchSize = Self.parseSize(arguments[index + 1])
        }
    }

    init(processInfo: ProcessInfo) {
        self.init(arguments: processInfo.arguments, environment: processInfo.environment)
    }

    /// Parses `"185x32"` into a size; returns `nil` for anything malformed or non-positive.
    static func parseSize(_ text: String) -> CGSize? {
        let parts = text.lowercased().split(separator: "x")
        guard parts.count == 2, let width = Double(parts[0]), let height = Double(parts[1]),
              width > 0, height > 0 else { return nil }
        return CGSize(width: width, height: height)
    }
}
