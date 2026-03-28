import Foundation
import OSLog

struct DraftBookmark {
    var url: String
    var title: String
    var description: String
    var tags: String
}

struct BookmarkSaveContext {
    var orgSlug: String
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

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case isActive
    }

    init(id: String, name: String, slug: String, isActive: Bool) {
        self.id = id
        self.name = name
        self.slug = slug
        self.isActive = isActive
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else if let intID = try? container.decode(Int.self, forKey: .id) {
            id = String(intID)
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.id],
                    debugDescription: "Expected organization id to decode as either String or Int."
                )
            )
        }

        name = try container.decode(String.self, forKey: .name)
        slug = try container.decode(String.self, forKey: .slug)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
}

struct AppConfig {
    var createBookmarkEndpoint: URL?
    var searchBookmarksEndpoint: URL?
    var bearerToken: String?
    var debugLoggingEnabled: Bool
    let graphqlEndpoint = URL(string: "https://api.linktaco.com/query")!

    static func loadFromEnvironment() -> AppConfig {
        let env = ProcessInfo.processInfo.environment
        let endpoint = env["LINKTACO_CREATE_ENDPOINT"].flatMap(URL.init(string:))
        let searchEndpoint = env["LINKTACO_SEARCH_ENDPOINT"].flatMap(URL.init(string:))
        let token = env["LINKTACO_BEARER_TOKEN"]
        let debugLoggingEnabled = env["LINKTACO_DEBUG_LOGS"] == "1"
        return AppConfig(
            createBookmarkEndpoint: endpoint,
            searchBookmarksEndpoint: searchEndpoint,
            bearerToken: token,
            debugLoggingEnabled: debugLoggingEnabled
        )
    }

    var hasAPIConfig: Bool {
        createBookmarkEndpoint != nil && !(bearerToken?.isEmpty ?? true)
    }

    var hasSearchAPIConfig: Bool {
        searchBookmarksEndpoint != nil && !(bearerToken?.isEmpty ?? true)
    }
}

enum AppLogger {
    static let logger = Logger(subsystem: "com.linktaco.LinkTacoQuickSave", category: "app")
}

extension String {
    var trimmedForAppUse: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func truncated(to maxLength: Int) -> String {
        if count <= maxLength {
            return self
        }

        return String(prefix(maxLength))
    }
}
