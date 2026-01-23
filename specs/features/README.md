# Feature Specifications

## Overview

This directory contains detailed specifications for each feature of ClaudeApp.

---

## Features

| Feature | Description | Priority |
|---------|-------------|----------|
| [View Usage](./view-usage.md) | Menu bar display and dropdown with usage data | P0 - Core |
| [Refresh Usage](./refresh-usage.md) | Auto and manual data refresh | P0 - Core |
| [Notifications](./notifications.md) | Usage warnings and alerts | P1 - Important |
| [Settings](./settings.md) | Configuration and preferences | P1 - Important |
| 🆕 Time-to-Exhaustion | Predict when usage limit will be reached | P1 - Important |
| 🆕 Burn Rate Indicator | Show consumption velocity (Low/Med/High) | P1 - Important |
| [Updates](./updates.md) | Version checking and updates | P2 - Nice to Have |

> 🆕 **NEW (January 2026):** Time-to-exhaustion and burn rate features added to [View Usage](./view-usage.md) spec. See that document for full details.

---

## Implementation Phases

### Phase 1: MVP ✅

**Goal**: Working menu bar app with basic functionality

- [x] View Usage (menu bar + dropdown)
- [x] Manual Refresh
- [x] Auto-refresh (fixed 5-min interval)
- [x] Basic error handling

### Phase 2: Polish ✅

**Goal**: Complete user experience

- [x] Configurable refresh interval
- [x] Usage notifications
- [x] Settings panel
- [x] Launch at login
- [x] Time-to-exhaustion predictions
- [x] Burn rate indicator

### Phase 3: Distribution ✅

**Goal**: Ready for public release

- [x] Update checking
- [x] GitHub Releases (CI workflow)
- [x] Homebrew formula (template created)
- [x] Documentation

---

## 🆕 New Requirements (January 2026)

Based on competitive analysis of [Claude Code Usage Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor):

| Feature | Description | Effort |
|---------|-------------|--------|
| **Time-to-Exhaustion** | Display "~2h until limit" for each usage window | Medium |
| **Burn Rate Indicator** | Badge showing Low/Med/High/Very High velocity | Low |

These features align with ClaudeApp's passive monitoring philosophy and enhance the glanceable experience. Full specs in [view-usage.md](./view-usage.md).

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

---

## Reading Order

For developers new to the project:

1. Start with **[View Usage](./view-usage.md)** - the core feature
2. Then **[Refresh Usage](./refresh-usage.md)** - data flow
3. Then **[Settings](./settings.md)** - configuration
4. Then **[Notifications](./notifications.md)** - alerts
5. Finally **[Updates](./updates.md)** - distribution
