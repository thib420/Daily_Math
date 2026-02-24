import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
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
                        starRatingForDay: viewModel.starRating,
                        onSelectDay: viewModel.startDay
                    )
                }
            }

            if let summary = viewModel.levelCompletionSummary, viewModel.activeSession == nil {
                LevelCompletionPopupView(
                    summary: summary,
                    onContinue: viewModel.continueToNextLevelFromSummary
                )
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: viewModel.levelCompletionSummary != nil)
        .task {
            await viewModel.configureDailyReminderNotification()
        }
    }
}

private struct LevelCompletionPopupView: View {
    let summary: AppViewModel.LevelCompletionSummary
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Level \(summary.day) completed")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { index in
                        Image(systemName: index <= summary.stars ? "star.fill" : "star")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(index <= summary.stars ? AppTheme.warning : AppTheme.textPrimary.opacity(0.45))
                    }
                }

                Button(action: onContinue) {
                    Text(buttonTitle)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(AppTheme.panelDark)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.textPrimary.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 24)
        }
    }

    private var buttonTitle: String {
        if let nextDay = summary.nextDay {
            return "Go to level \(nextDay)"
        }

        return "Back to levels"
    }
}
