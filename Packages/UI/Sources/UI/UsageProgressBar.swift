import SwiftUI

// MARK: - Diagonal Stripes Pattern

/// A diagonal stripe pattern shape for color-blind accessibility.
/// Used to provide visual pattern overlay on progress bars at critical thresholds.
/// This ensures status is conveyed through patterns, not just color (WCAG 2.1 AA).
struct DiagonalStripes: Shape {
    let lineWidth: CGFloat
    let spacing: CGFloat

    init(lineWidth: CGFloat = 2, spacing: CGFloat = 6) {
        self.lineWidth = lineWidth
        self.spacing = spacing
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Create diagonal lines from bottom-left to top-right
        let count = Int((rect.width + rect.height) / spacing) + 1
        for i in 0..<count {
            let x = CGFloat(i) * spacing - rect.height
            path.move(to: CGPoint(x: x, y: rect.height))
            path.addLine(to: CGPoint(x: x + rect.height, y: 0))
        }
        return path
    }
}

// MARK: - Usage Progress Bar

/// A single progress bar showing utilization percentage.
/// Displays reset time and optionally time-to-exhaustion when calculable.
/// Adapts layout for accessibility text sizes.
/// Includes diagonal stripe pattern at >90% for color-blind accessibility.
/// Respects "Reduce Motion" accessibility setting - instant width changes instead of animated.
public struct UsageProgressBar: View {
    public let value: Double
    public let label: String
    public let resetsAt: Date?
    public let timeToExhaustion: TimeInterval?

    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether we're using accessibility sizes (AX1 and above)
    private var isAccessibilitySize: Bool {
        sizeCategory >= .accessibilityMedium
    }

    /// Animation for the progress bar fill.
    /// Returns nil when Reduce Motion is enabled (instant width changes).
    private var progressAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.3)
    }

    /// Initialize with required parameters.
    /// - Parameters:
    ///   - value: Usage percentage (0-100)
    ///   - label: Label text for the progress bar
    ///   - resetsAt: When this window resets (optional)
    ///   - timeToExhaustion: Seconds until limit reached (optional)
    public init(value: Double, label: String, resetsAt: Date? = nil, timeToExhaustion: TimeInterval? = nil) {
        self.value = value
        self.label = label
        self.resetsAt = resetsAt
        self.timeToExhaustion = timeToExhaustion
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Header adapts to accessibility sizes
            if isAccessibilitySize {
                // Stack vertically for accessibility sizes to prevent truncation
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(Theme.Typography.label)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(Int(value))%")
                        .font(Theme.Typography.percentage)
                        .fontWeight(.medium)
                }
            } else {
                // Standard horizontal layout
                HStack {
                    Text(label)
                        .font(Theme.Typography.label)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(value))%")
                        .font(Theme.Typography.percentage)
                        .fontWeight(.medium)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(nsColor: .separatorColor))

                    // Progress fill with optional pattern overlay
                    ZStack {
                        // Base color fill
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor)

                        // Diagonal stripe pattern overlay for color-blind accessibility
                        // Shows at >90% utilization to convey critical status without relying on color
                        if shouldShowPattern {
                            DiagonalStripes(lineWidth: 1.5, spacing: 4)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    .frame(width: geometry.size.width * min(value / 100, 1))
                    .animation(progressAnimation, value: value)
                }
            }
            .frame(height: 6)

            // Display reset time and/or time-to-exhaustion
            if resetsAt != nil || shouldShowTimeToExhaustion {
                HStack(spacing: 0) {
                    if let resetsAt {
                        // Use localized format with system-provided relative date
                        Text(resetsAtText(for: resetsAt))
                    }
                    if resetsAt != nil, shouldShowTimeToExhaustion {
                        Text(" \u{00B7} ")
                    }
                    if shouldShowTimeToExhaustion {
                        Text(timeToExhaustionText)
                    }
                }
                .font(Theme.Typography.metadata)
                .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(Int(value)) percent")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var progressColor: Color {
        switch value {
        case 0..<50:
            Theme.Colors.success
        case 50..<90:
            Theme.Colors.warning
        default:
            Theme.Colors.primary
        }
    }

    /// Whether to show diagonal stripe pattern overlay.
    /// Shows at >90% utilization to convey critical status for color-blind users.
    /// Pattern provides redundant visual information beyond color alone (WCAG 2.1 AA).
    private var shouldShowPattern: Bool {
        value >= 90
    }

    /// Comprehensive accessibility label for VoiceOver.
    /// Includes label, percentage, reset time, and time-to-exhaustion when available.
    private var accessibilityLabel: String {
        var components: [String] = []

        // Primary: label and percentage
        components.append("\(label), \(Int(value)) percent")

        // Reset time if available (localized)
        if let resetsAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            let resetString = formatter.localizedString(for: resetsAt, relativeTo: Date())
            let key = "accessibility.progressBar.resets %@"
            let format = Bundle.main.localizedString(forKey: key, value: "resets %@", table: nil)
            components.append(String(format: format, resetString))
        }

        // Time-to-exhaustion if calculable and relevant (localized)
        if shouldShowTimeToExhaustion {
            let key = "accessibility.progressBar.timeToExhaustion %@"
            let format = Bundle.main.localizedString(forKey: key, value: "approximately %@ until limit", table: nil)
            components.append(String(format: format, spokenTimeToExhaustion))
        }

        return components.joined(separator: ", ")
    }

    /// Spoken format of time-to-exhaustion for VoiceOver.
    /// Examples: "3 hours", "45 minutes", "less than 1 minute"
    /// Uses localized strings from the app's String Catalog.
    private var spokenTimeToExhaustion: String {
        guard let seconds = timeToExhaustion, seconds > 0 else {
            return ""
        }

        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            if hours == 1 {
                return Bundle.main.localizedString(forKey: "time.hour", value: "1 hour", table: nil)
            } else {
                let format = Bundle.main.localizedString(forKey: "time.hours %lld", value: "%lld hours", table: nil)
                return String(format: format, hours)
            }
        } else if minutes > 0 {
            if minutes == 1 {
                return Bundle.main.localizedString(forKey: "time.minute", value: "1 minute", table: nil)
            } else {
                let format = Bundle.main.localizedString(forKey: "time.minutes %lld", value: "%lld minutes", table: nil)
                return String(format: format, minutes)
            }
        } else {
            return Bundle.main.localizedString(forKey: "time.lessThanMinute", value: "less than 1 minute", table: nil)
        }
    }

    /// Only show time-to-exhaustion when:
    /// - Utilization > 20% (avoid noise at low usage)
    /// - timeToExhaustion is not nil
    /// - value is less than 100% (not already at limit)
    private var shouldShowTimeToExhaustion: Bool {
        guard value > 20, value < 100, let tte = timeToExhaustion, tte > 0 else {
            return false
        }
        return true
    }

    /// Format TimeInterval to human-readable string.
    /// Examples: "3h", "45min", "<1min"
    private var formattedTimeToExhaustion: String {
        guard let seconds = timeToExhaustion, seconds > 0 else {
            return "\u{2014}"
        }

        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            // Show hours only for clarity (e.g., "3h" not "3h 45min")
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)min"
        } else {
            return "<1min"
        }
    }

    /// Localized text for time-to-exhaustion display.
    /// Uses Bundle.main to access the app's String Catalog.
    private var timeToExhaustionText: String {
        let key = "usage.timeToExhaustion.untilLimit %@"
        let format = Bundle.main.localizedString(forKey: key, value: "~%@ until limit", table: nil)
        return String(format: format, formattedTimeToExhaustion)
    }

    /// Localized text for reset time display.
    /// Combines localized "Resets" text with system-provided relative date.
    private func resetsAtText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let relativeTime = formatter.localizedString(for: date, relativeTo: Date())

        let key = "usage.resets %@"
        let format = Bundle.main.localizedString(forKey: key, value: "Resets %@", table: nil)
        return String(format: format, relativeTime)
    }
}
