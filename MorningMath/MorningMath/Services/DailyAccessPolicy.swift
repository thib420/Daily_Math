import Foundation

struct DailyAccessPolicy {
    static let totalDays = 25

    init() {}

    func canStart(day: Int, progress: ProgressState) -> Bool {
        guard (1...Self.totalDays).contains(day) else {
            return false
        }

        if progress.completedDays.contains(day) {
            return true
        }

        guard let nextDay = nextDayToPlay(progress: progress), nextDay == day else {
            return false
        }

        return true
    }

    func nextDayToPlay(progress: ProgressState) -> Int? {
        (1...Self.totalDays).first { !progress.completedDays.contains($0) }
    }
}
