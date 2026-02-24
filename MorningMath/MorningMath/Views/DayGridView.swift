import SwiftUI

struct DayGridView: View {
    let statusForDay: (Int) -> AppViewModel.DayStatus
    let starRatingForDay: (Int) -> Int?
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

                tileStatusView(for: day, status: status)
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

    @ViewBuilder
    private func tileStatusView(for day: Int, status: AppViewModel.DayStatus) -> some View {
        if status == .completed {
            let stars = min(max(starRatingForDay(day) ?? 1, 1), 3)
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { index in
                    Image(systemName: index <= stars ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(index <= stars ? AppTheme.warning : AppTheme.textPrimary.opacity(0.55))
                }
            }
        } else {
            Text(status == .locked ? "Locked" : "Play")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary.opacity(0.9))
        }
    }
}
