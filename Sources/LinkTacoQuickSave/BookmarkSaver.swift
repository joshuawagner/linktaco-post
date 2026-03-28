import AppKit
import Foundation

enum SaveResult {
    case success
    case fallbackRequired(String)
}

enum BookmarkSaver {
    static func save(_ draft: DraftBookmark, config: AppConfig) async throws -> SaveResult {
        guard let endpoint = config.createBookmarkEndpoint,
              let token = config.bearerToken,
              !token.isEmpty
        else {
            return .fallbackRequired("Missing API configuration")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "url": draft.url,
            "title": draft.title,
            "description": draft.description,
            "tags": draft.tags
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            return .fallbackRequired("No HTTP response")
        }

        if (200..<300).contains(http.statusCode) {
            return .success
        }

        return .fallbackRequired("Unexpected status code: \(http.statusCode)")
    }

    static func openBrowserFallback(_ draft: DraftBookmark, orgSlug: String? = nil) {
        var components = URLComponents(string: "https://linktaco.com/add")
        var queryItems = [
            URLQueryItem(name: "next", value: "same"),
            URLQueryItem(name: "url", value: draft.url),
            URLQueryItem(name: "description", value: draft.description),
            URLQueryItem(name: "title", value: draft.title)
        ]

        let normalizedTags = draft.tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ",")
        if !normalizedTags.isEmpty {
            queryItems.append(URLQueryItem(name: "tags", value: normalizedTags))
        }

        let normalizedOrgSlug = orgSlug?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !normalizedOrgSlug.isEmpty {
            queryItems.append(URLQueryItem(name: "org", value: normalizedOrgSlug))
        }

        components?.queryItems = queryItems

        if let url = components?.url {
            NSWorkspace.shared.open(url)
        }
    }
}
