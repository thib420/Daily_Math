import XCTest
@testable import MorningMath

final class DailyAccessPolicyTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testCanPlayNextLevelImmediatelyAfterCompletion() {
        let policy = DailyAccessPolicy()

        let progress = ProgressState(
            completedDays: [1],
            startedAt: date(2026, 2, 20, 8, 0)
        )

        XCTAssertTrue(policy.canStart(day: 2, progress: progress))
    }

    func testSequentialGatingPreventsSkippingFutureDays() {
        let policy = DailyAccessPolicy()

        let progress = ProgressState(
            completedDays: [1],
            startedAt: date(2026, 2, 20, 8, 0)
        )

        XCTAssertTrue(policy.canStart(day: 2, progress: progress))
        XCTAssertFalse(policy.canStart(day: 3, progress: progress))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.calendar = calendar
        components.timeZone = TimeZone(secondsFromGMT: 0)

        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
