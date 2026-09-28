import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Spring parameters for the expand/collapse transition.
public struct NotchAnimation: Equatable, Sendable {
    /// Spring response in seconds (≈ duration); `dampingFraction` < 1 gives a slight, native-feeling overshoot.
    public var response: Double
    public var dampingFraction: Double

    public static let expand = NotchAnimation(response: 0.42, dampingFraction: 0.78)
    public static let collapse = NotchAnimation(response: 0.34, dampingFraction: 0.92)
    /// With "Reduce motion" enabled: short and without overshoot.
    public static let reducedMotion = NotchAnimation(response: 0.2, dampingFraction: 1)

    public static func forTransition(to state: NotchState, reduceMotion: Bool) -> NotchAnimation {
        if reduceMotion { return .reducedMotion }
        return state == .expanded ? .expand : .collapse
    }
}
