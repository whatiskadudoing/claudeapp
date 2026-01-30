import Foundation
import Testing
@testable import Domain

@Suite("Domain Tests")
struct DomainTests {
    @Test("Domain version is correct")
    func domainVersion() {
        #expect(Domain.version == "1.6.0")
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

    // MARK: - isAtCapacity Tests

    @Test("isAtCapacity returns false when all windows below 100%")
    func isAtCapacityFalse() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: UsageWindow(utilization: 20.0),
            sevenDaySonnet: UsageWindow(utilization: 99.0)
        )

        #expect(data.isAtCapacity == false)
    }

    @Test("isAtCapacity returns true when fiveHour at 100%")
    func isAtCapacityFiveHour() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 100.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: UsageWindow(utilization: 20.0),
            sevenDaySonnet: UsageWindow(utilization: 30.0)
        )

        #expect(data.isAtCapacity == true)
    }

    @Test("isAtCapacity returns true when sevenDay at 100%")
    func isAtCapacitySevenDay() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 100.0),
            sevenDayOpus: UsageWindow(utilization: 20.0),
            sevenDaySonnet: UsageWindow(utilization: 40.0)
        )

        #expect(data.isAtCapacity == true)
    }

    @Test("isAtCapacity returns true when sevenDayOpus at 100%")
    func isAtCapacityOpus() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: UsageWindow(utilization: 100.0),
            sevenDaySonnet: UsageWindow(utilization: 40.0)
        )

        #expect(data.isAtCapacity == true)
    }

    @Test("isAtCapacity returns true when sevenDaySonnet at 100%")
    func isAtCapacitySonnet() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: UsageWindow(utilization: 20.0),
            sevenDaySonnet: UsageWindow(utilization: 100.0)
        )

        #expect(data.isAtCapacity == true)
    }

    @Test("isAtCapacity handles nil optional windows")
    func isAtCapacityNilOptionals() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 30.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: nil,
            sevenDaySonnet: nil
        )

        #expect(data.isAtCapacity == false)
    }

    @Test("isAtCapacity returns true when over 100%")
    func isAtCapacityOver100() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 105.0),
            sevenDay: UsageWindow(utilization: 50.0),
            sevenDayOpus: nil,
            sevenDaySonnet: nil
        )

        #expect(data.isAtCapacity == true)
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

// MARK: - IconStyle Tests

@Suite("IconStyle Tests")
struct IconStyleTests {
    @Test("IconStyle raw values are correct")
    func rawValues() {
        #expect(IconStyle.percentage.rawValue == "percentage")
        #expect(IconStyle.progressBar.rawValue == "progressBar")
        #expect(IconStyle.battery.rawValue == "battery")
        #expect(IconStyle.compact.rawValue == "compact")
        #expect(IconStyle.iconOnly.rawValue == "iconOnly")
        #expect(IconStyle.full.rawValue == "full")
    }

    @Test("IconStyle conforms to CaseIterable")
    func caseIterable() {
        let allCases = IconStyle.allCases
        #expect(allCases.count == 6)
        #expect(allCases.contains(.percentage))
        #expect(allCases.contains(.progressBar))
        #expect(allCases.contains(.battery))
        #expect(allCases.contains(.compact))
        #expect(allCases.contains(.iconOnly))
        #expect(allCases.contains(.full))
    }

    @Test("IconStyle is Equatable")
    func equatable() {
        #expect(IconStyle.percentage == IconStyle.percentage)
        #expect(IconStyle.percentage != IconStyle.battery)
        #expect(IconStyle.full != IconStyle.compact)
    }

    @Test("IconStyle is Codable")
    func codable() throws {
        let style = IconStyle.progressBar
        let data = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(IconStyle.self, from: data)
        #expect(decoded == style)
    }

    @Test("IconStyle is Sendable")
    func sendable() async {
        let style = IconStyle.battery

        // Verify it can be passed across actor boundaries
        let result = await Task.detached {
            style.rawValue
        }.value

        #expect(result == "battery")
    }

    @Test("IconStyle localization keys follow naming convention")
    func localizationKeys() {
        #expect(IconStyle.percentage.localizationKey == "iconStyle.percentage")
        #expect(IconStyle.progressBar.localizationKey == "iconStyle.progressBar")
        #expect(IconStyle.battery.localizationKey == "iconStyle.battery")
        #expect(IconStyle.compact.localizationKey == "iconStyle.compact")
        #expect(IconStyle.iconOnly.localizationKey == "iconStyle.iconOnly")
        #expect(IconStyle.full.localizationKey == "iconStyle.full")
    }

    @Test("IconStyle all cases have localization keys")
    func allCasesHaveKeys() {
        for style in IconStyle.allCases {
            #expect(!style.localizationKey.isEmpty)
            #expect(style.localizationKey.hasPrefix("iconStyle."))
        }
    }

    @Test("IconStyle localization keys are unique")
    func keysAreUnique() {
        var seenKeys = Set<String>()
        for style in IconStyle.allCases {
            let key = style.localizationKey
            #expect(!seenKeys.contains(key), "Duplicate key found: \(key)")
            seenKeys.insert(key)
        }
    }

    @Test("IconStyle localization keys do not contain spaces")
    func keysNoSpaces() {
        for style in IconStyle.allCases {
            #expect(!style.localizationKey.contains(" "), "Key should not contain spaces: \(style.localizationKey)")
        }
    }

    @Test("IconStyle display names are human readable")
    func displayNames() {
        #expect(IconStyle.percentage.displayName == "Percentage")
        #expect(IconStyle.progressBar.displayName == "Progress Bar")
        #expect(IconStyle.battery.displayName == "Battery")
        #expect(IconStyle.compact.displayName == "Compact")
        #expect(IconStyle.iconOnly.displayName == "Icon Only")
        #expect(IconStyle.full.displayName == "Full (Icon + Bar + %)")
    }

    @Test("IconStyle all cases have display names")
    func allCasesHaveDisplayNames() {
        for style in IconStyle.allCases {
            #expect(!style.displayName.isEmpty)
        }
    }

    @Test("IconStyle default is percentage")
    func defaultIsPercentage() {
        // Verify the settings key default matches the spec
        let defaultStyle = SettingsKey.iconStyle.defaultValue
        #expect(defaultStyle == .percentage)
    }
}

// MARK: - Power-Aware Refresh SettingsKey Tests

@Suite("Power-Aware Refresh SettingsKey Tests")
struct PowerAwareRefreshSettingsKeyTests {
    @Test("enablePowerAwareRefresh default is true")
    func enablePowerAwareRefreshDefault() {
        let key = SettingsKey.enablePowerAwareRefresh
        #expect(key.defaultValue == true)
        #expect(key.key == "enablePowerAwareRefresh")
    }

    @Test("reduceRefreshOnBattery default is true")
    func reduceRefreshOnBatteryDefault() {
        let key = SettingsKey.reduceRefreshOnBattery
        #expect(key.defaultValue == true)
        #expect(key.key == "reduceRefreshOnBattery")
    }

    @Test("Power-aware refresh keys are distinct")
    func keysAreDistinct() {
        #expect(SettingsKey.enablePowerAwareRefresh.key != SettingsKey.reduceRefreshOnBattery.key)
    }

    @Test("Power-aware refresh keys do not conflict with other keys")
    func keysDoNotConflict() {
        let powerAwareKeys = [
            SettingsKey.enablePowerAwareRefresh.key,
            SettingsKey.reduceRefreshOnBattery.key
        ]

        // Check against other boolean keys
        let otherKeys = [
            SettingsKey.showPlanBadge.key,
            SettingsKey.showPercentage.key,
            SettingsKey.notificationsEnabled.key,
            SettingsKey.warningEnabled.key,
            SettingsKey.capacityFullEnabled.key,
            SettingsKey.resetCompleteEnabled.key,
            SettingsKey.launchAtLogin.key,
            SettingsKey.checkForUpdates.key
        ]

        for powerAwareKey in powerAwareKeys {
            for otherKey in otherKeys {
                #expect(powerAwareKey != otherKey, "Key collision: \(powerAwareKey) == \(otherKey)")
            }
        }
    }
}

// MARK: - UsageDataPoint Tests

@Suite("UsageDataPoint Tests")
struct UsageDataPointTests {
    @Test("UsageDataPoint initializes with utilization and timestamp")
    func initWithUtilizationAndTimestamp() {
        let timestamp = Date()
        let point = UsageDataPoint(utilization: 45.5, timestamp: timestamp)

        #expect(point.utilization == 45.5)
        #expect(point.timestamp == timestamp)
    }

    @Test("UsageDataPoint defaults timestamp to now")
    func defaultTimestamp() {
        let before = Date()
        let point = UsageDataPoint(utilization: 50.0)
        let after = Date()

        #expect(point.timestamp >= before)
        #expect(point.timestamp <= after)
    }

    @Test("UsageDataPoint id equals timestamp")
    func idEqualsTimestamp() {
        let timestamp = Date()
        let point = UsageDataPoint(utilization: 45.5, timestamp: timestamp)

        #expect(point.id == timestamp)
    }

    @Test("UsageDataPoint is Equatable")
    func equatable() {
        let timestamp = Date()
        let point1 = UsageDataPoint(utilization: 45.5, timestamp: timestamp)
        let point2 = UsageDataPoint(utilization: 45.5, timestamp: timestamp)
        let point3 = UsageDataPoint(utilization: 50.0, timestamp: timestamp)

        #expect(point1 == point2)
        #expect(point1 != point3)
    }

    @Test("UsageDataPoint is Comparable by timestamp")
    func comparable() {
        let earlier = Date().addingTimeInterval(-60)
        let later = Date()
        let point1 = UsageDataPoint(utilization: 45.5, timestamp: earlier)
        let point2 = UsageDataPoint(utilization: 50.0, timestamp: later)

        #expect(point1 < point2)
        #expect(point2 > point1)
    }

    @Test("UsageDataPoint sorts chronologically")
    func sortsChronologically() {
        let now = Date()
        let points = [
            UsageDataPoint(utilization: 30.0, timestamp: now.addingTimeInterval(-120)),
            UsageDataPoint(utilization: 50.0, timestamp: now),
            UsageDataPoint(utilization: 40.0, timestamp: now.addingTimeInterval(-60))
        ]

        let sorted = points.sorted()

        #expect(sorted[0].utilization == 30.0)
        #expect(sorted[1].utilization == 40.0)
        #expect(sorted[2].utilization == 50.0)
    }

    @Test("UsageDataPoint is Codable")
    func codable() throws {
        let timestamp = Date()
        let point = UsageDataPoint(utilization: 45.5, timestamp: timestamp)

        let data = try JSONEncoder().encode(point)
        let decoded = try JSONDecoder().decode(UsageDataPoint.self, from: data)

        #expect(decoded == point)
        #expect(decoded.utilization == 45.5)
    }

    @Test("UsageDataPoint is Sendable")
    func sendable() async {
        let point = UsageDataPoint(utilization: 45.5)

        // Verify it can be passed across actor boundaries
        let result = await Task.detached {
            point.utilization
        }.value

        #expect(result == 45.5)
    }

    @Test("UsageDataPoint handles edge values")
    func edgeValues() {
        let point1 = UsageDataPoint(utilization: 0.0)
        let point2 = UsageDataPoint(utilization: 100.0)

        #expect(point1.utilization == 0.0)
        #expect(point2.utilization == 100.0)
    }

    @Test("UsageDataPoint equality considers timestamp")
    func equalityConsidersTimestamp() {
        let timestamp1 = Date()
        let timestamp2 = timestamp1.addingTimeInterval(1)
        let point1 = UsageDataPoint(utilization: 45.5, timestamp: timestamp1)
        let point2 = UsageDataPoint(utilization: 45.5, timestamp: timestamp2)

        #expect(point1 != point2)
    }

    @Test("UsageDataPoint conforms to Identifiable")
    func identifiable() {
        let timestamp = Date()
        let point = UsageDataPoint(utilization: 45.5, timestamp: timestamp)

        // Identifiable requirement: id should be accessible
        let id: Date = point.id
        #expect(id == timestamp)
    }

    @Test("Array of UsageDataPoint can be used in ForEach")
    func arrayUsableInForEach() {
        let now = Date()
        let points = [
            UsageDataPoint(utilization: 30.0, timestamp: now.addingTimeInterval(-2)),
            UsageDataPoint(utilization: 40.0, timestamp: now.addingTimeInterval(-1)),
            UsageDataPoint(utilization: 50.0, timestamp: now)
        ]

        // Verify unique IDs (timestamps serve as IDs)
        let ids = points.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(uniqueIds.count == 3)
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

// MARK: - ExportedSettings Tests

@Suite("ExportedSettings Tests")
struct ExportedSettingsTests {
    // MARK: - Helper to create test settings

    private func createTestSettings() -> ExportedSettings {
        ExportedSettings(
            version: ExportedSettings.currentVersion,
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "percentage",
                    showPlanBadge: false,
                    showPercentage: true,
                    percentageSource: "highest",
                    showSparklines: true,
                    planType: "pro"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 5,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: nil
        )
    }

    @Test("ExportedSettings initializes with all fields")
    func initialization() {
        let settings = createTestSettings()

        #expect(settings.version == "1.0")
        #expect(settings.appVersion == "1.8.0")
        #expect(settings.settings.display.iconStyle == "percentage")
        #expect(settings.settings.refresh.interval == 5)
        #expect(settings.settings.notifications.warningThreshold == 90)
        #expect(settings.settings.general.launchAtLogin == false)
        #expect(settings.usageHistory == nil)
    }

    @Test("ExportedSettings currentVersion is 1.0")
    func currentVersion() {
        #expect(ExportedSettings.currentVersion == "1.0")
    }

    @Test("ExportedSettings is Equatable")
    func equatable() {
        let date = Date()
        let settings1 = ExportedSettings(
            version: "1.0",
            exportedAt: date,
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "percentage",
                    showPlanBadge: false,
                    showPercentage: true,
                    percentageSource: "highest",
                    showSparklines: true,
                    planType: "pro"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 5,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: nil
        )
        let settings2 = settings1

        #expect(settings1 == settings2)
    }

    @Test("ExportedSettings is Codable")
    func codable() throws {
        let settings = createTestSettings()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(settings)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ExportedSettings.self, from: data)

        #expect(decoded.version == settings.version)
        #expect(decoded.appVersion == settings.appVersion)
        #expect(decoded.settings.display.iconStyle == settings.settings.display.iconStyle)
        #expect(decoded.settings.refresh.interval == settings.settings.refresh.interval)
    }

    @Test("ExportedSettings is Sendable")
    func sendable() async {
        let settings = createTestSettings()

        let result = await Task.detached {
            settings.version
        }.value

        #expect(result == "1.0")
    }

    @Test("ExportedSettings with usage history")
    func withUsageHistory() {
        let history = ExportedSettings.UsageHistoryPayload(
            sessionHistory: [
                UsageDataPoint(utilization: 30.0, timestamp: Date().addingTimeInterval(-300)),
                UsageDataPoint(utilization: 40.0, timestamp: Date())
            ],
            weeklyHistory: [
                UsageDataPoint(utilization: 50.0, timestamp: Date().addingTimeInterval(-3600)),
                UsageDataPoint(utilization: 55.0, timestamp: Date())
            ]
        )

        let settings = ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "percentage",
                    showPlanBadge: false,
                    showPercentage: true,
                    percentageSource: "highest",
                    showSparklines: true,
                    planType: "pro"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 5,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: history
        )

        #expect(settings.usageHistory != nil)
        #expect(settings.usageHistory?.sessionHistory.count == 2)
        #expect(settings.usageHistory?.weeklyHistory.count == 2)
    }
}

// MARK: - ExportedSettings Validation Tests

@Suite("ExportedSettings Validation Tests")
struct ExportedSettingsValidationTests {
    @Test("validate returns valid for correct settings")
    func validateCorrectSettings() {
        let settings = ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: IconStyle.percentage.rawValue,
                    showPlanBadge: false,
                    showPercentage: true,
                    percentageSource: PercentageSource.highest.rawValue,
                    showSparklines: true,
                    planType: PlanType.pro.rawValue
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 5,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: nil
        )

        let result = settings.validate()

        #expect(result.isValid == true)
        #expect(result.messages.first?.contains("valid") == true)
    }

    @Test("validate warns on unknown icon style")
    func validateUnknownIconStyle() {
        let settings = ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "unknownStyle",
                    showPlanBadge: false,
                    showPercentage: true,
                    percentageSource: "highest",
                    showSparklines: true,
                    planType: "pro"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 5,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: nil
        )

        let result = settings.validate()

        #expect(result.messages.contains { $0.contains("icon style") })
    }

    @Test("validate warns on out of range refresh interval")
    func validateOutOfRangeRefreshInterval() {
        let settings = ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "percentage",
                    showPlanBadge: false,
                    showPercentage: true,
                    percentageSource: "highest",
                    showSparklines: true,
                    planType: "pro"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 60, // Out of range (1-30)
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: nil
        )

        let result = settings.validate()

        #expect(result.messages.contains { $0.contains("Refresh interval") })
    }

    @Test("validate provides correct summary")
    func validateProvidesSummary() {
        let settings = ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "percentage",
                    showPlanBadge: false,
                    showPercentage: true,
                    percentageSource: "highest",
                    showSparklines: true,
                    planType: "pro"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 5,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: nil
        )

        let result = settings.validate()

        #expect(result.summary?.displaySettingsCount == 6)
        #expect(result.summary?.refreshSettingsCount == 3)
        #expect(result.summary?.notificationSettingsCount == 5)
        #expect(result.summary?.generalSettingsCount == 2)
        #expect(result.summary?.includesUsageHistory == false)
    }

    @Test("validate summary includes usage history when present")
    func validateSummaryWithHistory() {
        let history = ExportedSettings.UsageHistoryPayload(
            sessionHistory: [
                UsageDataPoint(utilization: 30.0),
                UsageDataPoint(utilization: 40.0)
            ],
            weeklyHistory: [
                UsageDataPoint(utilization: 50.0),
                UsageDataPoint(utilization: 55.0),
                UsageDataPoint(utilization: 60.0)
            ]
        )

        let settings = ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "percentage",
                    showPlanBadge: false,
                    showPercentage: true,
                    percentageSource: "highest",
                    showSparklines: true,
                    planType: "pro"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 5,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: history
        )

        let result = settings.validate()

        #expect(result.summary?.includesUsageHistory == true)
        #expect(result.summary?.sessionHistoryPoints == 2)
        #expect(result.summary?.weeklyHistoryPoints == 3)
    }

    @Test("validate warns on different version")
    func validateDifferentVersion() {
        let settings = ExportedSettings(
            version: "2.0", // Different version
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "percentage",
                    showPlanBadge: false,
                    showPercentage: true,
                    percentageSource: "highest",
                    showSparklines: true,
                    planType: "pro"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 5,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: nil
        )

        let result = settings.validate()

        #expect(result.messages.contains { $0.contains("version") })
    }
}

// MARK: - ExportedSettings Nested Types Tests

@Suite("ExportedSettings DisplaySettings Tests")
struct ExportedSettingsDisplaySettingsTests {
    @Test("DisplaySettings initializes correctly")
    func initialization() {
        let display = ExportedSettings.DisplaySettings(
            iconStyle: "battery",
            showPlanBadge: true,
            showPercentage: false,
            percentageSource: "session",
            showSparklines: false,
            planType: "max5x"
        )

        #expect(display.iconStyle == "battery")
        #expect(display.showPlanBadge == true)
        #expect(display.showPercentage == false)
        #expect(display.percentageSource == "session")
        #expect(display.showSparklines == false)
        #expect(display.planType == "max5x")
    }

    @Test("DisplaySettings is Codable")
    func codable() throws {
        let display = ExportedSettings.DisplaySettings(
            iconStyle: "progressBar",
            showPlanBadge: true,
            showPercentage: true,
            percentageSource: "weekly",
            showSparklines: true,
            planType: "max20x"
        )

        let data = try JSONEncoder().encode(display)
        let decoded = try JSONDecoder().decode(ExportedSettings.DisplaySettings.self, from: data)

        #expect(decoded == display)
    }
}

@Suite("ExportedSettings RefreshSettings Tests")
struct ExportedSettingsRefreshSettingsTests {
    @Test("RefreshSettings initializes correctly")
    func initialization() {
        let refresh = ExportedSettings.RefreshSettings(
            interval: 10,
            enablePowerAwareRefresh: false,
            reduceRefreshOnBattery: false
        )

        #expect(refresh.interval == 10)
        #expect(refresh.enablePowerAwareRefresh == false)
        #expect(refresh.reduceRefreshOnBattery == false)
    }

    @Test("RefreshSettings is Codable")
    func codable() throws {
        let refresh = ExportedSettings.RefreshSettings(
            interval: 15,
            enablePowerAwareRefresh: true,
            reduceRefreshOnBattery: false
        )

        let data = try JSONEncoder().encode(refresh)
        let decoded = try JSONDecoder().decode(ExportedSettings.RefreshSettings.self, from: data)

        #expect(decoded == refresh)
    }
}

@Suite("ExportedSettings NotificationSettings Tests")
struct ExportedSettingsNotificationSettingsTests {
    @Test("NotificationSettings initializes correctly")
    func initialization() {
        let notifications = ExportedSettings.NotificationSettings(
            enabled: false,
            warningThreshold: 80,
            warningEnabled: false,
            capacityFullEnabled: true,
            resetCompleteEnabled: false
        )

        #expect(notifications.enabled == false)
        #expect(notifications.warningThreshold == 80)
        #expect(notifications.warningEnabled == false)
        #expect(notifications.capacityFullEnabled == true)
        #expect(notifications.resetCompleteEnabled == false)
    }

    @Test("NotificationSettings is Codable")
    func codable() throws {
        let notifications = ExportedSettings.NotificationSettings(
            enabled: true,
            warningThreshold: 75,
            warningEnabled: true,
            capacityFullEnabled: false,
            resetCompleteEnabled: true
        )

        let data = try JSONEncoder().encode(notifications)
        let decoded = try JSONDecoder().decode(ExportedSettings.NotificationSettings.self, from: data)

        #expect(decoded == notifications)
    }
}

@Suite("ExportedSettings GeneralSettings Tests")
struct ExportedSettingsGeneralSettingsTests {
    @Test("GeneralSettings initializes correctly")
    func initialization() {
        let general = ExportedSettings.GeneralSettings(
            launchAtLogin: true,
            checkForUpdates: false
        )

        #expect(general.launchAtLogin == true)
        #expect(general.checkForUpdates == false)
    }

    @Test("GeneralSettings is Codable")
    func codable() throws {
        let general = ExportedSettings.GeneralSettings(
            launchAtLogin: true,
            checkForUpdates: true
        )

        let data = try JSONEncoder().encode(general)
        let decoded = try JSONDecoder().decode(ExportedSettings.GeneralSettings.self, from: data)

        #expect(decoded == general)
    }
}

@Suite("ExportedSettings UsageHistoryPayload Tests")
struct ExportedSettingsUsageHistoryPayloadTests {
    @Test("UsageHistoryPayload initializes correctly")
    func initialization() {
        let session = [UsageDataPoint(utilization: 30.0)]
        let weekly = [UsageDataPoint(utilization: 50.0)]

        let history = ExportedSettings.UsageHistoryPayload(
            sessionHistory: session,
            weeklyHistory: weekly
        )

        #expect(history.sessionHistory.count == 1)
        #expect(history.weeklyHistory.count == 1)
        #expect(history.sessionHistory[0].utilization == 30.0)
        #expect(history.weeklyHistory[0].utilization == 50.0)
    }

    @Test("UsageHistoryPayload is Codable")
    func codable() throws {
        let history = ExportedSettings.UsageHistoryPayload(
            sessionHistory: [
                UsageDataPoint(utilization: 30.0),
                UsageDataPoint(utilization: 40.0)
            ],
            weeklyHistory: [
                UsageDataPoint(utilization: 50.0)
            ]
        )

        let data = try JSONEncoder().encode(history)
        let decoded = try JSONDecoder().decode(ExportedSettings.UsageHistoryPayload.self, from: data)

        #expect(decoded.sessionHistory.count == 2)
        #expect(decoded.weeklyHistory.count == 1)
    }

    @Test("UsageHistoryPayload handles empty arrays")
    func emptyArrays() {
        let history = ExportedSettings.UsageHistoryPayload(
            sessionHistory: [],
            weeklyHistory: []
        )

        #expect(history.sessionHistory.isEmpty)
        #expect(history.weeklyHistory.isEmpty)
    }
}
