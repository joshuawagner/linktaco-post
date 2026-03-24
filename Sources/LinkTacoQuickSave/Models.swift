import Foundation

struct DraftBookmark {
    var url: String
    var title: String
    var description: String
    var tags: String
}

struct AppConfig {
    var createBookmarkEndpoint: URL?
    var bearerToken: String?

    static func loadFromEnvironment() -> AppConfig {
        let env = ProcessInfo.processInfo.environment
        let endpoint = env["LINKTACO_CREATE_ENDPOINT"].flatMap(URL.init(string:))
        let token = env["LINKTACO_BEARER_TOKEN"]
        return AppConfig(createBookmarkEndpoint: endpoint, bearerToken: token)
    }

    var hasAPIConfig: Bool {
        createBookmarkEndpoint != nil && !(bearerToken?.isEmpty ?? true)
    }
}
