import SwiftUI

struct ContentView: View {
    @StateObject private var store = ProductStore()
    @State private var showAddListSheet = false
    @State private var showFavoritesSheet = false
    @State private var showMealsSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    Section {
                        ForEach(store.lists) { list in
                            NavigationLink {
                                ListDetailView(store: store, listID: list.id)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(list.name)
                                        .font(.system(size: 20, weight: .semibold))
                                    Text("\(list.products.filter { $0.isActive }.count) producten")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { offsets in
                            for offset in offsets {
                                guard store.lists.indices.contains(offset) else { continue }
                                store.deleteList(id: store.lists[offset].id)
                            }
                        }
                    } header: {
                        Text("Boodschappenlijsten")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Boodschappenlijsten")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddListSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Theme.accent)
                            .clipShape(Circle())
                            .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 10) {
                        Button {
                            showFavoritesSheet = true
                        } label: {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Theme.accent)
                                .clipShape(Circle())
                                .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                        }
                        Button {
                            showMealsSheet = true
                        } label: {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Theme.accentSecondary)
                                .clipShape(Circle())
                                .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddListSheet) {
                AddListSheet { name in
                    store.addList(name: name)
                }
            }
            .sheet(isPresented: $showFavoritesSheet) {
                FavoritesManagerSheet(store: store)
            }
            .sheet(isPresented: $showMealsSheet) {
                MealsManagerSheet(store: store)
            }
        }
    }
}

// MARK: Detail View
private struct ListDetailView: View {
    @ObservedObject var store: ProductStore
    let listID: UUID

    @State private var showAddProductSheet = false
    @State private var showFavorites = false
    @State private var showScanner = false
    @State private var showMealPicker = false
    @State private var highlightedDay: DayOfWeek?
    @State private var highlightedTop: Bool = false
    @State private var hideDone: Bool = false
    @State private var suggestionSheetDay: DayOfWeek?
    @State private var showUnplannedSuggestions: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    listContent
                }
                .animation(.default, value: store.lists)
            }
            .navigationTitle(listName)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddProductSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 10) {
                        Button {
                            showFavorites = true
                        } label: {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Theme.accent)
                                .clipShape(Circle())
                                .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                        }
                        Button {
                            showMealPicker = true
                        } label: {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Theme.accentSecondary)
                                .clipShape(Circle())
                                .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                        }
                        Text(listName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.leading, 8)
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan barcode", systemImage: "barcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showAddProductSheet) {
                AddProductSheet(store: store) { name, category, favorite, day, quantity, price in
                    let suggested = store.suggestedCategory(for: name) ?? guessedCategory(for: name)
                    let resolvedCategory = canonicalCategory(category.isEmpty ? (suggested ?? "Overig") : category)
                    let price = price ?? guessPrice(for: name, category: resolvedCategory)
                    let isPlanned = day != nil
                    let product = Product(
                        name: name,
                        category: resolvedCategory,
                        quantity: quantity,
                        estimatedPrice: price,
                        isFavorite: favorite,
                        isActive: true,
                        isPlanned: isPlanned,
                        isDone: false,
                        day: day
                    )
                    store.add(product: product, to: listID)
                    store.rememberCategory(for: name, category: resolvedCategory)
                }
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesSheet(
                    store: store,
                    onAddToTop: { template in
                        store.addFavoriteTemplateToList(template, listID: listID)
                    },
                    onToggleFavorite: { template in
                        store.removeFavoriteTemplate(template)
                    }
                )
            }
            .sheet(isPresented: $showMealPicker) {
                NavigationStack {
                    if store.meals.isEmpty {
                        VStack(spacing: 12) {
                            Text("Nog geen maaltijden").foregroundStyle(.secondary)
                            Button("Sluit") { showMealPicker = false }
                                .buttonStyle(.bordered)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            MealPickerView(meals: store.meals) { meal, day in
                                store.addMealToList(meal, day: day, listID: listID)
                                showMealPicker = false
                            }
                            .padding(.top, 12)
                            .padding(.horizontal)
                        }
                        .navigationTitle("Kies maaltijd")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Sluit") { showMealPicker = false }
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView { code in
                    guard let code else {
                        showScanner = false
                        return
                    }
                    Task { @MainActor in
                        let info = await store.infoForBarcode(code) ?? BarcodeInfo(name: code, category: "Barcode", imageURL: nil)
                        let product = Product(
                            name: info.name,
                            category: canonicalCategory(info.category),
                            isFavorite: false,
                            isActive: true,
                            isPlanned: false,
                            isDone: false,
                            day: nil,
                            imageURL: info.imageURL
                        )
                        store.add(product: product, to: listID)
                        store.rememberCategory(for: info.name, category: canonicalCategory(info.category))
                        showScanner = false
                    }
                }
            }
            .sheet(item: $suggestionSheetDay) { day in
                NavigationStack {
                    SuggestionSheetView(store: store, listID: listID, day: day)
                }
            }
            .sheet(isPresented: $showUnplannedSuggestions) {
                let ingredients = unplannedProducts.map { $0.name }
                NavigationStack {
                    GenericSuggestionSheet(title: "Alle producten", ingredients: ingredients)
                }
            }
        }
    }

    private var listName: String {
        store.list(by: listID)?.name ?? "Lijst"
    }

    private var unplannedProducts: [Product] {
        store.list(by: listID)?
            .products
            .filter { !$0.isPlanned && $0.isActive && (!hideDone || !$0.isDone) } ?? []
    }

    private var totalEstimate: Double? {
        guard let list = store.list(by: listID) else { return nil }
        let prices = list.products.compactMap { prod -> Double? in
            guard let p = prod.estimatedPrice else { return nil }
            return p * Double(prod.quantity)
        }
        guard !prices.isEmpty else { return nil }
        return prices.reduce(0, +)
    }

    private var hasMissingPrices: Bool {
        guard let list = store.list(by: listID) else { return true }
        return list.products.contains { $0.estimatedPrice == nil }
    }

    private func planned(for day: DayOfWeek) -> [Product] {
        store.planned(for: day, in: listID)
            .filter { !hideDone || !$0.isDone }
    }

    @ViewBuilder
    private var listContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Alle producten")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal)
                .overlay(alignment: .trailing) {
                    Button {
                        showUnplannedSuggestions = true
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Theme.accent)
                            .clipShape(Circle())
                            .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                    }
                    .padding(.trailing, 16)
                }

            Toggle("Verberg afgevinkt", isOn: $hideDone)
                .padding(.horizontal)
                .toggleStyle(SwitchToggleStyle(tint: Theme.accent))

            VStack(spacing: 10) {
                ForEach(unplannedProducts) { product in
                    DraggableRow(
                        product: product,
                        showDay: product.day != nil,
                        favoriteAction: { store.toggleFavorite($0, in: listID) },
                        removeAction: { store.remove($0, inFavoritesView: false, from: listID) },
                        markFavoriteAction: { store.markFavorite($0, in: listID) },
                        onToggleDone: { store.toggleDone($0, in: listID) },
                        onChangeQuantity: { prod, delta in store.changeQuantity(prod, delta: delta, in: listID) },
                        aiHint: productAIHint(product)
                    )
                }
                if unplannedProducts.isEmpty {
                    Text("Nog geen producten")
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.vertical, 8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(highlightedTop ? Theme.accent.opacity(0.2) : Theme.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.stroke, lineWidth: 1))
                    .shadow(color: Theme.shadow, radius: 12, x: 0, y: 6)
            )
            .padding(.horizontal)
            .dropDestination(for: UUID.self) { items, _ in
                guard let id = items.first else { return false }
                return unplanProduct(id: id)
            } isTargeted: { hovering in
                highlightedTop = hovering
            }

            Text("Weekplanning")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal)

            VStack(spacing: 14) {
                ForEach(DayOfWeek.allCases) { day in
                    DayDropCard(
                        title: day.title,
                        isHighlighted: highlightedDay == day,
                        products: planned(for: day),
                        onFavorite: { store.toggleFavorite($0, in: listID) },
                        onRemove: { store.remove($0, inFavoritesView: false, from: listID) },
                        onMarkFavorite: { store.markFavorite($0, in: listID) },
                        onToggleDone: { store.toggleDone($0, in: listID) },
                        onChangeQuantity: { prod, delta in store.changeQuantity(prod, delta: delta, in: listID) },
                        aiHintProvider: { productAIHint($0) },
                        onShowSuggestions: { suggestionSheetDay = day },
                        hideDone: hideDone
                    )
                    .dropDestination(for: UUID.self) { items, _ in
                        guard let id = items.first else { return false }
                        store.assign(productID: id, to: day, in: listID)
                        highlightedDay = nil
                        return true
                    } isTargeted: { hovering in
                        highlightedDay = hovering ? day : (highlightedDay == day ? nil : highlightedDay)
                    }
                }
            }
            .padding(.horizontal)

            if let total = totalEstimate {
                EstimateFooter(total: total, hasMissing: hasMissingPrices)
                    .padding(.horizontal)
            } else {
                EstimateFooter(total: nil, hasMissing: hasMissingPrices)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private func unplanProduct(id: UUID) -> Bool {
        guard let list = store.list(by: listID),
              let product = list.products.first(where: { $0.id == id }) else {
            return false
        }
        store.unplan(product, in: listID)
        return true
    }

    private func productAIHint(_ product: Product) -> String? {
        if let stored = store.suggestedCategory(for: product.name) {
            return "AI: \(stored)"
        }
        if let guess = guessedCategory(for: product.name) {
            return "AI: \(guess)"
        }
        return nil
    }
}

// MARK: Components
private struct AddListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    var onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Lijstnaam") {
                    TextField("Bijv. Week 42, Familie, BBQ", text: $name)
                }
            }
            .navigationTitle("Nieuwe lijst")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        onSave(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct AddProductSheet: View {
    @ObservedObject var store: ProductStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var category: String = categoryList.first ?? "Overig"
    @State private var isFavorite: Bool = false
    @State private var day: DayOfWeek? = nil
    @State private var quantity: Int = 1
    @State private var useAICategory = true
    @State private var isSaving = false

    var onSave: (String, String, Bool, DayOfWeek?, Int, Double?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Product")) {
                    TextField("Naam", text: $name)
                    Picker("Categorie", selection: $category) {
                        ForEach(categoryList, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    HStack {
                        Text("Aantal")
                        Spacer()
                        HStack(spacing: 10) {
                            Button {
                                quantity = max(1, quantity - 1)
                            } label: {
                                Image(systemName: "minus")
                                    .frame(width: 28, height: 28)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            Text("\(quantity)")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(minWidth: 32)

                            Button {
                                quantity = min(99, quantity + 1)
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width: 28, height: 28)
                                    .background(Theme.accent.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Toggle("Favoriet", isOn: $isFavorite)
                    Picker("Dag", selection: $day) {
                        Text("Geen dag").tag(DayOfWeek?.none)
                        ForEach(DayOfWeek.allCases) { day in
                            Text(day.title).tag(DayOfWeek?.some(day))
                        }
                    }
                    Toggle("Gebruik AI categorie bij opslaan", isOn: $useAICategory)
                }
            }
            .navigationTitle("Nieuw product")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { @MainActor in
                            isSaving = true
                            let heuristic = guessedCategory(for: name)
                            var finalCategory = category
                            var resolvedPrice: Double? = nil
                            if useAICategory, let ai = await AICategoryService.suggestCategory(for: name) {
                                finalCategory = ai
                            }
                            if let heuristic {
                                finalCategory = heuristic
                            }
                            let resolved = canonicalCategory(finalCategory.isEmpty ? "Onbekend" : finalCategory)
                            // Vraag prijs bij AI, val terug op heuristiek
                            let aiPrice = await AIPriceService.fetchPrice(for: name)
                            if aiPrice == nil {
                                resolvedPrice = guessPrice(for: name, category: resolved)
                            } else {
                                resolvedPrice = aiPrice
                            }
                            onSave(name, resolved, isFavorite, day, quantity, resolvedPrice)
                            isSaving = false
                            dismiss()
                        }
                    } label: {
                        if isSaving { ProgressView() } else { Text("Bewaar") }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .onChange(of: name) { newValue in
                if let suggested = store.suggestedCategory(for: newValue) ?? guessedCategory(for: newValue) {
                    category = suggested
                }
            }
        }
    }
}

private struct FavoritesSheet: View {
    @ObservedObject var store: ProductStore
    let onAddToTop: (Product) -> Void
    let onToggleFavorite: (Product) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var sortOption: FavoriteSortOption = .name
    @State private var showAddFavorite = false
    @State private var showFavoriteSuggestions = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    Section("Sorteer") {
                        Picker("Sorteer op", selection: $sortOption) {
                            ForEach(FavoriteSortOption.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Favorieten catalogus") {
                        ForEach(sortedFavorites) { product in
                            HStack(spacing: 12) {
                                Text(categoryIcon(for: product.category))
                                    .frame(width: 32, height: 32)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text(product.category)
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Button {
                                    onAddToTop(product)
                                    dismiss()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Theme.accent)
                                }
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Favorieten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluiten") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddFavorite = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showFavoriteSuggestions = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("AI receptsuggesties")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddFavorite) {
                AddFavoriteSheet { newName, price in
                    Task { @MainActor in
                        let cat = await autoCategory(for: newName)
                        store.addFavoriteTemplate(name: newName, category: cat, price: price)
                    }
                }
            }
            .sheet(isPresented: $showFavoriteSuggestions) {
                let ingredients = store.favorites().map { $0.name }
                NavigationStack {
                    GenericSuggestionSheet(title: "Favorieten", ingredients: ingredients)
                }
            }
        }
    }

    private var sortedFavorites: [Product] {
        switch sortOption {
        case .name:
            return store.favorites().sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .category:
            return store.favorites().sorted { $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending }
        }
    }

    private func autoCategory(for name: String) async -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Overig" }
        if let stored = store.suggestedCategory(for: trimmed) {
            return stored
        }
        if let ai = await AICategoryService.suggestCategory(for: trimmed) {
            return canonicalCategory(ai)
        }
        if let guess = guessedCategory(for: trimmed) {
            return canonicalCategory(guess)
        }
        return "Overig"
    }
}

private struct FavoritesManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: ProductStore
    @State private var editing: Product?
    @State private var editName: String = ""
    @State private var showScanner = false
    @State private var showAddFavorite = false
    @State private var sortOption: FavoriteSortOption = .name
    @State private var showFavoriteSuggestions: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Sorteer") {
                    Picker("Sorteer op", selection: $sortOption) {
                        ForEach(FavoriteSortOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    }

                Section("Favorieten catalogus") {
                    ForEach(sortedFavorites) { product in
                        HStack {
                            Text(categoryIcon(for: product.category))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                    .font(.system(size: 18, weight: .semibold))
                                Text(product.category)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "pencil")
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editing = product
                            editName = product.name
                        }
                    }
                    .onDelete { offsets in
                        for offset in offsets {
                            guard sortedFavorites.indices.contains(offset) else { continue }
                            let product = sortedFavorites[offset]
                            store.removeFavoriteTemplate(product)
                        }
                    }
                }
            }
            .navigationTitle("Favorieten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluiten") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddFavorite = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan", systemImage: "barcode.viewfinder")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showFavoriteSuggestions = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("AI receptsuggesties")
                        }
                    }
                }
            }
            .sheet(item: $editing) { product in
                NavigationStack {
                    Form {
                        Section("Bewerk favoriet") {
                            TextField("Naam", text: $editName)
                        }
                    }
                    .navigationTitle("Bewerk favoriet")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Annuleer") { editing = nil }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Bewaar") {
                                Task { @MainActor in
                                    let cat = await autoCategory(for: editName)
                                    store.updateFavoriteTemplate(product, name: editName, category: cat)
                                    editing = nil
                                }
                            }
                            .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView { code in
                    guard let code else {
                        showScanner = false
                        return
                    }
                    Task { @MainActor in
                        let info = await store.infoForBarcode(code) ?? BarcodeInfo(name: code, category: "Barcode", imageURL: nil)
                        let aiPrice = await AIPriceService.fetchPrice(for: info.name)
                        store.addFavoriteTemplate(name: info.name, category: canonicalCategory(info.category), price: aiPrice ?? guessPrice(for: info.name, category: info.category))
                        store.rememberCategory(for: info.name, category: info.category)
                        showScanner = false
                    }
                }
            }
            .sheet(isPresented: $showFavoriteSuggestions) {
                let ingredients = store.favorites().map { $0.name }
                NavigationStack {
                    GenericSuggestionSheet(title: "Favorieten", ingredients: ingredients)
                }
            }
            .sheet(isPresented: $showAddFavorite) {
                AddFavoriteSheet { newName, price in
                    Task { @MainActor in
                        let cat = await autoCategory(for: newName)
                        store.addFavoriteTemplate(name: newName, category: cat, price: price)
                    }
                }
            }
        }
    }

    private var sortedFavorites: [Product] {
        switch sortOption {
        case .name:
            return store.favorites().sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .category:
            return store.favorites().sorted { $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending }
        }
    }

    private func autoCategory(for name: String) async -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Overig" }
        if let stored = store.suggestedCategory(for: trimmed) {
            return stored
        }
        if let ai = await AICategoryService.suggestCategory(for: trimmed) {
            return canonicalCategory(ai)
        }
        if let guess = guessedCategory(for: trimmed) {
            return canonicalCategory(guess)
        }
        return "Overig"
    }
}

private struct AddFavoriteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var isSaving = false
    let onSave: (String, Double?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Nieuw favoriet") {
                    TextField("Naam", text: $name)
                }
            }
            .navigationTitle("Nieuw favoriet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        Task { @MainActor in
                            isSaving = true
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else {
                                isSaving = false
                                return
                            }
                            let aiPrice = await AIPriceService.fetchPrice(for: trimmed)
                            onSave(trimmed, aiPrice ?? guessPrice(for: trimmed, category: "Overig"))
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }
}

// MARK: Day card
private struct DayDropCard: View {
    let title: String
    let isHighlighted: Bool
    let products: [Product]
    let onFavorite: (Product) -> Void
    let onRemove: (Product) -> Void
    let onMarkFavorite: (Product) -> Void
    let onToggleDone: (Product) -> Void
    let onChangeQuantity: (Product, Int) -> Void
    let aiHintProvider: (Product) -> String?
    let onShowSuggestions: () -> Void
    let hideDone: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    onShowSuggestions()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Suggesties")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        LinearGradient(
                            colors: [Theme.accent, Theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Theme.shadow.opacity(0.4), radius: 8, x: 0, y: 4)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if products.isEmpty {
                Text("Sleep hierheen")
                    .foregroundStyle(Theme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(bgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    ForEach(products) { product in
                        if !hideDone || !product.isDone {
                            DraggableRow(
                                product: product,
                                showDay: false,
                                favoriteAction: onFavorite,
                                removeAction: { _ in onRemove(product) },
                                markFavoriteAction: onMarkFavorite,
                                onToggleDone: onToggleDone,
                                onChangeQuantity: { deltaProd, delta in onChangeQuantity(deltaProd, delta) },
                                aiHint: aiHintProvider(product)
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var bgColor: Color {
        isHighlighted ? Theme.accent.opacity(0.2) : Theme.cardBackground
    }
}

// MARK: Row
private struct DraggableRow: View {
    let product: Product
    let showDay: Bool
    let favoriteAction: (Product) -> Void
    let removeAction: (Product) -> Void
    let markFavoriteAction: (Product) -> Void
    let onToggleDone: (Product) -> Void
    let onChangeQuantity: (Product, Int) -> Void
    let aiHint: String?

    @State private var swipeOffset: CGFloat = 0
    private let swipeThreshold: CGFloat = 80

    var body: some View {
        let drag = DragGesture(minimumDistance: 10)
            .onChanged { value in
                swipeOffset = value.translation.width
            }
            .onEnded { value in
                let translation = value.translation.width
                if translation > swipeThreshold {
                    markFavoriteAction(product)
                } else if translation < -swipeThreshold {
                    removeAction(product)
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    swipeOffset = 0
                }
            }

        HStack(alignment: .center, spacing: 12) {
            Text(categoryIcon(for: product.category))
                .frame(width: 32, height: 32)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: Theme.shadow, radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 18, weight: .semibold))
                    .strikethrough(product.isDone, color: Theme.textSecondary)
                    .foregroundStyle(product.isDone ? Theme.textSecondary : Theme.textPrimary)
                Text(product.category)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                if let price = product.estimatedPrice {
                    Text("≈ €\(price * Double(product.quantity), specifier: "%.2f")")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text("Prijs onbekend")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Text("x\(product.quantity)")
                .font(.system(size: 16, weight: .semibold))
            if showDay, let day = product.day {
                Text(day.title.prefix(2))
                    .font(.caption)
                    .padding(6)
                    .background(Theme.accent.opacity(0.15))
                    .clipShape(Capsule())
            }
            Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                .foregroundColor(product.isFavorite ? .white : Theme.accent)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 30, height: 30)
                .background(product.isFavorite ? Theme.accent : Color.white)
                .clipShape(Circle())
                .shadow(color: Theme.shadow, radius: 4, x: 0, y: 2)
            Image(systemName: product.isDone ? "checkmark.circle.fill" : "checkmark.circle")
                .foregroundColor(product.isDone ? .white : Color.gray)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 30, height: 30)
                .background(product.isDone ? Color.green : Color.white)
                .clipShape(Circle())
                .shadow(color: Theme.shadow, radius: 4, x: 0, y: 2)
                .onTapGesture(count: 2) {
                    onToggleDone(product)
                }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .offset(x: swipeOffset)
        .gesture(drag)
        .draggable(product.id)
        .onTapGesture(count: 2) {
            onToggleDone(product)
        }
    }

    private var backgroundColor: Color {
        let intensity = min(Double(abs(swipeOffset)) / 150.0, 0.3)
        if swipeOffset > 0 {
            return Color.green.opacity(intensity)
        } else if swipeOffset < 0 {
            return Color.red.opacity(intensity)
        }
        return Color.white.opacity(0.9)
    }
}

private enum FavoriteSortOption: String, CaseIterable, Identifiable {
    case name
    case category

    var id: String { rawValue }
    var label: String {
        switch self {
        case .name: return "Naam"
        case .category: return "Categorie"
        }
    }
}

private struct EstimateFooter: View {
    let total: Double?
    let hasMissing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let total {
                Text("Geschatte totaalprijs: €\(total, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            } else {
                Text("Geschatte totaalprijs: onbekend")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(hasMissing ? "Schatting o.b.v. gevonden prijzen. Kan afwijken van de werkelijke prijzen." : "Schatting o.b.v. alle producten.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke, lineWidth: 1))
    }
}

enum Theme {
    static let accent = Color(red: 0.18, green: 0.55, blue: 0.98)
    static let accentSecondary = Color(red: 0.46, green: 0.78, blue: 1.0)
    static let background = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.93, green: 0.96, blue: 1.0),
            Color(red: 0.90, green: 0.94, blue: 1.0)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardBackground = Color.white.opacity(0.92)
    static let stroke = Color.white.opacity(0.5)
    static let shadow = Color.black.opacity(0.08)
    static let textPrimary = Color.black.opacity(0.9)
    static let textSecondary = Color.black.opacity(0.55)
}

#Preview {
    ContentView()
}
