import Foundation

// AI categorie via eigen backend. Backend moet rekening houden met vaste categoryList.
enum AICategoryService {
    static let endpoint: String = "https://bijkersparks.nl/api/category.php"

    struct CategoryRequest: Codable {
        let name: String
        let categories: [String]
    }

    struct CategoryResponse: Codable {
        let category: String
    }

    static func suggestCategory(for name: String) async -> String? {
        guard !endpoint.isEmpty, let url = URL(string: endpoint) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = CategoryRequest(name: name, categories: categoryList)
        req.httpBody = try? JSONEncoder().encode(body)
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
            if let decoded = try? JSONDecoder().decode(CategoryResponse.self, from: data) {
                return decoded.category
            }
        } catch {
            print("AI category failed: \(error)")
        }
        return nil
    }
}
