import SwiftUI

struct MealPickerView: View {
    let meals: [MealTemplate]
    var onSelect: (MealTemplate, DayOfWeek?) -> Void

    @State private var selectedMeal: MealTemplate?
    @State private var selectedDay: DayOfWeek? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kies dag")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    TagButton(title: "Geen", isSelected: selectedDay == nil) { selectedDay = nil }
                    ForEach(DayOfWeek.allCases) { day in
                        TagButton(title: day.title, isSelected: selectedDay == day) { selectedDay = day }
                    }
                }
                .padding(.vertical, 4)
            }

            Text("Kies maaltijd")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(meals) { meal in
                    Button {
                        selectedMeal = meal
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.name)
                                    .font(.system(size: 16, weight: .semibold))
                                Text("\(meal.items.count) items")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedMeal?.id == meal.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground).opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Zet op lijst") {
                if let meal = selectedMeal {
                    onSelect(meal, selectedDay)
                    selectedMeal = nil
                    selectedDay = nil
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedMeal == nil)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}
