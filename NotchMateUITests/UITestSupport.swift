import AppKit
import XCTest

enum NotchID {
    static let compact = "notch.compact"
    static let expanded = "notch.expanded"
    static let clock = "notch.clock"
    static let nowPlaying = "notch.nowPlaying"
    static let settingsButton = "notch.settingsButton"
    static let settingsWindow = "settings.window"
    static let virtualNotchToggle = "settings.virtualNotch"
}

extension XCUIApplication {
    /// Launches NotchMate in a deterministic state: default settings, short delays,
    /// no haptics and no Apple Events.
    static func launchNotchMate(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-settings", "-openDelay", "0.05", "-closeDelay", "0.1"] + arguments
        app.launch()
        return app
    }

    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}

extension XCUIElement {
    var center: XCUICoordinate {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    }

    /// Waits until the element no longer exists (works on Xcode versions before 16).
    @discardableResult
    func waitUntilGone(_ timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}

extension XCTestCase {
    /// Moves the real mouse pointer onto the notch and waits for the panel.
    @MainActor
    func hoverNotch(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let compact = app.element(NotchID.compact)
        XCTAssertTrue(compact.waitForExistence(timeout: 10), "compact notch should be visible", file: file, line: line)
        compact.center.hover()
        let expanded = app.element(NotchID.expanded)
        XCTAssertTrue(expanded.waitForExistence(timeout: 5), "hovering the notch should expand it", file: file, line: line)
        return expanded
    }

    /// Moves the pointer well below the panel.
    @MainActor
    func moveAway(from element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1)).withOffset(CGVector(dx: 0, dy: 350)).hover()
    }

    /// Saves a screenshot as a test attachment and, when `NOTCHMATE_SCREENSHOT_DIR`
    /// is set (via `TEST_RUNNER_NOTCHMATE_SCREENSHOT_DIR`), as a cropped PNG file.
    @MainActor
    func captureScreenshot(named name: String, around region: CGRect?, margin: CGSize = CGSize(width: 60, height: 40)) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        guard let directory = ProcessInfo.processInfo.environment["NOTCHMATE_SCREENSHOT_DIR"],
              var image = screenshot.image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let screen = NSScreen.screens.first else { return }

        if let region {
            let scale = CGFloat(image.width) / screen.frame.width
            var crop = region.insetBy(dx: -margin.width, dy: -margin.height)
            crop.origin.y = max(0, crop.origin.y) // keep the menu bar in frame
            crop = crop.intersection(CGRect(origin: .zero, size: screen.frame.size))
            let pixels = CGRect(x: crop.minX * scale, y: crop.minY * scale, width: crop.width * scale, height: crop.height * scale).integral
            if let cropped = image.cropping(to: pixels) {
                image = cropped
            }
        }
        let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name).png")
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
        try? data?.write(to: url)
    }
}
