import SwiftUI

// MARK: - Section Header

/// KOSMA-style section header with bracket notation
/// Format: [SECTION TITLE] ─────────────
public struct SectionHeader: View {
    let title: String
    var showDivider: Bool

    public init(title: String, showDivider: Bool = true) {
        self.title = title
        self.showDivider = showDivider
    }

    public var body: some View {
        HStack(spacing: 8) {
            // KOSMA tight bracket notation [DISPLAY]
            HStack(spacing: 0) {
                Text("[")
                    .foregroundStyle(Theme.Colors.accentRed)
                Text(title.uppercased())
                    .foregroundStyle(Theme.Colors.brand.opacity(0.7))
                Text("]")
                    .foregroundStyle(Theme.Colors.accentRed)
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .tracking(1.5)

            if showDivider {
                // KOSMA divider - barely visible
                Rectangle()
                    .fill(Color(red: 26/255, green: 26/255, blue: 26/255))  // #1A1A1A
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Collapsible Section

/// KOSMA-style collapsible section with bracket header
public struct CollapsibleSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: Content

    public init(title: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // KOSMA-style header button
            Button {
                withAnimation(.kosma) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    // KOSMA tight bracket notation [DISPLAY]
                    HStack(spacing: 0) {
                        Text("[")
                            .foregroundStyle(Theme.Colors.accentRed)
                        Text(title.uppercased())
                            .foregroundStyle(Theme.Colors.brand.opacity(0.7))
                        Text("]")
                            .foregroundStyle(Theme.Colors.accentRed)
                    }
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(1.5)

                    // Technical divider - barely visible
                    Rectangle()
                        .fill(Color(red: 26/255, green: 26/255, blue: 26/255))  // #1A1A1A
                        .frame(height: 1)

                    // KOSMA-style chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.Colors.brand)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.kosma, value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: Theme.Space.md) {
                    content
                }
                .padding(.top, Theme.Space.md)
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Toggle

/// KOSMA-style settings toggle
public struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool
    var subtitle: String?
    var showSaveIndicator: Bool

    public init(title: String, isOn: Binding<Bool>, subtitle: String? = nil, showSaveIndicator: Bool = false) {
        self.title = title
        self._isOn = isOn
        self.subtitle = subtitle
        self.showSaveIndicator = showSaveIndicator
    }

    public var body: some View {
        HStack(alignment: subtitle != nil ? .top : .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textOnDark)
                    .tracking(0.5)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(red: 102/255, green: 102/255, blue: 102/255))  // #666666
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: Theme.Space.md)

            // Custom KOSMA toggle
            Toggle("", isOn: $isOn)
                .toggleStyle(KOSMAToggleStyle())
                .labelsHidden()
        }
    }
}

// MARK: - Picker Row

/// KOSMA-style picker row
public struct SettingsPickerRow<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    let content: Content

    public init(title: String, selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._selection = selection
        self.content = content()
    }

    public var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.Colors.textOnDark)
                .tracking(0.5)

            Spacer()

            Picker("", selection: $selection) { content }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
                .tint(Theme.Colors.brand)
                .accentColor(Theme.Colors.brand)
        }
    }
}

// MARK: - Slider Row

/// KOSMA-style slider with value display
public struct SettingsSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueFormatter: (Double) -> String
    var minLabel: String?
    var maxLabel: String?

    public init(
        title: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        minLabel: String? = nil,
        maxLabel: String? = nil,
        valueFormatter: @escaping (Double) -> String
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.minLabel = minLabel
        self.maxLabel = maxLabel
        self.valueFormatter = valueFormatter
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textOnDark)
                    .tracking(0.5)

                Spacer()

                // KOSMA tight bracket value
                HStack(spacing: 0) {
                    Text("[")
                        .foregroundStyle(Theme.Colors.accentRed)
                    Text(valueFormatter(value))
                        .foregroundStyle(Theme.Colors.brand)
                    Text("]")
                        .foregroundStyle(Theme.Colors.accentRed)
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
            }

            Slider(value: $value, in: range, step: step)
                .controlSize(.small)
                .tint(Theme.Colors.brand)
                .accentColor(Theme.Colors.brand)

            if minLabel != nil || maxLabel != nil {
                HStack {
                    Text(minLabel ?? "")
                    Spacer()
                    Text(maxLabel ?? "")
                }
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Theme.Colors.textTertiaryOnDark)
            }
        }
    }
}

// MARK: - Divider

/// KOSMA-style divider
public struct SettingsDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Theme.Colors.separator)
            .frame(height: 1)
    }
}

// MARK: - Save Indicator

/// Animated checkmark feedback on settings save
public struct SettingsSaveIndicator: View {
    @Binding var isVisible: Bool

    public init(isVisible: Binding<Bool>) {
        self._isVisible = isVisible
    }

    public var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Theme.Colors.brand)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.5)
            .animation(.gentle, value: isVisible)
    }
}

// MARK: - Legacy Components

public struct SettingsGroup<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) { content }
    }
}

public struct SettingsRow<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View { content }
}
