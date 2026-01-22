import Core
import Domain
import SwiftUI

@main
struct ClaudeApp: App {
    @State private var container: AppContainer

    init() {
        _container = State(initialValue: AppContainer())
    }

    var body: some Scene {
        MenuBarExtra {
            DropdownView()
                .environment(container.usageManager)
        } label: {
            MenuBarLabel()
                .environment(container.usageManager)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Label

/// The label displayed in the macOS menu bar.
/// Shows Claude icon + percentage or loading/error state.
struct MenuBarLabel: View {
    @Environment(UsageManager.self) private var usageManager

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkle")
                .font(.system(size: 14))

            if usageManager.isLoading && usageManager.usageData == nil {
                ProgressView()
                    .controlSize(.small)
            } else if let data = usageManager.usageData {
                Text("\(Int(data.highestUtilization))%")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
            } else {
                Text("--")
                    .font(.system(size: 12, weight: .medium))
            }
        }
    }
}

// MARK: - Dropdown View

/// The dropdown content that appears when clicking the menu bar item.
/// Shows detailed usage information with progress bars.
struct DropdownView: View {
    @Environment(UsageManager.self) private var usageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Claude Usage")
                    .font(.headline)
                Spacer()
                RefreshButton()
            }

            Divider()

            // Content
            if let data = usageManager.usageData {
                UsageContent(data: data)
            } else if usageManager.isLoading {
                LoadingView()
            } else if let error = usageManager.lastError {
                ErrorView(error: error) {
                    Task { await usageManager.refresh() }
                }
            } else {
                EmptyStateView {
                    Task { await usageManager.refresh() }
                }
            }

            Divider()

            // Footer
            HStack {
                if let lastUpdated = usageManager.lastUpdated {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .keyboardShortcut("r", modifiers: .command)
        .task {
            // Refresh on dropdown open if data is stale or missing
            if usageManager.usageData == nil || usageManager.isStale {
                await usageManager.refresh()
            }
        }
    }
}

// MARK: - Refresh Button

/// Button for manual refresh with visual state feedback.
/// Shows different icons based on refresh state: idle, loading, success, error.
struct RefreshButton: View {
    @Environment(UsageManager.self) private var usageManager

    var body: some View {
        Button {
            Task { await usageManager.refresh() }
        } label: {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .rotationEffect(.degrees(usageManager.refreshState == .loading ? 360 : 0))
                .animation(
                    usageManager.refreshState == .loading
                        ? .linear(duration: 1).repeatForever(autoreverses: false)
                        : .default,
                    value: usageManager.refreshState
                )
        }
        .buttonStyle(.plain)
        .disabled(usageManager.isLoading)
        .keyboardShortcut("r", modifiers: .command)
    }

    private var iconName: String {
        switch usageManager.refreshState {
        case .idle:
            "arrow.clockwise"
        case .loading:
            "arrow.clockwise"
        case .success:
            "checkmark.circle"
        case .error:
            "exclamationmark.circle"
        }
    }

    private var iconColor: Color {
        switch usageManager.refreshState {
        case .idle, .loading:
            .primary
        case .success:
            .green
        case .error:
            .red
        }
    }
}

// MARK: - Usage Content

/// Displays the usage progress bars when data is available.
struct UsageContent: View {
    let data: UsageData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            UsageProgressBar(
                value: data.fiveHour.utilization,
                label: "Current Session (5h)",
                resetsAt: data.fiveHour.resetsAt
            )

            UsageProgressBar(
                value: data.sevenDay.utilization,
                label: "Weekly (All Models)",
                resetsAt: data.sevenDay.resetsAt
            )

            if let opus = data.sevenDayOpus {
                UsageProgressBar(
                    value: opus.utilization,
                    label: "Weekly (Opus)",
                    resetsAt: opus.resetsAt
                )
            }

            if let sonnet = data.sevenDaySonnet {
                UsageProgressBar(
                    value: sonnet.utilization,
                    label: "Weekly (Sonnet)",
                    resetsAt: sonnet.resetsAt
                )
            }
        }
    }
}

// MARK: - Usage Progress Bar

/// A single progress bar showing utilization percentage.
struct UsageProgressBar: View {
    let value: Double
    let label: String
    let resetsAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value))%")
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(nsColor: .separatorColor))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * min(value / 100, 1))
                        .animation(.easeOut(duration: 0.3), value: value)
                }
            }
            .frame(height: 6)

            if let resetsAt {
                Text("Resets \(resetsAt, style: .relative)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var progressColor: Color {
        switch value {
        case 0..<50:
            Color.green
        case 50..<90:
            Color.yellow
        default:
            Color(red: 0.757, green: 0.373, blue: 0.235) // #C15F3C - Claude Crail
        }
    }
}

// MARK: - Loading View

/// Displayed while fetching initial data.
struct LoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView()
                Text("Loading usage data...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Error View

/// Displayed when an error occurs.
struct ErrorView: View {
    let error: AppError
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: errorIcon)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(errorTitle)
                .font(.caption)
                .fontWeight(.medium)

            Text(errorMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: retryAction)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var errorIcon: String {
        switch error {
        case .notAuthenticated:
            "person.crop.circle.badge.questionmark"
        default:
            "exclamationmark.triangle"
        }
    }

    private var errorTitle: String {
        switch error {
        case .notAuthenticated:
            "Claude Code not found"
        case .networkError:
            "Connection Error"
        case .rateLimited:
            "Rate Limited"
        default:
            "Unable to load data"
        }
    }

    private var errorMessage: String {
        switch error {
        case .notAuthenticated:
            "Run `claude login` in terminal to connect"
        case .networkError(let message):
            message
        case .rateLimited(let retryAfter):
            "Please wait \(retryAfter) seconds"
        case .apiError(let statusCode, _):
            "Server error (\(statusCode))"
        case .keychainError(let message):
            message
        case .decodingError(let message):
            message
        }
    }
}

// MARK: - Empty State View

/// Displayed when no data is available and not loading.
struct EmptyStateView: View {
    let refreshAction: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No usage data")
                .font(.caption)
                .fontWeight(.medium)

            Button("Refresh", action: refreshAction)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
