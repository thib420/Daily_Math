import SwiftUI

struct NumericKeypadView: View {
    let onDigit: (String) -> Void
    let onBackspace: () -> Void
    let onClear: () -> Void
    let onEnter: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                actionButton("Clear", action: onClear)
                actionButton("⌫", action: onBackspace)
                actionButton("Enter", action: onEnter)
            }

            ForEach([["1", "2", "3", "4", "5"], ["6", "7", "8", "9", "0"]], id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { digit in
                        digitButton(digit)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
    }

    private func digitButton(_ digit: String) -> some View {
        Button {
            onDigit(digit)
        } label: {
            Text(digit)
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(AppTheme.panelLight.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(AppTheme.panelLight.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
