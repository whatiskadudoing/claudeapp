import Foundation
import Testing
@testable import Domain

@Suite("Domain Tests")
struct DomainTests {
    @Test("Domain version is correct")
    func domainVersion() {
        #expect(Domain.version == "1.0.0")
    }
}

// MARK: - UsageWindow Tests

@Suite("UsageWindow Tests")
struct UsageWindowTests {
    @Test("UsageWindow initializes with utilization only")
    func initWithUtilizationOnly() {
        let window = UsageWindow(utilization: 45.5)

        #expect(window.utilization == 45.5)
        #expect(window.resetsAt == nil)
    }

    @Test("UsageWindow initializes with utilization and reset date")
    func initWithUtilizationAndResetDate() {
        let resetDate = Date()
        let window = UsageWindow(utilization: 75.0, resetsAt: resetDate)

        #expect(window.utilization == 75.0)
        #expect(window.resetsAt == resetDate)
    }

    @Test("UsageWindow is Equatable")
    func equatable() {
        let date = Date()
        let window1 = UsageWindow(utilization: 50.0, resetsAt: date)
        let window2 = UsageWindow(utilization: 50.0, resetsAt: date)
        let window3 = UsageWindow(utilization: 60.0, resetsAt: date)

        #expect(window1 == window2)
        #expect(window1 != window3)
    }
}

// MARK: - UsageData Tests

@Suite("UsageData Tests")
struct UsageDataTests {
    @Test("UsageData initializes with required fields")
    func initWithRequiredFields() {
        let fiveHour = UsageWindow(utilization: 30.0)
        let sevenDay = UsageWindow(utilization: 50.0)
        let fetchedAt = Date()

        let data = UsageData(
            fiveHour: fiveHour,
            sevenDay: sevenDay,
            fetchedAt: fetchedAt
        )

        #expect(data.fiveHour.utilization == 30.0)
        #expect(data.sevenDay.utilization == 50.0)
        #expect(data.sevenDayOpus == nil)
        #expect(data.sevenDaySonnet == nil)
        #expect(data.fetchedAt == fetchedAt)
    }

    @Test("UsageData initializes with all fields")
    func initWithAllFields() {
        let fiveHour = UsageWindow(utilization: 30.0)
        let sevenDay = UsageWindow(utilization: 50.0)
        let opus = UsageWindow(utilization: 20.0)
        let sonnet = UsageWindow(utilization: 80.0)

        let data = UsageData(
            fiveHour: fiveHour,
            sevenDay: sevenDay,
            sevenDayOpus: opus,
            sevenDaySonnet: sonnet
        )

        #expect(data.sevenDayOpus?.utilization == 20.0)
        #expect(data.sevenDaySonnet?.utilization == 80.0)
    }

    @Test("highestUtilization returns max from fiveHour")
    func highestUtilizationFiveHour() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 90.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: UsageWindow(utilization: 20.0),
            sevenDaySonnet: UsageWindow(utilization: 30.0)
        )

        #expect(data.highestUtilization == 90.0)
    }

    @Test("highestUtilization returns max from sevenDay")
    func highestUtilizationSevenDay() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 85.0),
            sevenDayOpus: UsageWindow(utilization: 20.0),
            sevenDaySonnet: UsageWindow(utilization: 40.0)
        )

        #expect(data.highestUtilization == 85.0)
    }

    @Test("highestUtilization returns max from optional windows")
    func highestUtilizationOptional() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: UsageWindow(utilization: 95.0),
            sevenDaySonnet: nil
        )

        #expect(data.highestUtilization == 95.0)
    }

    @Test("highestUtilization handles nil optional windows")
    func highestUtilizationNilOptionals() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: nil,
            sevenDaySonnet: nil
        )

        #expect(data.highestUtilization == 50.0)
    }

    @Test("UsageData is Equatable")
    func equatable() {
        let date = Date()
        let data1 = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            fetchedAt: date
        )
        let data2 = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            fetchedAt: date
        )
        let data3 = UsageData(
            fiveHour: UsageWindow(utilization: 40.0),
            sevenDay: UsageWindow(utilization: 50.0),
            fetchedAt: date
        )

        #expect(data1 == data2)
        #expect(data1 != data3)
    }

    @Test("utilization(for:) returns correct values for each source")
    func utilizationForSource() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: UsageWindow(utilization: 20.0),
            sevenDaySonnet: UsageWindow(utilization: 80.0)
        )

        #expect(data.utilization(for: .highest) == 80.0)
        #expect(data.utilization(for: .session) == 30.0)
        #expect(data.utilization(for: .weekly) == 50.0)
        #expect(data.utilization(for: .opus) == 20.0)
        #expect(data.utilization(for: .sonnet) == 80.0)
    }

    @Test("utilization(for:) falls back to highest when opus is nil")
    func utilizationForSourceOpusFallback() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: nil,
            sevenDaySonnet: UsageWindow(utilization: 40.0)
        )

        // When opus is nil, should fall back to highest (which is 50.0)
        #expect(data.utilization(for: .opus) == 50.0)
    }

    @Test("utilization(for:) falls back to highest when sonnet is nil")
    func utilizationForSourceSonnetFallback() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 60.0),
            sevenDayOpus: UsageWindow(utilization: 20.0),
            sevenDaySonnet: nil
        )

        // When sonnet is nil, should fall back to highest (which is 60.0)
        #expect(data.utilization(for: .sonnet) == 60.0)
    }
}

// MARK: - Credentials Tests

@Suite("Credentials Tests")
struct CredentialsTests {
    @Test("Credentials initializes with access token only")
    func initWithAccessTokenOnly() {
        let credentials = Credentials(accessToken: "test-token")

        #expect(credentials.accessToken == "test-token")
        #expect(credentials.refreshToken == nil)
        #expect(credentials.expiresAt == nil)
    }

    @Test("Credentials initializes with all fields")
    func initWithAllFields() {
        let expiresAt = Date().addingTimeInterval(3600)
        let credentials = Credentials(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: expiresAt
        )

        #expect(credentials.accessToken == "access-token")
        #expect(credentials.refreshToken == "refresh-token")
        #expect(credentials.expiresAt == expiresAt)
    }

    @Test("isExpired returns false when expiresAt is nil")
    func isExpiredNilExpiration() {
        let credentials = Credentials(accessToken: "test-token")

        #expect(credentials.isExpired == false)
    }

    @Test("isExpired returns false when not expired")
    func isExpiredNotExpired() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let credentials = Credentials(accessToken: "test-token", expiresAt: futureDate)

        #expect(credentials.isExpired == false)
    }

    @Test("isExpired returns true when expired")
    func isExpiredExpired() {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let credentials = Credentials(accessToken: "test-token", expiresAt: pastDate)

        #expect(credentials.isExpired == true)
    }
}

// MARK: - AppError Tests

@Suite("AppError Tests")
struct AppErrorTests {
    @Test("AppError cases are distinct")
    func casesAreDistinct() {
        let notAuthenticated = AppError.notAuthenticated
        let apiError = AppError.apiError(statusCode: 401, message: "Unauthorized")
        let networkError = AppError.networkError(message: "Connection failed")
        let keychainError = AppError.keychainError(message: "Access denied")
        let decodingError = AppError.decodingError(message: "Invalid JSON")
        let rateLimited = AppError.rateLimited(retryAfter: 60)

        #expect(notAuthenticated != apiError)
        #expect(apiError != networkError)
        #expect(networkError != keychainError)
        #expect(keychainError != decodingError)
        #expect(decodingError != rateLimited)
    }

    @Test("AppError.notAuthenticated has correct description")
    func notAuthenticatedDescription() {
        let error = AppError.notAuthenticated

        #expect(error.errorDescription?.contains("Not authenticated") == true)
        #expect(error.recoverySuggestion?.contains("claude login") == true)
    }

    @Test("AppError.apiError includes status code")
    func apiErrorDescription() {
        let error = AppError.apiError(statusCode: 500, message: "Server error")

        #expect(error.errorDescription?.contains("500") == true)
        #expect(error.errorDescription?.contains("Server error") == true)
    }

    @Test("AppError.rateLimited includes retry time")
    func rateLimitedDescription() {
        let error = AppError.rateLimited(retryAfter: 120)

        #expect(error.errorDescription?.contains("120") == true)
        #expect(error.recoverySuggestion?.contains("120") == true)
    }

    @Test("AppError is Equatable with same values")
    func equatableSameValues() {
        let error1 = AppError.apiError(statusCode: 401, message: "Test")
        let error2 = AppError.apiError(statusCode: 401, message: "Test")

        #expect(error1 == error2)
    }

    @Test("AppError is Equatable with different values")
    func equatableDifferentValues() {
        let error1 = AppError.apiError(statusCode: 401, message: "Test")
        let error2 = AppError.apiError(statusCode: 500, message: "Test")

        #expect(error1 != error2)
    }
}
