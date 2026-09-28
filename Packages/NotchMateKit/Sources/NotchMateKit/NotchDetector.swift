import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Where NotchMate draws its notch on a particular display.
public struct NotchPlacement: Equatable, Sendable {
    public var screen: ScreenDescriptor
    /// The notch rectangle in global coordinates. Its top edge is the top edge of the screen.
    public var notchRect: CGRect
    /// `true` when the display has no hardware notch and NotchMate draws a virtual one.
    public var isVirtual: Bool

    public init(screen: ScreenDescriptor, notchRect: CGRect, isVirtual: Bool) {
        self.screen = screen
        self.notchRect = notchRect
        self.isVirtual = isVirtual
    }
}

/// Detects hardware notches and picks the display NotchMate should live on.
public enum NotchDetector {
    /// Fallback notch width, used only if macOS reports a safe-area inset without
    /// the auxiliary menu bar areas (not observed in practice, but cheap to guard).
    public static let fallbackNotchWidth: CGFloat = 185
    /// Menu bar height used when the real one cannot be measured (auto-hidden menu bar).
    public static let fallbackMenuBarHeight: CGFloat = 24

    /// Returns the hardware notch rectangle of `screen` in global coordinates, or `nil`.
    ///
    /// macOS 12+ exposes the camera housing through two public APIs:
    /// - `safeAreaInsets.top` is the height of the notch (0 when there is none), and
    /// - `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` are the menu bar strips on
    ///   either side of it, so the notch is exactly the gap between them.
    ///
    /// Only widths are used, which keeps the calculation independent of whether the
    /// auxiliary rectangles are reported in local or global coordinates.
    public static func hardwareNotch(on screen: ScreenDescriptor) -> CGRect? {
        let height = screen.safeAreaTop
        guard height > 0 else { return nil }

        let frame = screen.frame
        let notchX: CGFloat
        let width: CGFloat
        if let left = screen.auxiliaryTopLeftWidth, let right = screen.auxiliaryTopRightWidth,
           left > 0, right > 0, left + right < frame.width {
            notchX = frame.minX + left
            width = frame.width - left - right
        } else {
            width = min(fallbackNotchWidth, frame.width)
            notchX = frame.midX - width / 2
        }
        // A "notch" wider than half the display is not a camera housing; distrust it.
        guard width > 0, width < frame.width / 2 else { return nil }
        return CGRect(x: notchX, y: frame.maxY - height, width: width, height: height)
    }

    /// A notch-shaped area drawn at the top centre of a display without a notch.
    /// It is exactly as tall as the menu bar so it reads as part of it.
    public static func virtualNotch(on screen: ScreenDescriptor, width: CGFloat) -> CGRect {
        let frame = screen.frame
        let height = screen.menuBarHeight ?? fallbackMenuBarHeight
        let clampedWidth = min(max(width, 80), frame.width / 2)
        return CGRect(x: frame.midX - clampedWidth / 2, y: frame.maxY - height, width: clampedWidth, height: height)
    }

    /// Chooses the display and notch rectangle NotchMate should use.
    ///
    /// - Returns: `nil` when no display qualifies, e.g. no display has a notch and
    ///   virtual notches are turned off in settings.
    public static func placement(for screens: [ScreenDescriptor], settings: NotchSettings) -> NotchPlacement? {
        guard !screens.isEmpty else { return nil }
        let primary = screens.first(where: \.isPrimary) ?? screens[0]
        let notched = screens.first { hardwareNotch(on: $0) != nil }

        let candidate: ScreenDescriptor
        switch settings.displayPreference {
        case .automatic:
            candidate = notched ?? primary
        case .builtIn:
            candidate = screens.first(where: \.isBuiltIn) ?? primary
        case .primary:
            candidate = primary
        }

        if let rect = hardwareNotch(on: candidate) {
            return NotchPlacement(screen: candidate, notchRect: rect, isVirtual: false)
        }
        guard settings.showOnDisplaysWithoutNotch else { return nil }
        let rect = virtualNotch(on: candidate, width: CGFloat(settings.virtualNotchWidth))
        return NotchPlacement(screen: candidate, notchRect: rect, isVirtual: true)
    }
}
