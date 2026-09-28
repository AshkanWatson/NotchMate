import Foundation

/// Decides whether the mouse pointer is "at the notch".
public enum NotchHitTesting {
    /// The area that counts as hovering the notch for a given state.
    ///
    /// While collapsed this is the notch plus `padding` on the sides and below, so a
    /// slightly imprecise flick to the top of the screen still triggers. While
    /// expanded it is the whole panel plus `padding`, so the panel stays open while
    /// the pointer moves across it. Both zones extend one point past the top of the
    /// display, because the pointer can rest exactly on the top edge.
    public static func activationZone(for layout: NotchLayout, state: NotchState, padding: CGFloat) -> CGRect {
        let base = state == .expanded ? layout.expandedRect : layout.notchRect
        let pad = max(padding, 0)
        let top = layout.screenFrame.maxY + 1
        let bottom = base.minY - pad
        return CGRect(x: base.minX - pad, y: bottom, width: base.width + 2 * pad, height: top - bottom)
    }

    public static func isPointer(_ point: CGPoint, inside zone: CGRect) -> Bool {
        point.x >= zone.minX && point.x <= zone.maxX && point.y >= zone.minY && point.y <= zone.maxY
    }
}

/// Turns a stream of pointer positions into enter/exit events.
public struct HoverTracker: Equatable, Sendable {
    public private(set) var isInside = false

    public init() {}

    /// Feeds a new pointer position; returns an event only when the inside/outside status changes.
    public mutating func update(pointer: CGPoint, zone: CGRect) -> NotchEvent? {
        let inside = NotchHitTesting.isPointer(pointer, inside: zone)
        guard inside != isInside else { return nil }
        isInside = inside
        return inside ? .pointerEntered : .pointerExited
    }

    public mutating func reset() {
        isInside = false
    }
}
