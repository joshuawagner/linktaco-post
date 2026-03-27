import Foundation
import Security

enum TokenStoreError: LocalizedError {
    case unexpectedStatus(OSStatus)
    case invalidTokenData

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            if let message = SecCopyErrorMessageString(status, nil) as String? {
                return message
            }
            return "Keychain operation failed with status \(status)."
        case .invalidTokenData:
            return "The saved Keychain token could not be decoded."
        }
    }
}

final class KeychainTokenStore {
    private let service = "com.linktaco.quicksave"
    private let account = "personal-access-token"

    func save(token: String) throws {
        let data = Data(token.utf8)
        let query = baseQuery()

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw TokenStoreError.unexpectedStatus(status)
        }
    }

    func loadToken() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data,
                  let token = String(data: data, encoding: .utf8)
            else {
                throw TokenStoreError.invalidTokenData
            }
            return token
        case errSecItemNotFound:
            return nil
        default:
            throw TokenStoreError.unexpectedStatus(status)
        }
    }

    func clearToken() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStoreError.unexpectedStatus(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
