import SwiftUI
import UIKit

extension UIScreen {
    /// Device screen corner radius via private `_displayCornerRadius` key.
    /// Falls back to 44 (common on modern iPhones) if unavailable.
    var displayCornerRadius: CGFloat {
        guard let radius = value(forKey: ["_displayCorner", "Radius"].joined()) as? CGFloat,
              radius > 0 else {
            return 44
        }
        return radius
    }
}

struct QuizView: View {
    let session: AppViewModel.QuizSession
    let onBack: () -> Void
    let onDigit: (String) -> Void
    let onBackspace: () -> Void
    let onClear: () -> Void
    let onEnter: () -> Void

    private let screenInset: CGFloat = 14
    private var innerRadius: CGFloat {
        max(UIScreen.main.displayCornerRadius - screenInset, 16)
    }

    var body: some View {
        GeometryReader { geo in
            let bottomPadding = max(screenInset - geo.safeAreaInsets.bottom, 0)

            VStack(spacing: 10) {
                VStack(spacing: 18) {
                    ZStack {
                        Text("\(session.currentQuestionIndex + 1)/\(session.level.questions.count)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)

                        HStack {
                            Button(action: onBack) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(width: 50, height: 50)
                                    .background(AppTheme.panelLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }

                            Spacer()

                            Text("Day \(session.day)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(AppTheme.panelLight)
                                .clipShape(Capsule())
                        }
                    }

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
                .padding(20)
                .frame(maxWidth: .infinity, minHeight: 360)
                .background(AppTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: innerRadius, style: .continuous))
                .padding(.horizontal, screenInset)
                .padding(.top, 8)

                NumericKeypadView(
                    onDigit: onDigit,
                    onBackspace: onBackspace,
                    onClear: onClear,
                    onEnter: onEnter,
                    cornerRadius: innerRadius
                )
                .padding(.horizontal, screenInset)
                .padding(.bottom, bottomPadding)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
