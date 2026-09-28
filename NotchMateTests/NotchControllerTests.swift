import XCTest
import NotchMateKit
@testable import NotchMate

@MainActor
final class NotchControllerTests: XCTestCase {
    private func makeController(
        screens: [ScreenDescriptor] = [TestScreens.notched],
        configure: (inout NotchSettings) -> Void = { _ in }
    ) -> (NotchController, SettingsModel) {
        let model = SettingsModel(store: InMemoryKeyValueStore())
        var settings = model.settings
        settings.openDelay = 0
        settings.closeDelay = 0
        configure(&settings)
        model.settings = settings
        let controller = NotchController(
            settingsModel: model,
            options: LaunchOptions(arguments: ["--ui-testing"]),
            screensProvider: { screens },
            presentsPanel: false
        )
        controller.updateLayout()
        return (controller, model)
    }

    func testDetectsHardwareNotch() throws {
        let (controller, _) = makeController()
        let placement = try XCTUnwrap(controller.placement)
        XCTAssertFalse(placement.isVirtual)
        XCTAssertEqual(controller.layout?.notchRect.width, 185)
        XCTAssertTrue(controller.statusDescription.hasPrefix("Notch detected (185×32 pt)"))
    }

    func testCompactUntilHover() {
        let (controller, _) = makeController()
        XCTAssertEqual(controller.state, .collapsed)
        controller.pointerMoved(to: CGPoint(x: 200, y: 500))
        XCTAssertEqual(controller.state, .collapsed)
    }

    func testHoverExpandsAndLeavingCollapses() {
        let (controller, _) = makeController()
        controller.pointerMoved(to: CGPoint(x: 756, y: 981))
        XCTAssertEqual(controller.state, .expanded)
        controller.pointerMoved(to: CGPoint(x: 756, y: 850)) // inside the panel
        XCTAssertEqual(controller.state, .expanded)
        controller.pointerMoved(to: CGPoint(x: 756, y: 300))
        XCTAssertEqual(controller.state, .collapsed)
    }

    func testDelaysAreHonoured() async throws {
        let (controller, _) = makeController { $0.openDelay = 0.1 }
        controller.pointerMoved(to: CGPoint(x: 756, y: 981))
        XCTAssertEqual(controller.state, .collapsed, "nothing happens before the delay")
        let deadline = Date().addingTimeInterval(3)
        while controller.state != .expanded, Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertEqual(controller.state, .expanded)
    }

    func testClickOutsideCollapses() {
        let (controller, _) = makeController()
        controller.toggle()
        XCTAssertEqual(controller.state, .expanded)
        controller.mouseDown(at: CGPoint(x: 756, y: 900))
        XCTAssertEqual(controller.state, .expanded, "click inside keeps it open")
        controller.mouseDown(at: CGPoint(x: 100, y: 100))
        XCTAssertEqual(controller.state, .collapsed)
    }

    func testHoverDisabledSetting() {
        let (controller, _) = makeController { $0.expandOnHover = false }
        controller.pointerMoved(to: CGPoint(x: 756, y: 981))
        XCTAssertEqual(controller.state, .collapsed)
    }

    func testVirtualNotchOnDisplayWithoutNotch() throws {
        let (controller, _) = makeController(screens: [TestScreens.plain])
        let layout = try XCTUnwrap(controller.layout)
        XCTAssertTrue(layout.isVirtual)
        XCTAssertEqual(layout.notchRect.height, 25, "virtual notch matches the menu bar")
        controller.pointerMoved(to: CGPoint(x: 960, y: 1079))
        XCTAssertEqual(controller.state, .expanded)
    }

    func testNoNotchAndVirtualNotchDisabledHidesEverything() {
        let (controller, _) = makeController(screens: [TestScreens.plain]) { $0.showOnDisplaysWithoutNotch = false }
        XCTAssertNil(controller.layout)
        controller.pointerMoved(to: CGPoint(x: 960, y: 1079))
        XCTAssertEqual(controller.state, .collapsed)
        XCTAssertTrue(controller.statusDescription.contains("No notch"))
    }

    func testSettingsChangeRelayouts() throws {
        let (controller, model) = makeController()
        controller.start()
        defer { controller.stop() }
        model.settings.expandedWidth = 640
        XCTAssertEqual(try XCTUnwrap(controller.layout).expandedRect.width, 640)
        model.settings.showOnDisplaysWithoutNotch = false
        XCTAssertNotNil(controller.layout, "a real notch is still used")
    }

    func testDisplayChangeCollapses() {
        var screens = [TestScreens.notched]
        let model = SettingsModel(store: InMemoryKeyValueStore())
        let controller = NotchController(
            settingsModel: model,
            options: LaunchOptions(arguments: ["--ui-testing"]),
            screensProvider: { screens },
            presentsPanel: false
        )
        controller.updateLayout()
        controller.toggle()
        XCTAssertEqual(controller.state, .expanded)
        screens = [TestScreens.plain]
        controller.updateLayout()
        XCTAssertEqual(controller.state, .collapsed)
        XCTAssertEqual(controller.layout?.isVirtual, true)
    }
}
