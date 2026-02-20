import XCTest
@testable import MorningMath

final class QuestionGeneratorTests: XCTestCase {
    func testReturnsFourQuestionsInExpectedOrder() {
        let generator = QuestionGenerator(calendar: Calendar(identifier: .gregorian))
        let questions = generator.questions(for: 1, anchorDate: Date(timeIntervalSince1970: 1_700_000_000))

        XCTAssertEqual(questions.count, 4)
        XCTAssertEqual(questions.map(\.kind), [.multiplication, .division, .percentage, .probability])
    }

    func testGenerationIsDeterministicForDayAndAnchorDate() {
        let generator = QuestionGenerator(calendar: Calendar(identifier: .gregorian))
        let anchor = Date(timeIntervalSince1970: 1_700_000_000)

        let first = generator.questions(for: 4, anchorDate: anchor)
        let second = generator.questions(for: 4, anchorDate: anchor)

        XCTAssertEqual(first.map(\.prompt), second.map(\.prompt))
        XCTAssertEqual(first.map(\.correctAnswer), second.map(\.correctAnswer))
    }

    func testAllGeneratedAnswersAreIntegersAndDivisionQuestionsAreExact() {
        let generator = QuestionGenerator(calendar: Calendar(identifier: .gregorian))

        for day in 1...DailyAccessPolicy.totalDays {
            let questions = generator.questions(for: day, anchorDate: Date(timeIntervalSince1970: 1_700_000_000))

            for question in questions {
                XCTAssertNotNil(Int(String(question.correctAnswer)))

                if question.kind == .division {
                    let parts = question.prompt.components(separatedBy: " ")
                    XCTAssertTrue(parts.count >= 3)

                    if let dividend = Int(parts[0]), let divisor = Int(parts[2]) {
                        XCTAssertEqual(dividend / divisor, question.correctAnswer)
                        XCTAssertEqual(dividend % divisor, 0)
                    } else {
                        XCTFail("Division prompt could not be parsed: \(question.prompt)")
                    }
                }
            }
        }
    }

    func testPercentageAndProbabilityProduceIntegerAnswers() {
        let generator = QuestionGenerator(calendar: Calendar(identifier: .gregorian))

        for day in 1...DailyAccessPolicy.totalDays {
            let questions = generator.questions(for: day, anchorDate: Date(timeIntervalSince1970: 1_700_123_456))

            for question in questions where question.kind == .percentage || question.kind == .probability {
                XCTAssertGreaterThanOrEqual(question.correctAnswer, 0)
            }
        }
    }
}
