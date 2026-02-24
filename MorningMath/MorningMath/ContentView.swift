import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        Group {
            if let session = viewModel.activeSession {
                QuizView(
                    session: session,
                    onBack: viewModel.exitSession,
                    onDigit: viewModel.appendDigit,
                    onBackspace: viewModel.backspace,
                    onClear: viewModel.clearInput,
                    onEnter: viewModel.submitInput,
                    elapsedTime: viewModel.sessionElapsedTime
                )
            } else {
                DayGridView(
                    statusForDay: viewModel.status,
                    savedTimeForDay: viewModel.savedTime,
                    onSelectDay: viewModel.startDay
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await viewModel.configureDailyReminderNotification()
        }
    }
}
