import AppKit
import SwiftUI
import NotchMateKit

/// Owns the notch panel and wires pointer input, the state machine and the UI together.
@MainActor
final class NotchController: ObservableObject {
    @Published private(set) var state: NotchState = .collapsed
    @Published private(set) var layout: NotchLayout?
    @Published private(set) var placement: NotchPlacement?

    let settingsModel: SettingsModel
    let battery = BatteryMonitor()
    let nowPlaying = NowPlayingService()
    var openSettings: @MainActor () -> Void = {}

    private let options: LaunchOptions
    private let screensProvider: @MainActor () -> [ScreenDescriptor]
    private let presentsPanel: Bool
    private var machine: NotchStateMachine
    private var tracker = HoverTracker()
    private var panel: NotchPanel?
    private let pointer = PointerMonitor()
    private var openTask: Task<Void, Never>?
    private var closeTask: Task<Void, Never>?
    private var watchdog: Timer?
    private var observers: [NSObjectProtocol] = []

    /// - Parameters:
    ///   - screensProvider: Injectable for tests; defaults to the real displays.
    ///   - presentsPanel: `false` in tests to skip creating a window.
    init(
        settingsModel: SettingsModel,
        options: LaunchOptions,
        screensProvider: (@MainActor () -> [ScreenDescriptor])? = nil,
        presentsPanel: Bool = true
    ) {
        self.settingsModel = settingsModel
        self.options = options
        self.screensProvider = screensProvider ?? { ScreenReader.currentScreens(options: options) }
        self.presentsPanel = presentsPanel
        self.machine = NotchStateMachine(configuration: .init(settings: settingsModel.settings))
        nowPlaying.isEnabled = !options.isUITesting
    }

    var settings: NotchSettings { settingsModel.settings }

    // MARK: Lifecycle

    func start() {
        settingsModel.onChange = { [weak self] settings in self?.apply(settings) }

        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateLayout() }
        })
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.panel?.orderFrontRegardless() }
        })

        pointer.onMove = { [weak self] point in self?.pointerMoved(to: point) }
        pointer.onMouseDown = { [weak self] point in self?.mouseDown(at: point) }
        pointer.start()
        battery.start()
        updateLayout()

        if options.startExpanded {
            send(.toggleRequested)
        }
    }

    func stop() {
        pointer.stop()
        battery.stop()
        nowPlaying.setActive(false)
        // Each token is only known to one of the two centres; removing it from the other is a no-op.
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
        openTask?.cancel()
        closeTask?.cancel()
        watchdog?.invalidate()
        panel?.orderOut(nil)
    }

    // MARK: Layout

    /// Re-detects the notch and repositions the panel. Called on launch, when
    /// displays are added/removed/rearranged or their resolution changes, and
    /// when settings change.
    func updateLayout() {
        let newPlacement = NotchDetector.placement(for: screensProvider(), settings: settings)
        placement = newPlacement

        guard let newPlacement else {
            send(.collapseRequested)
            layout = nil
            tracker.reset()
            panel?.orderOut(nil)
            return
        }

        let newLayout = NotchLayout(placement: newPlacement, expandedSize: settings.expandedSize)
        if newLayout != layout {
            if let old = layout, old.notchRect != newLayout.notchRect {
                // A different display or resolution: start fresh rather than animating across screens.
                send(.collapseRequested)
                tracker.reset()
            }
            layout = newLayout
        }
        presentPanel(frame: newLayout.windowFrame)
    }

    private func presentPanel(frame: CGRect) {
        guard presentsPanel else { return }
        let panel = self.panel ?? makePanel()
        panel.setFrame(frame, display: true)
        panel.ignoresMouseEvents = state == .collapsed
        panel.orderFrontRegardless()
    }

    private func makePanel() -> NotchPanel {
        let panel = NotchPanel()
        let root = NotchRootView(
            controller: self,
            settingsModel: settingsModel,
            battery: battery,
            nowPlaying: nowPlaying
        )
        let hostingView = NotchHostingView(rootView: root)
        hostingView.sizingOptions = []
        panel.contentView = hostingView
        self.panel = panel
        return panel
    }

    // MARK: Input

    func pointerMoved(to point: CGPoint) {
        guard let layout else { return }
        let zone = NotchHitTesting.activationZone(for: layout, state: state, padding: settings.hoverPadding)
        if let event = tracker.update(pointer: point, zone: zone) {
            send(event)
        }
    }

    func mouseDown(at point: CGPoint) {
        guard state == .expanded, let layout else { return }
        let zone = NotchHitTesting.activationZone(for: layout, state: .expanded, padding: settings.hoverPadding)
        if !NotchHitTesting.isPointer(point, inside: zone) {
            send(.collapseRequested)
        }
    }

    func toggle() {
        send(.toggleRequested)
    }

    func send(_ event: NotchEvent) {
        for effect in machine.handle(event) {
            perform(effect)
        }
    }

    // MARK: Effects

    private func perform(_ effect: NotchEffect) {
        switch effect {
        case .scheduleOpen(let delay):
            openTask?.cancel()
            openTask = send(.openTimerFired, after: delay)
        case .cancelOpen:
            openTask?.cancel()
            openTask = nil
        case .scheduleClose(let delay):
            closeTask?.cancel()
            closeTask = send(.closeTimerFired, after: delay)
        case .cancelClose:
            closeTask?.cancel()
            closeTask = nil
        case .expand:
            setState(.expanded)
        case .collapse:
            setState(.collapsed)
        }
    }

    private func send(_ event: NotchEvent, after delay: TimeInterval) -> Task<Void, Never> {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.send(event)
        }
    }

    private func setState(_ newState: NotchState) {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let spec = NotchAnimation.forTransition(to: newState, reduceMotion: reduceMotion)
        withAnimation(.spring(response: spec.response, dampingFraction: spec.dampingFraction)) {
            state = newState
        }

        let expanded = newState == .expanded
        panel?.ignoresMouseEvents = !expanded
        nowPlaying.setActive(expanded && settings.showNowPlaying)
        if expanded {
            if settings.hapticFeedback, !options.isUITesting {
                Haptics.tick()
            }
            startWatchdog()
        } else {
            watchdog?.invalidate()
            watchdog = nil
        }
    }

    /// Mouse events can be missed (e.g. the pointer jumps to another display while
    /// an app is in full screen), so while expanded the pointer is also sampled.
    private func startWatchdog() {
        watchdog?.invalidate()
        watchdog = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.pointerMoved(to: NSEvent.mouseLocation) }
        }
    }

    private func apply(_ settings: NotchSettings) {
        machine.configuration = .init(settings: settings)
        updateLayout()
        if state == .expanded {
            nowPlaying.setActive(settings.showNowPlaying)
        }
    }

    // MARK: Status

    /// A short, user-facing description of what was detected.
    var statusDescription: String {
        guard let placement else { return "No notch detected (virtual notch is off)" }
        let notch = placement.notchRect
        let size = "\(Int(notch.width.rounded()))×\(Int(notch.height.rounded())) pt"
        let name = placement.screen.name.isEmpty ? "display" : placement.screen.name
        return placement.isVirtual ? "Virtual notch (\(size)) on \(name)" : "Notch detected (\(size)) on \(name)"
    }
}
