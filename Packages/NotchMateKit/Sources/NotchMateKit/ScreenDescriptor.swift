import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A platform-independent snapshot of a display, captured from `NSScreen`.
///
/// All rectangles use AppKit's global screen coordinate space: the origin is the
/// bottom-left corner of the primary display, and y grows upwards. Values are in
/// points, not pixels; `backingScaleFactor` converts between the two.
public struct ScreenDescriptor: Equatable, Sendable {
    /// The `CGDirectDisplayID` of the display.
    public var displayID: UInt32
    public var name: String
    public var frame: CGRect
    public var visibleFrame: CGRect
    public var backingScaleFactor: CGFloat
    /// Whether this is the Mac's built-in panel (the only kind of display that can have a notch).
    public var isBuiltIn: Bool
    /// Whether this display hosts the menu bar (the first entry of `NSScreen.screens`).
    public var isPrimary: Bool
    /// `NSScreen.safeAreaInsets.top`. Non-zero only on displays with a camera housing.
    public var safeAreaTop: CGFloat
    /// Width of `NSScreen.auxiliaryTopLeftArea`, the usable menu bar area left of the notch.
    public var auxiliaryTopLeftWidth: CGFloat?
    /// Width of `NSScreen.auxiliaryTopRightArea`, the usable menu bar area right of the notch.
    public var auxiliaryTopRightWidth: CGFloat?

    public init(
        displayID: UInt32,
        name: String = "",
        frame: CGRect,
        visibleFrame: CGRect? = nil,
        backingScaleFactor: CGFloat = 2,
        isBuiltIn: Bool = false,
        isPrimary: Bool = false,
        safeAreaTop: CGFloat = 0,
        auxiliaryTopLeftWidth: CGFloat? = nil,
        auxiliaryTopRightWidth: CGFloat? = nil
    ) {
        self.displayID = displayID
        self.name = name
        self.frame = frame
        self.visibleFrame = visibleFrame ?? frame
        self.backingScaleFactor = backingScaleFactor
        self.isBuiltIn = isBuiltIn
        self.isPrimary = isPrimary
        self.safeAreaTop = safeAreaTop
        self.auxiliaryTopLeftWidth = auxiliaryTopLeftWidth
        self.auxiliaryTopRightWidth = auxiliaryTopRightWidth
    }

    /// Height of the menu bar on this display, or `nil` when it is hidden
    /// (auto-hide, full screen) or the display does not show one.
    public var menuBarHeight: CGFloat? {
        let height = frame.maxY - visibleFrame.maxY
        return height > 0 ? height : nil
    }
}
