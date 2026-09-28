import AppKit

/// Observes the mouse pointer system-wide.
///
/// Global monitors see events sent to other apps; local monitors see events sent
/// to NotchMate's own panel once it accepts mouse input. Together they cover every
/// position. Moving the pointer does not require Accessibility permission.
@MainActor
final class PointerMonitor {
    var onMove: (@MainActor (CGPoint) -> Void)?
    var onMouseDown: (@MainActor (CGPoint) -> Void)?

    private var monitors: [Any] = []

    func start() {
        guard monitors.isEmpty else { return }
        let moves: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        let clicks: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]

        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: moves, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.onMove?(NSEvent.mouseLocation) }
        }) {
            monitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: moves, handler: { [weak self] event in
            MainActor.assumeIsolated { self?.onMove?(NSEvent.mouseLocation) }
            return event
        }) {
            monitors.append(monitor)
        }
        // Only clicks in other apps: a click outside the panel dismisses it.
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: clicks, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.onMouseDown?(NSEvent.mouseLocation) }
        }) {
            monitors.append(monitor)
        }
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
    }
}
