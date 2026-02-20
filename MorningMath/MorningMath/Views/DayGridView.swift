import SwiftUI

struct DayGridView: View {
    let nextUnlockText: String?
    let statusForDay: (Int) -> AppViewModel.DayStatus
    let onSelectDay: (Int) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Math Daily")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.panelDark)

                Text("One level per day. 4 questions each day.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.panelDark.opacity(0.85))

                if let nextUnlockText {
                    Text(nextUnlockText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.warning)
                }

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(1...DailyAccessPolicy.totalDays, id: \.self) { day in
                        dayTile(day: day, status: statusForDay(day))
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
        }
    }

    private func dayTile(day: Int, status: AppViewModel.DayStatus) -> some View {
        Button {
            onSelectDay(day)
        } label: {
            VStack(spacing: 8) {
                Text("\(day)")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))

                tileStatusLabel(status)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(tileBackgroundColor(status))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(status != .available)
    }

    private func tileBackgroundColor(_ status: AppViewModel.DayStatus) -> Color {
        switch status {
        case .completed:
            AppTheme.success
        case .available:
            AppTheme.panel
        case .locked:
            AppTheme.panelLight
        case .lockedUntilTomorrow:
            AppTheme.warning
        }
    }

    @ViewBuilder
    private func tileStatusLabel(_ status: AppViewModel.DayStatus) -> some View {
        switch status {
        case .completed:
            Label("Done", systemImage: "checkmark")
        case .available:
            Text("Play")
        case .locked:
            Label("Locked", systemImage: "lock.fill")
        case .lockedUntilTomorrow:
            Label("Tomorrow", systemImage: "clock")
        }
    }
}
