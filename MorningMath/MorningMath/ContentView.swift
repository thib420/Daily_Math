import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.showCompletionScreen {
                CompletionView(onReset: viewModel.resetProgress)
            } else if let session = viewModel.activeSession {
                QuizView(
                    session: session,
                    onBack: viewModel.exitSession,
                    onDigit: viewModel.appendDigit,
                    onBackspace: viewModel.backspace,
                    onClear: viewModel.clearInput,
                    onEnter: viewModel.submitInput
                )
            } else {
                DayGridView(
                    nextUnlockText: viewModel.nextUnlockText(),
                    statusForDay: viewModel.status,
                    onSelectDay: viewModel.startDay
                )
            }
        }
    }
}
