import Foundation

enum BookmarkSearchService {
    static func search(query: String, config: AppConfig) async throws -> [BookmarkSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        guard let endpoint = config.searchBookmarksEndpoint,
              let token = config.bearerToken,
              !token.isEmpty
        else {
            return sampleResults(matching: trimmedQuery)
        }

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "q", value: trimmedQuery)
        ]

        guard let url = components?.url else {
            return sampleResults(matching: trimmedQuery)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else {
            return sampleResults(matching: trimmedQuery)
        }

        return try parseResults(from: data)
    }

    private static func parseResults(from data: Data) throws -> [BookmarkSearchResult] {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let items = json as? [[String: Any]] else {
            return []
        }

        return items.map { item in
            BookmarkSearchResult(
                title: item["title"] as? String ?? "(Untitled)",
                url: item["url"] as? String ?? "",
                description: item["description"] as? String ?? "",
                tags: item["tags"] as? [String] ?? []
            )
        }
    }

    private static func sampleResults(matching query: String) -> [BookmarkSearchResult] {
        let catalog = [
            BookmarkSearchResult(
                title: "LinkTaco Home",
                url: "https://linktaco.com",
                description: "LinkTaco landing page.",
                tags: ["linktaco", "home"]
            ),
            BookmarkSearchResult(
                title: "Example Search Result",
                url: "https://example.com/articles/search",
                description: "Placeholder result shown until the real search API is configured.",
                tags: ["sample", "search"]
            ),
            BookmarkSearchResult(
                title: "Quick Save Prototype Notes",
                url: "https://example.com/linktaco-quick-save",
                description: "Local app ideas for capture, search, and background sync.",
                tags: ["prototype", "notes"]
            )
        ]

        return catalog.filter { result in
            let haystack = [
                result.title,
                result.url,
                result.description,
                result.tags.joined(separator: " ")
            ]
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(query)
        }
    }
}
