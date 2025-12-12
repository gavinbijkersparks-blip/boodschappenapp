import SwiftUI

struct SuggestionSheetView: View {
    enum Context {
        case day(DayOfWeek)
        case unplanned

        var title: String {
            switch self {
            case .day(let day): return day.title
            case .unplanned: return "Alle producten"
            }
        }

        var subtitle: String {
            switch self {
            case .day:
                return "AI suggesties, missende ingrediënten en stappen op basis van de geplande items voor deze dag."
            case .unplanned:
                return "Voorbeelden van recepten en ontbrekende ingrediënten op basis van alles wat nu op je lijst staat."
            }
        }

        var day: DayOfWeek? {
            if case .day(let d) = self { return d }
            return nil
        }

        var ctaSuffix: String {
            if let day { return "voor \(day.title.lowercased())" }
            return "op je lijst"
        }
    }

    @ObservedObject var store: ProductStore
    let listID: UUID
    let context: Context

    @State private var suggestions: [RecipeSuggestion] = []
    @State private var loading: Bool = false
    @State private var error: String?
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(context.title)
                    .font(.title.bold())
                Text(context.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                if !baseIngredients.isEmpty {
                    IngredientChips(title: "In basis", ingredients: baseIngredients.map { $0.name })
                }

                Button(action: fetch) {
                    HStack {
                        if loading { ProgressView() }
                        Text(loading ? "Bezig..." : "Vraag 5 receptsuggesties")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(loading || baseIngredients.isEmpty)

                if let message { Text(message).foregroundStyle(.green).font(.footnote) }
                if let error = error { Text(error).foregroundColor(.red) }

                if !suggestions.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(suggestions) { suggestion in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(suggestion.title)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)

                                if !suggestion.missingIngredients.isEmpty {
                                    IngredientChips(
                                        title: "Ontbreekt",
                                        ingredients: suggestion.missingIngredients
                                    )
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Stappen").font(.subheadline.bold())
                                    ForEach(Array(suggestion.steps.enumerated()), id: \.offset) { idx, step in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(idx+1).")
                                                .font(.footnote.bold())
                                            Text(step)
                                                .font(.footnote)
                                        }
                                    }
                                }

                                if !suggestion.missingIngredients.isEmpty {
                                    Button {
                                        addMissing(for: suggestion)
                                    } label: {
                                        HStack {
                                            Image(systemName: "cart.badge.plus")
                                            Text("Zet ontbrekende producten \(context.ctaSuffix)")
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Theme.accentSecondary)
                                        .foregroundStyle(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                        }
                    }
                } else if !loading {
                    Text(baseIngredients.isEmpty ? "Voeg eerst ingrediënten toe." : "Nog geen suggesties")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding()
        }
        .onAppear(perform: fetch)
    }

    private var baseIngredients: [Product] {
        if let day = context.day {
            return store.planned(for: day, in: listID)
        }
        return store.unplanned(in: listID)
    }

    private func fetch() {
        error = nil
        message = nil
        suggestions = []
        guard !baseIngredients.isEmpty else { return }
        loading = true
        Task { @MainActor in
            let result = await store.recipeSuggestions(for: context.day, in: listID)
            suggestions = result
            if result.isEmpty {
                error = "Geen suggesties gevonden. Zorg dat er ingrediënten klaarstaan."
            }
            loading = false
        }
    }

    private func addMissing(for suggestion: RecipeSuggestion) {
        let added = store.addMissingIngredients(suggestion.missingIngredients, to: listID, plannedFor: context.day)
        if added.isEmpty {
            message = "Alle ontbrekende items stonden al op je lijst."
        } else {
            message = "Toegevoegd: \(added.map { $0.name }.joined(separator: ", "))."
        }
    }
}

private struct IngredientChips: View {
    let title: String
    let ingredients: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(Theme.textSecondary)
            FlexibleChipView(items: ingredients)
        }
    }
}

private struct FlexibleChipView: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { ingredient in
                Text(ingredient)
                    .font(.footnote)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }
}
