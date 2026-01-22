import Foundation

// MARK: - AppError

/// Application-level errors that can occur during operation.
public enum AppError: Error, Sendable, Equatable {
    /// User is not authenticated with Claude Code.
    /// Prompt user to run `claude login` in terminal.
    case notAuthenticated

    /// API returned an error response.
    /// - Parameters:
    ///   - statusCode: HTTP status code
    ///   - message: Error message from the API
    case apiError(statusCode: Int, message: String)

    /// Network request failed.
    /// - Parameter message: Description of the network failure
    case networkError(message: String)

    /// Failed to read credentials from Keychain.
    /// - Parameter message: Description of the keychain failure
    case keychainError(message: String)

    /// Failed to decode API response.
    /// - Parameter message: Description of the decoding failure
    case decodingError(message: String)

    /// Rate limited by the API.
    /// - Parameter retryAfter: Seconds to wait before retrying
    case rateLimited(retryAfter: Int)
}

// MARK: - LocalizedError

extension AppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Claude Code"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .rateLimited(let retryAfter):
            return "Rate limited. Retry after \(retryAfter) seconds"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated:
            return "Run `claude login` in terminal to authenticate"
        case .apiError:
            return "Try again later"
        case .networkError:
            return "Check your internet connection"
        case .keychainError:
            return "Ensure Claude Code is installed and authenticated"
        case .decodingError:
            return "The API response format may have changed"
        case .rateLimited(let retryAfter):
            return "Wait \(retryAfter) seconds before retrying"
        }
    }
}
