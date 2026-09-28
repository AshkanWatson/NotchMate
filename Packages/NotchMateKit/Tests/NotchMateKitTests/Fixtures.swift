import Foundation
@testable import NotchMateKit

/// Representative displays in their default "looks like" resolutions (points).
enum Fixtures {
    static func notchedMac(
        width: CGFloat,
        height: CGFloat,
        notchWidth: CGFloat = 185,
        notchHeight: CGFloat = 32,
        origin: CGPoint = .zero,
        scale: CGFloat = 2
    ) -> ScreenDescriptor {
        let side = (width - notchWidth) / 2
        let frame = CGRect(origin: origin, size: CGSize(width: width, height: height))
        var visible = frame
        visible.size.height -= 37 // notched Macs have a taller menu bar
        return ScreenDescriptor(
            displayID: 1,
            name: "Built-in Liquid Retina XDR Display",
            frame: frame,
            visibleFrame: visible,
            backingScaleFactor: scale,
            isBuiltIn: true,
            isPrimary: origin == .zero,
            safeAreaTop: notchHeight,
            auxiliaryTopLeftWidth: side,
            auxiliaryTopRightWidth: side
        )
    }

    static let macBookPro14 = notchedMac(width: 1512, height: 982)
    static let macBookPro16 = notchedMac(width: 1728, height: 1117)
    static let macBookAir13 = notchedMac(width: 1470, height: 956, notchWidth: 180)
    static let macBookAir15 = notchedMac(width: 1710, height: 1112, notchWidth: 180)
    /// 14" MacBook Pro in "More Space": same panel, more points (macOS still renders at 2x and downsamples).
    static let macBookPro14MoreSpace = notchedMac(width: 1800, height: 1169, notchWidth: 220, notchHeight: 38)

    static func externalDisplay(
        width: CGFloat = 2560,
        height: CGFloat = 1440,
        origin: CGPoint = .zero,
        isPrimary: Bool = true,
        menuBar: CGFloat = 25,
        scale: CGFloat = 1
    ) -> ScreenDescriptor {
        let frame = CGRect(origin: origin, size: CGSize(width: width, height: height))
        var visible = frame
        visible.size.height -= menuBar
        return ScreenDescriptor(
            displayID: 2,
            name: "Studio Display",
            frame: frame,
            visibleFrame: visible,
            backingScaleFactor: scale,
            isBuiltIn: false,
            isPrimary: isPrimary
        )
    }

    /// An Intel MacBook: built in, but no notch.
    static let intelMacBook = ScreenDescriptor(
        displayID: 3,
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875),
        backingScaleFactor: 2,
        isBuiltIn: true,
        isPrimary: true
    )
}
