import XCTest
@testable import NotchMate

final class LaunchOptionsTests: XCTestCase {
    func testDefaults() {
        let options = LaunchOptions(arguments: ["NotchMate"], environment: [:])
        XCTAssertEqual(options, LaunchOptions())
        XCTAssertFalse(options.isUITesting)
        XCTAssertNil(options.simulatedNotchSize)
    }

    func testParsesAllSwitches() {
        let options = LaunchOptions(arguments: [
            "NotchMate", "--ui-testing", "--reset-settings", "--simulate-notch", "200x38",
            "--start-expanded", "--open-settings"
        ])
        XCTAssertTrue(options.isUITesting)
        XCTAssertTrue(options.resetSettings)
        XCTAssertTrue(options.startExpanded)
        XCTAssertTrue(options.openSettingsOnLaunch)
        XCTAssertEqual(options.simulatedNotchSize, CGSize(width: 200, height: 38))
    }

    func testDetectsUnitTestHost() {
        let env = ["XCTestConfigurationFilePath": "/tmp/x.xctestconfiguration"]
        XCTAssertTrue(LaunchOptions(arguments: [], environment: env).isHostingUnitTests)
        XCTAssertFalse(LaunchOptions(arguments: ["--ui-testing"], environment: env).isHostingUnitTests)
    }

    func testParseSize() {
        XCTAssertEqual(LaunchOptions.parseSize("185X32"), CGSize(width: 185, height: 32))
        XCTAssertNil(LaunchOptions.parseSize("185"))
        XCTAssertNil(LaunchOptions.parseSize("0x32"))
        XCTAssertNil(LaunchOptions.parseSize("axb"))
        XCTAssertNil(LaunchOptions(arguments: ["--simulate-notch"]).simulatedNotchSize)
    }
}
