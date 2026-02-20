import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    enum DayStatus: Equatable {
        case completed
        case available
        case locked
        case lockedUntilTomorrow
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

    var isLockedForToday: Bool {
        accessPolicy.isLockedForToday(progress: progress, now: nowProvider())
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

        if isLockedForToday {
            return .lockedUntilTomorrow
        }

        return .available
    }

    func nextUnlockText() -> String? {
        guard let date = accessPolicy.nextUnlockDate(progress: progress, now: nowProvider()) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return "Next level unlocks on \(formatter.string(from: date))."
    }

    func startDay(_ day: Int) {
        guard accessPolicy.canStart(day: day, progress: progress, now: nowProvider()) else {
            return
        }

        let questions = generator.questions(for: day, anchorDate: progress.startedAt)
        activeSession = QuizSession(
            day: day,
            level: DailyLevel(dayNumber: day, questions: questions),
            currentQuestionIndex: 0,
            currentInput: "",
            feedback: nil
        )
    }

    func exitSession() {
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
        store.save(progress)
        activeSession = nil
    }
}
