import XCTest
@testable import NotchMateKit

final class NotchStateMachineTests: XCTestCase {
    private var machine = NotchStateMachine(configuration: .init(openDelay: 0.1, closeDelay: 0.3))

    func testStartsCollapsed() {
        XCTAssertEqual(machine.state, .collapsed)
        XCTAssertFalse(machine.isPointerInside)
    }

    func testHoverSchedulesOpenThenExpands() {
        XCTAssertEqual(machine.handle(.pointerEntered), [.scheduleOpen(after: 0.1)])
        XCTAssertEqual(machine.state, .collapsed, "no expansion before the delay elapses")
        XCTAssertEqual(machine.handle(.openTimerFired), [.expand])
        XCTAssertEqual(machine.state, .expanded)
    }

    func testPassingOverNotchQuicklyDoesNotExpand() {
        machine.handle(.pointerEntered)
        XCTAssertEqual(machine.handle(.pointerExited), [.cancelOpen])
        XCTAssertEqual(machine.handle(.openTimerFired), [], "a stale timer is ignored")
        XCTAssertEqual(machine.state, .collapsed)
    }

    func testLeavingSchedulesCollapse() {
        expand()
        XCTAssertEqual(machine.handle(.pointerExited), [.scheduleClose(after: 0.3)])
        XCTAssertEqual(machine.state, .expanded)
        XCTAssertEqual(machine.handle(.closeTimerFired), [.collapse])
        XCTAssertEqual(machine.state, .collapsed)
    }

    func testReenteringBeforeCloseKeepsPanelOpen() {
        expand()
        machine.handle(.pointerExited)
        XCTAssertEqual(machine.handle(.pointerEntered), [.cancelClose])
        XCTAssertEqual(machine.handle(.closeTimerFired), [])
        XCTAssertEqual(machine.state, .expanded)
    }

    func testDuplicateEventsAreIgnored() {
        machine.handle(.pointerEntered)
        XCTAssertEqual(machine.handle(.pointerEntered), [])
        machine.handle(.openTimerFired)
        machine.handle(.pointerExited)
        XCTAssertEqual(machine.handle(.pointerExited), [])
    }

    func testZeroDelaysActImmediately() {
        machine.configuration = .init(openDelay: 0, closeDelay: 0)
        XCTAssertEqual(machine.handle(.pointerEntered), [.expand])
        XCTAssertEqual(machine.handle(.pointerExited), [.collapse])
    }

    func testNegativeDelaysAreTreatedAsZero() {
        let configuration = NotchStateMachine.Configuration(openDelay: -1, closeDelay: -5)
        XCTAssertEqual(configuration.openDelay, 0)
        XCTAssertEqual(configuration.closeDelay, 0)
    }

    func testHoverDisabledNeverExpandsOnHover() {
        machine.configuration.expandOnHover = false
        XCTAssertEqual(machine.handle(.pointerEntered), [])
        XCTAssertEqual(machine.state, .collapsed)
        XCTAssertEqual(machine.handle(.toggleRequested), [.expand], "explicit toggle still works")
    }

    func testToggleCancelsPendingTimers() {
        machine.handle(.pointerEntered)
        XCTAssertEqual(machine.handle(.toggleRequested), [.cancelOpen, .expand])
        machine.handle(.pointerExited)
        XCTAssertEqual(machine.handle(.toggleRequested), [.cancelClose, .collapse])
        XCTAssertFalse(machine.isOpenPending)
        XCTAssertFalse(machine.isClosePending)
    }

    func testCollapseRequestIsIdempotent() {
        expand()
        XCTAssertEqual(machine.handle(.collapseRequested), [.collapse])
        XCTAssertEqual(machine.handle(.collapseRequested), [])
    }

    func testOpenTimerIgnoredIfAlreadyExpanded() {
        machine.handle(.pointerEntered)
        machine.handle(.toggleRequested)
        XCTAssertEqual(machine.handle(.openTimerFired), [])
    }

    func testConfigurationFromSettings() {
        var settings = NotchSettings()
        settings.openDelay = 0.5
        settings.closeDelay = 1
        settings.expandOnHover = false
        let configuration = NotchStateMachine.Configuration(settings: settings)
        XCTAssertEqual(configuration, .init(expandOnHover: false, openDelay: 0.5, closeDelay: 1))
    }

    private func expand() {
        machine.handle(.pointerEntered)
        machine.handle(.openTimerFired)
        XCTAssertEqual(machine.state, .expanded)
    }
}
