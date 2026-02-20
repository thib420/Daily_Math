import Foundation

struct ProgressState: Codable, Equatable {
    var completedDays: Set<Int>
    var lastCompletionDayStart: Date?
    var startedAt: Date

    init(completedDays: Set<Int> = [], lastCompletionDayStart: Date? = nil, startedAt: Date = Date()) {
        self.completedDays = completedDays
        self.lastCompletionDayStart = lastCompletionDayStart
        self.startedAt = startedAt
    }

    var isCourseCompleted: Bool {
        completedDays.count >= DailyAccessPolicy.totalDays
    }
}
