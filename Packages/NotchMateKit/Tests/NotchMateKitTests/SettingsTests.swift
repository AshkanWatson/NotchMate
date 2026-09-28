import XCTest
@testable import NotchMateKit

final class SettingsTests: XCTestCase {
    func testDefaults() {
        let settings = SettingsStore(store: InMemoryKeyValueStore()).load()
        XCTAssertEqual(settings, .default)
        XCTAssertTrue(settings.expandOnHover)
        XCTAssertTrue(settings.showOnDisplaysWithoutNotch)
        XCTAssertEqual(settings.displayPreference, .automatic)
        XCTAssertEqual(settings.appearance, .notch)
    }

    func testRoundTrip() {
        let store = SettingsStore(store: InMemoryKeyValueStore())
        var settings = NotchSettings()
        settings.expandOnHover = false
        settings.openDelay = 0.4
        settings.closeDelay = 1.2
        settings.expandedWidth = 600
        settings.expandedHeight = 200
        settings.hoverPadding = 12
        settings.showOnDisplaysWithoutNotch = false
        settings.virtualNotchWidth = 200
        settings.displayPreference = .primary
        settings.appearance = .system
        settings.showClock = false
        settings.showBattery = false
        settings.showNowPlaying = false
        settings.hapticFeedback = false
        store.save(settings)
        XCTAssertEqual(store.load(), settings)
    }

    func testOutOfRangeValuesAreClamped() {
        let backing = InMemoryKeyValueStore([
            "openDelay": 99.0,
            "closeDelay": -3.0,
            "expandedWidth": 5000.0,
            "expandedHeight": 1.0,
            "hoverPadding": Double.nan,
            "virtualNotchWidth": 0
        ])
        let settings = SettingsStore(store: backing).load()
        XCTAssertEqual(settings.openDelay, NotchSettings.openDelayRange.upperBound)
        XCTAssertEqual(settings.closeDelay, NotchSettings.closeDelayRange.lowerBound)
        XCTAssertEqual(settings.expandedWidth, NotchSettings.expandedWidthRange.upperBound)
        XCTAssertEqual(settings.expandedHeight, NotchSettings.expandedHeightRange.lowerBound)
        XCTAssertEqual(settings.hoverPadding, NotchSettings.hoverPaddingRange.lowerBound)
        XCTAssertEqual(settings.virtualNotchWidth, NotchSettings.virtualNotchWidthRange.lowerBound)
    }

    func testCommandLineStyleStringValues() {
        let backing = InMemoryKeyValueStore([
            "expandOnHover": "NO",
            "showClock": "false",
            "showBattery": "1",
            "openDelay": "0.25",
            "displayPreference": "builtIn"
        ])
        let settings = SettingsStore(store: backing).load()
        XCTAssertFalse(settings.expandOnHover)
        XCTAssertFalse(settings.showClock)
        XCTAssertTrue(settings.showBattery)
        XCTAssertEqual(settings.openDelay, 0.25)
        XCTAssertEqual(settings.displayPreference, .builtIn)
    }

    func testInvalidValuesFallBackToDefaults() {
        let backing = InMemoryKeyValueStore([
            "expandOnHover": "maybe",
            "displayPreference": "sideways",
            "appearance": 42,
            "openDelay": "soon"
        ])
        XCTAssertEqual(SettingsStore(store: backing).load(), .default)
    }

    func testResetRemovesAllKeys() {
        let backing = InMemoryKeyValueStore()
        let store = SettingsStore(store: backing)
        var settings = NotchSettings()
        settings.showClock = false
        store.save(settings)
        store.reset()
        for key in SettingsStore.Key.allCases {
            XCTAssertNil(backing.object(forKey: key.rawValue), key.rawValue)
        }
        XCTAssertEqual(store.load(), .default)
    }

    func testUserDefaultsConformance() throws {
        let suite = "NotchMateKitTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = SettingsStore(store: defaults)
        var settings = NotchSettings()
        settings.expandedWidth = 640
        settings.appearance = .system
        store.save(settings)
        XCTAssertEqual(store.load(), settings)
    }

    func testExpandedSize() {
        XCTAssertEqual(NotchSettings.default.expandedSize, CGSize(width: 520, height: 170))
    }
}
