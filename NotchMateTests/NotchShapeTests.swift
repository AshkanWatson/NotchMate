import SwiftUI
import XCTest
@testable import NotchMate

final class NotchShapeTests: XCTestCase {
    private let rect = CGRect(x: 0, y: 0, width: 200, height: 32)

    func testPathSpansFullWidthAtTopEdge() {
        let path = NotchShape.collapsed.path(in: rect)
        XCTAssertEqual(path.boundingRect.minX, rect.minX, accuracy: 0.01)
        XCTAssertEqual(path.boundingRect.maxX, rect.maxX, accuracy: 0.01)
        XCTAssertEqual(path.boundingRect.minY, rect.minY, accuracy: 0.01)
        XCTAssertEqual(path.boundingRect.maxY, rect.maxY, accuracy: 0.01)
    }

    func testBodyIsFilledAndCornersAreCutAway() {
        let path = NotchShape(topRadius: 6, bottomRadius: 10).path(in: rect)
        XCTAssertTrue(path.contains(CGPoint(x: 100, y: 16)), "centre")
        XCTAssertTrue(path.contains(CGPoint(x: 5, y: 1)), "shoulder reaches the top edge")
        XCTAssertFalse(path.contains(CGPoint(x: 1, y: 20)), "outside the shoulder")
        XCTAssertFalse(path.contains(CGPoint(x: 7, y: 31.5)), "rounded bottom-left corner")
        XCTAssertFalse(path.contains(CGPoint(x: 199, y: 31.5)), "rounded bottom-right corner")
    }

    func testRadiiAreClampedForTinyRects() {
        let tiny = CGRect(x: 0, y: 0, width: 10, height: 6)
        let path = NotchShape(topRadius: 50, bottomRadius: 50).path(in: tiny)
        XCTAssertFalse(path.isEmpty)
        XCTAssertLessThanOrEqual(path.boundingRect.width, 10.01)
    }

    func testAnimatableDataRoundTrip() {
        var shape = NotchShape.collapsed
        shape.animatableData = AnimatablePair(14, 30)
        XCTAssertEqual(shape.topRadius, NotchShape.expanded.topRadius)
        XCTAssertEqual(shape.bottomRadius, NotchShape.expanded.bottomRadius)
    }
}
