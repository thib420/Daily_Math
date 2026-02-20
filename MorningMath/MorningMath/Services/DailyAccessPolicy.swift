import Foundation

struct DailyAccessPolicy {
    static let totalDays = 7

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func canStart(day: Int, progress: ProgressState, now: Date) -> Bool {
        guard (1...Self.totalDays).contains(day) else {
            return false
        }

        guard let nextDay = nextDayToPlay(progress: progress), nextDay == day else {
            return false
        }

        return !isLockedForToday(progress: progress, now: now)
    }

    func isLockedForToday(progress: ProgressState, now: Date) -> Bool {
        guard let lastCompletionDayStart = progress.lastCompletionDayStart else {
            return false
        }

        return calendar.startOfDay(for: now) == lastCompletionDayStart
    }

    func nextUnlockDate(progress: ProgressState, now: Date) -> Date? {
        guard isLockedForToday(progress: progress, now: now) else {
            return nil
        }

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return nil
        }

        return tomorrow
    }

    func nextDayToPlay(progress: ProgressState) -> Int? {
        (1...Self.totalDays).first { !progress.completedDays.contains($0) }
    }
}
