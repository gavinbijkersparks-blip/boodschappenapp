import Foundation

struct RecipeSuggestion: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let steps: [String]
    let missingIngredients: [String]

    init(id: UUID = UUID(), title: String, steps: [String], missingIngredients: [String] = []) {
        self.id = id
        self.title = title
        self.steps = steps
        self.missingIngredients = missingIngredients
    }
}

enum AISuggestionsService {
    static let endpoint: String = "https://bijkersparks.nl/api/suggest.php"
    static let apiKey: String = ""
    private static let blockedKeywords: [String] = [
        "m&m",
        "m&m's",
        "snackmix",
        "candy",
        "snoep",
        "chocolade",
        "gummy",
        "lol", // defensief: vang gekke of grappenmakerij af
        "prank"
    ]

    private static let nonFoodKeywords: [String] = [
        "batterij",
        "batterijen",
        "schoonmaak",
        "wasmiddel",
        "zeep",
        "shampoo",
        "afwas",
        "poets",
        "wax",
        "kaars",
        "kaarsen",
        "zakdoek",
        "zakdoeken",
        "servet",
        "servetten",
        "papier",
        "folies",
        "folie"
    ]

    private static let lowRecipeValueKeywords: [String] = [
        "snoep",
        "candy",
        "chocolade",
        "koek",
        "koekje",
        "koekjes",
        "snack",
        "chips",
        "repen",
        "reep"
    ]

    struct RequestBody: Codable {
        let ingredients: [String]
        let day: String
        let language: String
    }

    struct ResponseBody: Codable {
        let suggestions: [RawSuggestion]
    }

    struct RawSuggestion: Codable {
        let id: String
        let title: String
        let steps: [String]
        let missingIngredients: [String]
    }

    static func fetchSuggestions(ingredients: [String], dayTitle: String) async throws -> [RecipeSuggestion] {
        let relevantIngredients = prioritizedRelevantIngredients(from: ingredients)
        guard !endpoint.isEmpty, let url = URL(string: endpoint) else {
            return mockSuggestions(ingredients: relevantIngredients, dayTitle: dayTitle)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let body = RequestBody(ingredients: relevantIngredients, day: dayTitle, language: "nl")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        if let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data) {
            let filtered = decoded.suggestions
                .filter { isAcceptable($0, ingredients: relevantIngredients) }
                .map { raw in
                    RecipeSuggestion(
                        id: UUID(uuidString: raw.id) ?? UUID(),
                        title: raw.title,
                        steps: raw.steps,
                        missingIngredients: raw.missingIngredients
                    )
                }
            return filtered
        }
        return mockSuggestions(ingredients: relevantIngredients, dayTitle: dayTitle)
    }

    private static func isAcceptable(_ suggestion: RawSuggestion, ingredients: [String]) -> Bool {
        let haystack = (suggestion.title + " " + suggestion.steps.joined(separator: " ")).lowercased()
        if blockedKeywords.contains(where: { haystack.contains($0) }) {
            return false
        }

        let cleanedIngredients = ingredients.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !cleanedIngredients.isEmpty else { return true }
        let allowedMissing = max(1, cleanedIngredients.count / 2)
        if suggestion.missingIngredients.count > allowedMissing {
            return false
        }
        let usedCount = cleanedIngredients.filter { haystack.contains($0) }.count
        let ingredientCoverage = Double(usedCount) / Double(cleanedIngredients.count)
        return ingredientCoverage >= 0.4 // eist dat minstens ~40% van de gekozen producten terugkomen
    }

    /// Filtert alleen bruikbare ingrediënten voor recepten, zodat snoep of niet-eetbare items de score niet verlagen.
    private static func prioritizedRelevantIngredients(from ingredients: [String]) -> [String] {
        let normalized = ingredients
            .map { $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        let withoutNonFood = normalized.filter { ingredient in
            !nonFoodKeywords.contains(where: { ingredient.contains($0) })
        }

        let withoutTreats = withoutNonFood.filter { ingredient in
            !lowRecipeValueKeywords.contains(where: { ingredient.contains($0) })
        }

        if !withoutTreats.isEmpty { return withoutTreats }
        if !withoutNonFood.isEmpty { return withoutNonFood }
        return normalized
    }

    private static func mockSuggestions(ingredients: [String], dayTitle: String) -> [RecipeSuggestion] {
        let joined = ingredients.joined(separator: ", ")
        return [
            RecipeSuggestion(
                title: "Snelle \(dayTitle)",
                steps: [
                    "Gebruik: \(joined).",
                    "Bak/roer alles in één pan, kruid naar smaak.",
                    "Serveer met brood of rijst."
                ]
            ),
            RecipeSuggestion(
                title: "Komfort bowl",
                steps: [
                    "Combineer \(joined) in een grote kom.",
                    "Voeg olie, zout en peper toe.",
                    "Rooster of wok en serveer warm."
                ]
            )
        ]
    }
}
