import Foundation

struct MathQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: QuestionKind
    let prompt: String
    let correctAnswer: Int

    init(id: UUID = UUID(), kind: QuestionKind, prompt: String, correctAnswer: Int) {
        self.id = id
        self.kind = kind
        self.prompt = prompt
        self.correctAnswer = correctAnswer
    }
}
