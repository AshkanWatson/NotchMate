import XCTest
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import NotchMateKit

final class HoverTests: XCTestCase {
    private var layout: NotchLayout!

    override func setUpWithError() throws {
        let placement = try XCTUnwrap(NotchDetector.placement(for: [Fixtures.macBookPro14], settings: .default))
        layout = NotchLayout(placement: placement, expandedSize: CGSize(width: 520, height: 170))
    }

    func testCollapsedZoneCoversNotchPlusPadding() {
        let zone = NotchHitTesting.activationZone(for: layout, state: .collapsed, padding: 8)
        XCTAssertEqual(zone.minX, layout.notchRect.minX - 8)
        XCTAssertEqual(zone.maxX, layout.notchRect.maxX + 8)
        XCTAssertEqual(zone.minY, layout.notchRect.minY - 8)
        XCTAssertGreaterThan(zone.maxY, layout.screenFrame.maxY, "the very top pixel row counts")
    }

    func testExpandedZoneCoversPanel() {
        let zone = NotchHitTesting.activationZone(for: layout, state: .expanded, padding: 8)
        XCTAssertTrue(zone.contains(layout.expandedRect))
    }

    func testPointerAtTopEdgeCenterIsInside() {
        let zone = NotchHitTesting.activationZone(for: layout, state: .collapsed, padding: 0)
        XCTAssertTrue(NotchHitTesting.isPointer(CGPoint(x: 756, y: 982), inside: zone))
        XCTAssertTrue(NotchHitTesting.isPointer(CGPoint(x: 756, y: 981), inside: zone))
    }

    func testPointerBesideNotchInMenuBarIsOutside() {
        let zone = NotchHitTesting.activationZone(for: layout, state: .collapsed, padding: 8)
        XCTAssertFalse(NotchHitTesting.isPointer(CGPoint(x: 400, y: 975), inside: zone))
        XCTAssertFalse(NotchHitTesting.isPointer(CGPoint(x: 756, y: 500), inside: zone))
    }

    func testNegativePaddingIsIgnored() {
        let zone = NotchHitTesting.activationZone(for: layout, state: .collapsed, padding: -20)
        XCTAssertEqual(zone.minX, layout.notchRect.minX)
    }

    func testTrackerEmitsOnlyTransitions() {
        var tracker = HoverTracker()
        let zone = NotchHitTesting.activationZone(for: layout, state: .collapsed, padding: 8)
        XCTAssertNil(tracker.update(pointer: CGPoint(x: 100, y: 100), zone: zone))
        XCTAssertEqual(tracker.update(pointer: CGPoint(x: 756, y: 980), zone: zone), .pointerEntered)
        XCTAssertNil(tracker.update(pointer: CGPoint(x: 760, y: 979), zone: zone))
        XCTAssertEqual(tracker.update(pointer: CGPoint(x: 100, y: 100), zone: zone), .pointerExited)
        tracker.reset()
        XCTAssertFalse(tracker.isInside)
    }

    /// End-to-end: pointer path → tracker → state machine, with the zone growing on expansion.
    func testHoverExpandMoveAcrossPanelAndLeave() {
        var tracker = HoverTracker()
        var machine = NotchStateMachine(configuration: .init(openDelay: 0, closeDelay: 0))

        func move(to point: CGPoint) {
            let zone = NotchHitTesting.activationZone(for: layout, state: machine.state, padding: 8)
            if let event = tracker.update(pointer: point, zone: zone) {
                machine.handle(event)
            }
        }

        move(to: CGPoint(x: 756, y: 981))
        XCTAssertEqual(machine.state, .expanded)
        // Below the notch but inside the expanded panel: must stay open.
        move(to: CGPoint(x: layout.expandedRect.minX + 20, y: layout.expandedRect.minY + 20))
        XCTAssertEqual(machine.state, .expanded)
        move(to: CGPoint(x: 756, y: 200))
        XCTAssertEqual(machine.state, .collapsed)
        // The same panel position no longer counts once collapsed.
        move(to: CGPoint(x: layout.expandedRect.minX + 20, y: layout.expandedRect.minY + 20))
        XCTAssertEqual(machine.state, .collapsed)
    }
}
