import SwiftUI

// MARK: - Theme

/// ClaudeApp KOSMA Design System
/// Inspired by KOSMA Business Card: Technical precision meets bold orange accents.
/// Features: Vibrant #FF4D00 orange, off-white card surfaces, bracket notation,
/// geometric typography, and distinctive visual artifacts.
public enum Theme {

    // MARK: - Colors

    public enum Colors {
        // === KOSMA PRIMARY PALETTE (EXACT VALUES) ===

        /// Primary brand orange - KOSMA signature (#FF4D00)
        public static let brand = Color(red: 255/255, green: 77/255, blue: 0/255)

        /// Light orange for gradients, hover (#FF6B35)
        public static let brandLight = Color(red: 255/255, green: 107/255, blue: 53/255)

        /// Dark orange for shadows, depth (#E04400)
        public static let brandDark = Color(red: 224/255, green: 68/255, blue: 0/255)

        /// Accent red for brackets and emphasis (#FF3300)
        public static let accentRed = Color(red: 255/255, green: 51/255, blue: 0/255)

        // === KOSMA SURFACE COLORS (EXACT VALUES) ===

        /// Off-white card surface (#F5F5F0)
        public static let cardSurface = Color(red: 245/255, green: 245/255, blue: 240/255)

        /// Pure white for highlights, specular (#FFFFFF)
        public static let pureWhite = Color.white

        /// Deep black canvas background (#0A0A0A)
        public static let canvasBlack = Color(red: 10/255, green: 10/255, blue: 10/255)

        /// Card black alternative (#111111)
        public static let cardBlack = Color(red: 17/255, green: 17/255, blue: 17/255)

        // === KOSMA TEXT COLORS (for dark backgrounds) ===

        /// Text primary on dark - bright white
        public static let textOnDark = Color(red: 245/255, green: 245/255, blue: 240/255)

        /// Text secondary on dark - muted
        public static let textSecondaryOnDark = Color(red: 160/255, green: 160/255, blue: 155/255)

        /// Text tertiary on dark - subtle
        public static let textTertiaryOnDark = Color(red: 100/255, green: 100/255, blue: 95/255)

        /// Text primary on light - dark (#1A1A1A)
        public static let textPrimary = Color(red: 26/255, green: 26/255, blue: 26/255)

        /// Text secondary on light (#666666)
        public static let textSecondary = Color(red: 102/255, green: 102/255, blue: 102/255)

        /// Text tertiary on light (#999999)
        public static let textTertiary = Color(red: 153/255, green: 153/255, blue: 153/255)

        // === STATUS COLORS (ALL KOSMA ORANGE) ===
        // KOSMA design uses ONLY orange palette - no green, no blue

        /// Safe state - uses KOSMA brand orange (lighter)
        public static let safe = brandLight

        /// Warning - uses KOSMA brand orange
        public static let warning = brand

        /// Critical - deeper KOSMA orange
        public static let critical = brandDark

        // === ADAPTIVE SYSTEM COLORS ===

        public static var primary: Color { Color(nsColor: .labelColor) }
        public static var secondary: Color { Color(nsColor: .secondaryLabelColor) }
        public static var tertiary: Color { Color(nsColor: .tertiaryLabelColor) }
        public static var quaternary: Color { Color(nsColor: .quaternaryLabelColor) }

        /// KOSMA dark background (uses canvasBlack in dark mode)
        public static var background: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                    ? NSColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1.0)  // #0A0A0A
                    : NSColor(red: 245/255, green: 245/255, blue: 240/255, alpha: 1.0)  // #F5F5F0
            })
        }

        // === BORDERS ===

        public static var separator: Color { Color.white.opacity(0.08) }
        public static var borderSubtle: Color { Color.white.opacity(0.06) }
        public static var borderMedium: Color { Color.white.opacity(0.12) }

        /// Status color for usage percentage - ALL KOSMA ORANGE
        public static func status(for value: Double) -> Color {
            switch value {
            case ..<50: return brand       // Low usage: brand orange
            case ..<80: return brand       // Medium: brand orange
            default: return brandDark      // High: darker orange for emphasis
            }
        }

        // Aliases for compatibility
        public static var label: Color { primary }
        public static var secondaryLabel: Color { secondary }
        public static var tertiaryLabel: Color { tertiary }
        public static var quaternaryLabel: Color { quaternary }
        public static var windowBackground: Color { background }
        public static let success = safe
        public static let danger = critical
        public static let orange = warning
        public static let statusSafe = safe
        public static let statusWarning = warning
        public static let statusCritical = critical
        public static func forUsage(_ value: Double) -> Color { status(for: value) }
    }

    // MARK: - Spacing

    public enum Space {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    /// KOSMA-specific spacing values
    public enum KOSMASpace {
        /// Card internal padding (KOSMA: generous margins)
        public static let cardPadding: CGFloat = 16

        /// Section gap (KOSMA: clear separation)
        public static let sectionGap: CGFloat = 20

        /// Element gap within sections
        public static let elementGap: CGFloat = 12

        /// Header/footer height
        public static let headerHeight: CGFloat = 44
    }

    public enum Spacing {
        public static let xs: CGFloat = Space.xs
        public static let sm: CGFloat = Space.sm
        public static let md: CGFloat = Space.md
        public static let lg: CGFloat = Space.lg
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = Space.xl
    }

    // MARK: - Radius

    public enum Radius {
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 6
    }

    public enum CornerRadius {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 6
        public static let md: CGFloat = 8
        public static let lg: CGFloat = 12
        public static let xl: CGFloat = 16  // KOSMA card radius
        public static let full: CGFloat = 9999  // Pill shape
    }

    // MARK: - Typography

    public enum Text {
        public static let title = Font.system(size: 13, weight: .medium)
        public static let body = Font.system(size: 12)
        public static let label = Font.system(size: 11)
        public static let small = Font.system(size: 10)
        public static let tiny = Font.system(size: 9)
    }

    public enum Typography {
        // === KOSMA HEADLINE TYPOGRAPHY ===

        /// Large headlines - KOSMA bold style
        public static let headline = Font.system(size: 14, weight: .bold)

        /// Section headers - KOSMA uppercase tracked
        public static let sectionHeader = Font.system(size: 10, weight: .semibold)

        // === KOSMA DATA TYPOGRAPHY ===

        /// Large percentage display - KOSMA data emphasis
        public static let dataValue = Font.system(size: 20, weight: .bold).monospacedDigit()

        /// Percentage suffix (smaller)
        public static let dataUnit = Font.system(size: 14, weight: .semibold).monospacedDigit()

        /// Menu bar percentage
        public static let menuBar = Font.system(size: 12, weight: .semibold).monospacedDigit()

        // === KOSMA BRACKET/TECHNICAL TYPOGRAPHY ===

        /// Bracket metadata text - KOSMA bracket style
        public static let bracketText = Font.system(size: 11, weight: .medium, design: .monospaced)

        /// Small bracket text
        public static let bracketSmall = Font.system(size: 10, weight: .medium, design: .monospaced)

        /// Caption/timestamp
        public static let caption = Font.system(size: 9, weight: .regular, design: .monospaced)

        // === STANDARD TYPOGRAPHY ===

        public static let title = Text.title
        public static let body = Text.body
        public static let label = Text.label
        public static let metadata = Text.small
        public static let tiny = Text.tiny

        public static let percentage = Font.system(size: 13, weight: .medium).monospacedDigit()
        public static let percentageLarge = Font.system(size: 15, weight: .semibold).monospacedDigit()
        public static let badge = Font.system(size: 9, weight: .semibold)
        public static let iconSmall = Font.system(size: 10)
        public static let iconMedium = Font.system(size: 12)
        public static let iconLarge = Font.system(size: 16)
        public static let technicalLabel = Font.system(size: 10, weight: .medium, design: .monospaced)
    }

    // MARK: - Progress Bar

    public enum ProgressBar {
        public static let height: CGFloat = 3  // KOSMA: thin, refined
        public static let cornerRadius: CGFloat = 1.5
    }

    public enum Borders {
        public static let standard: CGFloat = 1
        public static let highContrast: CGFloat = 2
        public static func width(isHighContrast: Bool) -> CGFloat {
            isHighContrast ? highContrast : standard
        }
    }
}

// MARK: - Animation

public extension Animation {
    // === KOSMA TIMING CURVES ===
    // KOSMA uses cubic-bezier(0.4, 0, 0.2, 1) for heavy, weighted feel

    /// KOSMA quick interaction (buttons, toggles) - weighted feel
    static let quick = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.2)

    /// KOSMA gentle transition (panels, sections) - momentum feel
    static let gentle = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.4)

    /// KOSMA signature animation - heavy with weight and momentum
    static let kosma = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.5)

    /// KOSMA major state transition (dramatic, cinematic)
    static let kosmaMajor = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.8)

    /// KOSMA glow pulse - slow, breathing rhythm
    static let kosmaGlow = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 2.0)

    // Legacy aliases
    static let appInstant = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.1)
    static let appFast = quick
    static let appNormal = gentle
    static let appSpring = Animation.spring(response: 0.4, dampingFraction: 0.75)  // Heavier spring
}

// MARK: - KOSMA Button Styles

/// KOSMA Primary Button - Bold orange with gradient and glow
public struct KOSMAPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.body)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.brand, Theme.Colors.brandLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(
                color: Theme.Colors.brand.opacity(configuration.isPressed ? 0.2 : 0.4),
                radius: configuration.isPressed ? 2 : 6,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.quick, value: configuration.isPressed)
    }
}

/// KOSMA Ghost Button - Subtle with bracket accents
public struct KOSMAGhostButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            Text("[")
                .foregroundStyle(Theme.Colors.accentRed.opacity(0.6))

            configuration.label
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("]")
                .foregroundStyle(Theme.Colors.accentRed.opacity(0.6))
        }
        .font(Theme.Typography.bracketSmall)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(configuration.isPressed ? 0.08 : 0.03))
        )
        .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - KOSMA Toggle Style

/// KOSMA-style toggle - orange when on, dark when off
/// Off-state thumb is dark gray, on-state thumb is off-white
public struct KOSMAToggleStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            // Custom toggle track
            ZStack {
                // Track background
                Capsule()
                    .fill(configuration.isOn ? Theme.Colors.brand : Color(red: 42/255, green: 42/255, blue: 42/255))
                    .frame(width: 40, height: 22)
                    .overlay(
                        Capsule()
                            .stroke(configuration.isOn ? Theme.Colors.brandLight.opacity(0.5) : Color(red: 58/255, green: 58/255, blue: 58/255), lineWidth: 1)
                    )

                // Thumb - dark gray when off, off-white when on
                Circle()
                    .fill(configuration.isOn ? Theme.Colors.cardSurface : Color(red: 85/255, green: 85/255, blue: 85/255))
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(x: configuration.isOn ? 9 : -9)
            }
            .animation(.kosma, value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

/// Quiet text button
public struct QuietButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Text.label)
            .foregroundStyle(Theme.Colors.tertiary)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

/// Subtle background button
public struct SubtleButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Text.label)
            .foregroundStyle(Theme.Colors.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(configuration.isPressed ? 0.06 : 0.03))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
    }
}

/// Hover highlight for icon buttons
public struct HoverHighlightButtonStyle: ButtonStyle {
    @State private var hovering = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.08 : (hovering ? 0.04 : 0)))
            )
            .onHover { hovering = $0 }
    }
}

public struct HoverScaleButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

// MARK: - Haptics

public enum HapticFeedback {
    public static func success() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
    public static func warning() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
}

// MARK: - KOSMA Shadow Extensions

public extension View {
    /// KOSMA card shadow (soft, diffuse)
    func kosmaShadowCard() -> some View {
        self.shadow(color: .black.opacity(0.25), radius: 20, y: 10)
    }

    /// KOSMA elevated shadow (dramatic)
    func kosmaShadowElevated() -> some View {
        self.shadow(color: .black.opacity(0.4), radius: 30, y: 15)
    }

    /// KOSMA subtle shadow for inline elements
    func kosmaShadowSubtle() -> some View {
        self.shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }

    /// KOSMA glow effect (colored shadow)
    func kosmaGlow(color: Color = Theme.Colors.brand, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 2)
    }

    // Legacy shadows
    func shadowSm() -> some View { shadow(color: .black.opacity(0.04), radius: 2, y: 1) }
    func shadowMd() -> some View { shadow(color: .black.opacity(0.06), radius: 4, y: 2) }
    func shadowLg() -> some View { shadow(color: .black.opacity(0.08), radius: 8, y: 4) }

    func shimmer() -> some View { self }
    func card(padding: CGFloat = 12, cornerRadius: CGFloat = 6) -> some View { self }
    func elevatedCard(padding: CGFloat = 12, cornerRadius: CGFloat = 6) -> some View { self }
    func highContrastBorder(cornerRadius: CGFloat = 4, standardWidth: CGFloat = 0, highContrastWidth: CGFloat = 2) -> some View { self }
    func progressBarHighContrast() -> some View { self }
}

// MARK: - KOSMA Tracking Extensions

public extension View {
    /// KOSMA section header tracking (0.15em equivalent)
    func kosmaHeaderTracking() -> some View {
        self.tracking(1.5)
    }

    /// KOSMA bracket tracking (0.05em equivalent)
    func kosmaBracketTracking() -> some View {
        self.tracking(0.5)
    }
}

// MARK: - KOSMA Visual Artifacts

/// KOSMA corner accent - subtle L-shaped brand element
public struct KOSMACornerAccent: View {
    var size: CGFloat
    var thickness: CGFloat
    var color: Color

    public init(size: CGFloat = 12, thickness: CGFloat = 2, color: Color = Theme.Colors.brand) {
        self.size = size
        self.thickness = thickness
        self.color = color
    }

    public var body: some View {
        Canvas { context, _ in
            // Vertical line
            var vPath = Path()
            vPath.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: thickness, height: size),
                cornerSize: CGSize(width: thickness / 2, height: thickness / 2)
            )
            context.fill(vPath, with: .color(color))

            // Horizontal line
            var hPath = Path()
            hPath.addRoundedRect(
                in: CGRect(x: 0, y: size - thickness, width: size, height: thickness),
                cornerSize: CGSize(width: thickness / 2, height: thickness / 2)
            )
            context.fill(hPath, with: .color(color))
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

/// KOSMA status indicator knobs - like audio equipment
/// All use KOSMA brand orange when active for visual consistency
public struct StatusIndicators: View {
    var isConnected: Bool
    var isSynced: Bool
    var notificationsEnabled: Bool

    public init(isConnected: Bool = true, isSynced: Bool = true, notificationsEnabled: Bool = true) {
        self.isConnected = isConnected
        self.isSynced = isSynced
        self.notificationsEnabled = notificationsEnabled
    }

    public var body: some View {
        HStack(spacing: 5) {
            // All knobs use KOSMA brand orange for consistent visual identity
            KOSMAStatusKnob(isActive: isConnected, activeColor: Theme.Colors.brand)
            KOSMAStatusKnob(isActive: isSynced, activeColor: Theme.Colors.brand)
            KOSMAStatusKnob(isActive: notificationsEnabled, activeColor: Theme.Colors.brand)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts: [String] = []
        parts.append(isConnected ? "Connected" : "Disconnected")
        parts.append(isSynced ? "Synced" : "Not synced")
        parts.append(notificationsEnabled ? "Notifications on" : "Notifications off")
        return parts.joined(separator: ", ")
    }
}

/// KOSMA-style status knob with glow - like audio equipment indicators
public struct KOSMAStatusKnob: View {
    var isActive: Bool
    var activeColor: Color
    var size: CGFloat = 8

    public init(isActive: Bool, activeColor: Color = Theme.Colors.brand, size: CGFloat = 8) {
        self.isActive = isActive
        self.activeColor = activeColor
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(isActive ? activeColor : Color.clear)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(
                        isActive ? activeColor.opacity(0.6) : Theme.Colors.textTertiaryOnDark.opacity(0.3),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isActive ? activeColor.opacity(0.7) : .clear,
                radius: 6,
                x: 0,
                y: 0
            )
    }
}

/// Legacy status dot (for compatibility)
public struct StatusDotIndicator: View {
    var isActive: Bool
    var activeColor: Color

    public init(isActive: Bool, activeColor: Color = Theme.Colors.brand) {
        self.isActive = isActive
        self.activeColor = activeColor
    }

    public var body: some View {
        KOSMAStatusKnob(isActive: isActive, activeColor: activeColor, size: 6)
    }
}

/// Legacy corner accent (for compatibility)
public struct CornerAccent: View {
    var size: CGFloat
    var color: Color

    public init(size: CGFloat = 40, color: Color = Theme.Colors.brand) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        KOSMACornerAccent(size: size, color: color)
    }
}

/// Technical grid background pattern
public struct TechnicalGridBackground: View {
    var gridSize: CGFloat = 20
    var opacity: Double = 0.02

    public init(gridSize: CGFloat = 20, opacity: Double = 0.02) {
        self.gridSize = gridSize
        self.opacity = opacity
    }

    public var body: some View {
        Canvas { context, size in
            let lineColor = Color.primary.opacity(opacity)

            for x in stride(from: 0, to: size.width, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }

            for y in stride(from: 0, to: size.height, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
        }
    }
}

/// Vertical branding text element
public struct VerticalBrandingText: View {
    var text: String = "CLAUDE"
    var color: Color = Theme.Colors.quaternary

    public init(text: String = "CLAUDE", color: Color = Theme.Colors.quaternary) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .tracking(2)
            .foregroundStyle(color)
            .rotationEffect(.degrees(-90))
            .fixedSize()
    }
}

// MARK: - KOSMA Bracket Text Helper

/// Creates KOSMA-style bracketed text (tight brackets, no space)
public struct KOSMABracketText: View {
    let text: String
    var bracketColor: Color = Theme.Colors.accentRed
    var textColor: Color = Theme.Colors.textTertiaryOnDark
    var font: Font = .system(size: 10, weight: .regular, design: .monospaced)

    public init(_ text: String, bracketColor: Color = Theme.Colors.accentRed, textColor: Color = Theme.Colors.textTertiaryOnDark, font: Font = .system(size: 10, weight: .regular, design: .monospaced)) {
        self.text = text
        self.bracketColor = bracketColor
        self.textColor = textColor
        self.font = font
    }

    public var body: some View {
        HStack(spacing: 0) {
            Text("[")
                .foregroundStyle(bracketColor)
            Text(text)
                .foregroundStyle(textColor)
            Text("]")
                .foregroundStyle(bracketColor)
        }
        .font(font)
    }
}
