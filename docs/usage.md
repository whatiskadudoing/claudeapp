# Usage Guide

## Menu Bar Display

ClaudeApp lives in your macOS menu bar, showing your Claude Code usage at a glance:

```
[sparkle] 86%
```

- **Icon**: Claude sparkle icon
- **Percentage**: Your current usage (configurable source in Settings)

### What the Percentage Shows

By default, the menu bar shows your **highest usage** across all windows. You can change this in Settings > Display > Percentage Source to show:

- Highest % (default) - The maximum across all windows
- Current Session - 5-hour rolling window only
- Weekly (All Models) - 7-day total usage
- Weekly (Opus) - Opus model quota only
- Weekly (Sonnet) - Sonnet model quota only

## Dropdown View

Click the menu bar item to see detailed usage breakdown:

```
┌──────────────────────────────────────┐
│ Claude Usage           [Med]  ⚙️  🔄  │  ← Header with burn rate badge
├──────────────────────────────────────┤
│ Current Session (5h)           45%   │
│ ████████████░░░░░░░░░░░░░░░░░░░░░░  │
│ Resets in 2h · ~3h until limit       │
│                                      │
│ Weekly (All Models)            72%   │
│ ██████████████████████████░░░░░░░░  │
│ Resets Fri 7:59 AM · ~1h until limit │
│                                      │
│ Weekly (Opus)                  15%   │
│ █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│ Resets Fri 7:59 AM                   │
│                                      │
│ Weekly (Sonnet)                68%   │
│ ████████████████████████░░░░░░░░░░  │
│ Resets Fri 7:59 AM                   │
├──────────────────────────────────────┤
│ Updated 2m ago                  Quit │  ← Footer
└──────────────────────────────────────┘
```

### Usage Windows

| Window | Description |
|--------|-------------|
| **Current Session (5h)** | Rolling 5-hour usage limit - resets continuously |
| **Weekly (All Models)** | 7-day total across all models - resets weekly |
| **Weekly (Opus)** | 7-day limit for Opus model specifically |
| **Weekly (Sonnet)** | 7-day limit for Sonnet model specifically |

Not all windows appear for all users - Opus and Sonnet windows only show if you have model-specific quotas.

### Progress Bar Colors

| Color | Usage Range | Meaning |
|-------|-------------|---------|
| 🟢 Green | 0-49% | Plenty of capacity remaining |
| 🟡 Yellow | 50-89% | Moderate usage, monitor consumption |
| 🔴 Red | 90-100% | Approaching or at limit |

At 90%+ usage, progress bars also show a **diagonal stripe pattern** for color-blind accessibility.

### Reset Times

Each usage window shows when it resets:
- "Resets in 2 hours" - Relative time until reset
- "Resets Fri 7:59 AM" - Absolute time for longer waits

## Burn Rate Indicator

The burn rate badge in the dropdown header shows how fast you're consuming your quota:

| Badge | Rate | Meaning |
|-------|------|---------|
| **Low** | <10%/hr | Sustainable pace |
| **Med** | 10-25%/hr | Moderate consumption |
| **High** | 25-50%/hr | Heavy usage |
| **V.High** | >50%/hr | Will exhaust quickly |

The badge color matches the urgency level (green → yellow → orange → red).

### Time-to-Exhaustion

When available, each progress bar shows predicted time until the limit is reached:

```
Resets in 2h · ~3h until limit
```

This prediction is based on your current burn rate. It only appears when:
- Usage is above 20% (avoids noise at low usage)
- Usage is below 100% (not already at limit)
- Sufficient history exists to calculate burn rate (2+ data points)

## Refreshing Data

### Automatic Refresh

ClaudeApp automatically refreshes usage data in the background:
- Default interval: 5 minutes
- Configurable: 1-30 minutes in Settings

### Manual Refresh

Click the refresh button (🔄) in the dropdown header to immediately fetch new data. The button shows a spinning animation while refreshing.

Keyboard shortcut: **Cmd + R** (when dropdown is open)

## Settings

Click the gear icon (⚙️) in the dropdown header to open Settings.

### Display Section

| Setting | Description |
|---------|-------------|
| **Show Plan Badge** | Display your plan type (Pro) in the menu bar |
| **Show Percentage** | Show/hide the percentage in the menu bar |
| **Percentage Source** | Choose which window's percentage to display |

### Refresh Section

| Setting | Range | Default |
|---------|-------|---------|
| **Refresh Interval** | 1-30 minutes | 5 minutes |

### Notifications Section

| Setting | Description |
|---------|-------------|
| **Enable Notifications** | Master toggle for all alerts |
| **Warning Threshold** | Percentage to trigger warning (50-99%, default 90%) |
| **Usage Warnings** | Alert when crossing the warning threshold |
| **Capacity Full** | Alert when reaching 100% usage |
| **Reset Complete** | Alert when weekly limits reset |

#### Notification Behavior

- **Usage Warning**: Fires once when crossing the threshold from below, then resets when usage drops 5% below the threshold
- **Capacity Full**: Fires once at 100%, resets when usage drops below 95%
- **Reset Complete**: Fires when 7-day usage resets (detected as >50% → <10%)

If notifications are enabled but system permission is denied, a banner appears with a button to open System Settings.

### General Section

| Setting | Description |
|---------|-------------|
| **Launch at Login** | Start ClaudeApp when you log in |
| **Check for Updates** | Automatically check for new versions |

### About Section

Shows app version, GitHub link, and update status:
- **Up to date**: You have the latest version
- **Version X.X.X available**: A newer version exists - click Download
- **Unable to check**: Network error - click Retry

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Cmd + R** | Refresh usage data (when dropdown open) |
| **Cmd + ,** | Open Settings |
| **Cmd + Q** | Quit ClaudeApp |
| **Tab** | Navigate between controls |
| **Space/Enter** | Activate focused button |

## Accessibility

ClaudeApp is fully accessible:

- **VoiceOver**: All elements have descriptive labels
- **Keyboard Navigation**: Full Tab navigation support
- **Dynamic Type**: Scales with system text size preferences
- **Reduced Motion**: Animations disabled when system preference is set
- **Color-Blind Safe**: Patterns supplement color for status indicators
- **High Contrast**: Enhanced borders when system setting is enabled

## Supported Languages

ClaudeApp is available in:
- English (default)
- Portuguese (Brazil)
- Spanish (Latin America)

The app automatically uses your macOS system language.

## Tips

1. **Monitor burn rate during intensive sessions** - A "High" or "V.High" burn rate badge means you'll hit limits soon
2. **Set a lower warning threshold** - If you need buffer time, set notifications to 70-80% instead of 90%
3. **Check time-to-exhaustion** - Plan your work sessions around predicted limit times
4. **Use the 5-hour window strategically** - It resets continuously, so timing breaks can help
