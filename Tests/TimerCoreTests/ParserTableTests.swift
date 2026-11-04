import XCTest
@testable import TimerCore

final class ParserTableTests: XCTestCase {
    private enum Expected {
        case duration(Int)
        case until(String)
        case adjust(Int)
        case error(TimerInputError)
    }

    private static func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    private static func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    private let now = date("2026-03-10T14:20:00Z")

    /// One line per case: input, expected result.
    private let table: [(String, Expected)] = [
        ("25", .duration(1500)),
        ("  25  ", .duration(1500)),
        ("1.5", .duration(90)),
        ("90s", .duration(90)),
        ("90 sec", .duration(90)),
        ("10 m", .duration(600)),
        ("10 minutes", .duration(600)),
        ("1 minute", .duration(60)),
        ("2h 30m", .duration(9000)),
        ("2h30m", .duration(9000)),
        ("1 hour and 30 minutes", .duration(5400)),
        ("1h, 5m, 10s", .duration(3910)),
        ("1.5h", .duration(5400)),
        ("1:30", .duration(90)),
        ("01:30", .duration(90)),
        ("1:02:03", .duration(3723)),
        ("99:59:59", .duration(359_999)),
        ("5pm", .until("2026-03-10T17:00:00Z")),
        ("5 PM", .until("2026-03-10T17:00:00Z")),
        ("5p", .until("2026-03-10T17:00:00Z")),
        ("5:30pm", .until("2026-03-10T17:30:00Z")),
        ("2pm", .until("2026-03-11T14:00:00Z")),
        ("2:15am", .until("2026-03-11T02:15:00Z")),
        ("12am", .until("2026-03-11T00:00:00Z")),
        ("12pm", .until("2026-03-11T12:00:00Z")),
        ("noon", .until("2026-03-11T12:00:00Z")),
        ("midnight", .until("2026-03-11T00:00:00Z")),
        ("at 17:30", .until("2026-03-10T17:30:00Z")),
        ("at 9", .until("2026-03-11T09:00:00Z")),
        ("+5m", .adjust(300)),
        ("+ 5 min", .adjust(300)),
        ("+5", .adjust(300)),
        ("-1h", .adjust(-3600)),
        ("add 5 min", .adjust(300)),
        ("plus 30s", .adjust(30)),
        ("subtract 2m", .adjust(-120)),
        ("minus 30 seconds", .adjust(-30)),
        ("", .error(.empty)),
        ("   ", .error(.empty)),
        ("abc", .error(.unrecognized)),
        ("5x", .error(.unrecognized)),
        ("+", .error(.unrecognized)),
        ("5m 3m", .error(.unrecognized)),
        ("1:75", .error(.unrecognized)),
        ("0", .error(.outOfRange)),
        ("0:00", .error(.outOfRange)),
        ("-0", .error(.outOfRange)),
        ("100:00:00", .error(.outOfRange)),
        ("13pm", .error(.invalidClockTime)),
        ("5:60pm", .error(.invalidClockTime)),
        ("at 24:00", .error(.invalidClockTime)),
    ]

    func testTable() {
        let parser = TimerInputParser(calendar: Self.calendar("UTC"))
        for (input, expected) in table {
            let want: Result<TimerInput, TimerInputError>
            switch expected {
            case .duration(let s): want = .success(.duration(seconds: s))
            case .until(let iso): want = .success(.until(Self.date(iso)))
            case .adjust(let s): want = .success(.adjust(seconds: s))
            case .error(let e): want = .failure(e)
            }
            XCTAssertEqual(parser.parse(input, now: now), want, "input: \"\(input)\"")
        }
    }

    /// 2026-03-08 02:30 does not exist in New York (clocks jump 02:00 -> 03:00).
    /// With `.nextTime` the parser returns the first valid instant after the gap: 03:00 EDT.
    func testDSTGapResolvesToFirstValidInstant() {
        let parser = TimerInputParser(calendar: Self.calendar("America/New_York"))
        let result = parser.parse("2:30am", now: Self.date("2026-03-08T01:30:00-05:00"))
        XCTAssertEqual(result, .success(.until(Self.date("2026-03-08T03:00:00-04:00"))))
    }

    func testFormattedDurationsRoundTrip() {
        let parser = TimerInputParser(calendar: Self.calendar("UTC"))
        let samples = Array(stride(from: 1, through: 359_999, by: 7)) + [359_999]
        for seconds in samples {
            let text = String(format: "%d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
            XCTAssertEqual(parser.parse(text, now: now), .success(.duration(seconds: seconds)), text)
        }
    }
}
