import SwiftUI

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.accent.opacity(0.15) : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? Theme.accent : Theme.textPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
