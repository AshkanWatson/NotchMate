import Foundation

/// Battery state, parsed from an IOKit power source description dictionary.
public struct BatteryInfo: Equatable, Sendable {
    /// Charge level from 0 to 1.
    public var level: Double
    public var isCharging: Bool
    public var isPluggedIn: Bool

    public init(level: Double, isCharging: Bool, isPluggedIn: Bool) {
        self.level = min(max(level, 0), 1)
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
    }

    /// Parses the dictionary returned by `IOPSGetPowerSourceDescription`.
    /// The keys are the documented string values of `kIOPS…Key` constants.
    /// Returns `nil` for anything that is not an internal battery (e.g. a UPS).
    public init?(powerSourceDescription description: [String: Any]) {
        if let type = description["Type"] as? String, type != "InternalBattery" { return nil }
        guard let current = (description["Current Capacity"] as? NSNumber)?.doubleValue,
              let maximum = (description["Max Capacity"] as? NSNumber)?.doubleValue,
              maximum > 0 else { return nil }
        let charging = (description["Is Charging"] as? NSNumber)?.boolValue ?? false
        let pluggedIn = (description["Power Source State"] as? String) == "AC Power"
        self.init(level: current / maximum, isCharging: charging, isPluggedIn: pluggedIn)
    }

    public var percentage: Int { Int((level * 100).rounded()) }

    /// The SF Symbol that best represents this state.
    public var symbolName: String {
        if isCharging { return "battery.100percent.bolt" }
        switch percentage {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    public var isLow: Bool { percentage <= 20 && !isPluggedIn }
}
