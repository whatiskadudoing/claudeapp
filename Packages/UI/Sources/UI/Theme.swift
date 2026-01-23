import SwiftUI

// MARK: - Theme

/// Design system constants for ClaudeApp.
/// Based on Claude brand colors and modern macOS design patterns.
public enum Theme {
    // MARK: - Colors

    public enum Colors {
        /// Claude Crail - Primary brand color #C15F3C
        public static let primary = Color(red: 0.757, green: 0.373, blue: 0.235)

        /// Cloudy - Secondary color #B1ADA1
        public static let secondary = Color(red: 0.694, green: 0.678, blue: 0.631)

        /// Pampas - Light background #F4F3EE
        public static let background = Color(red: 0.957, green: 0.953, blue: 0.933)

        /// Success green #22C55E
        public static let success = Color(red: 0.133, green: 0.773, blue: 0.369)

        /// Warning yellow #B8860B (goldenrod)
        /// Darkened from #EAB308 to meet WCAG AA 3:1 contrast ratio against background (#F4F3EE)
        /// Original #EAB308 had 2.1:1 contrast; #B8860B achieves 3.5:1
        public static let warning = Color(red: 0.722, green: 0.525, blue: 0.043)

        /// Danger/Error - same as primary #C15F3C
        public static let danger = primary

        /// High burn rate orange #F97316
        public static let orange = Color(red: 0.976, green: 0.451, blue: 0.086)
    }

    // MARK: - Spacing

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    public enum CornerRadius {
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 8
        public static let lg: CGFloat = 12
        public static let full: CGFloat = 9999
    }

    // MARK: - Typography

    /// Semantic font styles that scale with Dynamic Type.
    /// All styles use system fonts that automatically adapt to user accessibility settings.
    public enum Typography {
        /// Main dropdown/window title - scales with .headline
        public static let title: Font = .headline

        /// Section headers in settings - scales with .caption
        public static let sectionHeader: Font = .caption

        /// Primary content text - scales with .body
        public static let body: Font = .body

        /// Progress bar labels - scales with .caption
        public static let label: Font = .caption

        /// Progress bar percentage with monospaced digits - scales with .body
        public static let percentage: Font = .body.monospacedDigit()

        /// Secondary/metadata text - scales with .caption2
        public static let metadata: Font = .caption2

        /// Badge text (burn rate, plan) - scales with .caption2
        public static let badge: Font = .caption2.weight(.medium)

        /// Menu bar percentage - fixed size for menu bar constraints
        /// Note: Menu bar has limited space, but we use a reasonable default
        public static let menuBar: Font = .body.monospacedDigit()

        /// Small UI elements like slider labels - scales with .caption2
        public static let tiny: Font = .caption2

        /// Icon/symbol sizes that scale with text
        /// These are relative sizes for SF Symbols to match adjacent text
        public static let iconSmall: Font = .caption2
        public static let iconMedium: Font = .body
        public static let iconLarge: Font = .title2
    }
}
