import Foundation
import Security
import Testing
@testable import PersonalSchedule

/// Where the Coach's key lives, against the simulator's real Keychain. See ADR 0011.
///
/// Serialized and self-restoring: the test reads and writes the same slot the app uses, so whatever
/// key was there before is put back afterwards.
@Suite(.serialized)
struct CoachSecretsTests {
    private let legacyService = "com.kuypav.PersonalSchedule.coach.anthropic-api-key"

    @Test func anOldAnthropicKeyIsNeverReadAndSavingAQwenKeyWipesIt() throws {
        let before = CoachSecrets.apiKey()
        defer {
            if let before { CoachSecrets.save(apiKey: before) } else { CoachSecrets.remove() }
            deleteLegacy()
        }
        CoachSecrets.remove()
        try addLegacy("sk-ant-old")

        #expect(CoachSecrets.apiKey() == nil,
                "an Anthropic key sent to Alibaba comes back as a 401; it must read as no key yet")

        #expect(CoachSecrets.save(apiKey: "sk-new"))
        #expect(CoachSecrets.apiKey() == "sk-new")
        #expect(!legacyExists(), "the billable Anthropic key must not stay on the phone for good")
    }

    @Test func clearingTheKeyWipesAnOldAnthropicKeyToo() throws {
        let before = CoachSecrets.apiKey()
        defer {
            if let before { CoachSecrets.save(apiKey: before) } else { CoachSecrets.remove() }
            deleteLegacy()
        }
        try addLegacy("sk-ant-old")
        CoachSecrets.remove()
        #expect(!legacyExists())
    }

    // MARK: - The old slot

    private func addLegacy(_ key: String) throws {
        deleteLegacy()
        let attributes: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                         kSecAttrService as String: legacyService,
                                         kSecValueData as String: Data(key.utf8)]
        try #require(SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess)
    }

    private func legacyExists() -> Bool {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: legacyService]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    private func deleteLegacy() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: legacyService]
        SecItemDelete(query as CFDictionary)
    }
}
