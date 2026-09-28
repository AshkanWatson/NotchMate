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
    /// - Parameter fastDelays: Shortens the hover delays; turn off to show the real defaults (e.g. in screenshots).
    static func launchNotchMate(_ arguments: [String] = [], fastDelays: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        let delays = fastDelays ? ["-openDelay", "0.05", "-closeDelay", "0.1"] : []
        app.launchArguments = ["--ui-testing", "--reset-settings"] + delays + arguments
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

    /// Captures the screen and attaches two images to the test result: the full screen
    /// (`<name>-fullscreen`) and, cropped around `region`, `readme-<name>`.
    /// CI exports the `readme-` attachments into `docs/screenshots` (see `scripts/export-screenshots.py`).
    @MainActor
    func captureScreenshot(named name: String, around region: CGRect?, margin: CGSize = CGSize(width: 60, height: 40)) {
        let screenshot = XCUIScreen.main.screenshot()
        let fullScreen = XCTAttachment(screenshot: screenshot)
        fullScreen.name = "\(name)-fullscreen"
        fullScreen.lifetime = .keepAlways
        add(fullScreen)

        guard var image = screenshot.image.cgImage(forProposedRect: nil, context: nil, hints: nil),
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
        guard let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { return }
        let cropped = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        cropped.name = "readme-\(name)"
        cropped.lifetime = .keepAlways
        add(cropped)
    }
}
