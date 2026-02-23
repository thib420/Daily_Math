import Foundation

struct ProgressState: Codable, Equatable {
    var completedDays: Set<Int>
    var completedDayTimes: [Int: TimeInterval]
    var lastCompletionDayStart: Date?
    var startedAt: Date
    var inProgressDay: Int?
    var inProgressQuestionIndex: Int
    var inProgressElapsedTime: TimeInterval
    var inProgressStartedAt: Date?

    init(
        completedDays: Set<Int> = [],
        completedDayTimes: [Int: TimeInterval] = [:],
        lastCompletionDayStart: Date? = nil,
        startedAt: Date = Date(),
        inProgressDay: Int? = nil,
        inProgressQuestionIndex: Int = 0,
        inProgressElapsedTime: TimeInterval = 0,
        inProgressStartedAt: Date? = nil
    ) {
        self.completedDays = completedDays
        self.completedDayTimes = completedDayTimes
        self.lastCompletionDayStart = lastCompletionDayStart
        self.startedAt = startedAt
        self.inProgressDay = inProgressDay
        self.inProgressQuestionIndex = inProgressQuestionIndex
        self.inProgressElapsedTime = inProgressElapsedTime
        self.inProgressStartedAt = inProgressStartedAt
    }

    private enum CodingKeys: String, CodingKey {
        case completedDays
        case completedDayTimes
        case lastCompletionDayStart
        case startedAt
        case inProgressDay
        case inProgressQuestionIndex
        case inProgressElapsedTime
        case inProgressStartedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        completedDays = try container.decode(Set<Int>.self, forKey: .completedDays)
        completedDayTimes = try container.decodeIfPresent([Int: TimeInterval].self, forKey: .completedDayTimes) ?? [:]
        lastCompletionDayStart = try container.decodeIfPresent(Date.self, forKey: .lastCompletionDayStart)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        inProgressDay = try container.decodeIfPresent(Int.self, forKey: .inProgressDay)
        inProgressQuestionIndex = try container.decodeIfPresent(Int.self, forKey: .inProgressQuestionIndex) ?? 0
        inProgressElapsedTime = try container.decodeIfPresent(TimeInterval.self, forKey: .inProgressElapsedTime) ?? 0
        inProgressStartedAt = try container.decodeIfPresent(Date.self, forKey: .inProgressStartedAt)
    }

    var isCourseCompleted: Bool {
        completedDays.count >= DailyAccessPolicy.totalDays
    }
}
