import Foundation

/// All rectangles NotchMate needs to draw and hit-test the notch on one display.
///
/// Global rectangles use AppKit screen coordinates (bottom-left origin). The
/// `local…` rectangles are relative to the panel window with a top-left origin,
/// which is what SwiftUI uses inside the window.
public struct NotchLayout: Equatable, Sendable {
    /// Extra room around the expanded panel so its shadow is not clipped.
    public static let shadowPadding: CGFloat = 24
    /// Minimum horizontal gap between the expanded panel and the display edges.
    public static let screenMargin: CGFloat = 8
    /// The expanded panel is always at least this much wider than the notch on each side.
    public static let minimumSideExtension: CGFloat = 60

    public let screenFrame: CGRect
    public let scale: CGFloat
    public let isVirtual: Bool
    /// The collapsed shape; it covers the notch exactly.
    public let notchRect: CGRect
    /// The expanded panel, hanging from the top edge of the display.
    public let expandedRect: CGRect
    /// The borderless window hosting both states. It never changes size while
    /// animating, which keeps expand/collapse perfectly smooth.
    public let windowFrame: CGRect

    public init(placement: NotchPlacement, expandedSize: CGSize) {
        let screen = placement.screen
        let frame = screen.frame
        let scale = max(screen.backingScaleFactor, 1)
        let notch = Self.align(placement.notchRect, scale: scale)

        let maxWidth = max(frame.width - 2 * Self.screenMargin, notch.width)
        let minWidth = min(notch.width + 2 * Self.minimumSideExtension, maxWidth)
        let width = min(max(expandedSize.width, minWidth), maxWidth)
        let maxHeight = max(frame.height / 2, notch.height)
        let height = min(max(expandedSize.height, notch.height * 2), maxHeight)

        // Centre under the notch, then keep it on screen.
        var x = notch.midX - width / 2
        x = min(max(x, frame.minX + Self.screenMargin), frame.maxX - Self.screenMargin - width)
        let expanded = Self.align(CGRect(x: x, y: frame.maxY - height, width: width, height: height), scale: scale)
            .intersection(frame)

        let union = expanded.union(notch)
        let window = CGRect(
            x: union.minX - Self.shadowPadding,
            y: union.minY - Self.shadowPadding,
            width: union.width + 2 * Self.shadowPadding,
            height: union.height + Self.shadowPadding
        )
        let alignedWindow = Self.align(window, scale: scale).intersection(frame)

        self.screenFrame = frame
        self.scale = scale
        self.isVirtual = placement.isVirtual
        self.notchRect = notch
        self.expandedRect = expanded
        self.windowFrame = alignedWindow
    }

    /// The collapsed rectangle relative to the window, top-left origin.
    public var localNotchRect: CGRect { local(notchRect) }
    /// The expanded rectangle relative to the window, top-left origin.
    public var localExpandedRect: CGRect { local(expandedRect) }

    /// Converts a global rectangle to window-local, top-left-origin coordinates.
    public func local(_ rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX - windowFrame.minX,
            y: windowFrame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    /// Snaps a rectangle to the display's pixel grid so edges stay crisp on Retina
    /// and scaled resolutions. The rectangle only ever grows to the next pixel.
    public static func align(_ rect: CGRect, scale: CGFloat) -> CGRect {
        guard scale > 0, !rect.isNull, !rect.isInfinite else { return rect }
        let minX = (rect.minX * scale).rounded(.down) / scale
        let minY = (rect.minY * scale).rounded(.down) / scale
        let maxX = (rect.maxX * scale).rounded(.up) / scale
        let maxY = (rect.maxY * scale).rounded(.up) / scale
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
