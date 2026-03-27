import Foundation

struct DraftBookmark {
    var url: String
    var title: String
    var description: String
    var tags: String
}

struct BookmarkSearchResult: Identifiable {
    let id = UUID()
    var title: String
    var url: String
    var description: String
    var tags: [String]
}

struct Organization: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let slug: String
    let isActive: Bool
}

struct AppConfig {
    var createBookmarkEndpoint: URL?
    var searchBookmarksEndpoint: URL?
    var bearerToken: String?
    let graphqlEndpoint = URL(string: "https://api.linktaco.com/query")!

    static func loadFromEnvironment() -> AppConfig {
        let env = ProcessInfo.processInfo.environment
        let endpoint = env["LINKTACO_CREATE_ENDPOINT"].flatMap(URL.init(string:))
        let searchEndpoint = env["LINKTACO_SEARCH_ENDPOINT"].flatMap(URL.init(string:))
        let token = env["LINKTACO_BEARER_TOKEN"]
        return AppConfig(
            createBookmarkEndpoint: endpoint,
            searchBookmarksEndpoint: searchEndpoint,
            bearerToken: token
        )
    }

    var hasAPIConfig: Bool {
        createBookmarkEndpoint != nil && !(bearerToken?.isEmpty ?? true)
    }

    var hasSearchAPIConfig: Bool {
        searchBookmarksEndpoint != nil && !(bearerToken?.isEmpty ?? true)
    }
}

extension String {
    var trimmedForAppUse: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
