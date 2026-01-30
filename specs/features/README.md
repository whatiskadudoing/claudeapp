# Feature Specifications

## Overview

This directory contains detailed specifications for each feature of ClaudeApp.

---

## Implemented Features

| Feature | File | Status | SLC |
|---------|------|--------|-----|
| View Usage | [view-usage.md](./view-usage.md) | ✅ Complete | 1 |
| Refresh Usage | [refresh-usage.md](./refresh-usage.md) | ✅ Complete | 1 |
| Notifications | [notifications.md](./notifications.md) | ✅ Complete | 2 |
| Settings | [settings.md](./settings.md) | ✅ Complete | 2 |
| Updates | [updates.md](./updates.md) | ✅ Complete | 3 |
| Time-to-Exhaustion | [view-usage.md](./view-usage.md) | ✅ Complete | 3 |
| Burn Rate Indicator | [view-usage.md](./view-usage.md) | ✅ Complete | 3 |
| Power-Aware Refresh | [power-aware-refresh.md](./power-aware-refresh.md) | ✅ Complete | 4 |
| Premium Design System | [../design-system.md](../design-system.md) | ✅ Complete | 4 |

---

## Planned Features

Features identified through competitive analysis (January 2026):

### High Priority

| Feature | File | Competitors | Notes |
|---------|------|-------------|-------|
| Icon Styles | [icon-styles.md](./icon-styles.md) | Claude Usage Tracker (5 styles) | Most requested |
| ~~Power-Aware Refresh~~ | [power-aware-refresh.md](./power-aware-refresh.md) | Vibeviewer | ✅ Implemented |

### Medium Priority

| Feature | File | Competitors | Notes |
|---------|------|-------------|-------|
| Historical Charts | [historical-charts.md](./historical-charts.md) | ccseva, quotio | Sparklines |
| Settings Export | [settings-export.md](./settings-export.md) | Rectangle | JSON backup |
| Terminal Integration | [terminal-integration.md](./terminal-integration.md) | ccusage | Shell prompts |

### Lower Priority

| Feature | File | Competitors | Notes |
|---------|------|-------------|-------|
| Multi-Account | [multi-account.md](./multi-account.md) | Claude Usage Tracker | Complex |
| Widgets | [widgets.md](./widgets.md) | Stats | Requires signing |

---

## Feature Status

| Feature | Spec | Implemented | Tested |
|---------|------|-------------|--------|
| View Usage | ✅ | ✅ | ✅ |
| Refresh Usage | ✅ | ✅ | ✅ |
| Notifications | ✅ | ✅ | ✅ |
| Settings | ✅ | ✅ | ✅ |
| Updates | ✅ | ✅ | ✅ |
| Time-to-Exhaustion | ✅ | ✅ | ✅ |
| Burn Rate Indicator | ✅ | ✅ | ✅ |
| Power-Aware Refresh | ✅ | ✅ | ✅ |
| Design System (McLaren/TE/KOSMA) | ✅ | ✅ | ✅ |
| Icon Styles | ✅ | ❌ | ❌ |
| Historical Charts | ✅ | ❌ | ❌ |
| Settings Export | ✅ | ❌ | ❌ |
| Terminal Integration | ✅ | ❌ | ❌ |
| Multi-Account | ✅ | ❌ | ❌ |
| Widgets | ✅ | ❌ | ❌ |

---

## Research References

All feature specifications reference research from:

| Document | Topics |
|----------|--------|
| `research/competitive-analysis.md` | Direct competitors |
| `research/macos-menubar-apps.md` | Menu bar patterns |
| `research/swift-chart-libraries.md` | Chart libraries |
| `research/update-mechanisms.md` | Auto-update patterns |
| `research/advanced-settings-patterns.md` | Settings UI |
| `research/macos-widgets.md` | WidgetKit patterns |
| `research/llm-usage-tracking-tools.md` | Cost tracking |

See [../competitive-analysis.md](../competitive-analysis.md) for summary.

---

## Feature Template

When adding new features, use this template:

```markdown
# Feature: [Name]

## Overview
Brief description of the feature.

---

## Research References
> **Sources:**
> - [Project Name](URL) (X stars) - What we learned
> - Research document: `research/filename.md`

---

## User Story
**As a** [user type]
**I want to** [action]
**So that** [benefit]

---

## Design
[Wireframes, specifications]

---

## Implementation
[Code samples, data models]

---

## Acceptance Criteria

### Must Have
- [ ] Criterion 1
- [ ] Criterion 2

### Should Have
- [ ] Criterion 1

### Nice to Have
- [ ] Criterion 1

---

## Related Specifications
- [spec.md](./spec.md) - Description
```

---

## Reading Order

For developers new to the project:

1. Start with **[View Usage](./view-usage.md)** - the core feature
2. Then **[Refresh Usage](./refresh-usage.md)** - data flow
3. Then **[Settings](./settings.md)** - configuration
4. Then **[Notifications](./notifications.md)** - alerts
5. Then **[Updates](./updates.md)** - distribution
6. Then **[../competitive-analysis.md](../competitive-analysis.md)** - future features

---

## Implementation Phases

### Phase 1: MVP ✅ (SLC 1)

**Goal**: Working menu bar app with basic functionality

- [x] View Usage (menu bar + dropdown)
- [x] Manual Refresh
- [x] Auto-refresh (fixed 5-min interval)
- [x] Basic error handling

### Phase 2: Polish ✅ (SLC 2-3)

**Goal**: Complete user experience

- [x] Configurable refresh interval
- [x] Usage notifications
- [x] Settings panel
- [x] Launch at login
- [x] Time-to-exhaustion predictions
- [x] Burn rate indicator

### Phase 3: Distribution ✅ (SLC 4-6)

**Goal**: Ready for public release

- [x] Update checking
- [x] GitHub Releases (CI workflow)
- [x] Homebrew formula (template created)
- [x] Documentation
- [x] Accessibility (VoiceOver, keyboard, Dynamic Type)
- [x] Internationalization (en, pt-BR, es)

### Phase 4: Enhanced Features ✅ (SLC 7+)

**Goal**: Competitive feature parity + Premium design

- [x] Power-aware refresh ([power-aware-refresh.md](./power-aware-refresh.md))
- [x] Premium Design System (McLaren/TE/KOSMA hybrid) ([../design-system.md](../design-system.md))
- [ ] Icon styles ([icon-styles.md](./icon-styles.md))
- [ ] Historical sparklines ([historical-charts.md](./historical-charts.md))
- [ ] Settings export ([settings-export.md](./settings-export.md))
- [ ] Terminal integration ([terminal-integration.md](./terminal-integration.md))

### Phase 5: Advanced Features (Future)

**Goal**: Differentiation

- [ ] Multi-account ([multi-account.md](./multi-account.md))
- [ ] Widgets ([widgets.md](./widgets.md))
- [ ] Sparkle auto-updates ([../sparkle-updates.md](../sparkle-updates.md))
