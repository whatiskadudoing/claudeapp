import ArgumentParser
import Core
import Domain
import Foundation
import Services

// MARK: - Exit Codes

/// Exit codes for CLI operations.
/// Used to indicate status to shell scripts and prompt integrations.
public enum CLIExitCode: Int32 {
    /// Success - data retrieved successfully
    case success = 0

    /// Not authenticated - Claude Code credentials not found
    case notAuthenticated = 1

    /// API error - failed to fetch from API
    case apiError = 2

    /// Stale data - cached data is older than 15 minutes
    case staleData = 3
}

// MARK: - Output Format

/// Output format options for CLI.
enum CLIOutputFormat: String, ExpressibleByArgument, CaseIterable {
    /// Human-readable format: "86% (5h: 45%, 7d: 72%)"
    case plain

    /// Structured JSON output
    case json

    /// Single percentage value only: "86%"
    case minimal

    /// Multi-line detailed output with ASCII progress bars
    case verbose
}

// MARK: - Metric Selection

/// Metric selection for CLI output.
enum CLIMetric: String, ExpressibleByArgument, CaseIterable {
    /// 5-hour session window
    case session

    /// 7-day weekly window
    case weekly

    /// Highest across all windows
    case highest

    /// Opus-specific weekly quota
    case opus

    /// Sonnet-specific weekly quota
    case sonnet
}

// MARK: - CLI Handler

/// Command-line interface handler for ClaudeApp.
/// Provides usage data output for terminal statuslines, scripts, and integrations.
///
/// Usage:
/// ```bash
/// # Basic usage (reads from cached data)
/// claudeapp --status
///
/// # With format option
/// claudeapp --status --format json
/// claudeapp --status --format minimal
/// claudeapp --status --format verbose
///
/// # Force refresh (fetches from API)
/// claudeapp --status --refresh
///
/// # Specific metric only
/// claudeapp --status --metric session
/// ```
struct CLIHandler: ParsableCommand {
    /// App Group identifier for shared UserDefaults (matches SharedCacheManager)
    private static let appGroupIdentifier = "group.com.kaduwaengertner.ClaudeApp"

    /// Key for cached usage data in UserDefaults
    private static let usageDataKey = "cachedUsageData"
    static let configuration = CommandConfiguration(
        commandName: "claudeapp",
        abstract: "ClaudeApp - Claude Code usage monitor",
        discussion: """
        Monitor your Claude Code usage limits from the terminal.

        When run without --status, launches the GUI menu bar app.
        With --status, outputs usage data and exits.

        Exit codes:
          0 - Success
          1 - Not authenticated (run 'claude login')
          2 - API error
          3 - Data is stale (>15 min old)
        """
    )

    @Flag(name: .long, help: "Output usage status and exit")
    var status = false

    @Option(name: .long, help: "Output format: plain, json, minimal, verbose")
    var format: CLIOutputFormat = .plain

    @Option(name: .long, help: "Specific metric: session, weekly, highest, opus, sonnet")
    var metric: CLIMetric?

    @Flag(name: .long, help: "Force refresh from API (updates cache)")
    var refresh = false

    @Flag(name: .long, help: "Disable colored output")
    var noColor = false

    @Flag(name: .long, help: "Show version and exit")
    var version = false

    func run() throws {
        // Handle version flag
        if version {
            let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.9.0"
            print("ClaudeApp \(appVersion)")
            throw ExitCode.success
        }

        // If not status mode, indicate GUI should launch
        guard status else {
            // Return special exit code to signal GUI mode
            // The main entry point will detect this and launch GUI
            throw ExitCode(CLIExitCode.success.rawValue)
        }

        // CLI mode: output status
        let result = runCLI()
        throw ExitCode(result.rawValue)
    }

    /// Runs the CLI logic and returns the exit code.
    private func runCLI() -> CLIExitCode {
        // Use a semaphore to wait for async code
        let semaphore = DispatchSemaphore(value: 0)
        var exitCode: CLIExitCode = .success
        var outputString: String = ""

        Task {
            do {
                let (data, freshness) = try await fetchUsageData()
                outputString = formatOutput(data, freshness: freshness)

                // Set exit code based on freshness
                if freshness == .expired {
                    exitCode = .staleData
                } else {
                    exitCode = .success
                }
            } catch let error as AppError {
                switch error {
                case .notAuthenticated:
                    outputString = formatError("Not authenticated. Run 'claude login' to connect.")
                    exitCode = .notAuthenticated
                case .networkError(let message):
                    outputString = formatError("Network error: \(message)")
                    exitCode = .apiError
                case .apiError(let statusCode, let message):
                    outputString = formatError("API error (\(statusCode)): \(message)")
                    exitCode = .apiError
                case .rateLimited(let retryAfter):
                    outputString = formatError("Rate limited. Try again in \(retryAfter) seconds.")
                    exitCode = .apiError
                default:
                    outputString = formatError("Error: \(error)")
                    exitCode = .apiError
                }
            } catch {
                outputString = formatError("Unexpected error: \(error.localizedDescription)")
                exitCode = .apiError
            }
            semaphore.signal()
        }

        // Wait for async completion (with timeout)
        let timeout = DispatchTime.now() + .seconds(30)
        if semaphore.wait(timeout: timeout) == .timedOut {
            fputs(formatError("Timeout waiting for data"), stderr)
            return .apiError
        }

        // Output the result
        print(outputString)
        return exitCode
    }

    /// Fetches usage data from cache or API.
    /// - Returns: Tuple of UsageData and freshness state
    /// - Throws: AppError if data cannot be retrieved
    private func fetchUsageData() async throws -> (UsageData, CacheFreshness) {
        if refresh {
            // Force refresh from API
            let data = try await fetchFromAPI()
            // Write to cache
            await writeToCacheIfPossible(data)
            return (data, .fresh)
        } else {
            // Read from shared cache
            if let cached = readFromCache() {
                return (cached.data, cached.freshness())
            }

            // No cache available, try API
            let data = try await fetchFromAPI()
            await writeToCacheIfPossible(data)
            return (data, .fresh)
        }
    }

    /// Fetches fresh data from the API.
    private func fetchFromAPI() async throws -> UsageData {
        let credentials = KeychainCredentialsRepository()
        let client = ClaudeAPIClient(
            credentialsRepository: credentials,
            userAgent: "ClaudeApp-CLI/\(Bundle.main.appVersion)"
        )
        return try await client.fetchUsage()
    }

    /// Reads cached data from shared UserDefaults.
    private func readFromCache() -> CachedUsageData? {
        guard let defaults = UserDefaults(suiteName: Self.appGroupIdentifier),
              let data = defaults.data(forKey: Self.usageDataKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CachedUsageData.self, from: data)
    }

    /// Writes data to shared cache (best effort).
    @MainActor
    private func writeToCacheIfPossible(_ data: UsageData) {
        let manager = SharedCacheManager()
        _ = manager.writeUsageCache(data)
    }

    /// Formats the usage data for output.
    private func formatOutput(_ data: UsageData, freshness: CacheFreshness) -> String {
        switch format {
        case .plain:
            return formatPlain(data, freshness: freshness)
        case .json:
            return formatJSON(data, freshness: freshness)
        case .minimal:
            return formatMinimal(data)
        case .verbose:
            return formatVerbose(data, freshness: freshness)
        }
    }

    /// Plain text format: "86% (5h: 45%, 7d: 72%)"
    private func formatPlain(_ data: UsageData, freshness: CacheFreshness) -> String {
        if let metric {
            return "\(Int(metricValue(data, metric: metric)))%"
        }

        var output = "\(Int(data.highestUtilization))% (5h: \(Int(data.fiveHour.utilization))%, 7d: \(Int(data.sevenDay.utilization))%)"

        // Add freshness warning if stale
        if freshness == .stale {
            output += " [stale]"
        } else if freshness == .expired {
            output += " [expired]"
        }

        return output
    }

    /// JSON format with all data
    private func formatJSON(_ data: UsageData, freshness: CacheFreshness) -> String {
        var payload: [String: Any] = [
            "session": Int(data.fiveHour.utilization),
            "weekly": Int(data.sevenDay.utilization),
            "highest": Int(data.highestUtilization),
            "freshness": freshness.jsonValue
        ]

        if let opus = data.sevenDayOpus {
            payload["opus"] = Int(opus.utilization)
        }

        if let sonnet = data.sevenDaySonnet {
            payload["sonnet"] = Int(sonnet.utilization)
        }

        if let burnRate = data.highestBurnRate {
            payload["burnRate"] = burnRate.level.rawValue.lowercased()
            payload["burnRatePerHour"] = burnRate.percentPerHour
        }

        payload["fetchedAt"] = ISO8601DateFormatter().string(from: data.fetchedAt)

        // Convert to JSON string
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{\"error\": \"Failed to encode JSON\"}"
        }

        return jsonString
    }

    /// Minimal format: just the percentage
    private func formatMinimal(_ data: UsageData) -> String {
        if let metric {
            return "\(Int(metricValue(data, metric: metric)))%"
        }
        return "\(Int(data.highestUtilization))%"
    }

    /// Verbose format with ASCII progress bars
    private func formatVerbose(_ data: UsageData, freshness: CacheFreshness) -> String {
        var lines: [String] = []

        lines.append("Claude Usage")
        lines.append("")

        // Session window
        lines.append(formatVerboseLine(
            label: "Session (5h)",
            value: data.fiveHour.utilization,
            resetsAt: data.fiveHour.resetsAt
        ))

        // Weekly window
        lines.append(formatVerboseLine(
            label: "Weekly",
            value: data.sevenDay.utilization,
            resetsAt: data.sevenDay.resetsAt
        ))

        // Opus window (if available)
        if let opus = data.sevenDayOpus {
            lines.append(formatVerboseLine(
                label: "Opus",
                value: opus.utilization,
                resetsAt: opus.resetsAt
            ))
        }

        // Sonnet window (if available)
        if let sonnet = data.sevenDaySonnet {
            lines.append(formatVerboseLine(
                label: "Sonnet",
                value: sonnet.utilization,
                resetsAt: sonnet.resetsAt
            ))
        }

        // Burn rate
        if let burnRate = data.highestBurnRate {
            lines.append("")
            let levelColor = colorForBurnRate(burnRate.level)
            let levelText = colorize(burnRate.level.rawValue, color: levelColor)
            lines.append("  Burn Rate:     \(levelText) (\(burnRate.displayString))")
        }

        // Freshness warning
        if freshness == .stale || freshness == .expired {
            lines.append("")
            let warning = freshness == .stale ? "Data is stale (5-15 min old)" : "Data is expired (>15 min old)"
            lines.append(colorize("  ⚠ \(warning)", color: .yellow))
        }

        return lines.joined(separator: "\n")
    }

    /// Formats a single verbose line with progress bar
    private func formatVerboseLine(label: String, value: Double, resetsAt: Date?) -> String {
        let paddedLabel = label.padding(toLength: 12, withPad: " ", startingAt: 0)
        let percentage = String(format: "%3d%%", Int(value))
        let bar = progressBar(value)
        let coloredBar = colorize(bar, color: colorForUsage(value))

        var line = "  \(paddedLabel) \(percentage) \(coloredBar)"

        if let resetsAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let resetText = formatter.localizedString(for: resetsAt, relativeTo: Date())
            line += " (resets \(resetText))"
        }

        return line
    }

    /// Creates an ASCII progress bar
    private func progressBar(_ value: Double, width: Int = 16) -> String {
        let filled = Int(value / 100 * Double(width))
        let empty = width - filled
        return String(repeating: "█", count: max(0, min(filled, width))) +
               String(repeating: "░", count: max(0, empty))
    }

    /// Returns the value for a specific metric
    private func metricValue(_ data: UsageData, metric: CLIMetric) -> Double {
        switch metric {
        case .session:
            return data.fiveHour.utilization
        case .weekly:
            return data.sevenDay.utilization
        case .highest:
            return data.highestUtilization
        case .opus:
            return data.sevenDayOpus?.utilization ?? data.highestUtilization
        case .sonnet:
            return data.sevenDaySonnet?.utilization ?? data.highestUtilization
        }
    }

    /// Formats an error message
    private func formatError(_ message: String) -> String {
        if format == .json {
            let escaped = message.replacingOccurrences(of: "\"", with: "\\\"")
            return "{\"error\": \"\(escaped)\"}"
        }
        return colorize("Error: \(message)", color: .red)
    }

    // MARK: - Color Support

    private enum ANSIColor: String {
        case red = "\u{001B}[31m"
        case green = "\u{001B}[32m"
        case yellow = "\u{001B}[33m"
        case orange = "\u{001B}[38;5;208m"
        case reset = "\u{001B}[0m"
    }

    private func colorize(_ text: String, color: ANSIColor) -> String {
        guard !noColor, isTerminal else { return text }
        return "\(color.rawValue)\(text)\(ANSIColor.reset.rawValue)"
    }

    private var isTerminal: Bool {
        isatty(STDOUT_FILENO) != 0
    }

    private func colorForUsage(_ value: Double) -> ANSIColor {
        switch value {
        case 0..<50: return .green
        case 50..<90: return .yellow
        default: return .red
        }
    }

    private func colorForBurnRate(_ level: BurnRateLevel) -> ANSIColor {
        switch level {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
}

// MARK: - CacheFreshness Extension

extension CacheFreshness {
    /// JSON-friendly string representation
    var jsonValue: String {
        switch self {
        case .fresh: return "fresh"
        case .stale: return "stale"
        case .expired: return "expired"
        case .none: return "none"
        }
    }
}

// MARK: - Bundle Extension

extension Bundle {
    /// Returns the app version string
    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.9.0"
    }
}
