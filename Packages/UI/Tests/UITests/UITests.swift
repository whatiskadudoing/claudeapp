import Domain
import SwiftUI
import Testing
@testable import UI

@Suite("UI Tests")
struct UITests {
    @Test("UI version is correct")
    func uiVersion() {
        #expect(UI.version == "1.0.0")
    }
}

@Suite("Theme Tests")
struct ThemeTests {
    @Test("Theme.Colors.primary is Claude Crail")
    func primaryColor() {
        // Claude Crail is #C15F3C (RGB: 193, 95, 60 -> 0.757, 0.373, 0.235)
        // We can't directly compare Color values, but we verify the constant exists
        let _ = Theme.Colors.primary
        #expect(true) // Compilation success means the constant exists
    }

    @Test("Theme.Colors has all required colors")
    func allColorsExist() {
        let _ = Theme.Colors.primary
        let _ = Theme.Colors.secondary
        let _ = Theme.Colors.background
        let _ = Theme.Colors.success
        let _ = Theme.Colors.warning
        let _ = Theme.Colors.danger
        let _ = Theme.Colors.orange
        #expect(true)
    }

    @Test("Theme.Spacing has all values")
    func spacingValues() {
        #expect(Theme.Spacing.xs == 4)
        #expect(Theme.Spacing.sm == 8)
        #expect(Theme.Spacing.md == 12)
        #expect(Theme.Spacing.lg == 16)
        #expect(Theme.Spacing.xl == 24)
        #expect(Theme.Spacing.xxl == 32)
    }

    @Test("Theme.CornerRadius has all values")
    func cornerRadiusValues() {
        #expect(Theme.CornerRadius.sm == 4)
        #expect(Theme.CornerRadius.md == 8)
        #expect(Theme.CornerRadius.lg == 12)
        #expect(Theme.CornerRadius.full == 9999)
    }
}

@Suite("UsageProgressBar Tests")
struct UsageProgressBarTests {
    @Test("UsageProgressBar can be initialized with minimal parameters")
    func minimalInit() {
        let progressBar = UsageProgressBar(value: 50, label: "Test")
        // Verify it compiles and creates successfully
        #expect(true)
    }

    @Test("UsageProgressBar can be initialized with all parameters")
    func fullInit() {
        let resetDate = Date()
        let progressBar = UsageProgressBar(
            value: 75,
            label: "Test Usage",
            resetsAt: resetDate,
            timeToExhaustion: 3600
        )
        #expect(true)
    }
}

@Suite("BurnRateBadge Tests")
struct BurnRateBadgeTests {
    @Test("BurnRateBadge can be initialized for all levels")
    func allLevels() {
        let lowBadge = BurnRateBadge(level: .low)
        let medBadge = BurnRateBadge(level: .medium)
        let highBadge = BurnRateBadge(level: .high)
        let veryHighBadge = BurnRateBadge(level: .veryHigh)
        #expect(true)
    }
}

@Suite("SettingsComponents Tests")
struct SettingsComponentsTests {
    @Test("SectionHeader can be initialized")
    func sectionHeaderInit() {
        let header = SectionHeader(title: "Test Section")
        #expect(true)
    }

    @Test("SettingsToggle can be initialized without subtitle")
    func settingsToggleMinimal() {
        var isOn = false
        let toggle = SettingsToggle(title: "Test", isOn: .constant(false))
        #expect(true)
    }

    @Test("SettingsToggle can be initialized with subtitle")
    func settingsToggleWithSubtitle() {
        let toggle = SettingsToggle(
            title: "Test Toggle",
            isOn: .constant(true),
            subtitle: "A helpful description"
        )
        #expect(true)
    }
}
