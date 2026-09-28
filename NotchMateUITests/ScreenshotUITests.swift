import XCTest

/// Captures the README screenshots from the running app.
/// Extract them with `python3 scripts/export-screenshots.py <result bundle> docs/screenshots`.
final class ScreenshotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureScreenshots() {
        let app = XCUIApplication.launchNotchMate()
        let compact = app.element(NotchID.compact)
        XCTAssertTrue(compact.waitForExistence(timeout: 10))
        sleep(1)
        let context = compact.frame.insetBy(dx: -260, dy: 0)
        captureScreenshot(named: "01-compact", around: context, margin: CGSize(width: 0, height: 50))

        let expanded = hoverNotch(in: app)
        sleep(2) // let the spring settle
        captureScreenshot(named: "02-expanded", around: expanded.frame.insetBy(dx: -140, dy: 0), margin: CGSize(width: 0, height: 50))
        captureScreenshot(named: "03-main-interface", around: expanded.frame, margin: CGSize(width: 24, height: 24))

        moveAway(from: expanded)
        XCTAssertTrue(expanded.waitUntilGone(5))
    }

    @MainActor
    func testCaptureSystemAppearance() {
        let app = XCUIApplication.launchNotchMate(["-appearance", "system", "--start-expanded"])
        let expanded = app.element(NotchID.expanded)
        XCTAssertTrue(expanded.waitForExistence(timeout: 10))
        sleep(2)
        captureScreenshot(named: "05-system-appearance", around: expanded.frame, margin: CGSize(width: 24, height: 24))
    }

    @MainActor
    func testCaptureSettings() {
        let app = XCUIApplication.launchNotchMate(["--open-settings"])
        let window = app.windows.matching(identifier: NotchID.settingsWindow).firstMatch
        let fallback = app.element(NotchID.settingsWindow)
        XCTAssertTrue(fallback.waitForExistence(timeout: 10))
        sleep(1)
        let frame = window.exists ? window.frame : fallback.frame
        captureScreenshot(named: "04-settings", around: frame, margin: CGSize(width: 20, height: 20))
    }
}
