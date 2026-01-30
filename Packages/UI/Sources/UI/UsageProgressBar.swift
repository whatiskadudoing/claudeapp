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
        VStack(alignment: .leading, spacing: 12) {
            // === TE-STYLE LABEL ROW ===
            HStack(alignment: .firstTextBaseline) {
                // Label - light weight, tracked (Univers Light style)
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                    .tracking(1.5)

                Spacer()

                // Large percentage - calculator display style
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(Int(value))")
                        .font(.system(size: 32, weight: .bold, design: .monospaced).monospacedDigit())
                        .foregroundStyle(Theme.Colors.brand)
                        .contentTransition(.numericText())
                        .shadow(color: Theme.Colors.brand.opacity(0.4), radius: 8, x: 0, y: 0)

                    Text("%")
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundStyle(Theme.Colors.brand.opacity(0.6))
                        .baselineOffset(12)
                }
            }

            // === TE-STYLE PROGRESS BAR (LED meter aesthetic) ===
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track - recessed look
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 20/255, green: 20/255, blue: 24/255))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.black.opacity(0.5), lineWidth: 1)
                        )

                    // Fill with LED glow effect
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
                            .frame(width: max(geo.size.width * min(value / 100, 1), 4))
                            .padding(1)
                            // LED glow
                            .shadow(color: Theme.Colors.brand.opacity(0.5), radius: 6, x: 0, y: 0)
                            .shadow(color: Theme.Colors.brand.opacity(0.3), radius: 12, x: 0, y: 0)
                            .animation(reduceMotion ? nil : .kosma, value: value)
                    }
                }
            }
            .frame(height: 4)

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
