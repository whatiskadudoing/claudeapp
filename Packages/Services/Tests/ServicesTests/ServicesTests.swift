import Foundation
import Testing
@testable import Domain
@testable import Services

@Suite("Services Tests")
struct ServicesTests {
    @Test("Services version is correct")
    func servicesVersion() {
        #expect(Services.version == "1.0.0")
    }
}

// MARK: - KeychainCredentials Tests

@Suite("KeychainCredentials JSON Parsing")
struct KeychainCredentialsParsingTests {
    @Test("Parses valid OAuth credentials JSON")
    func parsesValidOAuthCredentials() throws {
        let json = """
        {
            "claudeAiOauth": {
                "accessToken": "sk-ant-oat01-test-token",
                "refreshToken": "sk-ant-ort01-refresh-token",
                "expiresAt": 1704067200000
            }
        }
        """
        let data = json.data(using: .utf8)!
        let credentials = try JSONDecoder().decode(KeychainCredentials.self, from: data)

        #expect(credentials.claudeAiOauth != nil)
        #expect(credentials.claudeAiOauth?.accessToken == "sk-ant-oat01-test-token")
        #expect(credentials.claudeAiOauth?.refreshToken == "sk-ant-ort01-refresh-token")
        #expect(credentials.claudeAiOauth?.expiresAt == 1704067200000)
    }

    @Test("Parses credentials without optional fields")
    func parsesCredentialsWithoutOptionalFields() throws {
        let json = """
        {
            "claudeAiOauth": {
                "accessToken": "sk-ant-oat01-test-token"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let credentials = try JSONDecoder().decode(KeychainCredentials.self, from: data)

        #expect(credentials.claudeAiOauth != nil)
        #expect(credentials.claudeAiOauth?.accessToken == "sk-ant-oat01-test-token")
        #expect(credentials.claudeAiOauth?.refreshToken == nil)
        #expect(credentials.claudeAiOauth?.expiresAt == nil)
    }

    @Test("Parses empty claudeAiOauth as nil")
    func parsesEmptyClaudeAiOauth() throws {
        let json = """
        {
            "claudeAiOauth": null
        }
        """
        let data = json.data(using: .utf8)!
        let credentials = try JSONDecoder().decode(KeychainCredentials.self, from: data)

        #expect(credentials.claudeAiOauth == nil)
    }

    @Test("Parses JSON without claudeAiOauth key")
    func parsesJsonWithoutClaudeAiOauthKey() throws {
        let json = """
        {
            "otherField": "value"
        }
        """
        let data = json.data(using: .utf8)!
        let credentials = try JSONDecoder().decode(KeychainCredentials.self, from: data)

        #expect(credentials.claudeAiOauth == nil)
    }

    @Test("Throws on invalid JSON")
    func throwsOnInvalidJson() {
        let json = "not valid json"
        let data = json.data(using: .utf8)!

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(KeychainCredentials.self, from: data)
        }
    }

    @Test("Throws on missing required accessToken")
    func throwsOnMissingAccessToken() {
        let json = """
        {
            "claudeAiOauth": {
                "refreshToken": "sk-ant-ort01-refresh-token"
            }
        }
        """
        let data = json.data(using: .utf8)!

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(KeychainCredentials.self, from: data)
        }
    }
}

// MARK: - OAuthCredentials Tests

@Suite("OAuthCredentials Tests")
struct OAuthCredentialsTests {
    @Test("Parses all fields correctly")
    func parsesAllFields() throws {
        let json = """
        {
            "accessToken": "access-123",
            "refreshToken": "refresh-456",
            "expiresAt": 1704067200000
        }
        """
        let data = json.data(using: .utf8)!
        let oauth = try JSONDecoder().decode(OAuthCredentials.self, from: data)

        #expect(oauth.accessToken == "access-123")
        #expect(oauth.refreshToken == "refresh-456")
        #expect(oauth.expiresAt == 1704067200000)
    }

    @Test("Handles optional fields being null")
    func handlesNullOptionalFields() throws {
        let json = """
        {
            "accessToken": "access-123",
            "refreshToken": null,
            "expiresAt": null
        }
        """
        let data = json.data(using: .utf8)!
        let oauth = try JSONDecoder().decode(OAuthCredentials.self, from: data)

        #expect(oauth.accessToken == "access-123")
        #expect(oauth.refreshToken == nil)
        #expect(oauth.expiresAt == nil)
    }

    @Test("Converts expiresAt milliseconds to Date correctly")
    func convertsExpiresAtToDate() throws {
        let json = """
        {
            "accessToken": "access-123",
            "expiresAt": 1704067200000
        }
        """
        let data = json.data(using: .utf8)!
        let oauth = try JSONDecoder().decode(OAuthCredentials.self, from: data)

        // 1704067200000 ms = 1704067200 seconds = Jan 1, 2024 00:00:00 UTC
        let expectedDate = Date(timeIntervalSince1970: 1704067200)
        let actualDate = oauth.expiresAt.map { Date(timeIntervalSince1970: $0 / 1000) }

        #expect(actualDate == expectedDate)
    }
}

// MARK: - KeychainCredentialsRepository Tests

@Suite("KeychainCredentialsRepository Tests")
struct KeychainCredentialsRepositoryTests {
    @Test("Repository is Sendable")
    func repositoryIsSendable() async {
        let repo = KeychainCredentialsRepository()

        // If this compiles, the type is Sendable
        // We're testing that the actor conforms to Sendable
        let _: any Sendable = repo
        #expect(Bool(true))
    }

    @Test("Repository uses default service name")
    func repositoryUsesDefaultServiceName() async {
        // Verifies the repository initializes without error with default service name
        let repo = KeychainCredentialsRepository()
        // The fact that we can call hasCredentials proves initialization succeeded
        _ = await repo.hasCredentials()
        #expect(Bool(true))
    }

    @Test("Repository accepts custom service name")
    func repositoryAcceptsCustomServiceName() async {
        // Verifies the repository initializes without error with custom service name
        let repo = KeychainCredentialsRepository(serviceName: "custom-service")
        // The fact that we can call hasCredentials proves initialization succeeded
        _ = await repo.hasCredentials()
        #expect(Bool(true))
    }

    @Test("hasCredentials returns false for non-existent service")
    func hasCredentialsReturnsFalseForNonExistentService() async {
        // Use a random service name that definitely won't exist
        let repo = KeychainCredentialsRepository(serviceName: "non-existent-service-\(UUID().uuidString)")
        let hasCredentials = await repo.hasCredentials()

        #expect(hasCredentials == false)
    }

    @Test("getCredentials throws notAuthenticated for non-existent service")
    func getCredentialsThrowsForNonExistentService() async {
        let repo = KeychainCredentialsRepository(serviceName: "non-existent-service-\(UUID().uuidString)")

        do {
            _ = try await repo.getCredentials()
            #expect(Bool(false), "Expected notAuthenticated error")
        } catch let error as AppError {
            #expect(error == AppError.notAuthenticated)
        } catch {
            #expect(Bool(false), "Expected AppError.notAuthenticated but got \(error)")
        }
    }

    @Test("Repository conforms to CredentialsRepository protocol")
    func repositoryConformsToProtocol() async {
        let repo: any CredentialsRepository = KeychainCredentialsRepository()

        // Verify protocol methods exist and can be called
        _ = await repo.hasCredentials()
        #expect(Bool(true))
    }
}
