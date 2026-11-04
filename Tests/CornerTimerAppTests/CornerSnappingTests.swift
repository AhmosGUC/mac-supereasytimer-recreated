import XCTest
@testable import CornerTimerApp

final class CornerSnappingTests: XCTestCase {
    private let panel = CGSize(width: 240, height: 76)
    /// Primary display with a 25 pt menu bar at the top (visible area ends at y = 875).
    private let primary = CGRect(x: 0, y: 0, width: 1440, height: 875)
    /// Secondary display left of the primary: negative x, no menu bar, Dock-height gap at the bottom.
    private let secondary = CGRect(x: -1920, y: 25, width: 1920, height: 1055)

    func testOriginInEachCornerOfPrimary() {
        XCTAssertEqual(CornerSnapping.origin(for: primary, corner: .topLeft, panelSize: panel), CGPoint(x: 16, y: 783))
        XCTAssertEqual(CornerSnapping.origin(for: primary, corner: .topRight, panelSize: panel), CGPoint(x: 1184, y: 783))
        XCTAssertEqual(CornerSnapping.origin(for: primary, corner: .bottomLeft, panelSize: panel), CGPoint(x: 16, y: 16))
        XCTAssertEqual(CornerSnapping.origin(for: primary, corner: .bottomRight, panelSize: panel), CGPoint(x: 1184, y: 16))
    }

    func testOriginOnSecondaryDisplayWithNegativeX() {
        XCTAssertEqual(CornerSnapping.origin(for: secondary, corner: .topLeft, panelSize: panel), CGPoint(x: -1904, y: 988))
        XCTAssertEqual(CornerSnapping.origin(for: secondary, corner: .bottomRight, panelSize: panel), CGPoint(x: -256, y: 41))
    }

    func testOriginHonorsCustomInset() {
        XCTAssertEqual(CornerSnapping.origin(for: primary, corner: .bottomLeft, panelSize: panel, inset: 0), CGPoint(x: 0, y: 0))
    }

    func testOriginScalesWithPanelSize() {
        let large = CGSize(width: 340, height: 108)
        XCTAssertEqual(CornerSnapping.origin(for: primary, corner: .topRight, panelSize: large), CGPoint(x: 1084, y: 751))
    }

    func testNearestCornerOnPrimary() {
        func corner(_ x: CGFloat, _ y: CGFloat) -> PanelCorner {
            CornerSnapping.nearestCorner(for: CGRect(origin: CGPoint(x: x, y: y), size: panel), in: primary)
        }
        XCTAssertEqual(corner(100, 700), .topLeft)
        XCTAssertEqual(corner(1100, 700), .topRight)
        XCTAssertEqual(corner(100, 100), .bottomLeft)
        XCTAssertEqual(corner(1100, 100), .bottomRight)
    }

    func testNearestCornerOnSecondaryDisplayWithNegativeX() {
        func corner(_ x: CGFloat, _ y: CGFloat) -> PanelCorner {
            CornerSnapping.nearestCorner(for: CGRect(origin: CGPoint(x: x, y: y), size: panel), in: secondary)
        }
        XCTAssertEqual(corner(-1800, 900), .topLeft)
        XCTAssertEqual(corner(-300, 40), .bottomRight)
        XCTAssertEqual(corner(-1800, 40), .bottomLeft)
    }

    func testNearestCornerTieGoesTopRight() {
        let centered = CGRect(x: primary.midX - 120, y: primary.midY - 38, width: 240, height: 76)
        XCTAssertEqual(CornerSnapping.nearestCorner(for: centered, in: primary), .topRight)
    }

    func testNearestCornerRoundTripsWithOrigin() {
        for corner in PanelCorner.allCases {
            let origin = CornerSnapping.origin(for: secondary, corner: corner, panelSize: panel)
            let frame = CGRect(origin: origin, size: panel)
            XCTAssertEqual(CornerSnapping.nearestCorner(for: frame, in: secondary), corner)
        }
    }

    func testClampedLeavesInsideFrameUntouched() {
        let frame = CGRect(x: 500, y: 400, width: 240, height: 76)
        XCTAssertEqual(CornerSnapping.clamped(frame, in: primary), frame)
    }

    func testClampedPullsOffscreenFrameBackIn() {
        let frame = CGRect(x: 1400, y: 800, width: 240, height: 76)
        XCTAssertEqual(CornerSnapping.clamped(frame, in: primary).origin, CGPoint(x: 1200, y: 799))
        let below = CGRect(x: -100, y: -50, width: 240, height: 76)
        XCTAssertEqual(CornerSnapping.clamped(below, in: primary).origin, CGPoint(x: 0, y: 0))
    }

    func testClampedIntoSecondaryAfterDisplayRemoved() {
        let frame = CGRect(x: -2500, y: 2000, width: 240, height: 76)
        XCTAssertEqual(CornerSnapping.clamped(frame, in: secondary).origin, CGPoint(x: -1920, y: 1004))
    }

    func testClampedFrameLargerThanAreaKeepsTopLeftVisible() {
        let area = CGRect(x: 0, y: 0, width: 100, height: 50)
        let frame = CGRect(x: 30, y: 30, width: 240, height: 76)
        XCTAssertEqual(CornerSnapping.clamped(frame, in: area).origin, CGPoint(x: 0, y: -26))
    }

    func testPanelSizesMatchSpec() {
        XCTAssertEqual(PanelSize.small.dimensions, CGSize(width: 180, height: 56))
        XCTAssertEqual(PanelSize.medium.dimensions, CGSize(width: 240, height: 76))
        XCTAssertEqual(PanelSize.large.dimensions, CGSize(width: 340, height: 108))
    }
}
