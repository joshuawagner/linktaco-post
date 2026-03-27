import Foundation

enum OrganizationServiceError: LocalizedError {
    case invalidHTTPResponse
    case unauthorized
    case serverStatus(Int)
    case graphql(String)
    case missingData

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

    func fetchOrganizations(token: String, endpoint: URL) async throws -> [Organization] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 3
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            GraphQLRequest(
                query: Self.getOrganizationsOperation,
                variables: Variables(input: EmptyInput())
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OrganizationServiceError.invalidHTTPResponse
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw OrganizationServiceError.unauthorized
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw OrganizationServiceError.serverStatus(httpResponse.statusCode)
        }

        let decodedResponse = try JSONDecoder().decode(GraphQLResponse.self, from: data)

        if let message = decodedResponse.errors?.first?.message, !message.isEmpty {
            throw OrganizationServiceError.graphql(message)
        }

        guard let organizations = decodedResponse.data?.getOrganizations else {
            throw OrganizationServiceError.missingData
        }

        return organizations
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
