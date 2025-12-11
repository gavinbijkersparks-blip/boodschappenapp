import Foundation

enum AIPriceService {
    static let endpoint = URL(string: "https://bijkersparks.nl/api/price.php")!

    struct PriceResponse: Decodable {
        let price: Double?
    }

    static func fetchPrice(for name: String) async -> Double? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["name": trimmed])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            if let decoded = try? JSONDecoder().decode(PriceResponse.self, from: data) {
                return decoded.price
            }
        } catch {
            print("AIPriceService error: \(error)")
        }
        return nil
    }
}
