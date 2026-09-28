import XCTest
@testable import NotchMateKit

final class NotchLayoutTests: XCTestCase {
    private func makeLayout(_ screen: ScreenDescriptor, size: CGSize = CGSize(width: 520, height: 170)) throws -> NotchLayout {
        let placement = try XCTUnwrap(NotchDetector.placement(for: [screen], settings: .default))
        return NotchLayout(placement: placement, expandedSize: size)
    }

    func testExpandedPanelHangsFromTopCentredOnNotch() throws {
        let layout = try makeLayout(Fixtures.macBookPro14)
        XCTAssertEqual(layout.expandedRect.maxY, 982)
        XCTAssertEqual(layout.expandedRect.midX, layout.notchRect.midX, accuracy: 0.5)
        XCTAssertEqual(layout.expandedRect.width, 520)
        XCTAssertEqual(layout.expandedRect.height, 170)
    }

    func testWindowContainsBothStatesAndTouchesTopEdge() throws {
        for screen in [Fixtures.macBookPro14, Fixtures.macBookPro16, Fixtures.macBookAir13, Fixtures.macBookPro14MoreSpace, Fixtures.intelMacBook] {
            let layout = try makeLayout(screen)
            XCTAssertTrue(layout.windowFrame.contains(layout.expandedRect), screen.name)
            XCTAssertTrue(layout.windowFrame.contains(layout.notchRect), screen.name)
            XCTAssertEqual(layout.windowFrame.maxY, screen.frame.maxY, accuracy: 0.001)
            XCTAssertTrue(screen.frame.contains(layout.windowFrame), screen.name)
        }
    }

    func testExpandedIsAlwaysWiderThanNotch() throws {
        let layout = try makeLayout(Fixtures.macBookPro14, size: CGSize(width: 10, height: 10))
        XCTAssertGreaterThanOrEqual(layout.expandedRect.width, layout.notchRect.width + 2 * NotchLayout.minimumSideExtension)
        XCTAssertGreaterThanOrEqual(layout.expandedRect.height, layout.notchRect.height * 2)
    }

    func testExpandedIsClampedToSmallScreens() throws {
        let tiny = Fixtures.externalDisplay(width: 400, height: 240)
        let layout = try makeLayout(tiny, size: CGSize(width: 900, height: 500))
        XCTAssertLessThanOrEqual(layout.expandedRect.width, 400 - 2 * NotchLayout.screenMargin)
        XCTAssertLessThanOrEqual(layout.expandedRect.height, 120)
        XCTAssertTrue(tiny.frame.contains(layout.expandedRect))
    }

    func testLocalRectsUseTopLeftOrigin() throws {
        let layout = try makeLayout(Fixtures.macBookPro14)
        let localNotch = layout.localNotchRect
        let localExpanded = layout.localExpandedRect
        XCTAssertEqual(localNotch.minY, 0, "notch touches the window's top edge")
        XCTAssertEqual(localExpanded.minY, 0)
        XCTAssertEqual(localNotch.midX, localExpanded.midX, accuracy: 0.5)
        XCTAssertEqual(localNotch.size, layout.notchRect.size)
    }

    func testLayoutOnSecondaryDisplay() throws {
        let screen = Fixtures.notchedMac(width: 1512, height: 982, origin: CGPoint(x: -1512, y: 300))
        let layout = try makeLayout(screen)
        XCTAssertEqual(layout.windowFrame.maxY, 1282)
        XCTAssertTrue(screen.frame.contains(layout.windowFrame))
        XCTAssertEqual(layout.expandedRect.midX, screen.frame.midX, accuracy: 0.5)
    }

    func testPixelAlignmentOnRetina() {
        let rect = CGRect(x: 10.3, y: 20.26, width: 100.1, height: 30.2)
        let aligned = NotchLayout.align(rect, scale: 2)
        XCTAssertEqual(aligned, CGRect(x: 10, y: 20, width: 100.5, height: 30.5))
        XCTAssertTrue(aligned.contains(rect))
        for value in [aligned.minX, aligned.minY, aligned.maxX, aligned.maxY] {
            XCTAssertEqual((value * 2).rounded(), value * 2, "edges land on the pixel grid")
        }
    }

    func testPixelAlignmentAtFractionalScale() {
        let aligned = NotchLayout.align(CGRect(x: 663.5, y: 944, width: 185, height: 38), scale: 1.68)
        for value in [aligned.minX, aligned.maxX] {
            XCTAssertEqual((value * 1.68).rounded(), value * 1.68, accuracy: 1e-9)
        }
    }

    func testPixelAlignmentIsIdentityOnGrid() {
        let rect = CGRect(x: 0, y: 950, width: 185, height: 32)
        XCTAssertEqual(NotchLayout.align(rect, scale: 2), rect)
        XCTAssertEqual(NotchLayout.align(rect, scale: 1), rect)
    }
}
