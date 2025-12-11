import Foundation

enum BarcodeLookupError: Error {
    case invalidResponse
}

struct BarcodeInfo: Codable {
    var name: String
    var category: String
    var imageURL: String?
}

struct OpenFoodFactsService {
    struct Response: Decodable {
        let status: Int
        let product: ProductInfo?

        struct ProductInfo: Decodable {
            let product_name: String?
            let brands: String?
            let categories_tags: [String]?
            let categories: String?
            let categories_hierarchy: [String]?
            let image_url: String?
            let image_front_small_url: String?
        }
    }

    static func fetchInfo(for code: String) async throws -> BarcodeInfo? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(code).json") else {
            return nil
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BarcodeLookupError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard decoded.status == 1 else { return nil }
        let product = decoded.product
        let name: String = {
            if let n = product?.product_name, !n.isEmpty { return n }
            return code
        }()
        let category: String = {
            if let tag = product?.categories_tags?.first {
                return humanize(tag)
            }
            if let hier = product?.categories_hierarchy?.first {
                return humanize(hier)
            }
            if let cats = product?.categories, let first = cats.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }).first, !first.isEmpty {
                return humanize(first)
            }
            if let brand = product?.brands, !brand.isEmpty {
                return brand
            }
            return "Barcode"
        }()
        let imageURL = product?.image_url ?? product?.image_front_small_url
        return BarcodeInfo(name: name, category: category, imageURL: imageURL)
    }

    private static func humanize(_ tag: String) -> String {
        let parts = tag.split(separator: ":")
        let raw = parts.count > 1 ? parts[1] : parts[0]
        let words = raw.replacingOccurrences(of: "-", with: " ").split(separator: " ")
        return words.map { $0.capitalized }.joined(separator: " ")
    }
}

