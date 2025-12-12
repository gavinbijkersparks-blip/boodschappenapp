import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

enum DayOfWeek: String, Codable, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    var id: String { rawValue }
    var title: String {
        switch self {
        case .monday: return "Maandag"
        case .tuesday: return "Dinsdag"
        case .wednesday: return "Woensdag"
        case .thursday: return "Donderdag"
        case .friday: return "Vrijdag"
        case .saturday: return "Zaterdag"
        case .sunday: return "Zondag"
        }
    }
}

struct Product: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String
    var quantity: Int
    var estimatedPrice: Double?
    var isFavorite: Bool
    var isActive: Bool
    var isDone: Bool
    var isPlanned: Bool
    var day: DayOfWeek?
    var createdAt: Date
    var imageURL: String?

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        quantity: Int = 1,
        estimatedPrice: Double? = nil,
        isFavorite: Bool = false,
        isActive: Bool = true,
        isPlanned: Bool = true,
        isDone: Bool = false,
        day: DayOfWeek? = nil,
        createdAt: Date = .now,
        imageURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = max(1, quantity)
        self.estimatedPrice = estimatedPrice
        self.isFavorite = isFavorite
        self.isActive = isActive
        self.isDone = isDone
        self.isPlanned = isPlanned
        self.day = day
        self.createdAt = createdAt
        self.imageURL = imageURL
    }
}

struct ShoppingList: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var products: [Product]

    init(id: UUID = UUID(), name: String, products: [Product]) {
        self.id = id
        self.name = name
        self.products = products
    }
}

struct MealTemplate: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var items: [MealItem]

    init(id: UUID = UUID(), name: String, items: [MealItem]) {
        self.id = id
        self.name = name
        self.items = items
    }
}

struct MealItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var category: String

    init(id: UUID = UUID(), name: String, category: String) {
        self.id = id
        self.name = name
        self.category = category
    }
}

struct StoreData: Codable {
    var lists: [ShoppingList]
    var favorites: [Product]
    var barcodeInfo: [String: BarcodeInfo]?
    var meals: [MealTemplate]
    var categoryMemory: [String: String]?
}

@MainActor
final class ProductStore: ObservableObject {
    @Published private(set) var lists: [ShoppingList] = []
    @Published private(set) var favoritesCatalog: [Product] = []
    @Published private var barcodeInfoCache: [String: BarcodeInfo] = [:]
    @Published private(set) var meals: [MealTemplate] = []
    @Published private var categoryMemory: [String: String] = [:]

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("shopping-lists.json")
    }()

    init() {
        load()
    }

    // MARK: Lists
    func addList(name: String) {
        lists.insert(ShoppingList(name: name, products: []), at: 0)
        save()
    }

    func deleteList(id: UUID) {
        lists.removeAll { $0.id == id }
        save()
    }

    func list(by id: UUID) -> ShoppingList? {
        lists.first { $0.id == id }
    }

    // MARK: Products
    func add(product: Product, to listID: UUID) {
        guard let idx = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[idx].products.insert(product, at: 0)
        save()
    }

    func changeQuantity(_ product: Product, delta: Int, in listID: UUID) {
        guard let li = lists.firstIndex(where: { $0.id == listID }),
              let pi = lists[li].products.firstIndex(of: product) else { return }
        let newQ = max(1, lists[li].products[pi].quantity + delta)
        lists[li].products[pi].quantity = newQ
        save()
    }

    func toggleFavorite(_ product: Product, in listID: UUID) {
        guard let li = lists.firstIndex(where: { $0.id == listID }),
              let pi = lists[li].products.firstIndex(of: product) else { return }
        lists[li].products[pi].isFavorite.toggle()
        if lists[li].products[pi].isFavorite {
            addToCatalog(from: lists[li].products[pi])
        } else {
            rebuildCatalog()
        }
        save()
    }

    func markFavorite(_ product: Product, in listID: UUID) {
        guard let li = lists.firstIndex(where: { $0.id == listID }),
              let pi = lists[li].products.firstIndex(of: product) else { return }
        lists[li].products[pi].isFavorite = true
        addToCatalog(from: lists[li].products[pi])
        save()
    }

    func toggleDone(_ product: Product, in listID: UUID) {
        guard let li = lists.firstIndex(where: { $0.id == listID }),
              let pi = lists[li].products.firstIndex(of: product) else { return }
        lists[li].products[pi].isDone.toggle()
        save()
    }

    func unplan(_ product: Product, in listID: UUID) {
        guard let li = lists.firstIndex(where: { $0.id == listID }),
              let pi = lists[li].products.firstIndex(of: product) else { return }
        lists[li].products[pi].isActive = true
        lists[li].products[pi].isDone = false
        lists[li].products[pi].isPlanned = false
        lists[li].products[pi].day = nil
        save()
    }

    func remove(_ product: Product, inFavoritesView: Bool, from listID: UUID) {
        guard let li = lists.firstIndex(where: { $0.id == listID }),
              let pi = lists[li].products.firstIndex(of: product) else { return }
        if inFavoritesView {
            lists[li].products.remove(at: pi)
        } else if lists[li].products[pi].isFavorite {
            lists[li].products[pi].isActive = false
            lists[li].products[pi].isPlanned = false
            lists[li].products[pi].day = nil
            lists[li].products[pi].isDone = false
        } else {
            lists[li].products.remove(at: pi)
        }
        save()
    }

    func favorites() -> [Product] {
        favoritesCatalog
    }

    func addFavoriteTemplateToList(_ template: Product, listID: UUID) {
        let product = Product(
            name: template.name,
            category: canonicalCategory(template.category),
            quantity: template.quantity,
            estimatedPrice: guessPrice(for: template.name, category: template.category),
            isFavorite: true,
            isActive: true,
            isPlanned: false,
            isDone: false,
            day: nil
        )
        add(product: product, to: listID)
        rememberCategory(for: template.name, category: template.category)
    }

    func addFavoriteTemplate(name: String, category: String, price: Double? = nil) {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = canonicalCategory(category.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !n.isEmpty else { return }
        if favoritesCatalog.contains(where: { $0.name.caseInsensitiveCompare(n) == .orderedSame && $0.category.caseInsensitiveCompare(c) == .orderedSame }) {
            return
        }
        let template = Product(
            name: n,
            category: c,
            estimatedPrice: price ?? guessPrice(for: n, category: c),
            isFavorite: true,
            isActive: true,
            isPlanned: false,
            isDone: false,
            day: nil
        )
        favoritesCatalog.insert(template, at: 0)
        rememberCategory(for: n, category: c)
        save()
    }

    func removeFavoriteTemplate(_ product: Product) {
        favoritesCatalog.removeAll { $0.id == product.id }
        save()
    }

    func updateFavoriteTemplate(_ product: Product, name: String, category: String) {
        guard let idx = favoritesCatalog.firstIndex(where: { $0.id == product.id }) else { return }
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return }
        favoritesCatalog[idx].name = n
        favoritesCatalog[idx].category = canonicalCategory(category)
        rememberCategory(for: n, category: favoritesCatalog[idx].category)
        save()
    }

    func planned(for day: DayOfWeek, in listID: UUID) -> [Product] {
        lists.first(where: { $0.id == listID })?.products.filter { $0.day == day && $0.isPlanned && $0.isActive } ?? []
    }

    func unplanned(in listID: UUID) -> [Product] {
        lists.first(where: { $0.id == listID })?.products.filter { !$0.isPlanned && $0.isActive } ?? []
    }

    func assign(productID: UUID, to day: DayOfWeek, in listID: UUID) {
        guard let li = lists.firstIndex(where: { $0.id == listID }),
              let pi = lists[li].products.firstIndex(where: { $0.id == productID }) else { return }
        lists[li].products[pi].isActive = true
        lists[li].products[pi].isDone = false
        lists[li].products[pi].day = day
        lists[li].products[pi].isPlanned = true
        save()
    }

    // MARK: Barcode
    func infoForBarcode(_ code: String) async -> BarcodeInfo? {
        if let cached = barcodeInfoCache[code], cached.category != "Barcode" {
            return BarcodeInfo(name: cached.name, category: canonicalCategory(cached.category), imageURL: cached.imageURL)
        }
        do {
            if let fetched = try await OpenFoodFactsService.fetchInfo(for: code) {
                let norm = BarcodeInfo(name: fetched.name, category: canonicalCategory(fetched.category), imageURL: fetched.imageURL)
                barcodeInfoCache[code] = norm
                save()
                return norm
            }
        } catch {
            print("Barcode lookup failed: \(error)")
        }
        if let cached = barcodeInfoCache[code] {
            return BarcodeInfo(name: cached.name, category: canonicalCategory(cached.category), imageURL: cached.imageURL)
        }
        return nil
    }

    // MARK: Meals
    func addMeal(name: String, items: [MealItem]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let cleaned = items.map { MealItem(name: $0.name, category: canonicalCategory($0.category)) }
        meals.insert(MealTemplate(name: trimmed, items: cleaned), at: 0)
        save()
    }

    func deleteMeal(_ meal: MealTemplate) {
        meals.removeAll { $0.id == meal.id }
        save()
    }

    func updateMeal(_ meal: MealTemplate, name: String, items: [MealItem]) {
        guard let idx = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        meals[idx].name = trimmed
        meals[idx].items = items.map { MealItem(name: $0.name, category: canonicalCategory($0.category)) }
        save()
    }

    func addMealToList(_ meal: MealTemplate, day: DayOfWeek?, listID: UUID) {
        guard let li = lists.firstIndex(where: { $0.id == listID }) else { return }
        let productsToAdd = meal.items.map {
            Product(name: $0.name, category: canonicalCategory($0.category), quantity: 1, estimatedPrice: guessPrice(for: $0.name, category: $0.category), isFavorite: false, isActive: true, isPlanned: day != nil, isDone: false, day: day)
        }
        lists[li].products.insert(contentsOf: productsToAdd, at: 0)
        save()
    }

    // MARK: AI Suggestions
    func recipeSuggestions(for day: DayOfWeek?, in listID: UUID) async -> [RecipeSuggestion] {
        guard let li = lists.firstIndex(where: { $0.id == listID }) else { return [] }
        let relevant = lists[li].products.filter { product in
            guard product.isActive else { return false }
            if let day { return product.isPlanned && product.day == day }
            return !product.isPlanned
        }
        let ingredients = relevant.map { $0.name }
        guard !ingredients.isEmpty else { return [] }
        do {
            let suggestions = try await AISuggestionsService.fetchSuggestions(ingredients: ingredients, dayTitle: day?.title ?? "Alle producten")
            return Array(suggestions.prefix(5))
        } catch {
            print("AI suggesties mislukt: \(error)")
            return []
        }
    }

    @discardableResult
    func addMissingIngredients(_ names: [String], to listID: UUID, plannedFor day: DayOfWeek?) -> [Product] {
        guard let li = lists.firstIndex(where: { $0.id == listID }) else { return [] }
        var existing = Set(lists[li].products.map { $0.name.lowercased() })
        var added: [Product] = []

        for raw in names {
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            guard !existing.contains(name.lowercased()) else { continue }
            let cat = suggestedCategory(for: name) ?? guessedCategory(for: name) ?? "Overig"
            let normalized = canonicalCategory(cat)
            let product = Product(
                name: name,
                category: normalized,
                estimatedPrice: guessPrice(for: name, category: normalized),
                isFavorite: false,
                isActive: true,
                isPlanned: day != nil,
                isDone: false,
                day: day
            )
            lists[li].products.insert(product, at: 0)
            rememberCategory(for: name, category: normalized)
            added.append(product)
            existing.insert(name.lowercased())
        }

        if !added.isEmpty {
            save()
        }
        return added
    }

    // MARK: Category memory
    func suggestedCategory(for name: String) -> String? {
        let key = nameKey(name)
        if let stored = categoryMemory[key] {
            return stored
        }
        if let guess = guessedCategory(for: name) {
            return canonicalCategory(guess)
        }
        return nil
    }

    func rememberCategory(for name: String, category: String) {
        let key = nameKey(name)
        categoryMemory[key] = canonicalCategory(category)
    }

    private func nameKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: Persistence
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            if let store = try? JSONDecoder().decode(StoreData.self, from: data) {
                lists = store.lists
                favoritesCatalog = store.favorites
                if let info = store.barcodeInfo { barcodeInfoCache = info }
                meals = store.meals
                categoryMemory = store.categoryMemory ?? [:]
            }
        } catch {
            print("Load error: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(StoreData(lists: lists, favorites: favoritesCatalog, barcodeInfo: barcodeInfoCache, meals: meals, categoryMemory: categoryMemory))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Save error: \(error)")
        }
    }

    // helpers
    private func addToCatalog(from product: Product) {
        if favoritesCatalog.contains(where: { $0.name == product.name && $0.category == product.category }) { return }
        let template = Product(name: product.name, category: canonicalCategory(product.category), quantity: 1, isFavorite: true, isActive: true, isPlanned: false, isDone: false, day: nil)
        favoritesCatalog.insert(template, at: 0)
        rememberCategory(for: product.name, category: template.category)
    }

    private func rebuildCatalog() {
        var set: Set<String> = []
        var combined: [Product] = []
        for list in lists {
            for product in list.products where product.isFavorite {
                let key = product.name.lowercased() + "|" + product.category.lowercased()
                if !set.contains(key) {
                    set.insert(key)
                    combined.append(Product(name: product.name, category: canonicalCategory(product.category), quantity: 1, isFavorite: true, isActive: true, isPlanned: false, isDone: false, day: nil))
                }
            }
        }
        favoritesCatalog = combined
    }
}

// UUID drag/drop transferable wrapper to avoid extending Foundation.UUID
struct DraggableUUID: Transferable {
    let id: UUID

    private enum UUIDTransferError: Error { case invalidData }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .utf8PlainText) { wrapper in
            wrapper.id.uuidString.data(using: .utf8) ?? Data()
        } importing: { data in
            guard let string = String(data: data, encoding: .utf8),
                  let uuid = UUID(uuidString: string) else {
                throw UUIDTransferError.invalidData
            }
            return DraggableUUID(id: uuid)
        }
    }
}
