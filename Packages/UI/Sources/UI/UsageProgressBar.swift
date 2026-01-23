import SwiftUI

// MARK: - Usage Progress Bar

/// A single progress bar showing utilization percentage.
/// Displays reset time and optionally time-to-exhaustion when calculable.
public struct UsageProgressBar: View {
    let value: Double
    let label: String
    let resetsAt: Date?
    let timeToExhaustion: TimeInterval?

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

            // Display reset time and/or time-to-exhaustion
            if resetsAt != nil || shouldShowTimeToExhaustion {
                HStack(spacing: 0) {
                    if let resetsAt {
                        Text("Resets \(resetsAt, style: .relative)")
                    }
                    if resetsAt != nil, shouldShowTimeToExhaustion {
                        Text(" \u{00B7} ")
                    }
                    if shouldShowTimeToExhaustion {
                        Text("~\(formattedTimeToExhaustion) until limit")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
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
}
