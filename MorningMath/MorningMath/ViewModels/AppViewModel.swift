import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    enum DayStatus: Equatable {
        case completed
        case available
        case locked
    }

    struct Feedback: Equatable {
        let message: String
        let isError: Bool
    }

    struct QuizSession: Equatable {
        let day: Int
        let level: DailyLevel
        var currentQuestionIndex: Int
        var currentInput: String
        var feedback: Feedback?

        var currentQuestion: MathQuestion {
            level.questions[currentQuestionIndex]
        }

        var progressText: String {
            "Question \(currentQuestionIndex + 1) / \(level.questions.count)"
        }
    }

    @Published private(set) var progress: ProgressState
    @Published private(set) var activeSession: QuizSession?

    private let store: ProgressStore
    private let accessPolicy: DailyAccessPolicy
    private let generator: QuestionGenerator
    private let nowProvider: () -> Date
    private let calendar: Calendar

    init(
        store: ProgressStore,
        accessPolicy: DailyAccessPolicy,
        generator: QuestionGenerator,
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.accessPolicy = accessPolicy
        self.generator = generator
        self.calendar = calendar
        self.nowProvider = nowProvider
        self.progress = store.load()
    }

    convenience init() {
        self.init(
            store: UserDefaultsProgressStore(),
            accessPolicy: DailyAccessPolicy(),
            generator: QuestionGenerator()
        )
    }

    var title: String {
        "Math Daily"
    }

    var showCompletionScreen: Bool {
        progress.isCourseCompleted && activeSession == nil
    }

    var nextDayToPlay: Int? {
        accessPolicy.nextDayToPlay(progress: progress)
    }

    func status(for day: Int) -> DayStatus {
        if progress.completedDays.contains(day) {
            return .completed
        }

        guard let nextDay = nextDayToPlay else {
            return .locked
        }

        guard day == nextDay else {
            return .locked
        }

        return .available
    }

    func startDay(_ day: Int) {
        guard accessPolicy.canStart(day: day, progress: progress) else {
            return
        }

        let questions = generator.questions(for: day, anchorDate: progress.startedAt)
        let isReplay = progress.completedDays.contains(day)
        let restoredIndex = progress.inProgressDay == day ? progress.inProgressQuestionIndex : 0
        let startIndex = isReplay ? 0 : min(restoredIndex, max(questions.count - 1, 0))

        activeSession = QuizSession(
            day: day,
            level: DailyLevel(dayNumber: day, questions: questions),
            currentQuestionIndex: startIndex,
            currentInput: "",
            feedback: nil
        )

        if !isReplay {
            progress.inProgressDay = day
            progress.inProgressQuestionIndex = startIndex
            store.save(progress)
        }
    }

    func exitSession() {
        if let session = activeSession, !progress.completedDays.contains(session.day) {
            progress.inProgressDay = session.day
            progress.inProgressQuestionIndex = session.currentQuestionIndex
            store.save(progress)
        }
        activeSession = nil
    }

    func appendDigit(_ digit: String) {
        guard var session = activeSession else {
            return
        }

        guard digit.count == 1, digit.first?.isWholeNumber == true else {
            return
        }

        guard session.currentInput.count < 6 else {
            return
        }

        session.currentInput.append(digit)
        session.feedback = nil
        activeSession = session
    }

    func clearInput() {
        guard var session = activeSession else {
            return
        }

        session.currentInput = ""
        session.feedback = nil
        activeSession = session
    }

    func backspace() {
        guard var session = activeSession else {
            return
        }

        if !session.currentInput.isEmpty {
            session.currentInput.removeLast()
            session.feedback = nil
            activeSession = session
        }
    }

    func submitInput() {
        guard var session = activeSession else {
            return
        }

        guard let answer = Int(session.currentInput) else {
            session.feedback = Feedback(message: "Enter a number first.", isError: true)
            activeSession = session
            return
        }

        let expected = session.currentQuestion.correctAnswer

        if answer == expected {
            if session.currentQuestionIndex == session.level.questions.count - 1 {
                completeDay(day: session.day)
                return
            }

            session.currentQuestionIndex += 1
            session.currentInput = ""
            session.feedback = nil
            activeSession = session
            progress.inProgressDay = session.day
            progress.inProgressQuestionIndex = session.currentQuestionIndex
            store.save(progress)
            return
        }

        session.currentInput = ""
        session.feedback = Feedback(message: "Wrong answer. Try again.", isError: true)
        activeSession = session
    }

    func resetProgress() {
        let fresh = ProgressState(startedAt: calendar.startOfDay(for: nowProvider()))
        progress = fresh
        activeSession = nil
        store.save(fresh)
    }

    private func completeDay(day: Int) {
        progress.completedDays.insert(day)
        progress.lastCompletionDayStart = calendar.startOfDay(for: nowProvider())
        if progress.inProgressDay == day {
            progress.inProgressDay = nil
            progress.inProgressQuestionIndex = 0
        }
        store.save(progress)
        activeSession = nil
    }
}
