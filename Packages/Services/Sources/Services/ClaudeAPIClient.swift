import Domain
import Foundation

// MARK: - ClaudeAPIClient

/// API client for fetching usage data from the Anthropic OAuth API.
/// Thread-safe actor that implements `UsageRepository` protocol from Domain.
public actor ClaudeAPIClient: UsageRepository {
    /// Base URL for the Anthropic API
    private let baseURL: URL

    /// URL session for network requests
    private let session: URLSession

    /// Repository for retrieving OAuth credentials
    private let credentialsRepository: CredentialsRepository

    /// User agent string for API requests
    private let userAgent: String

    /// Initializes the API client with dependencies.
    /// - Parameters:
    ///   - baseURL: Base URL for the Anthropic API. Defaults to production URL.
    ///   - session: URL session for network requests. Defaults to shared session.
    ///   - credentialsRepository: Repository for retrieving OAuth credentials.
    ///   - userAgent: User agent string for API requests. Defaults to "ClaudeApp/1.0.0".
    public init(
        baseURL: URL = URL(string: "https://api.anthropic.com")!,
        session: URLSession = .shared,
        credentialsRepository: CredentialsRepository,
        userAgent: String = "ClaudeApp/1.0.0"
    ) {
        self.baseURL = baseURL
        self.session = session
        self.credentialsRepository = credentialsRepository
        self.userAgent = userAgent
    }

    /// Fetches the current usage data from the Anthropic API.
    /// - Returns: The current usage data across all windows
    /// - Throws: `AppError` if the fetch fails
    public func fetchUsage() async throws -> UsageData {
        let credentials = try await credentialsRepository.getCredentials()
        let request = try buildRequest(with: credentials)
        let (data, response) = try await performRequest(request)
        return try handleResponse(data: data, response: response)
    }

    // MARK: - Private Methods

    /// Builds the URL request with required headers.
    /// - Parameter credentials: OAuth credentials for authorization
    /// - Returns: Configured URL request
    private func buildRequest(with credentials: Credentials) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("api/oauth/usage")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Required headers per API specification
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        return request
    }

    /// Performs the network request with error handling.
    /// - Parameter request: The URL request to perform
    /// - Returns: Tuple of response data and URL response
    /// - Throws: `AppError.networkError` if the request fails
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw AppError.networkError(message: error.localizedDescription)
        }
    }

    /// Handles the API response, decoding data or mapping errors.
    /// - Parameters:
    ///   - data: Response body data
    ///   - response: URL response object
    /// - Returns: Decoded `UsageData`
    /// - Throws: Appropriate `AppError` based on response status
    private func handleResponse(data: Data, response: URLResponse) throws -> UsageData {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError(message: "Invalid response type")
        }

        switch httpResponse.statusCode {
        case 200:
            return try decodeUsageData(from: data)

        case 401:
            throw AppError.notAuthenticated

        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "retry-after")
                .flatMap { Int($0) } ?? 60
            throw AppError.rateLimited(retryAfter: retryAfter)

        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.apiError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    /// Decodes the API response into domain `UsageData`.
    /// - Parameter data: JSON response data
    /// - Returns: Decoded `UsageData`
    /// - Throws: `AppError.decodingError` if decoding fails
    private func decodeUsageData(from data: Data) throws -> UsageData {
        let decoder = JSONDecoder()

        let apiResponse: APIUsageResponse
        do {
            apiResponse = try decoder.decode(APIUsageResponse.self, from: data)
        } catch {
            throw AppError.decodingError(message: error.localizedDescription)
        }

        return apiResponse.toUsageData()
    }
}

// MARK: - API Response Models (Internal)

/// Internal model representing the API response structure.
/// Uses snake_case coding keys to match API format.
struct APIUsageResponse: Decodable {
    let fiveHour: APIUsageWindow
    let sevenDay: APIUsageWindow
    let sevenDayOpus: APIUsageWindow?
    let sevenDaySonnet: APIUsageWindow?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
        case sevenDaySonnet = "seven_day_sonnet"
    }

    /// Converts API response to domain model.
    func toUsageData() -> UsageData {
        UsageData(
            fiveHour: fiveHour.toUsageWindow(),
            sevenDay: sevenDay.toUsageWindow(),
            sevenDayOpus: sevenDayOpus?.toUsageWindow(),
            sevenDaySonnet: sevenDaySonnet?.toUsageWindow(),
            fetchedAt: Date()
        )
    }
}

/// Internal model representing a usage window from the API.
struct APIUsageWindow: Decodable {
    let utilization: Double
    let resetsAt: Date?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        utilization = try container.decode(Double.self, forKey: .utilization)

        // Parse ISO 8601 date with fractional seconds
        if let dateString = try container.decodeIfPresent(String.self, forKey: .resetsAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            resetsAt = formatter.date(from: dateString)
        } else {
            resetsAt = nil
        }
    }

    /// Converts API model to domain model.
    func toUsageWindow() -> UsageWindow {
        UsageWindow(utilization: utilization, resetsAt: resetsAt)
    }
}
