import XCTest
@testable import MorningMath

final class DailyAccessPolicyTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testOneLevelPerDayLockAfterCompletion() {
        let policy = DailyAccessPolicy(calendar: calendar)
        let today = date(2026, 2, 20, 10, 0)

        let progress = ProgressState(
            completedDays: [1],
            lastCompletionDayStart: calendar.startOfDay(for: today),
            startedAt: date(2026, 2, 20, 8, 0)
        )

        XCTAssertTrue(policy.isLockedForToday(progress: progress, now: today))
        XCTAssertFalse(policy.canStart(day: 2, progress: progress, now: today))
    }

    func testUnlockHappensAtNextCalendarDayMidnight() {
        let policy = DailyAccessPolicy(calendar: calendar)
        let now = date(2026, 2, 20, 14, 15)

        let progress = ProgressState(
            completedDays: [1],
            lastCompletionDayStart: calendar.startOfDay(for: now),
            startedAt: date(2026, 2, 20, 8, 0)
        )

        let unlock = policy.nextUnlockDate(progress: progress, now: now)
        XCTAssertEqual(unlock, date(2026, 2, 21, 0, 0))
    }

    func testSequentialGatingPreventsSkippingFutureDays() {
        let policy = DailyAccessPolicy(calendar: calendar)
        let now = date(2026, 2, 21, 9, 0)

        let progress = ProgressState(
            completedDays: [1],
            lastCompletionDayStart: date(2026, 2, 20, 0, 0),
            startedAt: date(2026, 2, 20, 8, 0)
        )

        XCTAssertTrue(policy.canStart(day: 2, progress: progress, now: now))
        XCTAssertFalse(policy.canStart(day: 3, progress: progress, now: now))
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
