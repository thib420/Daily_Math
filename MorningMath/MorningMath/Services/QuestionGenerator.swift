import Foundation

struct QuestionGenerator {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func questions(for day: Int, anchorDate: Date) -> [MathQuestion] {
        var random = SeededGenerator(seed: seed(for: day, anchorDate: anchorDate))
        let difficulty = Difficulty(day: day)

        return [
            multiplicationQuestion(difficulty: difficulty, random: &random),
            divisionQuestion(difficulty: difficulty, random: &random),
            percentageQuestion(difficulty: difficulty, random: &random),
            probabilityQuestion(difficulty: difficulty, random: &random)
        ]
    }

    private func seed(for day: Int, anchorDate: Date) -> UInt64 {
        let dayStamp = Int(calendar.startOfDay(for: anchorDate).timeIntervalSince1970)
        let mixed = (day &* 73_856_093) ^ (dayStamp &* 19_349_663)
        return UInt64(bitPattern: Int64(mixed))
    }

    private func multiplicationQuestion(difficulty: Difficulty, random: inout SeededGenerator) -> MathQuestion {
        let a = random.nextInt(in: difficulty.smallOperandRange)
        let b = random.nextInt(in: difficulty.smallOperandRange)

        return MathQuestion(
            kind: .multiplication,
            prompt: "\(a) × \(b) = ?",
            correctAnswer: a * b
        )
    }

    private func divisionQuestion(difficulty: Difficulty, random: inout SeededGenerator) -> MathQuestion {
        let divisor = random.nextInt(in: difficulty.divisorRange)
        let quotient = random.nextInt(in: difficulty.quotientRange)
        let dividend = divisor * quotient

        return MathQuestion(
            kind: .division,
            prompt: "\(dividend) ÷ \(divisor) = ?",
            correctAnswer: quotient
        )
    }

    private func percentageQuestion(difficulty: Difficulty, random: inout SeededGenerator) -> MathQuestion {
        let percent = difficulty.percentChoices[random.nextInt(in: 0...(difficulty.percentChoices.count - 1))]
        let requiredMultiple = percent / gcd(percent, 100)
        let multiplier = random.nextInt(in: difficulty.percentMultiplierRange)
        let answer = requiredMultiple * multiplier
        let base = answer * 100 / percent

        return MathQuestion(
            kind: .percentage,
            prompt: "What is \(percent)% of \(base)?",
            correctAnswer: answer
        )
    }

    private func probabilityQuestion(difficulty: Difficulty, random: inout SeededGenerator) -> MathQuestion {
        let percent = difficulty.probabilityPercentChoices[random.nextInt(in: 0...(difficulty.probabilityPercentChoices.count - 1))]
        let denominator = 100 / gcd(percent, 100)
        let multiplier = random.nextInt(in: difficulty.probabilityMultiplierRange)
        let total = denominator * multiplier
        let favorable = total * percent / 100
        let unfavorable = total - favorable

        return MathQuestion(
            kind: .probability,
            prompt: "Bag: \(favorable) red, \(unfavorable) blue. P(red) in % = ?",
            correctAnswer: percent
        )
    }

    private func gcd(_ lhs: Int, _ rhs: Int) -> Int {
        var a = lhs
        var b = rhs

        while b != 0 {
            let temp = a % b
            a = b
            b = temp
        }

        return abs(a)
    }
}

private struct Difficulty {
    let smallOperandRange: ClosedRange<Int>
    let divisorRange: ClosedRange<Int>
    let quotientRange: ClosedRange<Int>
    let percentChoices: [Int]
    let percentMultiplierRange: ClosedRange<Int>
    let probabilityPercentChoices: [Int]
    let probabilityMultiplierRange: ClosedRange<Int>

    init(day: Int) {
        switch day {
        case 1...2:
            smallOperandRange = 2...9
            divisorRange = 2...9
            quotientRange = 2...12
            percentChoices = [10, 20, 25, 50]
            percentMultiplierRange = 1...8
            probabilityPercentChoices = [20, 25, 50]
            probabilityMultiplierRange = 2...8
        case 3...4:
            smallOperandRange = 6...14
            divisorRange = 3...12
            quotientRange = 6...20
            percentChoices = [10, 20, 25, 40, 50]
            percentMultiplierRange = 3...12
            probabilityPercentChoices = [20, 25, 40, 50]
            probabilityMultiplierRange = 4...12
        default:
            smallOperandRange = 9...20
            divisorRange = 4...16
            quotientRange = 9...30
            percentChoices = [10, 20, 25, 40, 50]
            percentMultiplierRange = 6...20
            probabilityPercentChoices = [20, 25, 40, 50]
            probabilityMultiplierRange = 6...20
        }
    }
}

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x123456789abcdef : seed
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        precondition(range.lowerBound <= range.upperBound)

        let span = UInt64(range.upperBound - range.lowerBound + 1)
        let value = next() % span
        return range.lowerBound + Int(value)
    }

    private mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1442695040888963407
        return state
    }
}
