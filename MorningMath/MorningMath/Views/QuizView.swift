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
    let elapsedTime: TimeInterval

    @State private var showSuccessAnimation = false
    @State private var successBurstProgress: CGFloat = 0
    @State private var successAnimationTask: Task<Void, Never>?

    private let screenInset: CGFloat = 14
    private var innerRadius: CGFloat {
        max(UIScreen.main.displayCornerRadius - screenInset, 16)
    }
    private var successParticleAngles: [Double] {
        [0, 30, 62, 98, 130, 165, 196, 228, 262, 296, 328].map { $0 * .pi / 180 }
    }

    var body: some View {
        GeometryReader { geo in
            let bottomPadding = max(screenInset - geo.safeAreaInsets.bottom, 0)

            VStack(spacing: 0) {
                // Question area
                VStack(spacing: 18) {
                    ZStack {
                        VStack(spacing: 2) {
                            Text("Level \(session.day)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary.opacity(0.9))

                            Text("\(session.currentQuestionIndex + 1)/\(session.level.questions.count)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(formattedElapsedTime)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary.opacity(0.85))
                        }

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
                        .overlay {
                            successBadge
                        }

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

                // Separator line
                Rectangle()
                    .fill(AppTheme.panelLight.opacity(0.4))
                    .frame(height: 1)
                    .padding(.horizontal, 20)

                // Keypad area
                NumericKeypadView(
                    onDigit: onDigit,
                    onBackspace: onBackspace,
                    onClear: onClear,
                    onEnter: onEnter,
                    cornerRadius: innerRadius
                )
                .padding(.bottom, bottomPadding)
            }
            .background(AppTheme.panel)
            .clipShape(Rectangle())
            .padding(.top, 8)
        }
        .background(AppTheme.panel.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .bottom)
        .onChange(of: session.currentQuestionIndex) { _ in
            triggerSuccessAnimation()
        }
        .onDisappear {
            successAnimationTask?.cancel()
        }
    }

    private var successBadge: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.success.opacity(showSuccessAnimation ? 0.35 : 0), lineWidth: 2)
                .frame(width: 62, height: 62)
                .scaleEffect(1 + (successBurstProgress * 0.95))
                .opacity(showSuccessAnimation ? (1 - successBurstProgress) : 0)

            Circle()
                .stroke(AppTheme.success.opacity(showSuccessAnimation ? 0.28 : 0), lineWidth: 2)
                .frame(width: 70, height: 70)
                .scaleEffect(1 + (successBurstProgress * 1.25))
                .opacity(showSuccessAnimation ? (0.85 - successBurstProgress) : 0)

            ForEach(Array(successParticleAngles.enumerated()), id: \.offset) { index, angle in
                Image(systemName: index % 2 == 0 ? "sparkle" : "circle.fill")
                    .font(.system(size: index % 2 == 0 ? 12 : 6, weight: .bold))
                    .foregroundStyle(AppTheme.success.opacity(0.95))
                    .offset(
                        x: CGFloat(cos(angle)) * (18 + successBurstProgress * 44),
                        y: CGFloat(sin(angle)) * (18 + successBurstProgress * 44)
                    )
                    .scaleEffect(0.65 + successBurstProgress * 0.65)
                    .opacity(showSuccessAnimation ? (1 - successBurstProgress) : 0)
            }

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, AppTheme.success],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: AppTheme.success.opacity(0.42), radius: 14, x: 0, y: 6)
                .scaleEffect(showSuccessAnimation ? 1 : 0.55)
                .opacity(showSuccessAnimation ? 1 : 0)
        }
        .offset(y: -56)
        .animation(.spring(response: 0.36, dampingFraction: 0.62), value: showSuccessAnimation)
        .animation(.easeOut(duration: 0.7), value: successBurstProgress)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func triggerSuccessAnimation() {
        successAnimationTask?.cancel()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        showSuccessAnimation = false
        successBurstProgress = 0

        withAnimation(.spring(response: 0.34, dampingFraction: 0.68)) {
            showSuccessAnimation = true
        }
        withAnimation(.easeOut(duration: 0.72)) {
            successBurstProgress = 1
        }

        successAnimationTask = Task {
            try? await Task.sleep(nanoseconds: 760_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.24)) {
                    showSuccessAnimation = false
                    successBurstProgress = 0
                }
            }
        }
    }

    private var formattedElapsedTime: String {
        let totalSeconds = max(Int(elapsedTime.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
