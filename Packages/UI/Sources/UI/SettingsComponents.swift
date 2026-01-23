import SwiftUI

// MARK: - Section Header

/// Consistent header style for settings sections.
public struct SectionHeader: View {
    let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(Theme.Typography.sectionHeader)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - Settings Toggle

/// A toggle with consistent styling for settings.
public struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool
    var subtitle: String?

    public init(title: String, isOn: Binding<Bool>, subtitle: String? = nil) {
        self.title = title
        self._isOn = isOn
        self.subtitle = subtitle
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.body)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.label)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }
}
