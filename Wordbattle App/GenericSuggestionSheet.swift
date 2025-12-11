import SwiftUI

struct GenericSuggestionSheet: View {
    let title: String
    let ingredients: [String]

    @State private var suggestions: [RecipeSuggestion] = []
    @State private var loading: Bool = false
    @State private var error: String?
    @State private var selectedRecipe: RecipeSuggestion?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title.bold())
                Text("AI suggesties en bereidingswijze op basis van: \(ingredients.joined(separator: ", "))")
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
                .disabled(loading || ingredients.isEmpty)

                if let error {
                    Text(error).foregroundColor(.red)
                }

                if !suggestions.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(suggestions) { suggestion in
                            Button {
                                selectedRecipe = suggestion
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(suggestion.title)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                        if !suggestion.missingIngredients.isEmpty {
                                            Text("Ontbrekend: \(suggestion.missingIngredients.joined(separator: ", "))")
                                                .font(.footnote)
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding()
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                            }
                            .buttonStyle(.plain)
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
        .sheet(item: $selectedRecipe) { recipe in
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(recipe.title)
                        .font(.title.bold())
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { idx, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(idx+1).").font(.footnote.bold())
                            Text(step).font(.footnote)
                        }
                    }
                    Spacer()
                }
                .padding()
                .navigationTitle("Recept")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Sluit") { selectedRecipe = nil }
                    }
                }
            }
        }
    }

    private func fetch() {
        guard !ingredients.isEmpty else {
            error = "Geen ingrediënten geselecteerd."
            return
        }
        error = nil
        loading = true
        suggestions = []
        Task { @MainActor in
            do {
                let result = try await AISuggestionsService.fetchSuggestions(ingredients: ingredients, dayTitle: title)
                suggestions = result
                if result.isEmpty {
                    error = "Geen suggesties gevonden."
                }
            } catch {
                self.error = "Fout bij ophalen: \(error.localizedDescription)"
            }
            loading = false
        }
    }
}
