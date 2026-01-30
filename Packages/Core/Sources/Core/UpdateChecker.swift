import Foundation

// MARK: - GitHub API Models

/// Represents a GitHub release from the GitHub Releases API
public struct GitHubRelease: Decodable, Sendable, Equatable {
    public let tagName: String
    public let name: String
    public let htmlUrl: String
    public let publishedAt: String
    public let body: String?
    public let assets: [GitHubAsset]
    public let draft: Bool
    public let prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case body
        case assets
        case draft
        case prerelease
    }

    public init(
        tagName: String,
        name: String,
        htmlUrl: String,
        publishedAt: String,
        body: String?,
        assets: [GitHubAsset],
        draft: Bool = false,
        prerelease: Bool = false
    ) {
        self.tagName = tagName
        self.name = name
        self.htmlUrl = htmlUrl
        self.publishedAt = publishedAt
        self.body = body
        self.assets = assets
        self.draft = draft
        self.prerelease = prerelease
    }
}

/// Represents a downloadable asset from a GitHub release
public struct GitHubAsset: Decodable, Sendable, Equatable {
    public let name: String
    public let browserDownloadUrl: URL
    public let size: Int
    public let downloadCount: Int

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
        case downloadCount = "download_count"
    }

    public init(name: String, browserDownloadUrl: URL, size: Int = 0, downloadCount: Int = 0) {
        self.name = name
        self.browserDownloadUrl = browserDownloadUrl
        self.size = size
        self.downloadCount = downloadCount
    }
}

// MARK: - Update Models

/// Information about an available update
public struct UpdateInfo: Sendable, Equatable {
    public let version: String
    public let downloadURL: URL
    public let releaseURL: URL
    public let releaseNotes: String?

    public init(version: String, downloadURL: URL, releaseURL: URL, releaseNotes: String?) {
        self.version = version
        self.downloadURL = downloadURL
        self.releaseURL = releaseURL
        self.releaseNotes = releaseNotes
    }
}

/// Result of checking for updates
public enum CheckResult: Sendable, Equatable {
    case upToDate
    case updateAvailable(UpdateInfo)
    case rateLimited
    case error(String)

    public static func == (lhs: CheckResult, rhs: CheckResult) -> Bool {
        switch (lhs, rhs) {
        case (.upToDate, .upToDate):
            return true
        case let (.updateAvailable(lhsInfo), .updateAvailable(rhsInfo)):
            return lhsInfo == rhsInfo
        case (.rateLimited, .rateLimited):
            return true
        case let (.error(lhsMsg), .error(rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - UpdateChecker

/// Actor responsible for checking GitHub releases for app updates
public actor UpdateChecker {
    private let repoOwner: String
    private let repoName: String
    private let session: URLSession
    private let currentVersionProvider: @Sendable () -> String

    private var lastCheckDate: Date?
    private var lastNotifiedVersion: String?

    /// Minimum interval between automatic checks (24 hours)
    private let minimumCheckInterval: TimeInterval = 86400

    /// Creates an UpdateChecker for a specific GitHub repository
    /// - Parameters:
    ///   - repoOwner: GitHub repository owner (e.g., "whatiskadudoing")
    ///   - repoName: GitHub repository name (e.g., "claudeapp")
    ///   - session: URLSession for network requests (defaults to .shared)
    ///   - currentVersionProvider: Closure that returns the current app version
    public init(
        repoOwner: String = "whatiskadudoing",
        repoName: String = "claudeapp",
        session: URLSession = .shared,
        currentVersionProvider: @escaping @Sendable () -> String = { Bundle.main.appVersion }
    ) {
        self.repoOwner = repoOwner
        self.repoName = repoName
        self.session = session
        self.currentVersionProvider = currentVersionProvider
    }

    /// Checks for updates from GitHub Releases
    /// - Returns: CheckResult indicating whether an update is available
    public func check() async -> CheckResult {
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            return .error("Invalid repository URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("ClaudeApp/\(currentVersionProvider())", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .error("Invalid server response")
            }

            switch httpResponse.statusCode {
            case 200:
                return try processSuccessResponse(data: data)

            case 404:
                // No releases yet - treat as up to date
                return .upToDate

            case 403:
                // Rate limited
                return .rateLimited

            default:
                return .error("Server error: \(httpResponse.statusCode)")
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }

    /// Checks for updates in the background, respecting rate limits
    /// Only checks if more than 24 hours have passed since the last check
    /// - Returns: CheckResult if a check was performed, nil if skipped due to rate limit
    public func checkInBackground() async -> CheckResult? {
        // Don't check more than once per 24 hours
        if let lastCheck = lastCheckDate,
           Date().timeIntervalSince(lastCheck) < minimumCheckInterval
        {
            return nil
        }

        lastCheckDate = Date()
        return await check()
    }

    /// Checks if an update notification should be shown
    /// - Parameter result: The check result to evaluate
    /// - Returns: UpdateInfo if a notification should be shown, nil otherwise
    public func shouldNotify(for result: CheckResult) -> UpdateInfo? {
        guard case let .updateAvailable(info) = result else {
            return nil
        }

        // Only notify if we haven't notified for this version
        if lastNotifiedVersion == info.version {
            return nil
        }

        lastNotifiedVersion = info.version
        return info
    }

    /// Gets the last check date
    public func getLastCheckDate() -> Date? {
        lastCheckDate
    }

    /// Resets the check state (useful for testing)
    public func reset() {
        lastCheckDate = nil
        lastNotifiedVersion = nil
    }

    // MARK: - Private Methods

    private func processSuccessResponse(data: Data) throws -> CheckResult {
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

        // Skip drafts and prereleases
        if release.draft || release.prerelease {
            return .upToDate
        }

        let latestVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let currentVersion = currentVersionProvider()

        if Self.isVersion(latestVersion, newerThan: currentVersion) {
            // Find DMG asset or fall back to release page
            let downloadURL =
                release.assets.first { $0.name.hasSuffix(".dmg") }?.browserDownloadUrl
                    ?? URL(string: release.htmlUrl)!

            return .updateAvailable(
                UpdateInfo(
                    version: latestVersion,
                    downloadURL: downloadURL,
                    releaseURL: URL(string: release.htmlUrl)!,
                    releaseNotes: release.body
                ))
        } else {
            return .upToDate
        }
    }

    /// Compares two semantic version strings
    /// - Parameters:
    ///   - v1: First version (potentially newer)
    ///   - v2: Second version (potentially older)
    /// - Returns: true if v1 is newer than v2
    public static func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        // Strip leading 'v' or 'V' if present
        let clean1 = v1.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let clean2 = v2.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

        let parts1 = clean1.split(separator: ".").compactMap { Int($0) }
        let parts2 = clean2.split(separator: ".").compactMap { Int($0) }

        // Compare each version component
        for i in 0 ..< max(parts1.count, parts2.count) {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        return false
    }
}

// MARK: - Bundle Extension

public extension Bundle {
    /// Returns the app version from CFBundleShortVersionString
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// Returns the build number from CFBundleVersion
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }
}
