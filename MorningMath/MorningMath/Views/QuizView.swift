import SwiftUI

struct QuizView: View {
    let session: AppViewModel.QuizSession
    let onBack: () -> Void
    let onDigit: (String) -> Void
    let onBackspace: () -> Void
    let onClear: () -> Void
    let onEnter: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 50, height: 50)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer()

                Text("Day \(session.day)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.panel)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            VStack(spacing: 18) {
                Text("\(session.currentQuestionIndex + 1)/\(session.level.questions.count)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)

                Text(session.currentQuestion.prompt)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .minimumScaleFactor(0.65)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                Text(session.currentInput.isEmpty ? "" : session.currentInput)
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 62)

                if let feedback = session.feedback {
                    Text(feedback.message)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(feedback.isError ? AppTheme.warning : AppTheme.success)
                }

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 360)
            .background(AppTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 14)

            NumericKeypadView(
                onDigit: onDigit,
                onBackspace: onBackspace,
                onClear: onClear,
                onEnter: onEnter
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }
}
