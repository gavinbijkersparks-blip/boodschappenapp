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
            return fallbackSuggestions(ingredients: ingredients, dayTitle: dayTitle)
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
            var mapped: [RecipeSuggestion] = decoded.suggestions.map { raw in
                let missing = enrichedMissing(rawMissing: raw.missingIngredients, raw: raw, available: ingredients)
                return RecipeSuggestion(
                    id: UUID(uuidString: raw.id) ?? UUID(),
                    title: raw.title,
                    steps: raw.steps,
                    missingIngredients: missing
                )
            }
            if mapped.count < 5 {
                mapped = padWithFallback(current: mapped, ingredients: ingredients, dayTitle: dayTitle)
            }
            return mapped
        }
        return fallbackSuggestions(ingredients: ingredients, dayTitle: dayTitle)
    }

    @MainActor
    static func fallbackSuggestions(ingredients: [String], dayTitle: String) -> [RecipeSuggestion] {
        return generateFallback(ingredients: ingredients, dayTitle: dayTitle)
    }

    @MainActor
    private static func padWithFallback(current: [RecipeSuggestion], ingredients: [String], dayTitle: String) -> [RecipeSuggestion] {
        var combined = current
        let fallback = fallbackSuggestions(ingredients: ingredients, dayTitle: dayTitle)
        for candidate in fallback {
            guard !combined.contains(where: { $0.title == candidate.title }) else { continue }
            combined.append(candidate)
            if combined.count >= 5 { break }
        }
        return combined
    }

    nonisolated private static func enrichedMissing(rawMissing: [String], raw: RawSuggestion, available: [String]) -> [String] {
        let availableSet = Set(available.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        let normalizedMissing = rawMissing
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .filter { !availableSet.contains($0) }
        return normalizedMissing.map { $0.capitalized }
    }

    // MARK: Fallback generation tuned to common bases
    @MainActor
    private static func generateFallback(ingredients: [String], dayTitle: String) -> [RecipeSuggestion] {
        let base = ingredients.map { $0.lowercased() }
        let hasPasta = base.contains(where: { $0.contains("pasta") || $0.contains("penne") || $0.contains("spaghetti") })
        let hasPotato = base.contains(where: { $0.contains("kriel") || $0.contains("aardappel") })
        let hasRice = base.contains(where: { $0.contains("rijst") })
        let hasTandoori = base.contains(where: { $0.contains("tandoori") || $0.contains("tandori") })
        let hasCurry = base.contains(where: { $0.contains("curry") || $0.contains("kerrie") })

        if hasTandoori || hasCurry {
            return tandooriFallbacks(dayTitle: dayTitle)
        } else if hasPasta {
            return pastaFallbacks(dayTitle: dayTitle)
        } else if hasPotato {
            return potatoFallbacks(dayTitle: dayTitle)
        } else if hasRice {
            return riceFallbacks(dayTitle: dayTitle)
        } else {
            return pantryFallbacks(dayTitle: dayTitle)
        }
    }

    @MainActor
    private static func tandooriFallbacks(dayTitle: String) -> [RecipeSuggestion] {
        return [
            RecipeSuggestion(
                title: "Kip Tandoori met rijst",
                steps: [
                    "Marineer kip in tandoori kruiden, yoghurt en knoflook.",
                    "Bak kip goudbruin en voeg ui en paprika toe.",
                    "Laat 15 minuten sudderen en serveer met rijst.",
                    "Garneer met koriander."
                ],
                missingIngredients: ["kip", "tandoori kruiden", "yoghurt", "knoflook", "ui", "paprika", "koriander", "rijst"]
            ),
            RecipeSuggestion(
                title: "Tandoori ovenschotel met krieltjes",
                steps: [
                    "Meng krieltjes en kip met tandoori kruiden en yoghurt.",
                    "Voeg ui en paprika toe, verdeel in ovenschaal.",
                    "Bak 25-30 minuten op 200°C.",
                    "Serveer met frisse komkommersalade."
                ],
                missingIngredients: ["kip", "tandoori kruiden", "yoghurt", "ui", "paprika", "komkommer"]
            ),
            RecipeSuggestion(
                title: "Tandoori wrap",
                steps: [
                    "Bak tandoori gemarineerde kip met ui.",
                    "Vul wraps met kip, sla en yoghurt-knoflooksaus.",
                    "Top met komkommer en koriander."
                ],
                missingIngredients: ["kip", "tandoori kruiden", "yoghurt", "knoflook", "ui", "wraps", "sla", "komkommer", "koriander"]
            ),
            RecipeSuggestion(
                title: "Vegetarische tandoori met bloemkool",
                steps: [
                    "Rooster bloemkoolroosjes met tandoori kruiden en olie.",
                    "Voeg kikkererwten toe en bak kort mee.",
                    "Serveer met naan en yoghurt-munt saus."
                ],
                missingIngredients: ["bloemkool", "tandoori kruiden", "olie", "kikkererwten", "naan", "yoghurt", "munt"]
            ),
            RecipeSuggestion(
                title: "Tandoori garnalen met rijst",
                steps: [
                    "Marineer garnalen in tandoori kruiden en yoghurt.",
                    "Bak kort met knoflook en ui.",
                    "Serveer met rijst en citroen."
                ],
                missingIngredients: ["garnalen", "tandoori kruiden", "yoghurt", "knoflook", "ui", "rijst", "citroen"]
            )
        ]
    }

    @MainActor
    private static func pastaFallbacks(dayTitle: String) -> [RecipeSuggestion] {
        return [
            RecipeSuggestion(
                title: "Romige pasta met kip en spinazie",
                steps: [
                    "Kook pasta beetgaar in gezouten water.",
                    "Bak stukjes kip met knoflook en ui goudbruin.",
                    "Voeg room, spinazie en Parmezaan toe en laat indikken.",
                    "Meng met de pasta en breng op smaak met peper/zout."
                ],
                missingIngredients: ["kip", "knoflook", "ui", "room", "spinazie", "parmezaan"]
            ),
            RecipeSuggestion(
                title: "Pasta bolognese",
                steps: [
                    "Bak rundergehakt rul met ui en knoflook.",
                    "Voeg tomatenblokjes en Italiaanse kruiden toe, laat sudderen.",
                    "Kook pasta en meng met de saus.",
                    "Serveer met Parmezaan."
                ],
                missingIngredients: ["rundergehakt", "ui", "knoflook", "tomatenblokjes", "italiaanse kruiden", "parmezaan"]
            ),
            RecipeSuggestion(
                title: "Pasta met zalm en dille",
                steps: [
                    "Kook pasta beetgaar.",
                    "Bak zalmblokjes kort met knoflook.",
                    "Roer roomkaas en dille erdoor en meng met pasta.",
                    "Serveer met citroen."
                ],
                missingIngredients: ["zalm", "roomkaas", "dille", "citroen", "knoflook"]
            ),
            RecipeSuggestion(
                title: "Pesto pasta met gegrilde groenten",
                steps: [
                    "Gril paprika, courgette en rode ui.",
                    "Meng gekookte pasta met pesto en gegrilde groenten.",
                    "Garneer met pijnboompitten en Parmezaan."
                ],
                missingIngredients: ["pesto", "paprika", "courgette", "rode ui", "pijnboompitten", "parmezaan"]
            ),
            RecipeSuggestion(
                title: "Pasta carbonara",
                steps: [
                    "Bak spekblokjes knapperig.",
                    "Klop eieren met Parmezaan en peper.",
                    "Meng met hete pasta en spek (niet op het vuur) tot romig.",
                    "Serveer direct."
                ],
                missingIngredients: ["spek", "eieren", "parmezaan"]
            )
        ]
    }

    @MainActor
    private static func potatoFallbacks(dayTitle: String) -> [RecipeSuggestion] {
        return [
            RecipeSuggestion(
                title: "Krieltjes met kip en paprika uit de oven",
                steps: [
                    "Verwarm de oven voor op 200°C.",
                    "Meng krieltjes met kipblokjes, paprika en ui, olie en kruiden.",
                    "Rooster 25-30 minuten tot goudbruin.",
                    "Serveer met frisse yoghurt-knoflooksaus."
                ],
                missingIngredients: ["kip", "paprika", "ui", "yoghurt", "knoflook", "oregano"]
            ),
            RecipeSuggestion(
                title: "Traybake zalm met krieltjes en broccoli",
                steps: [
                    "Verdeel krieltjes en broccoli op een bakplaat met olie en peper/zout.",
                    "Rooster 15 minuten op 200°C.",
                    "Leg zalmfilets erop, bestrijk met citroen en dille, en bak nog 10 minuten.",
                    "Serveer met crème fraîche."
                ],
                missingIngredients: ["zalm", "broccoli", "citroen", "dille", "creme fraiche"]
            ),
            RecipeSuggestion(
                title: "Spaanse tortilla met chorizo",
                steps: [
                    "Bak krieltjes en ui zacht in olie.",
                    "Voeg chorizo toe en bak kort mee.",
                    "Giet geklopte eieren erover en gaar langzaam tot stevig.",
                    "Serveer warm met salade."
                ],
                missingIngredients: ["eieren", "chorizo", "ui", "salade"]
            ),
            RecipeSuggestion(
                title: "Stoofpotje rund met krieltjes",
                steps: [
                    "Braad runderlappen aan met ui en knoflook.",
                    "Blus af met bouillon en laurier, laat 2 uur stoven.",
                    "Voeg krieltjes toe en stoof nog 30 minuten.",
                    "Serveer met wortel of doperwten."
                ],
                missingIngredients: ["rundvlees", "ui", "knoflook", "bouillon", "laurier", "wortel", "doperwten"]
            ),
            RecipeSuggestion(
                title: "Krieltjes roerbak met groenten en sojasaus",
                steps: [
                    "Bak krieltjes in plakjes goudbruin.",
                    "Voeg paprika, sperziebonen en taugé toe en roerbak kort.",
                    "Blus af met sojasaus en sesamolie.",
                    "Serveer met gebakken tofu of kip."
                ],
                missingIngredients: ["paprika", "sperziebonen", "tauge", "sojasaus", "sesamolie", "tofu of kip"]
            )
        ]
    }

    @MainActor
    private static func riceFallbacks(dayTitle: String) -> [RecipeSuggestion] {
        return [
            RecipeSuggestion(
                title: "Kip kerrie met rijst",
                steps: [
                    "Bak kip met ui en knoflook.",
                    "Voeg kerriepoeder, kokosmelk en paprika toe, laat sudderen.",
                    "Serveer met gekookte rijst en koriander."
                ],
                missingIngredients: ["kip", "ui", "knoflook", "kerriepoeder", "kokosmelk", "paprika", "koriander"]
            ),
            RecipeSuggestion(
                title: "Rijst met zalm en groenten",
                steps: [
                    "Stoom zalm met citroen en dille.",
                    "Roerbak broccoli en wortel met sojasaus.",
                    "Serveer op rijst met sesam."
                ],
                missingIngredients: ["zalm", "citroen", "dille", "broccoli", "wortel", "sojasaus", "sesam"]
            ),
            RecipeSuggestion(
                title: "Vegetarische nasi",
                steps: [
                    "Bak ui, knoflook en doperwten met kerrie.",
                    "Voeg rijst en ketjap toe en roerbak.",
                    "Serveer met gebakken ei en kroepoek."
                ],
                missingIngredients: ["ui", "knoflook", "doperwten", "kerrie", "ketjap", "ei", "kroepoek"]
            ),
            RecipeSuggestion(
                title: "Biefstuk met peperroomsaus en rijst",
                steps: [
                    "Bak biefstuk naar wens en houd warm.",
                    "Maak saus van room, peperkorrels en fond.",
                    "Serveer met rijst en gebakken spinazie."
                ],
                missingIngredients: ["biefstuk", "room", "peperkorrels", "fond", "spinazie"]
            ),
            RecipeSuggestion(
                title: "Shrimp fried rice",
                steps: [
                    "Bak garnalen met knoflook en lente-ui.",
                    "Voeg rijst, ei en sojasaus toe en roerbak.",
                    "Werk af met sesam en limoen."
                ],
                missingIngredients: ["garnalen", "knoflook", "lente-ui", "ei", "sojasaus", "sesam", "limoen"]
            )
        ]
    }

    @MainActor
    private static func pantryFallbacks(dayTitle: String) -> [RecipeSuggestion] {
        return [
            RecipeSuggestion(
                title: "Snelle chili met brood",
                steps: [
                    "Bak gehakt met ui en knoflook.",
                    "Voeg tomatenblokjes en bonen toe, laat 20 minuten sudderen.",
                    "Serveer met brood of wraps."
                ],
                missingIngredients: ["rundergehakt", "ui", "knoflook", "tomatenblokjes", "kidneybonen", "brood of wraps"]
            ),
            RecipeSuggestion(
                title: "Ovenschotel met kip en groenten",
                steps: [
                    "Meng kip, broccoli, paprika en ui met room en kaas.",
                    "Bak 25 minuten op 200°C.",
                    "Serveer met rijst of pasta."
                ],
                missingIngredients: ["kip", "broccoli", "paprika", "ui", "room", "geraspte kaas", "rijst of pasta"]
            ),
            RecipeSuggestion(
                title: "Wraps met pulled chicken",
                steps: [
                    "Stoof kip met tomatensaus en paprika zacht.",
                    "Trek uit elkaar en serveer in wraps met sla.",
                    "Top met yoghurt-knoflooksaus."
                ],
                missingIngredients: ["kip", "tomatensaus", "paprika", "wraps", "sla", "yoghurt", "knoflook"]
            ),
            RecipeSuggestion(
                title: "Vegetarische curry",
                steps: [
                    "Bak ui, knoflook en gember.",
                    "Voeg kokosmelk, kikkererwten en groenten toe, laat sudderen.",
                    "Serveer met rijst of naan."
                ],
                missingIngredients: ["ui", "knoflook", "gember", "kokosmelk", "kikkererwten", "groentenmix", "rijst of naan"]
            ),
            RecipeSuggestion(
                title: "Gegrilde zalm met salade",
                steps: [
                    "Gril zalm met citroen en peper/zout.",
                    "Maak een salade van komkommer, tomaat en rucola.",
                    "Serveer met krieltjes of brood."
                ],
                missingIngredients: ["zalm", "citroen", "komkommer", "tomaat", "rucola", "krieltjes of brood"]
            )
        ]
    }
}
