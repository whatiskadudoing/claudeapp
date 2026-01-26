import SwiftUI

// MARK: - Theme

/// Design system constants for ClaudeApp.
/// Based on Claude brand colors and modern macOS design patterns.
public enum Theme {
    // MARK: - Colors

    /// Native macOS colors that automatically adapt to light/dark mode and system preferences.
    public enum Colors {
        // MARK: Brand Colors (Claude identity)

        /// Claude brand color #D97757 - used only for icon and key brand elements
        public static let brand = Color(red: 0.851, green: 0.467, blue: 0.341)

        /// Legacy alias for brand color
        public static let primary = brand

        // MARK: System Semantic Colors (native macOS)

        /// Primary label color - adapts to light/dark mode
        public static var label: Color { Color(nsColor: .labelColor) }

        /// Secondary label color - for less prominent text
        public static var secondaryLabel: Color { Color(nsColor: .secondaryLabelColor) }

        /// Tertiary label color - for metadata, timestamps
        public static var tertiaryLabel: Color { Color(nsColor: .tertiaryLabelColor) }

        /// Window background - native macOS window color
        public static var windowBackground: Color { Color(nsColor: .windowBackgroundColor) }

        /// Control background - for controls and inputs
        public static var controlBackground: Color { Color(nsColor: .controlBackgroundColor) }

        /// Separator color - for dividers and borders
        public static var separator: Color { Color(nsColor: .separatorColor) }

        /// Selected content background
        public static var selection: Color { Color(nsColor: .selectedContentBackgroundColor) }

        // MARK: Status Colors (system standard)

        /// Success/positive state - system green
        public static let success = Color.green

        /// Warning state - system yellow/orange
        public static let warning = Color.yellow

        /// Danger/error state - system red
        public static let danger = Color.red

        /// High usage - system orange
        public static let orange = Color.orange

        // MARK: Legacy Aliases (for compatibility)

        public static var secondary: Color { secondaryLabel }
        public static var background: Color { windowBackground }
        public static var surface: Color { controlBackground }
        public static var text: Color { label }
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

    // MARK: - High Contrast Support

    /// Border widths that adjust based on high contrast mode.
    /// Standard: 1pt borders; High Contrast: 2pt borders for increased visibility.
    public enum Borders {
        /// Standard border width (1pt)
        public static let standard: CGFloat = 1

        /// High contrast border width (2pt)
        public static let highContrast: CGFloat = 2

        /// Returns appropriate border width based on contrast setting
        public static func width(isHighContrast: Bool) -> CGFloat {
            isHighContrast ? highContrast : standard
        }
    }
}

// MARK: - High Contrast View Modifier

/// A view modifier that provides high contrast mode detection and styling.
/// When "Increase Contrast" is enabled in System Settings > Accessibility > Display,
/// this modifier applies enhanced borders and visual clarity improvements.
public struct HighContrastBorderModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let cornerRadius: CGFloat
    let standardWidth: CGFloat
    let highContrastWidth: CGFloat

    public init(
        cornerRadius: CGFloat = Theme.CornerRadius.sm,
        standardWidth: CGFloat = 0,
        highContrastWidth: CGFloat = Theme.Borders.highContrast
    ) {
        self.cornerRadius = cornerRadius
        self.standardWidth = standardWidth
        self.highContrastWidth = highContrastWidth
    }

    public func body(content: Content) -> some View {
        let isHighContrast = colorSchemeContrast == .increased
        let borderWidth = isHighContrast ? highContrastWidth : standardWidth

        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.primary.opacity(isHighContrast ? 0.5 : 0), lineWidth: borderWidth)
            )
    }
}

/// A view modifier specifically for progress bar tracks that adds borders in high contrast mode.
public struct ProgressBarHighContrastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public init() {}

    public func body(content: Content) -> some View {
        let isHighContrast = colorSchemeContrast == .increased

        content
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color.primary.opacity(isHighContrast ? 0.4 : 0), lineWidth: isHighContrast ? 1.5 : 0)
            )
    }
}

// MARK: - View Extensions for High Contrast

public extension View {
    /// Adds a high contrast border when "Increase Contrast" is enabled.
    /// - Parameters:
    ///   - cornerRadius: Corner radius for the border
    ///   - standardWidth: Border width in normal mode (default: 0, no border)
    ///   - highContrastWidth: Border width in high contrast mode (default: 2pt)
    func highContrastBorder(
        cornerRadius: CGFloat = Theme.CornerRadius.sm,
        standardWidth: CGFloat = 0,
        highContrastWidth: CGFloat = Theme.Borders.highContrast
    ) -> some View {
        modifier(HighContrastBorderModifier(
            cornerRadius: cornerRadius,
            standardWidth: standardWidth,
            highContrastWidth: highContrastWidth
        ))
    }

    /// Adds high contrast styling specifically for progress bar tracks.
    func progressBarHighContrast() -> some View {
        modifier(ProgressBarHighContrastModifier())
    }

    /// Adds a small shadow for subtle lift.
    func shadowSm() -> some View {
        shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }

    /// Adds a medium shadow for cards and buttons.
    func shadowMd() -> some View {
        shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    /// Adds a large shadow for dropdowns and popovers.
    func shadowLg() -> some View {
        shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

// MARK: - Animation Constants

public extension Animation {
    /// Instant animation for micro-interactions and hovers (100ms)
    static let appInstant = Animation.easeOut(duration: 0.1)

    /// Fast animation for toggles and state changes (200ms)
    static let appFast = Animation.easeOut(duration: 0.2)

    /// Normal animation for progress bars and larger animations (300ms)
    static let appNormal = Animation.easeOut(duration: 0.3)

    /// Spring animation for playful interactions
    static let appSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
