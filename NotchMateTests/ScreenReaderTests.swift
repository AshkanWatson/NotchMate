import AppKit
import XCTest
import NotchMateKit
@testable import NotchMate

@MainActor
final class ScreenReaderTests: XCTestCase {
    func testDescriptorMirrorsNSScreen() throws {
        let screen = try XCTUnwrap(NSScreen.screens.first, "tests need a display")
        let descriptor = ScreenReader.descriptor(for: screen, isPrimary: true)
        XCTAssertEqual(descriptor.frame, screen.frame)
        XCTAssertEqual(descriptor.visibleFrame, screen.visibleFrame)
        XCTAssertEqual(descriptor.backingScaleFactor, screen.backingScaleFactor)
        XCTAssertEqual(descriptor.safeAreaTop, screen.safeAreaInsets.top)
        XCTAssertEqual(descriptor.displayID, screen.displayID)
        XCTAssertTrue(descriptor.isPrimary)
        // Whatever the hardware, detection must agree with the safe area.
        XCTAssertEqual(NotchDetector.hardwareNotch(on: descriptor) != nil, screen.safeAreaInsets.top > 0)
    }

    func testCurrentScreensMarksOnlyFirstAsPrimary() {
        let screens = ScreenReader.currentScreens(options: LaunchOptions())
        XCTAssertEqual(screens.count, NSScreen.screens.count)
        XCTAssertEqual(screens.filter(\.isPrimary).count, screens.isEmpty ? 0 : 1)
        XCTAssertEqual(screens.first?.isPrimary, screens.isEmpty ? nil : true)
    }

    func testSimulatedNotch() throws {
        var options = LaunchOptions()
        options.simulatedNotchSize = CGSize(width: 200, height: 38)
        let screens = ScreenReader.applySimulation(to: [TestScreens.plain], options: options)
        let notch = try XCTUnwrap(NotchDetector.hardwareNotch(on: screens[0]))
        XCTAssertEqual(notch.size, CGSize(width: 200, height: 38))
        XCTAssertEqual(notch.midX, 960)
    }

    func testSimulatedNoNotchRemovesHardwareNotch() {
        var options = LaunchOptions()
        options.simulateNoNotch = true
        let screens = ScreenReader.applySimulation(to: [TestScreens.notched], options: options)
        XCTAssertNil(NotchDetector.hardwareNotch(on: screens[0]))
    }

    func testNoSimulationIsIdentity() {
        XCTAssertEqual(ScreenReader.applySimulation(to: [TestScreens.notched, TestScreens.plain], options: LaunchOptions()),
                       [TestScreens.notched, TestScreens.plain])
    }
}
