import XCTest
import NotchMateKit
@testable import NotchMate

@MainActor
final class SettingsModelTests: XCTestCase {
    func testPersistsChanges() {
        let store = InMemoryKeyValueStore()
        let model = SettingsModel(store: store)
        model.settings.showClock = false
        model.settings.appearance = .system
        let reloaded = SettingsModel(store: store)
        XCTAssertFalse(reloaded.settings.showClock)
        XCTAssertEqual(reloaded.settings.appearance, .system)
    }

    func testNotifiesOnlyOnRealChanges() {
        let model = SettingsModel(store: InMemoryKeyValueStore())
        var notifications = 0
        model.onChange = { _ in notifications += 1 }
        model.settings.showBattery = false
        model.settings.showBattery = false
        XCTAssertEqual(notifications, 1)
    }

    func testResetToDefaults() {
        let model = SettingsModel(store: InMemoryKeyValueStore())
        model.settings.expandedWidth = 700
        model.resetToDefaults()
        XCTAssertEqual(model.settings, .default)
    }
}
