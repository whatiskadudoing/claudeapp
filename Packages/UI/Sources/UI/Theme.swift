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

        /// Warning yellow #EAB308
        public static let warning = Color(red: 0.918, green: 0.702, blue: 0.031)

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
}
