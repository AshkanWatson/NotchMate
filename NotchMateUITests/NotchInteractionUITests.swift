import XCTest

/// Drives the real app with the real mouse pointer.
///
/// CI Macs have no notch, so these tests exercise both paths: the virtual notch
/// (what users of Macs without a notch get) and a simulated hardware notch
/// (`--simulate-notch`), which runs the same detection code on fake geometry.
final class NotchInteractionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCompactStateOnLaunch() {
        let app = XCUIApplication.launchNotchMate(["--simulate-notch", "185x32"])
        let compact = app.element(NotchID.compact)
        XCTAssertTrue(compact.waitForExistence(timeout: 10))
        XCTAssertFalse(app.element(NotchID.expanded).exists, "the panel stays hidden until hovered")
        XCTAssertEqual(compact.frame.width, 185, accuracy: 1)
        XCTAssertEqual(compact.frame.height, 32, accuracy: 1)
        XCTAssertEqual(compact.frame.minY, 0, accuracy: 1, "the notch is flush with the top of the screen")
    }

    @MainActor
    func testHoverExpandsAndLeavingCollapses() {
        let app = XCUIApplication.launchNotchMate(["--simulate-notch", "185x32"])
        let compactFrame = app.element(NotchID.compact).frame
        let expanded = hoverNotch(in: app)

        XCTAssertGreaterThan(expanded.frame.width, compactFrame.width)
        XCTAssertGreaterThan(expanded.frame.height, compactFrame.height)
        XCTAssertEqual(expanded.frame.minY, 0, accuracy: 1)
        XCTAssertEqual(expanded.frame.midX, compactFrame.midX, accuracy: 2, "the panel grows out of the notch")
        XCTAssertTrue(app.element(NotchID.clock).exists)
        XCTAssertTrue(app.element(NotchID.nowPlaying).exists)

        // Moving within the panel keeps it open.
        expanded.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7)).hover()
        XCTAssertTrue(expanded.exists)

        moveAway(from: expanded)
        XCTAssertTrue(expanded.waitUntilGone(5), "leaving the panel collapses it")
        XCTAssertTrue(app.element(NotchID.compact).waitForExistence(timeout: 5))
    }

    @MainActor
    func testRepeatedTransitionsStayConsistent() {
        let app = XCUIApplication.launchNotchMate()
        for _ in 0..<3 {
            let expanded = hoverNotch(in: app)
            moveAway(from: expanded)
            XCTAssertTrue(expanded.waitUntilGone(5))
        }
        XCTAssertTrue(app.element(NotchID.compact).exists)
    }

    @MainActor
    func testHoverDisabledKeepsCompact() {
        let app = XCUIApplication.launchNotchMate(["-expandOnHover", "NO"])
        let compact = app.element(NotchID.compact)
        XCTAssertTrue(compact.waitForExistence(timeout: 10))
        compact.center.hover()
        XCTAssertFalse(app.element(NotchID.expanded).waitForExistence(timeout: 1.5))
    }

    @MainActor
    func testDifferentNotchSizes() {
        for size in [CGSize(width: 180, height: 32), CGSize(width: 220, height: 38)] {
            let app = XCUIApplication.launchNotchMate(["--simulate-notch", "\(Int(size.width))x\(Int(size.height))"])
            let compact = app.element(NotchID.compact)
            XCTAssertTrue(compact.waitForExistence(timeout: 10))
            XCTAssertEqual(compact.frame.width, size.width, accuracy: 1)
            XCTAssertEqual(compact.frame.height, size.height, accuracy: 1)
            let expanded = hoverNotch(in: app)
            XCTAssertEqual(expanded.frame.midX, compact.frame.midX, accuracy: 2)
            app.terminate()
        }
    }

    @MainActor
    func testMacWithoutNotchShowsVirtualNotch() {
        let app = XCUIApplication.launchNotchMate(["--simulate-no-notch"])
        let compact = app.element(NotchID.compact)
        XCTAssertTrue(compact.waitForExistence(timeout: 10), "a virtual notch is shown by default")
        XCTAssertEqual(compact.frame.minY, 0, accuracy: 1)
        XCTAssertLessThanOrEqual(compact.frame.height, 40, "the virtual notch is only as tall as the menu bar")
        _ = hoverNotch(in: app)
    }

    @MainActor
    func testMacWithoutNotchAndVirtualNotchDisabled() {
        let app = XCUIApplication.launchNotchMate(["--simulate-no-notch", "-showOnDisplaysWithoutNotch", "NO"])
        XCTAssertFalse(app.element(NotchID.compact).waitForExistence(timeout: 3), "nothing is drawn without a notch")
    }

    @MainActor
    func testClickOutsideCollapses() {
        let app = XCUIApplication.launchNotchMate(["--start-expanded"])
        let expanded = app.element(NotchID.expanded)
        XCTAssertTrue(expanded.waitForExistence(timeout: 10))
        expanded.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1)).withOffset(CGVector(dx: 0, dy: 300)).click()
        XCTAssertTrue(expanded.waitUntilGone(5))
    }

    @MainActor
    func testSettingsButtonOpensSettings() {
        let app = XCUIApplication.launchNotchMate()
        _ = hoverNotch(in: app)
        let button = app.element(NotchID.settingsButton)
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.click()
        XCTAssertTrue(app.element(NotchID.settingsWindow).waitForExistence(timeout: 5))
    }

    @MainActor
    func testTogglingVirtualNotchSettingAppliesImmediately() {
        let app = XCUIApplication.launchNotchMate(["--simulate-no-notch", "--open-settings"])
        XCTAssertTrue(app.element(NotchID.compact).waitForExistence(timeout: 10))
        let toggle = app.element(NotchID.virtualNotchToggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.click()
        XCTAssertTrue(app.element(NotchID.compact).waitUntilGone(5))
        toggle.click()
        XCTAssertTrue(app.element(NotchID.compact).waitForExistence(timeout: 5))
    }
}
