//
//  SecretStore.swift
//  weather
//
//  Storage for user-supplied secrets (API keys). Keychain-backed in the app, in-memory in tests.
//

import Foundation
import Security

protocol SecretStore: AnyObject {
    func string(forKey key: String) -> String?
    func set(_ value: String?, forKey key: String)
}

final class KeychainSecretStore: SecretStore {
    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "dev.andernet.weather") {
        self.service = service
    }

    private func query(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }

    func string(forKey key: String) -> String? {
        var request = query(for: key)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func set(_ value: String?, forKey key: String) {
        SecItemDelete(query(for: key) as CFDictionary)
        guard let value, !value.isEmpty else { return }
        var item = query(for: key)
        item[kSecValueData as String] = Data(value.utf8)
        // Readable after the first unlock so background refresh can use it.
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(item as CFDictionary, nil)
    }
}

final class InMemorySecretStore: SecretStore {
    private var values: [String: String] = [:]
    func string(forKey key: String) -> String? { values[key] }
    func set(_ value: String?, forKey key: String) { values[key] = value }
}
