# ClaudeApp Brand Identity

## Brand Positioning

ClaudeApp is a **premium, technical utility** for developers and power users who need precise control over their Claude API usage. The design language communicates:

- **Precision** - Like F1 telemetry or high-end audio equipment
- **Technical Excellence** - Industrial design that respects the user's intelligence
- **Trust** - Professional aesthetic that feels reliable and secure
- **Focus** - Minimal interface that doesn't distract from the data

---

## Design Heritage

ClaudeApp's visual identity draws from three distinct design philosophies:

### 1. KOSMA Business Card Aesthetic
The foundation of our bracket notation and typography system.

**Key Elements:**
- `[BRACKET]` notation for section headers
- Uppercase labels with generous letter-spacing
- Bold, large data values (percentages)
- Deep black backgrounds (`#0F0E12`)
- Orange as the ONLY accent color

### 2. McLaren F1 Playbook
The precision engineering aesthetic and signature orange.

**Key Elements:**
- **Papaya Orange** `#FF7300` - Warmer, more vibrant than standard orange
- **McLaren Timing Curve** - `cubic-bezier(0.19, 1, 0.22, 1)` with 300ms duration
- **Anthracite** `#111314` - Technical dark surface color
- Angular precision in layouts
- Data-driven visualization approach

### 3. Teenage Engineering
The warmth, light typography, and LED indicator aesthetic.

**Key Elements:**
- **Signature Yellow-Orange** `#FFC003` - Warm accent for gradients
- **Light Typography** - 300 weight (Univers Light equivalent)
- **LED Indicators** - Realistic glow with specular highlights
- **Calculator Aesthetic** - Monospaced digits, grid layouts
- **Icon-Based Communication** - Symbols over text labels

---

## Brand Colors

### Primary Orange Spectrum

| Color | Hex | Usage |
|-------|-----|-------|
| McLaren Papaya | `#FF7300` | Primary brand color, CTAs, active states |
| TE Warm Orange | `#FFC003` | Gradients, hover states, warm highlights |
| Deep Orange | `#E65100` | Shadows, pressed states |
| Accent Red | `#FF3300` | Brackets, alerts, critical states |

### Neutral Spectrum

| Color | Hex | Usage |
|-------|-----|-------|
| TE Near-Black | `#0F0E12` | Primary background canvas |
| McLaren Anthracite | `#111314` | Card surfaces, elevated elements |
| TE Off-White | `#F9FAF9` | Primary text, light surfaces |
| Mid Grey | `#A8A8A8` | Secondary text (70% feel) |
| Subtle Grey | `#787878` | Tertiary text (50% feel) |

### Color Rules

1. **Orange is the ONLY accent color** - No blue, no purple, no teal
2. **High contrast always** - Text must be clearly readable
3. **Warm over cool** - Prefer warm greys over cool greys
4. **Glow effects** - Orange elements should have subtle LED-like glow

---

## Typography

### Weight Philosophy

Following Teenage Engineering's use of Univers Light, we use **light weights** (300) for most text, creating an elegant, technical feel.

| Element | Weight | Rationale |
|---------|--------|-----------|
| Section Headers | Light | Clean, unobtrusive |
| Labels | Light | Elegant, readable |
| Body Text | Light | Consistent with labels |
| Data Values | Bold | Maximum impact, instant readability |
| Percentages | Bold | Hero elements stand out |

### Monospace Usage

All technical data uses monospaced fonts:
- Percentages
- Timestamps
- API values
- Bracket notation text

---

## Logo & Icon

### Claude Icon

The Claude coral/terracotta icon (`#D97757`) is used as the brand mark.

| Location | Size | Style |
|----------|------|-------|
| Menu Bar | 16x16 | Color, template mode |
| Popover Header | 20x20 | Color |
| About Section | 48x48 | Color |

### ClaudeApp Wordmark

When the app name appears:
- Font: SF Mono Light
- Case: Uppercase
- Tracking: 2.0
- Format: `[CLAUDE]` or `CLAUDEAPP`

---

## Voice & Tone

### Technical but Approachable
- Use precise language, not jargon
- Explain complex concepts simply
- Respect the user's intelligence

### Confident but Not Arrogant
- State facts directly
- Avoid hedging language
- Don't over-explain

### Helpful but Not Intrusive
- Provide information when needed
- Don't interrupt workflow
- Let the data speak for itself

### Example Copy

**Good:**
- "Usage resets in 2h 34m"
- "87% of daily limit used"
- "[DISPLAY] Settings"

**Avoid:**
- "You're doing great! Only 87% used!"
- "Warning: You might run out soon!"
- "Display Settings Section"

---

## Animation Philosophy

### McLaren-Inspired Motion

All animations use the McLaren timing curve for a precise, engineered feel:

```
cubic-bezier(0.19, 1, 0.22, 1)
```

This creates:
- Quick initial movement
- Smooth deceleration
- Subtle overshoot for polish

### Duration Guidelines

| Interaction | Duration |
|-------------|----------|
| Hover states | 150ms |
| Button press | 200ms |
| Panel transitions | 300ms |
| Major state changes | 400ms |
| LED pulse | 800ms (repeating) |

### Reduced Motion

Always respect `accessibilityReduceMotion`:
- Disable all animations
- Use instant state changes
- Maintain functionality

---

## Component Personality

### Toggles
- Industrial, chunky feel
- Orange when active
- Dark grey when inactive
- Satisfying click (visual feedback)

### Progress Bars
- LED meter aesthetic
- Glowing fill
- Recessed track
- Large percentage readout above

### Buttons
- Minimal chrome
- Icon-first when possible
- Orange accent on hover
- No gradients on buttons

### Cards/Panels
- Flat, solid backgrounds
- No rounded corners (or very subtle)
- Thin dividers between sections
- Generous padding

---

## Don't Do

| Avoid | Why |
|-------|-----|
| Blue accents | Orange is the only accent color |
| Rounded, bubbly shapes | Conflicts with technical aesthetic |
| Gradient backgrounds | Keep surfaces flat and solid |
| Decorative elements | Form follows function |
| Light mode (for now) | Dark-first design |
| Emojis in UI | Maintain technical tone |
| Verbose labels | Keep text minimal |
| Shadows on everything | Use sparingly, for elevation only |

---

## Brand Applications

### Menu Bar
- Claude icon in color
- Percentage in monospaced digits
- Minimal footprint

### Popover
- Full dark canvas background
- Vertical sidebar with controls
- LED-style progress bars
- Bracket section headers

### Settings
- Same dark aesthetic
- KOSMA toggle style
- Tracked uppercase labels

### Notifications
- Brief, factual messages
- Orange accent for alerts
- No emoji or exclamation marks

---

## Future Considerations

### Light Mode
If implemented, should maintain:
- Same orange accent colors
- Light typography weights
- Technical aesthetic
- High contrast

### Widgets
- Same LED indicator style
- Compact version of progress bars
- Dark background preferred

### Apple Watch
- Simplified data display
- LED-style complications
- Orange accent maintained
