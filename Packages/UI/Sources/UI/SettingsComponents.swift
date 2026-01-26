import SwiftUI

// MARK: - Section Header

/// Clean section header - just bold text.
public struct SectionHeader: View {
    let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - Settings Toggle

/// A toggle row with label on left, switch on right.
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 16)
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
    }
}

// MARK: - Settings Picker Row

/// A picker row with label on left, dropdown on right.
public struct SettingsPickerRow<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    let content: Content

    public init(
        title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._selection = selection
        self.content = content()
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
            Spacer()
            Picker("", selection: $selection) {
                content
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize()
        }
    }
}

// MARK: - Settings Slider Row

/// A slider with label and current value display.
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13))
                Spacer()
                Text(valueFormatter(value))
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: range, step: step)
                .controlSize(.small)

            if minLabel != nil || maxLabel != nil {
                HStack {
                    if let minLabel {
                        Text(minLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    if let maxLabel {
                        Text(maxLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Backwards Compatibility

/// Backwards compatibility aliases
public struct SettingsGroup<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
    }
}

public struct SettingsRow<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    public var body: some View {
        content
    }
}

public struct SettingsDivider: View {
    public init() {}
    public var body: some View {
        EmptyView()
    }
}
