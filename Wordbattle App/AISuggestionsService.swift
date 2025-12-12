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
        guard !endpoint.isEmpty, let url = URL(string: endpoint) else {
            return mockSuggestions(ingredients: ingredients, dayTitle: dayTitle)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let body = RequestBody(ingredients: ingredients, day: dayTitle, language: "nl")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        if let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data) {
            return decoded.suggestions.map { raw in
                RecipeSuggestion(
                    id: UUID(uuidString: raw.id) ?? UUID(),
                    title: raw.title,
                    steps: raw.steps,
                    missingIngredients: raw.missingIngredients
                )
            }
        }
        return mockSuggestions(ingredients: ingredients, dayTitle: dayTitle)
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
                ],
                missingIngredients: ["brood", "rijst"]
            ),
            RecipeSuggestion(
                title: "Komfort bowl",
                steps: [
                    "Combineer \(joined) in een grote kom.",
                    "Voeg olie, zout en peper toe.",
                    "Rooster of wok en serveer warm."
                ],
                missingIngredients: ["sojasaus"]
            ),
            RecipeSuggestion(
                title: "Ovenschotel \(dayTitle.lowercased())",
                steps: [
                    "Snij en meng \(joined) met room of tomatensaus.",
                    "Dek af met kaas en bak 20-25 minuten.",
                    "Serveer met salade."
                ],
                missingIngredients: ["room", "geraspte kaas"]
            ),
            RecipeSuggestion(
                title: "Wrap night",
                steps: [
                    "Verwarm wraps en vul met \(joined).",
                    "Voeg salsa of yoghurt toe voor frisheid.",
                    "Oprollen en meteen serveren."
                ],
                missingIngredients: ["wraps", "salsa"]
            ),
            RecipeSuggestion(
                title: "Snelle soep",
                steps: [
                    "Fruit \(joined) kort in olie.",
                    "Blus af met bouillon en laat 12 minuten koken.",
                    "Pureer of serveer grof."
                ],
                missingIngredients: ["bouillon"]
            )
        ]
    }
}
