import XCTest
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import NotchMateKit

final class NotchDetectorTests: XCTestCase {
    func testDetectsNotchFromAuxiliaryAreas() throws {
        let notch = try XCTUnwrap(NotchDetector.hardwareNotch(on: Fixtures.macBookPro14))
        XCTAssertEqual(notch.width, 185, accuracy: 0.001)
        XCTAssertEqual(notch.height, 32)
        XCTAssertEqual(notch.maxY, 982, "notch must touch the top edge")
        XCTAssertEqual(notch.midX, 756, accuracy: 0.001, "notch is centred on a 1512pt display")
    }

    func testNoNotchWithoutSafeAreaInset() {
        XCTAssertNil(NotchDetector.hardwareNotch(on: Fixtures.intelMacBook))
        XCTAssertNil(NotchDetector.hardwareNotch(on: Fixtures.externalDisplay()))
    }

    func testDifferentModelsAndResolutions() throws {
        for screen in [Fixtures.macBookPro14, Fixtures.macBookPro16, Fixtures.macBookAir13, Fixtures.macBookAir15, Fixtures.macBookPro14MoreSpace] {
            let notch = try XCTUnwrap(NotchDetector.hardwareNotch(on: screen), screen.name)
            XCTAssertEqual(notch.midX, screen.frame.midX, accuracy: 0.001)
            XCTAssertEqual(notch.maxY, screen.frame.maxY)
            XCTAssertEqual(notch.height, screen.safeAreaTop)
        }
        let moreSpace = try XCTUnwrap(NotchDetector.hardwareNotch(on: Fixtures.macBookPro14MoreSpace))
        XCTAssertEqual(moreSpace.width, 220, accuracy: 0.001)
    }

    func testNotchOnSecondaryDisplayUsesGlobalCoordinates() throws {
        // Built-in display to the right of and above a primary external display.
        let screen = Fixtures.notchedMac(width: 1512, height: 982, origin: CGPoint(x: 2560, y: 200))
        let notch = try XCTUnwrap(NotchDetector.hardwareNotch(on: screen))
        XCTAssertEqual(notch.minX, 2560 + (1512 - 185) / 2, accuracy: 0.001)
        XCTAssertEqual(notch.maxY, 1182)
    }

    func testAsymmetricAuxiliaryAreas() throws {
        var screen = Fixtures.macBookPro14
        screen.auxiliaryTopLeftWidth = 600
        screen.auxiliaryTopRightWidth = 700
        let notch = try XCTUnwrap(NotchDetector.hardwareNotch(on: screen))
        XCTAssertEqual(notch.minX, 600)
        XCTAssertEqual(notch.width, 212)
    }

    func testFallsBackToEstimatedWidthWithoutAuxiliaryAreas() throws {
        var screen = Fixtures.macBookPro14
        screen.auxiliaryTopLeftWidth = nil
        screen.auxiliaryTopRightWidth = nil
        let notch = try XCTUnwrap(NotchDetector.hardwareNotch(on: screen))
        XCTAssertEqual(notch.width, NotchDetector.fallbackNotchWidth)
        XCTAssertEqual(notch.midX, screen.frame.midX, accuracy: 0.001)
    }

    func testRejectsImplausiblyWideNotch() {
        var screen = Fixtures.macBookPro14
        screen.auxiliaryTopLeftWidth = 10
        screen.auxiliaryTopRightWidth = 10
        XCTAssertNil(NotchDetector.hardwareNotch(on: screen))
    }

    func testVirtualNotchMatchesMenuBarHeight() {
        let notch = NotchDetector.virtualNotch(on: Fixtures.externalDisplay(menuBar: 25), width: 185)
        XCTAssertEqual(notch.height, 25)
        XCTAssertEqual(notch.width, 185)
        XCTAssertEqual(notch.midX, 1280)
        XCTAssertEqual(notch.maxY, 1440)
    }

    func testVirtualNotchWithHiddenMenuBarUsesFallbackHeight() {
        let notch = NotchDetector.virtualNotch(on: Fixtures.externalDisplay(menuBar: 0), width: 185)
        XCTAssertEqual(notch.height, NotchDetector.fallbackMenuBarHeight)
    }

    func testVirtualNotchWidthIsClamped() {
        let small = Fixtures.externalDisplay(width: 300, height: 200)
        XCTAssertEqual(NotchDetector.virtualNotch(on: small, width: 1000).width, 150)
        XCTAssertEqual(NotchDetector.virtualNotch(on: small, width: 10).width, 80)
    }

    // MARK: Display selection

    func testAutomaticPrefersNotchedDisplay() throws {
        let external = Fixtures.externalDisplay(isPrimary: true)
        let builtIn = Fixtures.notchedMac(width: 1512, height: 982, origin: CGPoint(x: 2560, y: 0))
        let placement = try XCTUnwrap(NotchDetector.placement(for: [external, builtIn], settings: .default))
        XCTAssertEqual(placement.screen, builtIn)
        XCTAssertFalse(placement.isVirtual)
    }

    func testAutomaticFallsBackToPrimaryWithVirtualNotch() throws {
        let placement = try XCTUnwrap(NotchDetector.placement(for: [Fixtures.intelMacBook], settings: .default))
        XCTAssertTrue(placement.isVirtual)
        XCTAssertEqual(placement.notchRect.height, 25)
    }

    func testNoPlacementWhenVirtualNotchDisabledAndNoNotch() {
        var settings = NotchSettings()
        settings.showOnDisplaysWithoutNotch = false
        XCTAssertNil(NotchDetector.placement(for: [Fixtures.intelMacBook], settings: settings))
        XCTAssertNotNil(NotchDetector.placement(for: [Fixtures.macBookPro14], settings: settings))
    }

    func testPrimaryPreferenceIgnoresNotchedSecondary() throws {
        var settings = NotchSettings()
        settings.displayPreference = .primary
        let external = Fixtures.externalDisplay(isPrimary: true)
        let builtIn = Fixtures.notchedMac(width: 1512, height: 982, origin: CGPoint(x: 2560, y: 0))
        let placement = try XCTUnwrap(NotchDetector.placement(for: [external, builtIn], settings: settings))
        XCTAssertEqual(placement.screen, external)
        XCTAssertTrue(placement.isVirtual)
    }

    func testBuiltInPreferenceFallsBackInClamshellMode() throws {
        var settings = NotchSettings()
        settings.displayPreference = .builtIn
        let placement = try XCTUnwrap(NotchDetector.placement(for: [Fixtures.externalDisplay()], settings: settings))
        XCTAssertEqual(placement.screen.displayID, 2)
    }

    func testNoScreens() {
        XCTAssertNil(NotchDetector.placement(for: [], settings: .default))
    }
}
