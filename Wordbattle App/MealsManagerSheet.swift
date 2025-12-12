import SwiftUI

struct MealsManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: ProductStore

    @State private var mealName: String = ""
    @State private var items: [MealItem] = []
    @State private var newItemName: String = ""
    @State private var editingMeal: MealTemplate?
    @State private var editMealName: String = ""
    @State private var editItems: [MealItem] = []
    @State private var editNewItemName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Nieuwe maaltijd") {
                    TextField("Naam", text: $mealName)
                    HStack {
                        TextField("Productnaam", text: $newItemName)
                        Button { addItem() } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if !items.isEmpty {
                        ForEach(items) { item in
                            HStack {
                                Text(categoryIcon(for: item.category))
                                Text(item.name)
                                Spacer()
                                Text(item.category).foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .onDelete { offsets in items.remove(atOffsets: offsets) }
                    }
                    Button("Bewaar maaltijd") {
                        store.addMeal(name: mealName, items: items)
                        mealName = ""
                        items = []
                        newItemName = ""
                    }
                    .disabled(mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || items.isEmpty)
                }

                Section("Bestaande maaltijden") {
                    if store.meals.isEmpty {
                        Text("Nog geen maaltijden").foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(store.meals) { meal in
                            HStack {
                                Text(meal.name)
                                Spacer()
                                Text("\(meal.items.count) items").foregroundStyle(Theme.textSecondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                prepareEditState(for: meal)
                            }
                        }
                        .onDelete { offsets in
                            for offset in offsets where store.meals.indices.contains(offset) {
                                store.deleteMeal(store.meals[offset])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Maaltijden")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluiten") { dismiss() }
                }
            }
            .sheet(item: $editingMeal) { meal in
                NavigationStack {
                    Form {
                        Section("Naam") {
                            TextField("Naam", text: $editMealName)
                        }
                        Section("Items") {
                            HStack {
                                TextField("Productnaam", text: $editNewItemName)
                                Button { addEditItem() } label: {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .buttonStyle(.borderless)
                                .disabled(editNewItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            if !editItems.isEmpty {
                                ForEach(editItems) { item in
                                    HStack {
                                        Text(categoryIcon(for: item.category))
                                        Text(item.name)
                                        Spacer()
                                        Text(item.category).foregroundStyle(Theme.textSecondary)
                                    }
                                }
                                .onDelete { offsets in editItems.remove(atOffsets: offsets) }
                            }
                        }
                    }
                    .navigationTitle("Bewerk maaltijd")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Annuleer") { editingMeal = nil }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Bewaar") {
                                store.updateMeal(meal, name: editMealName, items: editItems)
                                editingMeal = nil
                            }
                            .disabled(editMealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editItems.isEmpty)
                        }
                    }
                }
            }
        }
    }

    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        items.append(MealItem(name: name, category: resolvedCategory(for: name)))
        newItemName = ""
    }

    private func addEditItem() {
        let name = editNewItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        editItems.append(MealItem(name: name, category: resolvedCategory(for: name)))
        editNewItemName = ""
    }

    private func resolvedCategory(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Onbekend" }
        if let stored = store.suggestedCategory(for: trimmed) {
            return canonicalCategory(stored)
        }
        if let guess = guessedCategory(for: trimmed) {
            return canonicalCategory(guess)
        }
        return "Onbekend"
    }

    private func prepareEditState(for meal: MealTemplate) {
        editMealName = meal.name
        editItems = meal.items
        editNewItemName = ""
        editingMeal = meal
    }
}
