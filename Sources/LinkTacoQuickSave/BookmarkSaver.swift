import AppKit
import Foundation

enum SaveResult {
    case success
    case fallbackRequired(String)
}

enum BookmarkSaverError: LocalizedError {
    case invalidHTTPResponse
    case unauthorized
    case serverStatus(Int)
    case graphql(String)
    case missingData
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidHTTPResponse:
            return "The save response was not a valid HTTP response."
        case .unauthorized:
            return "The PAT was rejected. Check that it is valid and has LINKS:RW scope."
        case .serverStatus(let statusCode):
            return "The save request failed with HTTP \(statusCode)."
        case .graphql(let message):
            return message
        case .missingData:
            return "The save response did not include bookmark data."
        case .decoding(let details):
            return "The save response could not be decoded: \(details)"
        }
    }
}

enum BookmarkSaver {
    private static let addLinkOperation = """
    mutation AddLink($input: LinkInput) {
      addLink(input: $input) {
        id
        title
        description
        url
        hash
        visibility
        unread
        starred
        archiveUrl
        type
        tags { name slug }
        author
        orgSlug
        createdOn
        updatedOn
        baseUrlHash
      }
    }
    """

    static func save(_ draft: DraftBookmark, config: AppConfig) async throws -> SaveResult {
        return try await saveInternal(draft, context: nil, config: config, correlationID: UUID().uuidString)
    }

    static func save(_ draft: DraftBookmark, context: BookmarkSaveContext, config: AppConfig) async throws -> SaveResult {
        return try await saveInternal(draft, context: context, config: config, correlationID: UUID().uuidString)
    }

    private static func saveInternal(
        _ draft: DraftBookmark,
        context: BookmarkSaveContext?,
        config: AppConfig,
        correlationID: String
    ) async throws -> SaveResult {
        guard let token = config.bearerToken?.trimmedForAppUse,
              !token.isEmpty
        else {
            return .fallbackRequired("Missing API configuration")
        }

        guard let orgSlug = context?.orgSlug.trimmedForAppUse, !orgSlug.isEmpty else {
            return .fallbackRequired("Missing organization selection")
        }

        var request = URLRequest(url: config.graphqlEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 3
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let requestBody = GraphQLRequest(
            query: Self.addLinkOperation,
            variables: AddLinkVariables(
                input: AddLinkInput(
                    url: draft.url.trimmedForAppUse,
                    title: draft.title.trimmedForAppUse,
                    description: draft.description.trimmedForAppUse.emptyStringAsNil,
                    tags: normalizedTags(from: draft.tags).emptyStringAsNil,
                    orgSlug: orgSlug,
                    unread: false,
                    starred: false,
                    archive: false
                )
            )
        )
        request.httpBody = try JSONEncoder().encode(requestBody)
        logDebug(
            enabled: config.debugLoggingEnabled,
            message: "save_request_started correlationID=\(correlationID) urlLength=\(requestBody.variables.input.url.count) titleLength=\(requestBody.variables.input.title.count) hasDescription=\(requestBody.variables.input.description != nil) hasTags=\(requestBody.variables.input.tags != nil) orgSlugLength=\(orgSlug.count)"
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BookmarkSaverError.invalidHTTPResponse
        }
        logDebug(
            enabled: config.debugLoggingEnabled,
            message: "save_response_received correlationID=\(correlationID) status=\(http.statusCode) bytes=\(data.count)"
        )

        if http.statusCode == 401 || http.statusCode == 403 {
            throw BookmarkSaverError.unauthorized
        }

        guard (200..<300).contains(http.statusCode) else {
            throw BookmarkSaverError.serverStatus(http.statusCode)
        }

        let decodedResponse: GraphQLResponse
        do {
            decodedResponse = try JSONDecoder().decode(GraphQLResponse.self, from: data)
        } catch let decodingError as DecodingError {
            throw BookmarkSaverError.decoding(describe(decodingError))
        }

        if let message = decodedResponse.errors?.first?.message, !message.isEmpty {
            logDebug(
                enabled: config.debugLoggingEnabled,
                message: "save_response_graphql_error correlationID=\(correlationID) message=\(message)"
            )
            throw BookmarkSaverError.graphql(message)
        }

        guard decodedResponse.data?.addLink != nil else {
            throw BookmarkSaverError.missingData
        }

        logDebug(enabled: config.debugLoggingEnabled, message: "save_request_succeeded correlationID=\(correlationID)")

        return .success
    }

    static func openBrowserFallback(_ draft: DraftBookmark, orgSlug: String? = nil) {
        var components = URLComponents(string: "https://linktaco.com/add")
        var queryItems = [
            URLQueryItem(name: "next", value: "same"),
            URLQueryItem(name: "url", value: draft.url.trimmedForAppUse.truncated(to: 2048)),
            URLQueryItem(name: "description", value: draft.description.truncated(to: 2000)),
            URLQueryItem(name: "title", value: draft.title.truncated(to: 300))
        ]

        let normalizedTags = normalizedTags(from: draft.tags).truncated(to: 500)
        if !normalizedTags.isEmpty {
            queryItems.append(URLQueryItem(name: "tags", value: normalizedTags))
        }

        let normalizedOrgSlug = orgSlug?.trimmedForAppUse.truncated(to: 64) ?? ""
        if !normalizedOrgSlug.isEmpty {
            queryItems.append(URLQueryItem(name: "org", value: normalizedOrgSlug))
        }

        components?.queryItems = queryItems

        if let url = components?.url {
            NSWorkspace.shared.open(url)
        }
    }

    private static func normalizedTags(from rawTags: String) -> String {
        rawTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ",")
    }

    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' at \(codingPathDescription(context.codingPath))."
        case .typeMismatch(_, let context):
            return "Type mismatch at \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
        case .valueNotFound(_, let context):
            return "Missing value at \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
        case .dataCorrupted(let context):
            return "Data corrupted at \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
        @unknown default:
            return "Unknown decoding error."
        }
    }

    private static func codingPathDescription(_ codingPath: [CodingKey]) -> String {
        let path = codingPath.map(\.stringValue).joined(separator: ".")
        return path.isEmpty ? "<root>" : path
    }

    private static func logDebug(enabled: Bool, message: String) {
        guard enabled else {
            return
        }

        AppLogger.logger.debug("\(message, privacy: .public)")
    }
}

private struct GraphQLRequest: Encodable {
    let query: String
    let variables: AddLinkVariables
}

private struct AddLinkVariables: Encodable {
    let input: AddLinkInput
}

private struct AddLinkInput: Encodable {
    let url: String
    let title: String
    let description: String?
    let tags: String?
    let orgSlug: String
    let unread: Bool
    let starred: Bool
    let archive: Bool
}

private struct GraphQLResponse: Decodable {
    let data: GraphQLResponseData?
    let errors: [GraphQLError]?
}

private struct GraphQLResponseData: Decodable {
    let addLink: AddedLink?
}

private struct AddedLink: Decodable {
    let id: String

    private enum CodingKeys: String, CodingKey {
        case id
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
                    debugDescription: "Expected saved bookmark id to decode as either String or Int."
                )
            )
        }
    }
}

private struct GraphQLError: Decodable {
    let message: String
}

private extension String {
    var emptyStringAsNil: String? {
        let trimmed = trimmedForAppUse
        return trimmed.isEmpty ? nil : trimmed
    }
}
