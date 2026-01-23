import Foundation
import Testing
@testable import Domain

@Suite("Domain Tests")
struct DomainTests {
    @Test("Domain version is correct")
    func domainVersion() {
        #expect(Domain.version == "1.2.0")
    }
}

// MARK: - BurnRateLevel Tests

@Suite("BurnRateLevel Tests")
struct BurnRateLevelTests {
    @Test("BurnRateLevel raw values are correct")
    func rawValues() {
        #expect(BurnRateLevel.low.rawValue == "Low")
        #expect(BurnRateLevel.medium.rawValue == "Med")
        #expect(BurnRateLevel.high.rawValue == "High")
        #expect(BurnRateLevel.veryHigh.rawValue == "V.High")
    }

    @Test("BurnRateLevel color values are correct")
    func colorValues() {
        #expect(BurnRateLevel.low.color == "green")
        #expect(BurnRateLevel.medium.color == "yellow")
        #expect(BurnRateLevel.high.color == "orange")
        #expect(BurnRateLevel.veryHigh.color == "red")
    }

    @Test("BurnRateLevel conforms to CaseIterable")
    func caseIterable() {
        let allCases = BurnRateLevel.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.low))
        #expect(allCases.contains(.medium))
        #expect(allCases.contains(.high))
        #expect(allCases.contains(.veryHigh))
    }

    @Test("BurnRateLevel is Equatable")
    func equatable() {
        #expect(BurnRateLevel.low == BurnRateLevel.low)
        #expect(BurnRateLevel.low != BurnRateLevel.high)
    }

    @Test("BurnRateLevel is Codable")
    func codable() throws {
        let level = BurnRateLevel.medium
        let data = try JSONEncoder().encode(level)
        let decoded = try JSONDecoder().decode(BurnRateLevel.self, from: data)
        #expect(decoded == level)
    }
}

// MARK: - BurnRate Tests

@Suite("BurnRate Tests")
struct BurnRateTests {
    @Test("BurnRate initializes with percentPerHour")
    func initialization() {
        let burnRate = BurnRate(percentPerHour: 15.0)
        #expect(burnRate.percentPerHour == 15.0)
    }

    @Test("BurnRate level is low for rates below 10")
    func levelLow() {
        #expect(BurnRate(percentPerHour: 0.0).level == .low)
        #expect(BurnRate(percentPerHour: 5.0).level == .low)
        #expect(BurnRate(percentPerHour: 9.9).level == .low)
    }

    @Test("BurnRate level is medium for rates 10-25")
    func levelMedium() {
        #expect(BurnRate(percentPerHour: 10.0).level == .medium)
        #expect(BurnRate(percentPerHour: 15.0).level == .medium)
        #expect(BurnRate(percentPerHour: 24.9).level == .medium)
    }

    @Test("BurnRate level is high for rates 25-50")
    func levelHigh() {
        #expect(BurnRate(percentPerHour: 25.0).level == .high)
        #expect(BurnRate(percentPerHour: 35.0).level == .high)
        #expect(BurnRate(percentPerHour: 49.9).level == .high)
    }

    @Test("BurnRate level is veryHigh for rates above 50")
    func levelVeryHigh() {
        #expect(BurnRate(percentPerHour: 50.0).level == .veryHigh)
        #expect(BurnRate(percentPerHour: 75.0).level == .veryHigh)
        #expect(BurnRate(percentPerHour: 100.0).level == .veryHigh)
    }

    @Test("BurnRate level threshold edge cases")
    func levelThresholdEdgeCases() {
        // Exactly at boundaries
        #expect(BurnRate(percentPerHour: 10.0).level == .medium)
        #expect(BurnRate(percentPerHour: 25.0).level == .high)
        #expect(BurnRate(percentPerHour: 50.0).level == .veryHigh)

        // Just below boundaries
        #expect(BurnRate(percentPerHour: 9.999).level == .low)
        #expect(BurnRate(percentPerHour: 24.999).level == .medium)
        #expect(BurnRate(percentPerHour: 49.999).level == .high)
    }

    @Test("BurnRate displayString formats correctly")
    func displayString() {
        #expect(BurnRate(percentPerHour: 15.0).displayString == "15%/hr")
        #expect(BurnRate(percentPerHour: 0.0).displayString == "0%/hr")
        #expect(BurnRate(percentPerHour: 100.0).displayString == "100%/hr")
        #expect(BurnRate(percentPerHour: 15.7).displayString == "16%/hr") // Rounds
    }

    @Test("BurnRate displayString rounds decimals")
    func displayStringRounding() {
        #expect(BurnRate(percentPerHour: 15.4).displayString == "15%/hr")
        #expect(BurnRate(percentPerHour: 15.5).displayString == "16%/hr")
        #expect(BurnRate(percentPerHour: 15.9).displayString == "16%/hr")
    }

    @Test("BurnRate is Equatable")
    func equatable() {
        let rate1 = BurnRate(percentPerHour: 15.0)
        let rate2 = BurnRate(percentPerHour: 15.0)
        let rate3 = BurnRate(percentPerHour: 20.0)

        #expect(rate1 == rate2)
        #expect(rate1 != rate3)
    }

    @Test("BurnRate is Sendable")
    func sendable() async {
        let burnRate = BurnRate(percentPerHour: 15.0)

        // Verify it can be passed across actor boundaries
        let result = await Task.detached {
            burnRate.percentPerHour
        }.value

        #expect(result == 15.0)
    }

    @Test("BurnRate is Codable")
    func codable() throws {
        let burnRate = BurnRate(percentPerHour: 25.5)
        let data = try JSONEncoder().encode(burnRate)
        let decoded = try JSONDecoder().decode(BurnRate.self, from: data)

        #expect(decoded == burnRate)
        #expect(decoded.percentPerHour == 25.5)
    }

    @Test("BurnRate handles negative values")
    func negativeValues() {
        // Negative rates can occur during resets but should map to low
        let negativeRate = BurnRate(percentPerHour: -5.0)
        #expect(negativeRate.level == .low)
        #expect(negativeRate.displayString == "-5%/hr")
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

    @Test("UsageWindow initializes with burn rate")
    func initWithBurnRate() {
        let burnRate = BurnRate(percentPerHour: 15.0)
        let window = UsageWindow(utilization: 45.5, burnRate: burnRate)

        #expect(window.utilization == 45.5)
        #expect(window.resetsAt == nil)
        #expect(window.burnRate?.percentPerHour == 15.0)
        #expect(window.timeToExhaustion == nil)
    }

    @Test("UsageWindow initializes with time to exhaustion")
    func initWithTimeToExhaustion() {
        let window = UsageWindow(utilization: 50.0, timeToExhaustion: 7200.0)

        #expect(window.utilization == 50.0)
        #expect(window.burnRate == nil)
        #expect(window.timeToExhaustion == 7200.0)
    }

    @Test("UsageWindow initializes with all burn rate properties")
    func initWithAllBurnRateProperties() {
        let resetDate = Date()
        let burnRate = BurnRate(percentPerHour: 25.0)
        let window = UsageWindow(
            utilization: 60.0,
            resetsAt: resetDate,
            burnRate: burnRate,
            timeToExhaustion: 5400.0
        )

        #expect(window.utilization == 60.0)
        #expect(window.resetsAt == resetDate)
        #expect(window.burnRate == burnRate)
        #expect(window.burnRate?.level == .high)
        #expect(window.timeToExhaustion == 5400.0)
    }

    @Test("UsageWindow burn rate defaults to nil")
    func burnRateDefaultsToNil() {
        let window = UsageWindow(utilization: 30.0)

        #expect(window.burnRate == nil)
        #expect(window.timeToExhaustion == nil)
    }

    @Test("UsageWindow equality considers burn rate properties")
    func equalityWithBurnRate() {
        let burnRate = BurnRate(percentPerHour: 20.0)
        let window1 = UsageWindow(utilization: 50.0, burnRate: burnRate, timeToExhaustion: 3600.0)
        let window2 = UsageWindow(utilization: 50.0, burnRate: burnRate, timeToExhaustion: 3600.0)
        let window3 = UsageWindow(utilization: 50.0, burnRate: burnRate, timeToExhaustion: 7200.0)
        let window4 = UsageWindow(utilization: 50.0, burnRate: nil, timeToExhaustion: 3600.0)

        #expect(window1 == window2)
        #expect(window1 != window3)
        #expect(window1 != window4)
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

    @Test("highestBurnRate returns nil when no windows have burn rate")
    func highestBurnRateNil() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: UsageWindow(utilization: 20.0),
            sevenDaySonnet: UsageWindow(utilization: 40.0)
        )

        #expect(data.highestBurnRate == nil)
    }

    @Test("highestBurnRate returns the only burn rate when one exists")
    func highestBurnRateSingle() {
        let burnRate = BurnRate(percentPerHour: 15.0)
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0, burnRate: burnRate),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: nil,
            sevenDaySonnet: nil
        )

        #expect(data.highestBurnRate?.percentPerHour == 15.0)
    }

    @Test("highestBurnRate returns max from fiveHour")
    func highestBurnRateFiveHour() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0, burnRate: BurnRate(percentPerHour: 60.0)),
            sevenDay: UsageWindow(utilization: 50.0, burnRate: BurnRate(percentPerHour: 20.0)),
            sevenDayOpus: UsageWindow(utilization: 20.0, burnRate: BurnRate(percentPerHour: 10.0)),
            sevenDaySonnet: UsageWindow(utilization: 40.0, burnRate: BurnRate(percentPerHour: 30.0))
        )

        #expect(data.highestBurnRate?.percentPerHour == 60.0)
        #expect(data.highestBurnRate?.level == .veryHigh)
    }

    @Test("highestBurnRate returns max from sevenDay")
    func highestBurnRateSevenDay() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0, burnRate: BurnRate(percentPerHour: 5.0)),
            sevenDay: UsageWindow(utilization: 50.0, burnRate: BurnRate(percentPerHour: 35.0)),
            sevenDayOpus: UsageWindow(utilization: 20.0, burnRate: BurnRate(percentPerHour: 10.0)),
            sevenDaySonnet: UsageWindow(utilization: 40.0, burnRate: BurnRate(percentPerHour: 15.0))
        )

        #expect(data.highestBurnRate?.percentPerHour == 35.0)
        #expect(data.highestBurnRate?.level == .high)
    }

    @Test("highestBurnRate returns max from optional windows")
    func highestBurnRateOptional() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0, burnRate: BurnRate(percentPerHour: 5.0)),
            sevenDay: UsageWindow(utilization: 50.0, burnRate: BurnRate(percentPerHour: 10.0)),
            sevenDayOpus: UsageWindow(utilization: 20.0, burnRate: BurnRate(percentPerHour: 45.0)),
            sevenDaySonnet: nil
        )

        #expect(data.highestBurnRate?.percentPerHour == 45.0)
        #expect(data.highestBurnRate?.level == .high)
    }

    @Test("highestBurnRate handles mix of nil and non-nil burn rates")
    func highestBurnRateMixed() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),  // No burn rate
            sevenDay: UsageWindow(utilization: 50.0, burnRate: BurnRate(percentPerHour: 12.0)),
            sevenDayOpus: nil,
            sevenDaySonnet: UsageWindow(utilization: 40.0, burnRate: BurnRate(percentPerHour: 8.0))
        )

        #expect(data.highestBurnRate?.percentPerHour == 12.0)
        #expect(data.highestBurnRate?.level == .medium)
    }

    @Test("highestBurnRate ignores nil optional windows")
    func highestBurnRateNilOptionals() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0, burnRate: BurnRate(percentPerHour: 20.0)),
            sevenDay: UsageWindow(utilization: 50.0, burnRate: BurnRate(percentPerHour: 15.0)),
            sevenDayOpus: nil,
            sevenDaySonnet: nil
        )

        #expect(data.highestBurnRate?.percentPerHour == 20.0)
        #expect(data.highestBurnRate?.level == .medium)
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

// MARK: - Localization Key Tests

@Suite("Localization Key Tests")
struct LocalizationKeyTests {
    // MARK: - BurnRateLevel Localization Keys

    @Test("BurnRateLevel localization keys follow naming convention")
    func burnRateLevelLocalizationKeys() {
        // Keys should be lowercase and match the case names
        #expect(BurnRateLevel.low.localizationKey == "low")
        #expect(BurnRateLevel.medium.localizationKey == "medium")
        #expect(BurnRateLevel.high.localizationKey == "high")
        #expect(BurnRateLevel.veryHigh.localizationKey == "veryHigh")
    }

    @Test("BurnRateLevel all cases have localization keys")
    func burnRateLevelAllCasesHaveKeys() {
        for level in BurnRateLevel.allCases {
            #expect(!level.localizationKey.isEmpty)
        }
    }

    @Test("BurnRateLevel display keys are properly formatted")
    func burnRateLevelDisplayKeys() {
        // The UI uses "burnRate." prefix for display text
        for level in BurnRateLevel.allCases {
            let displayKey = "burnRate.\(level.localizationKey)"
            #expect(displayKey.hasPrefix("burnRate."))
            #expect(displayKey.count > "burnRate.".count)
        }
    }

    @Test("BurnRateLevel accessibility keys are properly formatted")
    func burnRateLevelAccessibilityKeys() {
        // The UI uses "accessibility.burnRate." prefix for VoiceOver
        for level in BurnRateLevel.allCases {
            let accessibilityKey = "accessibility.burnRate.\(level.localizationKey)"
            #expect(accessibilityKey.hasPrefix("accessibility.burnRate."))
            #expect(accessibilityKey.count > "accessibility.burnRate.".count)
        }
    }

    // MARK: - PercentageSource Localization Keys

    @Test("PercentageSource localization keys follow naming convention")
    func percentageSourceLocalizationKeys() {
        // Keys should use "percentageSource." prefix
        #expect(PercentageSource.highest.localizationKey == "percentageSource.highest")
        #expect(PercentageSource.session.localizationKey == "percentageSource.session")
        #expect(PercentageSource.weekly.localizationKey == "percentageSource.weekly")
        #expect(PercentageSource.opus.localizationKey == "percentageSource.opus")
        #expect(PercentageSource.sonnet.localizationKey == "percentageSource.sonnet")
    }

    @Test("PercentageSource all cases have localization keys")
    func percentageSourceAllCasesHaveKeys() {
        for source in PercentageSource.allCases {
            #expect(!source.localizationKey.isEmpty)
            #expect(source.localizationKey.hasPrefix("percentageSource."))
        }
    }

    @Test("PercentageSource localization keys are unique")
    func percentageSourceKeysAreUnique() {
        var seenKeys = Set<String>()
        for source in PercentageSource.allCases {
            let key = source.localizationKey
            #expect(!seenKeys.contains(key), "Duplicate key found: \(key)")
            seenKeys.insert(key)
        }
    }

    @Test("BurnRateLevel localization keys are unique")
    func burnRateLevelKeysAreUnique() {
        var seenKeys = Set<String>()
        for level in BurnRateLevel.allCases {
            let key = level.localizationKey
            #expect(!seenKeys.contains(key), "Duplicate key found: \(key)")
            seenKeys.insert(key)
        }
    }

    // MARK: - Key Naming Convention Tests

    @Test("Localization key format uses dot notation")
    func localizationKeyFormatUsesDotNotation() {
        // All keys should use dot notation (category.subcategory.item)
        for source in PercentageSource.allCases {
            let parts = source.localizationKey.split(separator: ".")
            #expect(parts.count >= 2, "Key should have at least category.item format")
        }
    }

    @Test("Localization keys do not contain spaces")
    func localizationKeysNoSpaces() {
        for source in PercentageSource.allCases {
            #expect(!source.localizationKey.contains(" "), "Key should not contain spaces: \(source.localizationKey)")
        }
        for level in BurnRateLevel.allCases {
            #expect(!level.localizationKey.contains(" "), "Key should not contain spaces: \(level.localizationKey)")
        }
    }

    @Test("Localization keys use camelCase for multi-word items")
    func localizationKeysCamelCase() {
        // veryHigh should be camelCase, not very_high or very-high
        #expect(BurnRateLevel.veryHigh.localizationKey == "veryHigh")
        #expect(!BurnRateLevel.veryHigh.localizationKey.contains("_"))
        #expect(!BurnRateLevel.veryHigh.localizationKey.contains("-"))
    }
}

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
