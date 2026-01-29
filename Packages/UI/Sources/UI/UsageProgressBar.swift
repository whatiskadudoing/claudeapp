import SwiftUI

// MARK: - Usage Progress Bar

/// KOSMA-inspired usage progress bar.
/// Features: Thin 3px bar, gradient fill with glow, large bold percentage,
/// bracket metadata notation [Resets in X / ~Xh remaining], specular highlight.
public struct UsageProgressBar: View {
    public let value: Double
    public let label: String
    public let resetsAt: Date?
    public let timeToExhaustion: TimeInterval?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(value: Double, label: String, resetsAt: Date? = nil, timeToExhaustion: TimeInterval? = nil) {
        self.value = value
        self.label = label
        self.resetsAt = resetsAt
        self.timeToExhaustion = timeToExhaustion
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // === KOSMA LABEL ROW ===
            HStack(alignment: .firstTextBaseline) {
                // Label with KOSMA uppercase tracking - monospaced
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textSecondaryOnDark)
                    .tracking(0.8)

                Spacer()

                // Large, bold percentage (KOSMA orange - tabular figures)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(Int(value))")
                        .font(.system(size: 28, weight: .bold, design: .monospaced).monospacedDigit())
                        .foregroundStyle(Theme.Colors.brand)
                        .contentTransition(.numericText())

                    Text("%")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.Colors.brand.opacity(0.5))
                        .baselineOffset(8)
                }
            }

            // === KOSMA PROGRESS BAR (3px, technical) ===
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track - deep with inner shadow effect
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(red: 26/255, green: 26/255, blue: 26/255))
                        .overlay(
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.5), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )

                    // KOSMA gradient fill with leading edge glow
                    if value > 0 {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.brand,
                                        Theme.Colors.brandLight
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * min(value / 100, 1), 3))
                            // Leading edge glow
                            .shadow(
                                color: Theme.Colors.brand.opacity(0.6),
                                radius: 8,
                                x: 4,
                                y: 0
                            )
                            // Leading edge highlight (white cap)
                            .overlay(alignment: .trailing) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 2)
                            }
                            .animation(reduceMotion ? nil : .kosma, value: value)
                    }
                }
            }
            .frame(height: 3)

            // === KOSMA BRACKET METADATA (tight brackets) ===
            if resetsAt != nil || shouldShowTime {
                HStack(spacing: 0) {
                    Text("[")
                        .foregroundStyle(Theme.Colors.accentRed)

                    if let date = resetsAt {
                        Text(resetText(date))
                            .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                    }

                    if resetsAt != nil && shouldShowTime {
                        Text(" / ")
                            .foregroundStyle(Theme.Colors.textTertiaryOnDark.opacity(0.5))
                    }

                    if shouldShowTime, let time = formattedTime {
                        Text("~\(time) remaining")
                            .foregroundStyle(Theme.Colors.brand.opacity(0.8))
                    }

                    Text("]")
                        .foregroundStyle(Theme.Colors.accentRed)
                }
                .font(.system(size: 10, weight: .regular, design: .monospaced))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(Int(value)) percent")
        .accessibilityValue(accessibilityDetail)
    }

    private var statusColor: Color {
        Theme.Colors.status(for: value)
    }

    private var shouldShowTime: Bool {
        value >= 50 && value < 100 && timeToExhaustion != nil && timeToExhaustion! > 0
    }

    private var formattedTime: String? {
        guard let seconds = timeToExhaustion, seconds > 0 else { return nil }
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 { return "\(hours)h" }
        if minutes > 0 { return "\(minutes)m" }
        return "<1m"
    }

    private func resetText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Resets \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    private var accessibilityDetail: String {
        var parts: [String] = []
        if let date = resetsAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            parts.append("resets \(formatter.localizedString(for: date, relativeTo: Date()))")
        }
        if shouldShowTime, let time = formattedTime {
            parts.append("approximately \(time) until limit")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Compact Variant

/// Compact KOSMA-style progress bar for tight spaces
public struct CompactProgressBar: View {
    public let value: Double
    public let label: String

    public init(value: Double, label: String) {
        self.value = value
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .tracking(0.8)

                Spacer()

                Text("\(Int(value))%")
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.Colors.status(for: value))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.primary.opacity(0.05))

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.status(for: value),
                                    Theme.Colors.status(for: value).opacity(0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * min(value / 100, 1), 0))
                        .shadow(
                            color: Theme.Colors.status(for: value).opacity(0.4),
                            radius: 3,
                            x: 2,
                            y: 0
                        )
                }
            }
            .frame(height: 3)
        }
    }
}

// MARK: - Legacy Aliases

public struct UsageCard: View {
    public let value: Double
    public let label: String
    public let resetsAt: Date?
    public let timeToExhaustion: TimeInterval?

    public init(value: Double, label: String, resetsAt: Date? = nil, timeToExhaustion: TimeInterval? = nil) {
        self.value = value
        self.label = label
        self.resetsAt = resetsAt
        self.timeToExhaustion = timeToExhaustion
    }

    public var body: some View {
        UsageProgressBar(value: value, label: label, resetsAt: resetsAt, timeToExhaustion: timeToExhaustion)
    }
}
