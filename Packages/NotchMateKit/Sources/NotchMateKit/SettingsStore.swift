import Foundation

/// The subset of `UserDefaults` NotchMate needs; lets tests use an in-memory store.
public protocol KeyValueStore: AnyObject {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

extension UserDefaults: KeyValueStore {}

public final class InMemoryKeyValueStore: KeyValueStore {
    private var values: [String: Any]

    public init(_ values: [String: Any] = [:]) {
        self.values = values
    }

    public func object(forKey defaultName: String) -> Any? { values[defaultName] }
    public func set(_ value: Any?, forKey defaultName: String) { values[defaultName] = value }
    public func removeObject(forKey defaultName: String) { values[defaultName] = nil }
}

/// Loads and saves `NotchSettings`, one defaults key per setting.
///
/// Separate keys (rather than one encoded blob) mean any setting can be
/// overridden from the command line, e.g. `-expandOnHover NO`, which the UI
/// tests rely on.
public struct SettingsStore {
    public enum Key: String, CaseIterable {
        case expandOnHover
        case openDelay
        case closeDelay
        case expandedWidth
        case expandedHeight
        case hoverPadding
        case showOnDisplaysWithoutNotch
        case virtualNotchWidth
        case displayPreference
        case appearance
        case showClock
        case showBattery
        case showNowPlaying
        case hapticFeedback
    }

    public let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    public func load() -> NotchSettings {
        var settings = NotchSettings()
        settings.expandOnHover = bool(.expandOnHover) ?? settings.expandOnHover
        settings.openDelay = double(.openDelay) ?? settings.openDelay
        settings.closeDelay = double(.closeDelay) ?? settings.closeDelay
        settings.expandedWidth = double(.expandedWidth) ?? settings.expandedWidth
        settings.expandedHeight = double(.expandedHeight) ?? settings.expandedHeight
        settings.hoverPadding = double(.hoverPadding) ?? settings.hoverPadding
        settings.showOnDisplaysWithoutNotch = bool(.showOnDisplaysWithoutNotch) ?? settings.showOnDisplaysWithoutNotch
        settings.virtualNotchWidth = double(.virtualNotchWidth) ?? settings.virtualNotchWidth
        settings.displayPreference = string(.displayPreference).flatMap(DisplayPreference.init) ?? settings.displayPreference
        settings.appearance = string(.appearance).flatMap(PanelAppearance.init) ?? settings.appearance
        settings.showClock = bool(.showClock) ?? settings.showClock
        settings.showBattery = bool(.showBattery) ?? settings.showBattery
        settings.showNowPlaying = bool(.showNowPlaying) ?? settings.showNowPlaying
        settings.hapticFeedback = bool(.hapticFeedback) ?? settings.hapticFeedback
        return settings.sanitized()
    }

    public func save(_ settings: NotchSettings) {
        let settings = settings.sanitized()
        store.set(settings.expandOnHover, forKey: Key.expandOnHover.rawValue)
        store.set(settings.openDelay, forKey: Key.openDelay.rawValue)
        store.set(settings.closeDelay, forKey: Key.closeDelay.rawValue)
        store.set(settings.expandedWidth, forKey: Key.expandedWidth.rawValue)
        store.set(settings.expandedHeight, forKey: Key.expandedHeight.rawValue)
        store.set(settings.hoverPadding, forKey: Key.hoverPadding.rawValue)
        store.set(settings.showOnDisplaysWithoutNotch, forKey: Key.showOnDisplaysWithoutNotch.rawValue)
        store.set(settings.virtualNotchWidth, forKey: Key.virtualNotchWidth.rawValue)
        store.set(settings.displayPreference.rawValue, forKey: Key.displayPreference.rawValue)
        store.set(settings.appearance.rawValue, forKey: Key.appearance.rawValue)
        store.set(settings.showClock, forKey: Key.showClock.rawValue)
        store.set(settings.showBattery, forKey: Key.showBattery.rawValue)
        store.set(settings.showNowPlaying, forKey: Key.showNowPlaying.rawValue)
        store.set(settings.hapticFeedback, forKey: Key.hapticFeedback.rawValue)
    }

    public func reset() {
        Key.allCases.forEach { store.removeObject(forKey: $0.rawValue) }
    }

    // Values can arrive as native types (written by the app) or as strings
    // (command-line arguments such as `-expandOnHover NO`).

    private func bool(_ key: Key) -> Bool? {
        switch store.object(forKey: key.rawValue) {
        case let value as Bool: return value
        case let value as Int: return value != 0
        case let value as String:
            switch value.lowercased() {
            case "yes", "true", "1": return true
            case "no", "false", "0": return false
            default: return nil
            }
        default: return nil
        }
    }

    private func double(_ key: Key) -> Double? {
        switch store.object(forKey: key.rawValue) {
        case let value as Double: return value
        case let value as Int: return Double(value)
        case let value as String: return Double(value)
        default: return nil
        }
    }

    private func string(_ key: Key) -> String? {
        store.object(forKey: key.rawValue) as? String
    }
}
