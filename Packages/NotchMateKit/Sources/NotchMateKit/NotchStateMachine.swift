import Foundation

public enum NotchState: String, Equatable, Sendable {
    /// Only the notch-sized shape is shown. On a notched display it is invisible.
    case collapsed
    /// The full panel is shown below the notch.
    case expanded
}

public enum NotchEvent: Equatable, Sendable {
    case pointerEntered
    case pointerExited
    case openTimerFired
    case closeTimerFired
    /// Explicit open/close from the menu bar item or a click.
    case toggleRequested
    /// Close immediately, e.g. a click outside, the display changed, or the app lost its notch.
    case collapseRequested
}

/// Side effects the caller must perform after handling an event.
public enum NotchEffect: Equatable, Sendable {
    case scheduleOpen(after: TimeInterval)
    case cancelOpen
    case scheduleClose(after: TimeInterval)
    case cancelClose
    case expand
    case collapse
}

/// The hover → expand → leave → collapse logic, free of timers and UI.
///
/// Timers are modelled as effects so behaviour is deterministic and testable: the
/// caller schedules them and feeds `openTimerFired` / `closeTimerFired` back in.
/// A short open delay avoids expanding when the pointer merely passes the top of
/// the screen; a close delay keeps the panel open if the pointer briefly slips out.
public struct NotchStateMachine: Equatable, Sendable {
    public struct Configuration: Equatable, Sendable {
        public var expandOnHover: Bool
        public var openDelay: TimeInterval
        public var closeDelay: TimeInterval

        public init(expandOnHover: Bool = true, openDelay: TimeInterval = 0.12, closeDelay: TimeInterval = 0.35) {
            self.expandOnHover = expandOnHover
            self.openDelay = max(openDelay, 0)
            self.closeDelay = max(closeDelay, 0)
        }

        public init(settings: NotchSettings) {
            self.init(expandOnHover: settings.expandOnHover, openDelay: settings.openDelay, closeDelay: settings.closeDelay)
        }
    }

    public var configuration: Configuration
    public private(set) var state: NotchState = .collapsed
    public private(set) var isPointerInside = false
    public private(set) var isOpenPending = false
    public private(set) var isClosePending = false

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    @discardableResult
    public mutating func handle(_ event: NotchEvent) -> [NotchEffect] {
        switch event {
        case .pointerEntered:
            return pointerEntered()
        case .pointerExited:
            return pointerExited()
        case .openTimerFired:
            guard isOpenPending else { return [] }
            isOpenPending = false
            guard isPointerInside, state == .collapsed else { return [] }
            return transition(to: .expanded)
        case .closeTimerFired:
            guard isClosePending else { return [] }
            isClosePending = false
            guard !isPointerInside, state == .expanded else { return [] }
            return transition(to: .collapsed)
        case .toggleRequested:
            let effects = cancelPendingOpen() + cancelPendingClose()
            return effects + transition(to: state == .expanded ? .collapsed : .expanded)
        case .collapseRequested:
            let effects = cancelPendingOpen() + cancelPendingClose()
            return effects + transition(to: .collapsed)
        }
    }

    private mutating func pointerEntered() -> [NotchEffect] {
        guard !isPointerInside else { return [] }
        isPointerInside = true
        var effects = cancelPendingClose()
        guard state == .collapsed, configuration.expandOnHover, !isOpenPending else { return effects }
        if configuration.openDelay == 0 {
            effects += transition(to: .expanded)
        } else {
            isOpenPending = true
            effects.append(.scheduleOpen(after: configuration.openDelay))
        }
        return effects
    }

    private mutating func pointerExited() -> [NotchEffect] {
        guard isPointerInside else { return [] }
        isPointerInside = false
        var effects = cancelPendingOpen()
        guard state == .expanded, !isClosePending else { return effects }
        if configuration.closeDelay == 0 {
            effects += transition(to: .collapsed)
        } else {
            isClosePending = true
            effects.append(.scheduleClose(after: configuration.closeDelay))
        }
        return effects
    }

    private mutating func transition(to newState: NotchState) -> [NotchEffect] {
        guard newState != state else { return [] }
        state = newState
        return [newState == .expanded ? .expand : .collapse]
    }

    private mutating func cancelPendingOpen() -> [NotchEffect] {
        guard isOpenPending else { return [] }
        isOpenPending = false
        return [.cancelOpen]
    }

    private mutating func cancelPendingClose() -> [NotchEffect] {
        guard isClosePending else { return [] }
        isClosePending = false
        return [.cancelClose]
    }
}
