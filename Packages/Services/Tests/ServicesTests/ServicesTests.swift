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

// MARK: - ClaudeAPIClient Tests

@Suite("ClaudeAPIClient Tests")
struct ClaudeAPIClientTests {
    @Test("Client is Sendable")
    func clientIsSendable() async {
        let mockCredentialsRepo = MockCredentialsRepository()
        let client = ClaudeAPIClient(credentialsRepository: mockCredentialsRepo)

        // If this compiles, the type is Sendable
        let _: any Sendable = client
        #expect(Bool(true))
    }

    @Test("Client conforms to UsageRepository protocol")
    func clientConformsToUsageRepository() async {
        let mockCredentialsRepo = MockCredentialsRepository()
        let client: any UsageRepository = ClaudeAPIClient(credentialsRepository: mockCredentialsRepo)

        // Verify protocol type conformance
        #expect(client is ClaudeAPIClient)
    }

    @Test("Client uses default base URL")
    func clientUsesDefaultBaseURL() async {
        let mockCredentialsRepo = MockCredentialsRepository()
        let _ = ClaudeAPIClient(credentialsRepository: mockCredentialsRepo)

        // If this compiles without error, the default URL is valid
        #expect(Bool(true))
    }

    @Test("Client accepts custom base URL")
    func clientAcceptsCustomBaseURL() async {
        let mockCredentialsRepo = MockCredentialsRepository()
        let customURL = URL(string: "https://custom.api.example.com")!
        let _ = ClaudeAPIClient(baseURL: customURL, credentialsRepository: mockCredentialsRepo)

        #expect(Bool(true))
    }

    @Test("Client accepts custom user agent")
    func clientAcceptsCustomUserAgent() async {
        let mockCredentialsRepo = MockCredentialsRepository()
        let _ = ClaudeAPIClient(credentialsRepository: mockCredentialsRepo, userAgent: "CustomApp/2.0.0")

        #expect(Bool(true))
    }
}

// MARK: - APIUsageResponse Tests

@Suite("APIUsageResponse Parsing Tests")
struct APIUsageResponseParsingTests {
    @Test("Parses full API response with all fields")
    func parsesFullApiResponse() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 33.0,
                "resets_at": "2026-01-22T20:59:59.644126+00:00"
            },
            "seven_day": {
                "utilization": 32.0,
                "resets_at": "2026-01-28T01:59:59.644147+00:00"
            },
            "seven_day_opus": {
                "utilization": 15.0,
                "resets_at": "2026-01-28T01:59:59.644147+00:00"
            },
            "seven_day_sonnet": {
                "utilization": 2.0,
                "resets_at": "2026-01-28T13:59:59.644155+00:00"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIUsageResponse.self, from: data)

        #expect(response.fiveHour.utilization == 33.0)
        #expect(response.sevenDay.utilization == 32.0)
        #expect(response.sevenDayOpus?.utilization == 15.0)
        #expect(response.sevenDaySonnet?.utilization == 2.0)
    }

    @Test("Parses API response with null optional fields")
    func parsesApiResponseWithNullOptionalFields() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 45.5,
                "resets_at": "2026-01-22T15:59:59.943648+00:00"
            },
            "seven_day": {
                "utilization": 72.3,
                "resets_at": "2026-01-25T03:59:59.943679+00:00"
            },
            "seven_day_opus": null,
            "seven_day_sonnet": null
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIUsageResponse.self, from: data)

        #expect(response.fiveHour.utilization == 45.5)
        #expect(response.sevenDay.utilization == 72.3)
        #expect(response.sevenDayOpus == nil)
        #expect(response.sevenDaySonnet == nil)
    }

    @Test("Parses API response without optional fields")
    func parsesApiResponseWithoutOptionalFields() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 50.0,
                "resets_at": null
            },
            "seven_day": {
                "utilization": 60.0,
                "resets_at": null
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIUsageResponse.self, from: data)

        #expect(response.fiveHour.utilization == 50.0)
        #expect(response.fiveHour.resetsAt == nil)
        #expect(response.sevenDay.utilization == 60.0)
        #expect(response.sevenDay.resetsAt == nil)
        #expect(response.sevenDayOpus == nil)
        #expect(response.sevenDaySonnet == nil)
    }

    @Test("Converts API response to UsageData correctly")
    func convertsToUsageData() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 33.0,
                "resets_at": "2026-01-22T20:59:59.644126+00:00"
            },
            "seven_day": {
                "utilization": 72.0,
                "resets_at": "2026-01-28T01:59:59.644147+00:00"
            },
            "seven_day_opus": {
                "utilization": 15.0,
                "resets_at": null
            },
            "seven_day_sonnet": null
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIUsageResponse.self, from: data)
        let usageData = response.toUsageData()

        #expect(usageData.fiveHour.utilization == 33.0)
        #expect(usageData.sevenDay.utilization == 72.0)
        #expect(usageData.sevenDayOpus?.utilization == 15.0)
        #expect(usageData.sevenDaySonnet == nil)
        #expect(usageData.highestUtilization == 72.0)
    }

    @Test("Ignores extra fields in API response")
    func ignoresExtraFields() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 33.0,
                "resets_at": null
            },
            "seven_day": {
                "utilization": 32.0,
                "resets_at": null
            },
            "seven_day_oauth_apps": null,
            "iguana_necktie": null,
            "extra_usage": {
                "is_enabled": false,
                "monthly_limit": null,
                "used_credits": null,
                "utilization": null
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIUsageResponse.self, from: data)

        #expect(response.fiveHour.utilization == 33.0)
        #expect(response.sevenDay.utilization == 32.0)
    }
}

// MARK: - APIUsageWindow Tests

@Suite("APIUsageWindow Parsing Tests")
struct APIUsageWindowParsingTests {
    @Test("Parses ISO 8601 date with fractional seconds")
    func parsesIso8601DateWithFractionalSeconds() throws {
        let json = """
        {
            "utilization": 45.5,
            "resets_at": "2026-01-22T20:59:59.644126+00:00"
        }
        """
        let data = json.data(using: .utf8)!
        let window = try JSONDecoder().decode(APIUsageWindow.self, from: data)

        #expect(window.utilization == 45.5)
        #expect(window.resetsAt != nil)
    }

    @Test("Handles null resets_at")
    func handlesNullResetsAt() throws {
        let json = """
        {
            "utilization": 75.0,
            "resets_at": null
        }
        """
        let data = json.data(using: .utf8)!
        let window = try JSONDecoder().decode(APIUsageWindow.self, from: data)

        #expect(window.utilization == 75.0)
        #expect(window.resetsAt == nil)
    }

    @Test("Converts to UsageWindow correctly")
    func convertsToUsageWindow() throws {
        let json = """
        {
            "utilization": 50.0,
            "resets_at": "2026-01-22T15:00:00.000000+00:00"
        }
        """
        let data = json.data(using: .utf8)!
        let apiWindow = try JSONDecoder().decode(APIUsageWindow.self, from: data)
        let usageWindow = apiWindow.toUsageWindow()

        #expect(usageWindow.utilization == 50.0)
        #expect(usageWindow.resetsAt != nil)
    }
}

// MARK: - Mock Credentials Repository

/// Mock credentials repository for testing ClaudeAPIClient
actor MockCredentialsRepository: CredentialsRepository {
    var shouldSucceed: Bool
    var credentials: Credentials

    init(
        shouldSucceed: Bool = true,
        credentials: Credentials = Credentials(accessToken: "test-token")
    ) {
        self.shouldSucceed = shouldSucceed
        self.credentials = credentials
    }

    func getCredentials() async throws -> Credentials {
        guard shouldSucceed else {
            throw AppError.notAuthenticated
        }
        return credentials
    }

    func hasCredentials() async -> Bool {
        shouldSucceed
    }
}
