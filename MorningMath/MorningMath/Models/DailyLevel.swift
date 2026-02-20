import Foundation

struct DailyLevel: Codable, Equatable {
    let dayNumber: Int
    let questions: [MathQuestion]
}
