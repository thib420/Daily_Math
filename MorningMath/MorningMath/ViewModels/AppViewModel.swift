import Foundation
import Combine
import UserNotifications

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

    struct LevelCompletionSummary: Equatable {
        let day: Int
        let stars: Int
        let nextDay: Int?
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
    @Published private(set) var sessionElapsedTime: TimeInterval = 0
    @Published private(set) var levelCompletionSummary: LevelCompletionSummary?

    private let store: ProgressStore
    private let accessPolicy: DailyAccessPolicy
    private let generator: QuestionGenerator
    private let nowProvider: () -> Date
    private let calendar: Calendar
    private var timerCancellable: AnyCancellable?
    private var didAttemptNotificationSetup = false

    private static let dailyReminderNotificationID = "morningmath.daily.new-level"

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

    func configureDailyReminderNotification() async {
        guard !didAttemptNotificationSetup else {
            return
        }
        didAttemptNotificationSetup = true

        let center = UNUserNotificationCenter.current()
        let settings = await notificationSettings(from: center)

        switch settings.authorizationStatus {
        case .notDetermined:
            guard await requestNotificationAuthorization(from: center) else {
                return
            }
        case .authorized, .provisional, .ephemeral:
            break
        case .denied:
            return
        @unknown default:
            return
        }

        await scheduleDailyReminder(from: center)
    }

    func savedTime(for day: Int) -> TimeInterval? {
        progress.completedDayTimes[day]
    }

    func starRating(for day: Int) -> Int? {
        progress.completedDayTimes[day].map(starRating(forElapsed:))
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
        levelCompletionSummary = nil

        let questions = generator.questions(for: day, anchorDate: progress.startedAt)
        let isReplay = progress.completedDays.contains(day)
        let restoredIndex = progress.inProgressDay == day ? progress.inProgressQuestionIndex : 0
        let startIndex = isReplay ? 0 : min(restoredIndex, max(questions.count - 1, 0))
        let isNewTimerRun = isReplay || progress.inProgressDay != day

        activeSession = QuizSession(
            day: day,
            level: DailyLevel(dayNumber: day, questions: questions),
            currentQuestionIndex: startIndex,
            currentInput: "",
            feedback: nil
        )

        progress.inProgressDay = day
        progress.inProgressQuestionIndex = startIndex
        if isNewTimerRun {
            progress.inProgressElapsedTime = 0
        }
        if progress.inProgressStartedAt == nil || isNewTimerRun {
            progress.inProgressStartedAt = nowProvider()
        }
        store.save(progress)
        refreshSessionElapsedTime()
        startElapsedTimer()
    }

    func exitSession() {
        if let session = activeSession {
            progress.inProgressDay = session.day
            progress.inProgressQuestionIndex = session.currentQuestionIndex
            pauseElapsedTimer(saveToStore: false)
            store.save(progress)
        }
        activeSession = nil
        sessionElapsedTime = 0
        stopElapsedTimer()
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
            refreshSessionElapsedTime()
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
        levelCompletionSummary = nil
        store.save(fresh)
    }

    func dismissLevelCompletionSummary() {
        levelCompletionSummary = nil
    }

    func continueToNextLevelFromSummary() {
        let nextDay = levelCompletionSummary?.nextDay
        levelCompletionSummary = nil
        guard let day = nextDay else {
            return
        }
        startDay(day)
    }

    private func completeDay(day: Int) {
        pauseElapsedTimer(saveToStore: false)
        let elapsed = progress.inProgressDay == day ? progress.inProgressElapsedTime : 0
        progress.completedDays.insert(day)
        progress.completedDayTimes[day] = elapsed
        progress.lastCompletionDayStart = calendar.startOfDay(for: nowProvider())
        levelCompletionSummary = LevelCompletionSummary(
            day: day,
            stars: starRating(forElapsed: elapsed),
            nextDay: accessPolicy.nextDayToPlay(progress: progress)
        )
        if progress.inProgressDay == day {
            progress.inProgressDay = nil
            progress.inProgressQuestionIndex = 0
            progress.inProgressElapsedTime = 0
            progress.inProgressStartedAt = nil
        }
        store.save(progress)
        activeSession = nil
        sessionElapsedTime = 0
        stopElapsedTimer()
    }

    private func startElapsedTimer() {
        stopElapsedTimer()
        timerCancellable = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshSessionElapsedTime()
            }
    }

    private func stopElapsedTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func pauseElapsedTimer(saveToStore: Bool) {
        guard let inProgressDay = progress.inProgressDay,
              activeSession?.day == inProgressDay else {
            return
        }

        if let startedAt = progress.inProgressStartedAt {
            progress.inProgressElapsedTime += max(0, nowProvider().timeIntervalSince(startedAt))
            progress.inProgressStartedAt = nil
        }

        if saveToStore {
            store.save(progress)
        }
    }

    private func refreshSessionElapsedTime() {
        guard let session = activeSession, progress.inProgressDay == session.day else {
            sessionElapsedTime = 0
            return
        }

        let running = progress.inProgressStartedAt.map { max(0, nowProvider().timeIntervalSince($0)) } ?? 0
        sessionElapsedTime = progress.inProgressElapsedTime + running
    }

    private func starRating(forElapsed elapsed: TimeInterval) -> Int {
        let safeElapsed = max(elapsed, 0)

        if safeElapsed < 30 {
            return 3
        }

        if safeElapsed <= 40 {
            return 2
        }

        return 1
    }

    private func notificationSettings(from center: UNUserNotificationCenter) async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func requestNotificationAuthorization(from center: UNUserNotificationCenter) async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    private func scheduleDailyReminder(from center: UNUserNotificationCenter) async {
        await withCheckedContinuation { continuation in
            center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderNotificationID])

            let content = UNMutableNotificationContent()
            content.title = "New level unlocked"
            content.body = "Solve today's MorningMath challenge."
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = 10
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: Self.dailyReminderNotificationID,
                content: content,
                trigger: trigger
            )

            center.add(request) { _ in
                continuation.resume()
            }
        }
    }
}
