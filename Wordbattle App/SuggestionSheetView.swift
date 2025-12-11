import SwiftUI

struct SuggestionSheetView: View {
    let store: ProductStore
    let listID: UUID
    let day: DayOfWeek

    @State private var suggestions: [RecipeSuggestion] = []
    @State private var loading: Bool = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(day.title)
                    .font(.title.bold())
                Text("AI suggesties en bereidingswijze op basis van geplande items voor deze dag.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                Button {
                    fetch()
                } label: {
                    HStack {
                        if loading { ProgressView() }
                        Text(loading ? "Bezig..." : "Vraag suggesties")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(loading)

                if let error = error {
                    Text(error).foregroundColor(.red)
                }

                if !suggestions.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(suggestions) { suggestion in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(suggestion.title)
                                    .font(.system(size: 18, weight: .semibold))
                                if !suggestion.missingIngredients.isEmpty {
                                    Text("Ontbrekend: \(suggestion.missingIngredients.joined(separator: ", "))")
                                        .font(.footnote)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                ForEach(Array(suggestion.steps.enumerated()), id: \.offset) { idx, step in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(idx+1).")
                                            .font(.footnote.bold())
                                        Text(step)
                                            .font(.footnote)
                                    }
                                }
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                        }
                    }
                } else if !loading {
                    Text("Nog geen suggesties")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding()
        }
        .onAppear { fetch() }
    }

    private func fetch() {
        error = nil
        loading = true
        suggestions = []
        Task { @MainActor in
            let result = await store.recipeSuggestions(for: day, in: listID)
            suggestions = result
            if result.isEmpty {
                error = "Geen suggesties gevonden. Zorg dat er ingrediënten gepland staan."
            }
            loading = false
        }
    }
}
