# Design System Specification

## Overview

ClaudeApp uses a **hybrid design system** combining three distinct design philosophies:

1. **KOSMA** - Business card aesthetic with bracket notation and bold typography
2. **McLaren F1** - Precision engineering with Papaya orange and chamfered corners
3. **Teenage Engineering** - Calculator/LED aesthetic with light typography and warm colors

The result is a **technical, premium, industrial** interface that feels like high-end audio equipment or F1 telemetry.

---

## Design Philosophy

### Core Principles

| Principle | Description |
|-----------|-------------|
| **Industrial Minimalism** | Stark simplicity, visual restraint, raw functionality |
| **Technical Precision** | Grid-aligned, calculated spacing, engineering aesthetic |
| **Function as Form** | Every element serves a purpose, no decoration for decoration's sake |
| **High Contrast** | Maximum readability, accessibility-first |
| **LED/Calculator Aesthetic** | Digital readouts, glowing indicators, monospaced data |

### Design DNA Sources

| Source | Contribution |
|--------|--------------|
| McLaren F1 Playbook | Papaya orange `#FF7300`, timing curves, angular precision |
| Teenage Engineering | Warm yellow `#FFC003`, light typography, LED indicators |
| KOSMA | Bracket notation `[TEXT]`, uppercase tracking, deep blacks |
| Dieter Rams | "As little design as possible", honest materials |

---

## Brand Colors

### Primary Palette (Hybrid)

| Token | Hex | RGB | Source | Usage |
|-------|-----|-----|--------|-------|
| `brand` | `#FF7300` | 255, 115, 0 | McLaren Papaya | Primary accent, active states, buttons |
| `brandLight` | `#FFC003` | 255, 192, 3 | TE Signature | Gradients, hover states, warm glow |
| `brandDark` | `#E65100` | 230, 81, 0 | Derived | Shadows, depth, pressed states |
| `accentRed` | `#FF3300` | 255, 51, 0 | KOSMA | Brackets, emphasis, alerts |

### Surface Colors (TE-inspired)

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `canvasBlack` | `#0F0E12` | 15, 14, 18 | Primary background (TE near-black) |
| `cardBlack` | `#111314` | 17, 19, 20 | Card surfaces (McLaren Anthracite) |
| `cardSurface` | `#F9FAF9` | 249, 250, 249 | Light mode surfaces (TE cream) |
| `pureWhite` | `#FFFFFF` | 255, 255, 255 | Highlights, specular |

### Text Colors (High Contrast Hierarchy)

| Token | Hex | Opacity Feel | Usage |
|-------|-----|--------------|-------|
| `textOnDark` | `#F9FAF9` | 100% | Primary text on dark backgrounds |
| `textSecondaryOnDark` | `#A8A8A8` | 70% | Secondary labels, descriptions |
| `textTertiaryOnDark` | `#787878` | 50% | Hints, timestamps, disabled |
| `textPrimary` | `#0F0E12` | 100% | Primary text on light backgrounds |
| `textSecondary` | `#484B50` | 70% | McLaren mid-grey |
| `textTertiary` | `#53565A` | 50% | McLaren subtle grey |

### Usage Threshold Colors

| Range | Color | Hex | Description |
|-------|-------|-----|-------------|
| 0-49% | Green | `#22C55E` | Safe, sustainable |
| 50-89% | Yellow | `#EAB308` | Warning, moderate |
| 90-100% | Orange/Red | `#FF7300` | Critical, high usage |

### SwiftUI Implementation

```swift
public enum Colors {
    // Primary
    static let brand = Color(red: 255/255, green: 115/255, blue: 0/255)       // #FF7300
    static let brandLight = Color(red: 255/255, green: 192/255, blue: 3/255)  // #FFC003
    static let brandDark = Color(red: 230/255, green: 81/255, blue: 0/255)    // #E65100
    static let accentRed = Color(red: 255/255, green: 51/255, blue: 0/255)    // #FF3300

    // Surfaces
    static let canvasBlack = Color(red: 15/255, green: 14/255, blue: 18/255)  // #0F0E12
    static let cardBlack = Color(red: 17/255, green: 19/255, blue: 20/255)    // #111314
    static let cardSurface = Color(red: 249/255, green: 250/255, blue: 249/255) // #F9FAF9

    // Text
    static let textOnDark = Color(red: 249/255, green: 250/255, blue: 249/255)
    static let textSecondaryOnDark = Color(red: 168/255, green: 168/255, blue: 168/255)
    static let textTertiaryOnDark = Color(red: 120/255, green: 120/255, blue: 120/255)
}
```

---

## Typography

### Font Philosophy (TE-inspired Light Weight)

Teenage Engineering uses **Univers Light (300 weight)** throughout their products. We translate this to **SF Pro Light** for system consistency while maintaining the ultra-clean, technical aesthetic.

### Type Scale

| Token | Size | Weight | Design | Usage |
|-------|------|--------|--------|-------|
| `headline` | 14pt | Medium | Default | Section titles |
| `sectionHeader` | 10pt | Medium | Default | KOSMA bracket headers |
| `dataValue` | 24-32pt | Bold | Monospaced | Large percentage display |
| `dataUnit` | 12pt | Light | Monospaced | % suffix, units |
| `bracketText` | 11pt | Light | Monospaced | Technical labels |
| `bracketSmall` | 10pt | Light | Monospaced | Compact labels |
| `caption` | 9pt | Light | Monospaced | Timestamps, hints |
| `body` | 12pt | Light | Default | General text |
| `label` | 11pt | Light | Default | Form labels |

### Letter Spacing (Tracking)

| Element | Tracking | Usage |
|---------|----------|-------|
| Section headers | 2.0 | KOSMA uppercase headers |
| Labels | 1.2-1.5 | Settings labels, descriptions |
| Data values | 0 | Percentages, numbers |
| Brackets | 0 | Tight bracket notation |

### SwiftUI Implementation

```swift
public enum Typography {
    // Headlines
    static let headline = Font.system(size: 14, weight: .medium)
    static let sectionHeader = Font.system(size: 10, weight: .medium)

    // Data Display (Calculator style)
    static let dataValue = Font.system(size: 24, weight: .bold, design: .monospaced).monospacedDigit()
    static let dataUnit = Font.system(size: 12, weight: .light, design: .monospaced).monospacedDigit()

    // Technical/Bracket
    static let bracketText = Font.system(size: 11, weight: .light, design: .monospaced)
    static let bracketSmall = Font.system(size: 10, weight: .light, design: .monospaced)
    static let caption = Font.system(size: 9, weight: .light, design: .monospaced)

    // Body
    static let body = Font.system(size: 12, weight: .light)
    static let label = Font.system(size: 11, weight: .light)
}
```

---

## Spacing

### Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4px | Tight spacing, inline elements |
| `sm` | 8px | Component padding, small gaps |
| `md` | 12px | Standard gaps, form fields |
| `lg` | 16px | Section padding |
| `xl` | 24px | Major section breaks |
| `xxl` | 32px | KOSMA section gaps |

### SwiftUI Implementation

```swift
public enum Space {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}
```

---

## Animation

### McLaren Timing Curve

McLaren F1 Playbook uses `cubic-bezier(0.19, 1, 0.22, 1)` - a smooth ease-out with subtle overshoot that feels precise and engineered.

### Duration Scale

| Token | Duration | Usage |
|-------|----------|-------|
| `instant` | 150ms | Micro-interactions, hovers |
| `quick` | 200ms | Buttons, toggles |
| `standard` | 300ms | McLaren standard - most animations |
| `major` | 400ms | Major state transitions |
| `glow` | 1500ms | LED pulse, breathing effects |

### SwiftUI Implementation

```swift
extension Animation {
    // McLaren timing curve: cubic-bezier(0.19, 1, 0.22, 1)
    static let quick = Animation.timingCurve(0.19, 1, 0.22, 1, duration: 0.2)
    static let kosma = Animation.timingCurve(0.19, 1, 0.22, 1, duration: 0.3)
    static let gentle = Animation.timingCurve(0.19, 1, 0.22, 1, duration: 0.3)
    static let kosmaMajor = Animation.timingCurve(0.19, 1, 0.22, 1, duration: 0.4)
    static let kosmaGlow = Animation.timingCurve(0.19, 1, 0.22, 1, duration: 1.5)

    // LED pulse for indicators
    static let ledPulse = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
}
```

---

## Components

### Bracket Notation (KOSMA)

The signature KOSMA element - tight bracket notation for section headers.

```
[DISPLAY]  [SETTINGS]  [ABOUT]
```

**Specifications:**
- Brackets: `accentRed` at 80% opacity
- Text: `brand` at 80% opacity
- Font: 10pt Light Monospaced
- Tracking: 2.0
- No internal spaces: `[TEXT]` not `[ TEXT ]`

### LED Status Indicator (TE-style)

Realistic LED indicators like those on Teenage Engineering products.

**Specifications:**
- Size: 6px diameter
- Active: Radial gradient with specular highlight and outer glow
- Inactive: Dark grey recessed look
- Glow radius: 2.5x LED size
- Specular: Small white dot offset top-left

```swift
struct KOSMAStatusKnob: View {
    var isActive: Bool
    var activeColor: Color = Theme.Colors.brand
    var size: CGFloat = 6

    var body: some View {
        ZStack {
            // Outer glow
            if isActive {
                Circle()
                    .fill(activeColor.opacity(0.3))
                    .frame(width: size * 2.5, height: size * 2.5)
                    .blur(radius: 4)
            }

            // LED body with gradient
            Circle()
                .fill(RadialGradient(...))
                .frame(width: size, height: size)

            // Specular highlight
            if isActive {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(x: -size * 0.15, y: -size * 0.15)
            }
        }
    }
}
```

### Progress Bar (LED Meter Aesthetic)

Calculator/VU meter style progress bars with LED glow.

**Specifications:**
- Height: 4px
- Track: Recessed dark (`#141418`) with 1px black stroke
- Fill: Linear gradient `brand` to `brandLight`
- Glow: Double shadow (6px + 12px radius)
- Numbers: 32pt bold monospaced with LED glow shadow

### Toggle Switch (KOSMA)

Custom toggle with industrial feel.

**Specifications:**
- Track: 36px × 18px
- Off: Dark grey (`#2A2A2A`)
- On: `brand` orange
- Thumb off: Dark grey (`#4A4A4A`)
- Thumb on: Off-white (`#F5F5F0`)
- Animation: 200ms McLaren curve

---

## Layout Patterns

### Vertical Sidebar

Main UI uses a vertical control sidebar on the right:
- Width: 44px
- Contains: Ghosted `[CLAUDE]` text (rotated), icon strip
- Background: Slightly lighter than canvas

### Section Gaps

- Between major sections: 32px (KOSMA spec)
- Internal padding: 16px
- Label-to-control gap: 12px

### Dividers

- Color: `brand` at 10% opacity
- Height: 1px
- Barely visible, just enough to separate sections

---

## Accessibility

### Color Contrast

All color combinations meet WCAG AA standards:

| Combination | Ratio | Standard |
|-------------|-------|----------|
| `textOnDark` on `canvasBlack` | 16.8:1 | AAA |
| `brand` on `canvasBlack` | 6.2:1 | AA |
| `textTertiaryOnDark` on `canvasBlack` | 4.6:1 | AA |

### Reduced Motion

Respect `@Environment(\.accessibilityReduceMotion)`:
- Disable all animations when enabled
- LED indicators use static state instead of pulse
- Progress bar updates without animation

### Focus Indicators

- All interactive elements have visible focus rings
- Focus color: `brand` with 2px offset ring
- Keyboard navigation supported throughout

---

## Design References

### McLaren F1 Playbook
- URL: https://www.mclaren.com/racing/formula-1/playbook/
- Key elements: Papaya orange, chamfered corners, precision animations

### Teenage Engineering EP-133
- URL: https://teenage.engineering/products/ep-133
- Key elements: Warm orange `#FFC003`, light typography, LED indicators, calculator aesthetic

### KOSMA Business Card
- Internal spec
- Key elements: Bracket notation, uppercase tracking, deep blacks, bold data

---

## Implementation Files

| File | Purpose |
|------|---------|
| `Packages/UI/Sources/UI/Theme.swift` | Core design tokens, colors, typography, animations |
| `Packages/UI/Sources/UI/UsageProgressBar.swift` | LED-style progress bars |
| `Packages/UI/Sources/UI/SettingsComponents.swift` | Toggle, slider, picker, section headers |
| `Packages/UI/Sources/UI/BrandedStateViews.swift` | Loading, error, empty states |
| `App/ClaudeApp.swift` | Main app layout with vertical sidebar |
