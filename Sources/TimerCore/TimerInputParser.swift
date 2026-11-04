import Foundation

/// A command produced by ``TimerInputParser``.
public enum TimerInput: Equatable, Sendable {
    /// Start a countdown of this length.
    case duration(seconds: Int)
    /// Count down to this wall-clock instant.
    case until(Date)
    /// Add (positive) or subtract (negative) time.
    case adjust(seconds: Int)
}

/// Why an input could not be turned into a ``TimerInput``.
public enum TimerInputError: Error, Equatable, Sendable {
    case empty
    case unrecognized
    case outOfRange
    case invalidClockTime

    /// Short, friendly, shown under the input field.
    public var userMessage: String {
        switch self {
        case .empty:            return "Type a time, like 25 or 1h 30m"
        case .unrecognized:     return "Try 25, 1h 30m, 1:30, 5pm or +5m"
        case .outOfRange:       return "Timers can be 1 second to 99 hours"
        case .invalidClockTime: return "That's not a valid time of day"
        }
    }
}

/// Turns free-form text into a ``TimerInput``.
///
/// Rules are tried in this order (see `docs/INPUT_SYNTAX.md` for the user-facing list):
/// adjustment, clock time, colon duration, unit duration, bare number (minutes).
///
/// ```swift
/// let parser = TimerInputParser()
/// parser.parse("25", now: now)        // .success(.duration(seconds: 1500))
/// parser.parse("1h 30m", now: now)    // .success(.duration(seconds: 5400))
/// parser.parse("5:30pm", now: now)    // .success(.until(<next 17:30>))
/// parser.parse("+5m", now: now)       // .success(.adjust(seconds: 300))
/// parser.parse("abc", now: now)       // .failure(.unrecognized)
/// ```
public struct TimerInputParser: Sendable {
    private let calendar: Calendar

    /// - Parameter calendar: Used to resolve clock times (its time zone decides what "5pm" means).
    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Parses `text`; `now` is the reference instant for clock times (the parser never reads the system clock).
    public func parse(_ text: String, now: Date) -> Result<TimerInput, TimerInputError> {
        let input = Self.normalize(text)
        if input.isEmpty { return .failure(.empty) }

        if let (sign, rest) = Self.splitAdjustment(input) {
            return duration(rest).map { .adjust(seconds: sign * $0) }
        }
        if let clock = Self.clockTime(input) {
            return clock.flatMap { nextOccurrence(hour: $0.hour, minute: $0.minute, after: now) }
                .map { .until($0) }
        }
        return duration(input).map { .duration(seconds: $0) }
    }

    // MARK: - Normalizing

    /// Trims, lowercases, and treats commas and the word "and" as whitespace.
    private static func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: ",", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .filter { $0 != "and" }
            .joined(separator: " ")
    }

    private static let adjustmentPrefixes: [(prefix: String, sign: Int)] = [
        ("+", 1), ("-", -1), ("add ", 1), ("plus ", 1), ("subtract ", -1), ("minus ", -1),
    ]

    private static func splitAdjustment(_ input: String) -> (sign: Int, rest: String)? {
        for (prefix, sign) in adjustmentPrefixes where input.hasPrefix(prefix) {
            return (sign, String(input.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces))
        }
        return nil
    }

    // MARK: - Clock times

    private static let twelveHour = regex("^(?:at )?([0-9]{1,2})(?::([0-9]{2}))? ?(am|pm|a|p)$")
    private static let twentyFourHour = regex("^at ([0-9]{1,2})(?::([0-9]{2}))?$")

    /// `nil` when `input` is not a clock-time expression at all.
    private static func clockTime(_ input: String) -> Result<(hour: Int, minute: Int), TimerInputError>? {
        switch input {
        case "noon": return .success((12, 0))
        case "midnight": return .success((0, 0))
        default: break
        }
        if let g = twelveHour.captures(in: input), let hour = g[0].flatMap(Int.init) {
            let minute = g[1].flatMap(Int.init) ?? 0
            guard (1...12).contains(hour), minute < 60 else { return .failure(.invalidClockTime) }
            let isPM = g[2]?.hasPrefix("p") == true
            return .success((hour % 12 + (isPM ? 12 : 0), minute))
        }
        if let g = twentyFourHour.captures(in: input), let hour = g[0].flatMap(Int.init) {
            let minute = g[1].flatMap(Int.init) ?? 0
            guard hour < 24, minute < 60 else { return .failure(.invalidClockTime) }
            return .success((hour, minute))
        }
        return nil
    }

    /// The next instant strictly after `now` at `hour:minute:00`.
    /// `.nextTime` makes a time skipped by a DST jump resolve to the first valid instant after the gap.
    private func nextOccurrence(hour: Int, minute: Int, after now: Date) -> Result<Date, TimerInputError> {
        let target = DateComponents(hour: hour, minute: minute, second: 0)
        guard let date = calendar.nextDate(after: now, matching: target, matchingPolicy: .nextTime) else {
            return .failure(.invalidClockTime)
        }
        return .success(date)
    }

    // MARK: - Durations

    private static let colonDuration = regex("^([0-9]+):([0-9]{2})(?::([0-9]{2}))?$")
    private static let unitsOnly = regex("^(?:[0-9]+(?:\\.[0-9]+)? ?[a-z]+ ?)+$")
    private static let unitGroup = regex("([0-9]+(?:\\.[0-9]+)?) ?([a-z]+)")
    private static let bareNumber = regex("^[0-9]+(?:\\.[0-9]+)?$")

    private static let unitSeconds: [String: Double] = {
        var table: [String: Double] = [:]
        for name in ["s", "sec", "secs", "second", "seconds"] { table[name] = 1 }
        for name in ["m", "min", "mins", "minute", "minutes"] { table[name] = 60 }
        for name in ["h", "hr", "hrs", "hour", "hours"] { table[name] = 3600 }
        return table
    }()

    /// Rules 3-5, rounded and range-checked (1...359 999 s).
    private func duration(_ input: String) -> Result<Int, TimerInputError> {
        guard let total = Self.rawSeconds(input) else { return .failure(.unrecognized) }
        let rounded = total.rounded()
        guard (1...359_999).contains(rounded) else { return .failure(.outOfRange) }
        return .success(Int(rounded))
    }

    private static func rawSeconds(_ input: String) -> Double? {
        if let g = colonDuration.captures(in: input) {
            // `M:SS` or `H:MM:SS`: every field after the first must be below 60.
            let fields = g.compactMap { $0.flatMap(Double.init) }
            guard fields.dropFirst().allSatisfy({ $0 < 60 }) else { return nil }
            return fields.reduce(0) { $0 * 60 + $1 }
        }
        if unitsOnly.captures(in: input) != nil {
            var seen = Set<Double>()
            var total = 0.0
            for g in unitGroup.allCaptures(in: input) {
                guard let amount = g[0].flatMap(Double.init),
                      let unit = g[1].flatMap({ unitSeconds[$0] }),
                      seen.insert(unit).inserted else { return nil }
                total += amount * unit
            }
            return total
        }
        if bareNumber.captures(in: input) != nil {
            return Double(input).map { $0 * 60 }
        }
        return nil
    }

    private static func regex(_ pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("Invalid built-in pattern: \(pattern)")
        }
    }
}

private extension NSRegularExpression {
    /// Capture groups of the first match (`nil` entries for groups that did not participate), or `nil` if no match.
    func captures(in text: String) -> [String?]? {
        firstMatch(in: text, range: NSRange(text.startIndex..., in: text)).map { groups($0, in: text) }
    }

    /// Capture groups of every non-overlapping match.
    func allCaptures(in text: String) -> [[String?]] {
        matches(in: text, range: NSRange(text.startIndex..., in: text)).map { groups($0, in: text) }
    }

    private func groups(_ match: NSTextCheckingResult, in text: String) -> [String?] {
        (1..<match.numberOfRanges).map { i in
            Range(match.range(at: i), in: text).map { String(text[$0]) }
        }
    }
}
