import SwiftUI

struct CompletionView: View {
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Math Daily")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.panelDark)

            Text("\(DailyAccessPolicy.totalDays) days completed")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.panelDark)

            Text("Great consistency. You can now reset and start a new \(DailyAccessPolicy.totalDays)-day cycle.")
                .multilineTextAlignment(.center)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.panelDark.opacity(0.8))
                .padding(.horizontal)

            Button(action: onReset) {
                Text("Reset Progress")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.panelDark)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.vertical, 30)
    }
}
