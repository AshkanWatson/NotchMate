import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public enum DisplayPreference: String, CaseIterable, Sendable {
    /// The display with a notch if there is one, otherwise the one with the menu bar.
    case automatic
    /// Always the built-in display (falls back to the menu bar display in clamshell mode).
    case builtIn
    /// Always the display with the menu bar.
    case primary
}

public enum PanelAppearance: String, CaseIterable, Sendable {
    /// Always black, so the panel looks like it grows out of the hardware notch.
    case notch
    /// Follows the system light/dark appearance.
    case system
}

/// User-configurable settings. Every value is clamped to a sane range on load.
public struct NotchSettings: Equatable, Sendable {
    public static let openDelayRange: ClosedRange<Double> = 0...1
    public static let closeDelayRange: ClosedRange<Double> = 0...2
    public static let expandedWidthRange: ClosedRange<Double> = 360...760
    public static let expandedHeightRange: ClosedRange<Double> = 120...260
    public static let hoverPaddingRange: ClosedRange<Double> = 0...40
    public static let virtualNotchWidthRange: ClosedRange<Double> = 120...260

    public var expandOnHover = true
    public var openDelay = 0.12
    public var closeDelay = 0.35
    public var expandedWidth = 520.0
    public var expandedHeight = 170.0
    public var hoverPadding = 8.0
    public var showOnDisplaysWithoutNotch = true
    public var virtualNotchWidth = 185.0
    public var displayPreference = DisplayPreference.automatic
    public var appearance = PanelAppearance.notch
    public var showClock = true
    public var showBattery = true
    public var showNowPlaying = true
    public var hapticFeedback = true

    public static let `default` = NotchSettings()

    public init() {}

    /// A copy with every numeric value clamped to its allowed range.
    public func sanitized() -> NotchSettings {
        var copy = self
        copy.openDelay = Self.clamp(openDelay, to: Self.openDelayRange)
        copy.closeDelay = Self.clamp(closeDelay, to: Self.closeDelayRange)
        copy.expandedWidth = Self.clamp(expandedWidth, to: Self.expandedWidthRange)
        copy.expandedHeight = Self.clamp(expandedHeight, to: Self.expandedHeightRange)
        copy.hoverPadding = Self.clamp(hoverPadding, to: Self.hoverPaddingRange)
        copy.virtualNotchWidth = Self.clamp(virtualNotchWidth, to: Self.virtualNotchWidthRange)
        return copy
    }

    public var expandedSize: CGSize { CGSize(width: expandedWidth, height: expandedHeight) }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return range.lowerBound }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
