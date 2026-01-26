import Domain
import Foundation

// MARK: - KeychainCredentialsRepository

/// Repository that reads OAuth credentials from the macOS Keychain.
/// Uses the `/usr/bin/security` CLI tool to access credentials stored by Claude Code.
public actor KeychainCredentialsRepository: CredentialsRepository {
    /// The service name used by Claude Code to store credentials in Keychain.
    private let serviceName: String

    /// Initializes the repository with the service name for Keychain lookups.
    /// - Parameter serviceName: The Keychain service name. Defaults to "Claude Code-credentials".
    public init(serviceName: String = "Claude Code-credentials") {
        self.serviceName = serviceName
    }

    /// Retrieves OAuth credentials from the macOS Keychain.
    /// - Returns: The stored OAuth credentials
    /// - Throws: `AppError.notAuthenticated` if no credentials exist,
    ///           `AppError.keychainError` if credentials cannot be read or parsed
    public func getCredentials() async throws -> Credentials {
        let jsonString = try await readFromKeychain()
        return try parseCredentials(from: jsonString)
    }

    /// Checks if valid credentials exist in the Keychain.
    /// - Returns: `true` if credentials are available and readable
    public func hasCredentials() async -> Bool {
        do {
            _ = try await getCredentials()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private Methods

    /// Reads the raw JSON string from the Keychain using the security CLI.
    /// - Returns: The JSON string containing credentials
    /// - Throws: `AppError.notAuthenticated` if the keychain entry doesn't exist,
    ///           `AppError.keychainError` if the command fails or output is invalid
    private func readFromKeychain() async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", serviceName, "-w"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw AppError.keychainError(message: "Failed to execute security command: \(error.localizedDescription)")
        }

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            // Exit code 44 means "item not found"
            // Any non-zero exit typically means credentials don't exist
            throw AppError.notAuthenticated
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let jsonString = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw AppError.keychainError(message: "Failed to decode keychain output as UTF-8")
        }

        guard !jsonString.isEmpty else {
            throw AppError.keychainError(message: "Keychain entry is empty")
        }

        return jsonString
    }

    /// Parses the JSON string into Credentials.
    /// - Parameter jsonString: The raw JSON from the Keychain
    /// - Returns: Parsed Credentials object
    /// - Throws: `AppError.notAuthenticated` if OAuth credentials are missing,
    ///           `AppError.keychainError` if JSON parsing fails
    private func parseCredentials(from jsonString: String) throws -> Credentials {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AppError.keychainError(message: "Failed to convert JSON string to data")
        }

        let keychainCredentials: KeychainCredentials
        do {
            keychainCredentials = try JSONDecoder().decode(KeychainCredentials.self, from: jsonData)
        } catch {
            throw AppError.keychainError(message: "Failed to parse credentials JSON: \(error.localizedDescription)")
        }

        guard let oauth = keychainCredentials.claudeAiOauth else {
            throw AppError.notAuthenticated
        }

        return Credentials(
            accessToken: oauth.accessToken,
            refreshToken: oauth.refreshToken,
            expiresAt: oauth.expiresAt.map { Date(timeIntervalSince1970: $0 / 1000) },
            subscriptionType: oauth.subscriptionType,
            rateLimitTier: oauth.rateLimitTier
        )
    }
}

// MARK: - KeychainCredentials (Internal JSON Model)

/// Internal model representing the JSON structure stored in the Keychain by Claude Code.
struct KeychainCredentials: Decodable {
    let claudeAiOauth: OAuthCredentials?

    enum CodingKeys: String, CodingKey {
        case claudeAiOauth
    }
}

/// OAuth credentials structure within the Keychain JSON.
struct OAuthCredentials: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Double? // Unix timestamp in milliseconds
    let subscriptionType: String?
    let rateLimitTier: String?

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case expiresAt
        case subscriptionType
        case rateLimitTier
    }
}
