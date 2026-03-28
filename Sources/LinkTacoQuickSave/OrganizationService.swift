import Foundation

enum OrganizationServiceError: LocalizedError {
    case invalidHTTPResponse
    case unauthorized
    case serverStatus(Int)
    case graphql(String)
    case missingData
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidHTTPResponse:
            return "The organization response was not a valid HTTP response."
        case .unauthorized:
            return "The PAT was rejected. Check that it is valid and has ORGS:RO scope."
        case .serverStatus(let statusCode):
            return "The organization request failed with HTTP \(statusCode)."
        case .graphql(let message):
            return message
        case .missingData:
            return "The organization response did not include any organization data."
        case .decoding(let details):
            return "The organization response could not be decoded: \(details)"
        }
    }
}

final class OrganizationService {
    private static let getOrganizationsOperation = """
    query GetOrganizations($input: GetOrganizationsInput) {
      getOrganizations(input: $input) {
        id
        name
        slug
        isActive
      }
    }
    """

    func fetchOrganizations(token: String, endpoint: URL, debugLoggingEnabled: Bool = false, correlationID: String = UUID().uuidString) async throws -> [Organization] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 3
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let requestBody = GraphQLRequest(
            query: Self.getOrganizationsOperation,
            variables: Variables(input: EmptyInput())
        )
        request.httpBody = try JSONEncoder().encode(requestBody)
        logDebug(enabled: debugLoggingEnabled, message: "org_request_started correlationID=\(correlationID)")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OrganizationServiceError.invalidHTTPResponse
        }
        logDebug(
            enabled: debugLoggingEnabled,
            message: "org_response_received correlationID=\(correlationID) status=\(httpResponse.statusCode) bytes=\(data.count)"
        )

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw OrganizationServiceError.unauthorized
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw OrganizationServiceError.serverStatus(httpResponse.statusCode)
        }

        let decodedResponse: GraphQLResponse
        do {
            decodedResponse = try JSONDecoder().decode(GraphQLResponse.self, from: data)
        } catch let decodingError as DecodingError {
            throw OrganizationServiceError.decoding(describe(decodingError))
        }

        if let message = decodedResponse.errors?.first?.message, !message.isEmpty {
            logDebug(
                enabled: debugLoggingEnabled,
                message: "org_response_graphql_error correlationID=\(correlationID) message=\(message)"
            )
            throw OrganizationServiceError.graphql(message)
        }

        guard let organizations = decodedResponse.data?.getOrganizations else {
            throw OrganizationServiceError.missingData
        }

        let activeCount = organizations.filter(\.isActive).count
        logDebug(
            enabled: debugLoggingEnabled,
            message: "org_request_succeeded correlationID=\(correlationID) count=\(organizations.count) active=\(activeCount)"
        )

        return organizations
    }

    private func describe(_ error: DecodingError) -> String {
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

    private func codingPathDescription(_ codingPath: [CodingKey]) -> String {
        let path = codingPath.map(\.stringValue).joined(separator: ".")
        return path.isEmpty ? "<root>" : path
    }

    private func logDebug(enabled: Bool, message: String) {
        guard enabled else {
            return
        }

        AppLogger.logger.debug("\(message, privacy: .public)")
    }
}

private struct GraphQLRequest: Encodable {
    let query: String
    let variables: Variables
}

private struct Variables: Encodable {
    let input: EmptyInput
}

private struct EmptyInput: Encodable {}

private struct GraphQLResponse: Decodable {
    let data: DataContainer?
    let errors: [GraphQLError]?
}

private struct DataContainer: Decodable {
    let getOrganizations: [Organization]
}

private struct GraphQLError: Decodable {
    let message: String
}
