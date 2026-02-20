import Foundation

enum QuestionKind: String, CaseIterable, Codable {
    case multiplication
    case division
    case percentage
    case probability

    var title: String {
        switch self {
        case .multiplication:
            return "Multiplication"
        case .division:
            return "Division"
        case .percentage:
            return "Percentage"
        case .probability:
            return "Probability"
        }
    }
}
