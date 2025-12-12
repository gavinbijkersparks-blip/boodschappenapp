import SwiftUI

struct MealsManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: ProductStore

    @State private var mealName: String = ""
    @State private var items: [MealItem] = []
    @State private var newItemName: String = ""
    @State private var newItemCategory: String = categoryList.first ?? "Overig"
    @State private var editingMeal: MealTemplate?
    @State private var editMealName: String = ""
    @State private var editItems: [MealItem] = []
    @State private var editNewItemName: String = ""
    @State private var editNewItemCategory: String = categoryList.first ?? "Overig"
    @State private var editingItem: MealItem?
    @State private var editItemName: String = ""
    @State private var editItemCategory: String = categoryList.first ?? "Overig"

    var body: some View {
        NavigationStack {
            Form {
                Section("Nieuwe maaltijd") {
                    TextField("Naam", text: $mealName)
                    HStack {
                        TextField("Productnaam", text: $newItemName)
                            .onChange(of: newItemName) { value in
                                if let suggested = store.suggestedCategory(for: value) ?? guessedCategory(for: value) {
                                    newItemCategory = canonicalCategory(suggested)
                                }
                            }
                        Picker("Categorie", selection: $newItemCategory) {
                            ForEach(categoryList, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .labelsHidden()
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
                        newItemCategory = categoryList.first ?? "Overig"
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
                                primeEditingState(with: meal)
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
                                    .onChange(of: editNewItemName) { value in
                                        if let suggested = store.suggestedCategory(for: value) ?? guessedCategory(for: value) {
                                            editNewItemCategory = canonicalCategory(suggested)
                                        }
                                    }
                                Picker("Categorie", selection: $editNewItemCategory) {
                                    ForEach(categoryList, id: \.self) { cat in
                                        Text(cat).tag(cat)
                                    }
                                }
                                .labelsHidden()
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
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingItem = item
                                        editItemName = item.name
                                        editItemCategory = canonicalCategory(item.category)
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
                    .onAppear { primeEditingState(with: meal) }
                }
            }
        }
    }

    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = newItemCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        items.append(MealItem(name: name, category: canonicalCategory(category.isEmpty ? "Onbekend" : category)))
        newItemName = ""
        newItemCategory = categoryList.first ?? "Overig"
    }

    private func addEditItem() {
        let name = editNewItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = editNewItemCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        editItems.append(MealItem(name: name, category: canonicalCategory(category.isEmpty ? "Onbekend" : category)))
        editNewItemName = ""
        editNewItemCategory = categoryList.first ?? "Overig"
    }

    private func primeEditingState(with meal: MealTemplate) {
        editingMeal = meal
        editMealName = meal.name
        editItems = meal.items
        editNewItemName = ""
        editNewItemCategory = categoryList.first ?? "Overig"
    }
}

