import Charts
import Domain
import SwiftUI

// MARK: - Usage Sparkline

/// A sparkline chart showing usage history trends.
///
/// Features:
/// - Smooth catmullRom interpolation for flowing curves
/// - Gradient fill from solid to transparent
/// - LED-glow effect on the line matching KOSMA design
/// - Respects reduce motion accessibility setting
/// - Accessible as decorative (parent provides context)
public struct UsageSparkline: View {
    /// The historical data points to display
    public let dataPoints: [UsageDataPoint]

    /// The color for the sparkline (matches progress bar)
    public let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(dataPoints: [UsageDataPoint], color: Color = Theme.Colors.brand) {
        self.dataPoints = dataPoints
        self.color = color
    }

    public var body: some View {
        Chart(dataPoints) { point in
            // Area fill with gradient
            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Usage", point.utilization)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [color.opacity(0.3), color.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            // Line on top with LED glow effect
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Usage", point.utilization)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...100)
        .chartLegend(.hidden)
        .frame(height: 20)
        // LED glow shadow effect - KOSMA design system
        .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 0)
        // Accessibility: mark as decorative since parent UsageProgressBar provides context
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Usage Sparkline - Rising") {
    let dataPoints = (0..<12).map { i in
        UsageDataPoint(
            utilization: Double(i) * 8 + Double.random(in: -2...2),
            timestamp: Date().addingTimeInterval(TimeInterval(-3600 * (12 - i)))
        )
    }

    return UsageSparkline(dataPoints: dataPoints)
        .padding()
        .background(Theme.Colors.canvasBlack)
}

#Preview("Usage Sparkline - Fluctuating") {
    let dataPoints = (0..<24).map { i in
        UsageDataPoint(
            utilization: 40 + sin(Double(i) * 0.5) * 30 + Double.random(in: -5...5),
            timestamp: Date().addingTimeInterval(TimeInterval(-300 * (24 - i)))
        )
    }

    return UsageSparkline(dataPoints: dataPoints, color: Theme.Colors.brandDark)
        .padding()
        .background(Theme.Colors.canvasBlack)
}

#Preview("Usage Sparkline - Minimal Data") {
    let dataPoints = [
        UsageDataPoint(utilization: 20, timestamp: Date().addingTimeInterval(-600)),
        UsageDataPoint(utilization: 45, timestamp: Date())
    ]

    return UsageSparkline(dataPoints: dataPoints)
        .padding()
        .background(Theme.Colors.canvasBlack)
}

#Preview("In Context - Progress Bar") {
    let dataPoints = (0..<30).map { i in
        UsageDataPoint(
            utilization: min(100, Double(i) * 3 + Double.random(in: -3...3)),
            timestamp: Date().addingTimeInterval(TimeInterval(-300 * (30 - i)))
        )
    }

    return VStack(alignment: .leading, spacing: 12) {
        Text("CURRENT SESSION (5H)")
            .font(.system(size: 10, weight: .light, design: .monospaced))
            .foregroundStyle(Theme.Colors.textTertiaryOnDark)
            .tracking(1.5)

        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("86")
                .font(.system(size: 32, weight: .bold, design: .monospaced).monospacedDigit())
                .foregroundStyle(Theme.Colors.brand)
                .shadow(color: Theme.Colors.brand.opacity(0.4), radius: 8)

            Text("%")
                .font(.system(size: 12, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.Colors.brand.opacity(0.6))
                .baselineOffset(12)
        }

        // Progress bar
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 20/255, green: 20/255, blue: 24/255))

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.brand, Theme.Colors.brandLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * 0.86)
                    .padding(1)
                    .shadow(color: Theme.Colors.brand.opacity(0.5), radius: 6)
            }
        }
        .frame(height: 4)

        // Sparkline
        UsageSparkline(dataPoints: dataPoints)

        // Bracket metadata
        HStack(spacing: 0) {
            Text("[")
                .foregroundStyle(Theme.Colors.accentRed)
            Text("Resets in 2 hr / ~3h remaining")
                .foregroundStyle(Theme.Colors.textTertiaryOnDark)
            Text("]")
                .foregroundStyle(Theme.Colors.accentRed)
        }
        .font(.system(size: 10, weight: .regular, design: .monospaced))
    }
    .padding(20)
    .background(Theme.Colors.canvasBlack)
    .frame(width: 280)
}
#endif
