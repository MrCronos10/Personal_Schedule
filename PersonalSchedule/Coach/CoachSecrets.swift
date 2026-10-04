import Foundation
import Security

/// Where the student's Anthropic API key lives. See ADR 0008.
///
/// Keychain, not UserDefaults: UserDefaults is unencrypted and backed up to iCloud by default, so a
/// key stored there is a key that can walk off the phone with a backup file. Keychain is
/// device-only (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) so the key stays here, even if
/// the student later turns iCloud backups on.
///
/// A one-student app does not need per-user accounts: the service identifier is enough to find the
/// one entry. Reading or writing returns nil / false rather than throwing; the Settings screen can
/// react without needing to translate a `OSStatus` into a sentence.
struct CoachSecrets {
    static let service = "com.kuypav.PersonalSchedule.coach.anthropic-api-key"

    static func apiKey() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8),
              !string.isEmpty
        else { return nil }
        return string
    }

    @discardableResult
    static func save(apiKey: String) -> Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return remove() }
        let data = Data(trimmed.utf8)
        // Overwrite rather than insert-then-fail: a student pasting a new key over an old one must
        // not have to clear the field first for the save to work.
        remove()
        var attributes = baseQuery()
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    static func remove() -> Bool {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static var hasAPIKey: Bool { apiKey() != nil }

    private static func baseQuery() -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service]
    }
}
