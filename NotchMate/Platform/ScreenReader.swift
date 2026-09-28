import AppKit
import NotchMateKit

/// Reads display geometry from AppKit and converts it to `ScreenDescriptor`s.
enum ScreenReader {
    /// All connected displays; the first one hosts the menu bar.
    @MainActor
    static func currentScreens(options: LaunchOptions) -> [ScreenDescriptor] {
        let screens = NSScreen.screens.enumerated().map { index, screen in
            descriptor(for: screen, isPrimary: index == 0)
        }
        return applySimulation(to: screens, options: options)
    }

    @MainActor
    static func descriptor(for screen: NSScreen, isPrimary: Bool) -> ScreenDescriptor {
        let displayID = screen.displayID
        return ScreenDescriptor(
            displayID: displayID,
            name: screen.localizedName,
            frame: screen.frame,
            visibleFrame: screen.visibleFrame,
            backingScaleFactor: screen.backingScaleFactor,
            isBuiltIn: CGDisplayIsBuiltin(displayID) != 0,
            isPrimary: isPrimary,
            safeAreaTop: screen.safeAreaInsets.top,
            auxiliaryTopLeftWidth: screen.auxiliaryTopLeftArea?.width,
            auxiliaryTopRightWidth: screen.auxiliaryTopRightArea?.width
        )
    }

    /// Applies `--simulate-notch` / `--simulate-no-notch` so notch behaviour can be
    /// exercised on any Mac, including CI machines without a notch.
    static func applySimulation(to screens: [ScreenDescriptor], options: LaunchOptions) -> [ScreenDescriptor] {
        if options.simulateNoNotch {
            return screens.map { screen in
                var screen = screen
                screen.safeAreaTop = 0
                screen.auxiliaryTopLeftWidth = nil
                screen.auxiliaryTopRightWidth = nil
                return screen
            }
        }
        guard let size = options.simulatedNotchSize else { return screens }
        return screens.map { screen in
            guard screen.isPrimary else { return screen }
            var screen = screen
            let side = (screen.frame.width - size.width) / 2
            screen.safeAreaTop = size.height
            screen.auxiliaryTopLeftWidth = side
            screen.auxiliaryTopRightWidth = side
            return screen
        }
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        return number?.uint32Value ?? 0
    }
}
