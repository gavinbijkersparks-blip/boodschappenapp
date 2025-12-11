import Foundation

// Vaste categorieënlijst voor de app.
let categoryList: [String] = [
    "Groente", "Fruit", "Kruiden", "Aardappelen", "Brood", "Ontbijtgranen", "Bakmixen",
    "Koek en gebak", "Vlees", "Vis", "Vega en vegan", "Vleeswaren", "Melk en yoghurt",
    "Kaas", "Boter en smeersels", "Eieren", "Water", "Frisdrank", "Sappen", "Koffie en thee",
    "Alcohol", "Pasta, rijst en granen", "Conserven", "Sauzen en olie", "Soepen", "Snacks",
    "Diepvries", "Ontbijtproducten", "Noten en gedroogd fruit", "Chips en zoutjes", "Snoep",
    "Chocolade", "Koekjes", "Schoonmaak", "Afwas", "Wasmiddel", "Papierwaren",
    "Haarverzorging", "Lichaamsverzorging", "Mondverzorging", "Scheerproducten",
    "Babyvoeding", "Luiers", "Billendoekjes", "Hondenvoeding", "Kattenvoeding",
    "Dierverzorging", "Feestartikelen", "Kantoorartikelen", "Keukenartikelen", "Overig"
]

func canonicalCategory(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return "Overig" }
    if let exact = categoryList.first(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
        return exact
    }
    return "Overig"
}

// Eenvoudige heuristiek op basis van naam.
func guessedCategory(for name: String) -> String? {
    let lower = name.lowercased()
    let keywords: [(String, String)] = [
        ("appel", "Fruit"), ("banaan", "Fruit"), ("peer", "Fruit"), ("citroen", "Fruit"), ("sinaas", "Fruit"),
        ("tomaat", "Groente"), ("komkommer", "Groente"), ("paprika", "Groente"), ("sla", "Groente"),
        ("aardappel", "Aardappelen"), ("brood", "Brood"), ("croissant", "Brood"),
        ("pasta", "Pasta, rijst en granen"), ("spaghetti", "Pasta, rijst en granen"), ("rijst", "Pasta, rijst en granen"), ("noedel", "Pasta, rijst en granen"),
        ("boon", "Groente"), ("bonen", "Groente"), ("kidney", "Groente"), ("linzen", "Groente"), ("erwt", "Groente"), ("peul", "Groente"),
        ("havermout", "Ontbijtgranen"), ("muesli", "Ontbijtgranen"),
        ("koek", "Koekjes"), ("cracker", "Koekjes"), ("chips", "Chips en zoutjes"),
        ("kip", "Vlees"), ("gehakt", "Vlees"), ("rund", "Vlees"), ("speklap", "Vlees"), ("bief", "Vlees"), ("biefstuk", "Vlees"), ("steak", "Vlees"),
        ("zalm", "Vis"), ("tonijn", "Vis"), ("makreel", "Vis"),
        ("veg", "Vega en vegan"), ("tofu", "Vega en vegan"), ("tempeh", "Vega en vegan"),
        ("kaas", "Kaas"), ("boter", "Boter en smeersels"), ("smeer", "Boter en smeersels"),
        ("melk", "Melk en yoghurt"), ("yoghurt", "Melk en yoghurt"), ("kwark", "Melk en yoghurt"),
        ("ei", "Eieren"),
        ("water", "Water"), ("cola", "Frisdrank"), ("fanta", "Frisdrank"), ("limonade", "Frisdrank"), ("sap", "Sappen"),
        ("bier", "Alcohol"), ("wijn", "Alcohol"),
        ("koffie", "Koffie en thee"), ("espresso", "Koffie en thee"), ("thee", "Koffie en thee"),
        ("saus", "Sauzen en olie"), ("olie", "Sauzen en olie"), ("mayonaise", "Sauzen en olie"),
        ("soep", "Soepen"),
        ("ijs", "Diepvries"), ("pizza", "Diepvries"),
        ("noot", "Noten en gedroogd fruit"), ("rozijn", "Noten en gedroogd fruit"),
        ("snoep", "Snoep"), ("chocolade", "Chocolade"),
        ("afwas", "Afwas"), ("douche", "Lichaamsverzorging"), ("shampoo", "Haarverzorging"),
        ("tand", "Mondverzorging"), ("scheer", "Scheerproducten"),
        ("wc ", "Papierwaren"), ("toiletpapier", "Papierwaren"), ("keukenrol", "Papierwaren")
    ]
    for (keyword, category) in keywords where lower.contains(keyword) {
        return category
    }
    return nil
}

func categoryIcon(for rawCategory: String) -> String {
    let cat = canonicalCategory(rawCategory)
    switch cat {
    case "Groente": return "🥬"
    case "Fruit": return "🍎"
    case "Kruiden": return "🌿"
    case "Aardappelen": return "🥔"
    case "Brood": return "🍞"
    case "Ontbijtgranen": return "🥣"
    case "Bakmixen": return "🧁"
    case "Koek en gebak": return "🍰"
    case "Vlees": return "🥩"
    case "Vis": return "🐟"
    case "Vega en vegan": return "🌱"
    case "Vleeswaren": return "🥓"
    case "Melk en yoghurt": return "🥛"
    case "Kaas": return "🧀"
    case "Boter en smeersels": return "🧈"
    case "Eieren": return "🥚"
    case "Water": return "💧"
    case "Frisdrank": return "🥤"
    case "Sappen": return "🧃"
    case "Koffie en thee": return "☕️"
    case "Alcohol": return "🍻"
    case "Pasta, rijst en granen": return "🍚"
    case "Conserven": return "🥫"
    case "Sauzen en olie": return "🫙"
    case "Soepen": return "🍲"
    case "Snacks": return "🍿"
    case "Diepvries": return "❄️"
    case "Ontbijtproducten": return "🥐"
    case "Noten en gedroogd fruit": return "🥜"
    case "Chips en zoutjes": return "🍟"
    case "Snoep": return "🍬"
    case "Chocolade": return "🍫"
    case "Koekjes": return "🍪"
    case "Schoonmaak": return "🧽"
    case "Afwas": return "🧴"
    case "Wasmiddel": return "🧺"
    case "Papierwaren": return "🧻"
    case "Haarverzorging": return "💇‍♀️"
    case "Lichaamsverzorging": return "🧴"
    case "Mondverzorging": return "🪥"
    case "Scheerproducten": return "🪒"
    case "Babyvoeding": return "🍼"
    case "Luiers": return "🧷"
    case "Billendoekjes": return "🧻"
    case "Hondenvoeding": return "🐶"
    case "Kattenvoeding": return "🐱"
    case "Dierverzorging": return "🐾"
    case "Feestartikelen": return "🎉"
    case "Kantoorartikelen": return "✏️"
    case "Keukenartikelen": return "🍽️"
    default: return "🛒"
    }
}

// Eenvoudige prijs-schatting op basis van categorie/naam.
func guessPrice(for name: String, category: String) -> Double? {
    let cat = canonicalCategory(category)
    let lower = name.lowercased()
    let base: Double
    switch cat {
    case "Vlees": base = 8.0
    case "Vis": base = 7.0
    case "Groente": base = 1.5
    case "Fruit": base = 1.5
    case "Brood": base = 2.0
    case "Pasta, rijst en granen": base = 1.2
    case "Snacks", "Chips en zoutjes": base = 2.0
    case "Frisdrank": base = 1.8
    case "Sauzen en olie": base = 2.5
    case "Schoonmaak", "Afwas": base = 2.5
    case "Kaas", "Melk en yoghurt": base = 2.0
    case "Koffie en thee": base = 4.0
    case "Boter en smeersels": base = 2.0
    default: base = 2.0
    }
    // Kleine variatie op basis van naamlengte.
    let variance = Double((lower.count % 5)) * 0.1
    let estimate = base + variance
    return estimate
}
