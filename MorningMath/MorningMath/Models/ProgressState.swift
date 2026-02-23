import Foundation

struct ProgressState: Codable, Equatable {
    var completedDays: Set<Int>
    var lastCompletionDayStart: Date?
    var startedAt: Date
    var inProgressDay: Int?
    var inProgressQuestionIndex: Int

    init(
        completedDays: Set<Int> = [],
        lastCompletionDayStart: Date? = nil,
        startedAt: Date = Date(),
        inProgressDay: Int? = nil,
        inProgressQuestionIndex: Int = 0
    ) {
        self.completedDays = completedDays
        self.lastCompletionDayStart = lastCompletionDayStart
        self.startedAt = startedAt
        self.inProgressDay = inProgressDay
        self.inProgressQuestionIndex = inProgressQuestionIndex
    }

    private enum CodingKeys: String, CodingKey {
        case completedDays
        case lastCompletionDayStart
        case startedAt
        case inProgressDay
        case inProgressQuestionIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        completedDays = try container.decode(Set<Int>.self, forKey: .completedDays)
        lastCompletionDayStart = try container.decodeIfPresent(Date.self, forKey: .lastCompletionDayStart)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        inProgressDay = try container.decodeIfPresent(Int.self, forKey: .inProgressDay)
        inProgressQuestionIndex = try container.decodeIfPresent(Int.self, forKey: .inProgressQuestionIndex) ?? 0
    }

    var isCourseCompleted: Bool {
        completedDays.count >= DailyAccessPolicy.totalDays
    }
}
