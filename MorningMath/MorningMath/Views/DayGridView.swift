import SwiftUI

struct DayGridView: View {
    let statusForDay: (Int) -> AppViewModel.DayStatus
    let savedTimeForDay: (Int) -> TimeInterval?
    let onSelectDay: (Int) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Math Daily")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.panelDark)

                Text("4 Math questions every day")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.panelDark.opacity(0.85))

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
            guard status != .locked else {
                return
            }
            onSelectDay(day)
        } label: {
            VStack(spacing: 6) {
                Text("\(day)")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(tileSubtitle(for: day, status: status))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(tileColor(for: status))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func tileColor(for status: AppViewModel.DayStatus) -> Color {
        switch status {
        case .completed:
            return AppTheme.panel
        case .available:
            return AppTheme.panel
        case .locked:
            return AppTheme.panelLight
        }
    }

    private func tileSubtitle(for day: Int, status: AppViewModel.DayStatus) -> String {
        if status == .completed {
            guard let elapsed = savedTimeForDay(day) else {
                return ""
            }

            let totalSeconds = max(Int(elapsed.rounded()), 0)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return "\(minutes):\(String(format: "%02d", seconds))"
        }

        return status == .locked ? "Locked" : "Play"
    }
}
