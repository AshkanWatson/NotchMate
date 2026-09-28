import Foundation
import NotchMateKit

enum TestScreens {
    static let notched = ScreenDescriptor(
        displayID: 1,
        name: "Built-in Retina Display",
        frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 945),
        backingScaleFactor: 2,
        isBuiltIn: true,
        isPrimary: true,
        safeAreaTop: 32,
        auxiliaryTopLeftWidth: 663.5,
        auxiliaryTopRightWidth: 663.5
    )

    static let plain = ScreenDescriptor(
        displayID: 2,
        name: "External Display",
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055),
        backingScaleFactor: 1,
        isBuiltIn: false,
        isPrimary: true
    )
}
