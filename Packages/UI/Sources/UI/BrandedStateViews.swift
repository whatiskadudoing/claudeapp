import SwiftUI

// MARK: - Loading

/// KOSMA-style loading state
public struct BrandedLoadingView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 14) {
            // KOSMA-style loading spinner
            ProgressView()
                .controlSize(.regular)
                .tint(Theme.Colors.brand)

            // KOSMA bracket text
            KOSMABracketText(
                "Loading",
                bracketColor: Theme.Colors.accentRed,
                textColor: Theme.Colors.textSecondary,
                font: Theme.Typography.bracketSmall
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.KOSMASpace.sectionGap)
    }
}

// MARK: - Error

/// KOSMA-style error state with retry action
public struct BrandedErrorView: View {
    public let title: String
    public let message: String
    public let retryAction: () -> Void

    public init(title: String, message: String, retryAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: Theme.Space.lg) {
            // KOSMA error icon with glow
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(Theme.Colors.warning)
                .kosmaGlow(color: Theme.Colors.warning, radius: 10)

            VStack(spacing: Theme.Space.sm) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primary)

                // KOSMA bracket message
                KOSMABracketText(
                    message,
                    bracketColor: Theme.Colors.accentRed,
                    textColor: Theme.Colors.textSecondary,
                    font: Theme.Typography.caption
                )
                .multilineTextAlignment(.center)
            }

            Button("Try Again", action: retryAction)
                .buttonStyle(KOSMAPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.KOSMASpace.sectionGap)
    }
}

// MARK: - Empty

/// KOSMA-style empty state with refresh action
public struct BrandedEmptyStateView: View {
    public let refreshAction: () -> Void

    public init(refreshAction: @escaping () -> Void) {
        self.refreshAction = refreshAction
    }

    public var body: some View {
        VStack(spacing: Theme.Space.lg) {
            // KOSMA icon with subtle glow
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 28))
                .foregroundStyle(Theme.Colors.textTertiary)

            KOSMABracketText(
                "No data available",
                bracketColor: Theme.Colors.accentRed,
                textColor: Theme.Colors.textSecondary,
                font: Theme.Typography.bracketSmall
            )

            Button("Refresh", action: refreshAction)
                .buttonStyle(KOSMAPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.KOSMASpace.sectionGap)
    }
}
