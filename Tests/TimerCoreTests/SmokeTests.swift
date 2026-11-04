import XCTest
@testable import TimerCore

final class SmokeTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(TimerCoreVersion.value, "0.1.0")
    }
}
