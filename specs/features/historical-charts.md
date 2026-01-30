# Feature: Historical Usage Charts

## Overview

Add sparkline charts showing usage trends over time, enabling users to understand their consumption patterns at a glance.

---

## Research References

> **Sources:**
> - [ccseva](https://github.com/Iamshankhadeep/ccseva) (761 stars) - 7-day usage charts
> - [quotio](https://github.com/nguyenphutrong/quotio) (3,099 stars) - Usage analytics
> - [DSFSparkline](https://github.com/dagronf/DSFSparkline) (160 stars) - Recommended sparkline library
> - [Swift-Charts-Examples](https://github.com/jordibruin/Swift-Charts-Examples) (2,368 stars) - Native Swift Charts patterns
> - Research document: `research/swift-chart-libraries.md`

---

## User Story

**As a** ClaudeApp user
**I want to** see my usage trends over time
**So that** I can understand my consumption patterns and plan accordingly

---

## Design

### Sparkline in Dropdown

Add mini sparkline charts below each usage progress bar:

```
┌──────────────────────────────────────┐
│ Claude Usage        [Med] ⚙️  🔄      │
├──────────────────────────────────────┤
│                                      │
│ Current Session (5h)           45%   │
│ ████████████░░░░░░░░░░░░░░░░░░░░░░  │
│ ▁▂▃▅▆▇█▇▆▅▄▃▂▁▂▃▄▅▆▇            │ ← Sparkline
│ Resets in 2 hours · ~3h until limit  │
│                                      │
│ Weekly (All Models)            72%   │
│ ██████████████████████████░░░░░░░░  │
│ ▁▁▂▂▃▄▅▆▆▇▇███▇▆▆▅▄▄▃▃▂▂▁        │ ← 7-day trend
│ Resets Fri 7:59 AM · ~8h until limit │
│                                      │
├──────────────────────────────────────┤
│ Updated 2m ago                  ...  │
└──────────────────────────────────────┘
```

### Sparkline Specifications

| Property | Value |
|----------|-------|
| Width | Full width of usage section (~248px) |
| Height | 20px |
| Color | Matches progress bar color |
| Data points | 24 points (1 per 5 min for 5h, 1 per day for 7d) |
| Line style | Smooth curve with filled area |

### Data Points

| Window | Granularity | Points | Period |
|--------|-------------|--------|--------|
| 5-hour session | 5 minutes | 60 | Last 5 hours |
| 7-day windows | 1 hour | 168 | Last 7 days |

---

## Settings Toggle

Add option to show/hide sparklines:

```swift
extension SettingsKey {
    static let showSparklines = SettingsKey<Bool>(
        key: "showSparklines",
        defaultValue: true
    )
}
```

In Settings UI:

```
┌──────────────────────────────────────┐
│ Display ─────────────────────────    │
│ ┌──────────────────────────────────┐ │
│ │ Menu Bar Style      [Percentage ▾]│ │
│ ├──────────────────────────────────┤ │
│ │ Show Usage Charts         [───●] │ │ ← NEW
│ ├──────────────────────────────────┤ │
│ │ Show Plan Badge           [○───] │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

---

## Data Model

### Usage History

```swift
/// Represents a single usage data point for historical tracking
public struct UsageDataPoint: Sendable, Equatable, Codable {
    public let utilization: Double
    public let timestamp: Date

    public init(utilization: Double, timestamp: Date) {
        self.utilization = utilization
        self.timestamp = timestamp
    }
}

/// Manages usage history for sparkline charts
@Observable
public final class UsageHistoryManager {
    /// History for 5-hour session (5-min granularity, max 60 points)
    public private(set) var sessionHistory: [UsageDataPoint] = []

    /// History for 7-day windows (1-hour granularity, max 168 points)
    public private(set) var weeklyHistory: [UsageDataPoint] = []

    private let maxSessionPoints = 60    // 5 hours at 5-min intervals
    private let maxWeeklyPoints = 168    // 7 days at 1-hour intervals

    /// Record a new usage snapshot
    public func record(sessionUtilization: Double, weeklyUtilization: Double) {
        let now = Date()

        // Session history (5-min granularity)
        if shouldRecordSession(at: now) {
            sessionHistory.append(UsageDataPoint(utilization: sessionUtilization, timestamp: now))
            if sessionHistory.count > maxSessionPoints {
                sessionHistory.removeFirst()
            }
        }

        // Weekly history (1-hour granularity)
        if shouldRecordWeekly(at: now) {
            weeklyHistory.append(UsageDataPoint(utilization: weeklyUtilization, timestamp: now))
            if weeklyHistory.count > maxWeeklyPoints {
                weeklyHistory.removeFirst()
            }
        }
    }

    private func shouldRecordSession(at date: Date) -> Bool {
        guard let last = sessionHistory.last else { return true }
        return date.timeIntervalSince(last.timestamp) >= 300 // 5 minutes
    }

    private func shouldRecordWeekly(at date: Date) -> Bool {
        guard let last = weeklyHistory.last else { return true }
        return date.timeIntervalSince(last.timestamp) >= 3600 // 1 hour
    }

    /// Clear session history (called on session reset)
    public func clearSessionHistory() {
        sessionHistory.removeAll()
    }
}
```

### Persistence

Store history in UserDefaults or a lightweight local file:

```swift
extension UsageHistoryManager {
    private static let sessionHistoryKey = "sessionUsageHistory"
    private static let weeklyHistoryKey = "weeklyUsageHistory"

    func save() {
        let encoder = JSONEncoder()
        if let sessionData = try? encoder.encode(sessionHistory) {
            UserDefaults.standard.set(sessionData, forKey: Self.sessionHistoryKey)
        }
        if let weeklyData = try? encoder.encode(weeklyHistory) {
            UserDefaults.standard.set(weeklyData, forKey: Self.weeklyHistoryKey)
        }
    }

    func load() {
        let decoder = JSONDecoder()
        if let sessionData = UserDefaults.standard.data(forKey: Self.sessionHistoryKey),
           let history = try? decoder.decode([UsageDataPoint].self, from: sessionData) {
            sessionHistory = history
        }
        if let weeklyData = UserDefaults.standard.data(forKey: Self.weeklyHistoryKey),
           let history = try? decoder.decode([UsageDataPoint].self, from: weeklyData) {
            weeklyHistory = history
        }
    }
}
```

---

## UI Implementation

### Option 1: Native Swift Charts (Recommended)

Using Apple's built-in Swift Charts framework (iOS 16+/macOS 13+):

```swift
import Charts

struct UsageSparkline: View {
    let dataPoints: [UsageDataPoint]
    let color: Color

    var body: some View {
        Chart(dataPoints, id: \.timestamp) { point in
            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Usage", point.utilization)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [color.opacity(0.3), color.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Usage", point.utilization)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...100)
        .frame(height: 20)
    }
}
```

### Option 2: DSFSparkline Library

If more customization is needed:

```swift
// Package.swift dependency
.package(url: "https://github.com/dagronf/DSFSparkline", from: "6.0.0")

// Usage
import DSFSparkline

struct UsageSparkline: View {
    let dataPoints: [UsageDataPoint]
    let color: Color

    var body: some View {
        DSFSparklineSurface.SwiftUI.Line(
            dataSource: sparklineDataSource,
            graphColor: DSFColor(color),
            lineWidth: 1.5,
            interpolated: true,
            shadowed: true
        )
        .frame(height: 20)
    }

    private var sparklineDataSource: DSFSparkline.DataSource {
        let values = dataPoints.map { CGFloat($0.utilization) }
        return DSFSparkline.DataSource(values: values, range: 0...100)
    }
}
```

### Integration with UsageProgressBar

```swift
struct UsageProgressBar: View {
    let value: Double
    let label: String
    let resetsAt: Date?
    let timeToExhaustion: TimeInterval?
    let historyDataPoints: [UsageDataPoint]?  // NEW

    @AppStorage("showSparklines") private var showSparklines = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // ... existing header and progress bar ...

            // NEW: Sparkline chart
            if showSparklines, let dataPoints = historyDataPoints, dataPoints.count >= 2 {
                UsageSparkline(dataPoints: dataPoints, color: progressColor)
                    .padding(.top, 2)
            }

            // ... existing reset time and time-to-exhaustion ...
        }
    }
}
```

---

## Today vs Yesterday Comparison

Add delta indicator showing change from previous day:

```swift
struct UsageDeltaIndicator: View {
    let currentValue: Double
    let previousValue: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                .font(.system(size: 8))
            Text("\(abs(Int(delta)))%")
                .font(.caption2)
        }
        .foregroundStyle(delta >= 0 ? .red : .green)
    }

    private var delta: Double {
        currentValue - previousValue
    }
}
```

Display in dropdown header or per-window:

```
│ Weekly (All Models)      ↑5%   72%   │
```

---

## Performance Considerations

### Memory Budget

- Session history: 60 points × ~32 bytes = ~2 KB
- Weekly history: 168 points × ~32 bytes = ~5.5 KB
- Total: < 10 KB (negligible)

### CPU Budget

- Chart rendering: < 5ms per sparkline
- Data recording: < 1ms per refresh
- Use `drawingGroup()` for Metal acceleration if needed

### Battery Optimization

- Only render sparklines when dropdown is visible
- Use `@State` to cache rendered chart images
- Disable animations when `accessibilityReduceMotion` is enabled

---

## Acceptance Criteria

### Must Have

- [x] Sparkline chart for 5-hour session window
- [x] Sparkline chart for 7-day weekly window
- [x] Toggle to enable/disable sparklines in settings
- [x] Charts update on data refresh
- [x] History persists across app restarts

### Should Have

- [x] Smooth interpolated line style
- [x] Gradient fill under line
- [x] Color matches progress bar threshold
- [ ] Today vs yesterday delta indicator

### Nice to Have

- [ ] Tap sparkline to see detailed history view
- [ ] Export history as CSV
- [ ] Configurable history retention period

---

## Related Specifications

- [view-usage.md](./view-usage.md) - Main usage display
- [design-system.md](../design-system.md) - Colors and styling
- [performance.md](../performance.md) - Performance budgets
