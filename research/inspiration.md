# Inspiration & Reference Projects

## Design Inspiration (Primary Sources)

These three sources form the foundation of ClaudeApp's hybrid design system:

### McLaren F1 Playbook
| Attribute | Details |
|-----------|---------|
| URL | https://www.mclaren.com/racing/formula-1/playbook/ |
| Primary Color | Papaya Orange `#FF7300` |
| Secondary Color | Anthracite `#111314` |
| Animation Curve | `cubic-bezier(0.19, 1, 0.22, 1)` with 300ms duration |
| Key Features | Chamfered corners, precision engineering aesthetic, data-driven visualization |
| What We Use | Primary brand orange, animation timing, technical precision feel |

### Teenage Engineering EP-133 K.O. II
| Attribute | Details |
|-----------|---------|
| URL | https://teenage.engineering/products/ep-133 |
| Primary Color | Signature Yellow-Orange `#FFC003` |
| Background | Near-black `#0F0E12` |
| Typography | Univers Light (300 weight) |
| Key Features | LED indicators with glow, calculator aesthetic, light typography, grid layouts |
| What We Use | Warm orange for gradients, light font weights, LED indicator style, monospaced data display |

### KOSMA Business Card (Internal Spec)
| Attribute | Details |
|-----------|---------|
| Primary Color | Orange `#FF4D00` (evolved to McLaren Papaya) |
| Accent | Red brackets `#FF3300` |
| Background | Deep black `#0A0A0A` (evolved to TE near-black) |
| Typography | Bold percentages, uppercase tracked labels |
| Key Features | `[BRACKET]` notation, minimal chrome, data-first design |
| What We Use | Bracket notation, uppercase tracking, bold data values, orange-only accent rule |

### Design System Synthesis

The hybrid system combines:
- **McLaren's precision** - Animation timing, Papaya orange
- **TE's warmth** - Light typography, LED indicators, warm accents
- **KOSMA's structure** - Bracket notation, data hierarchy, minimal aesthetic

---

## Similar Products

### System Monitoring & Menu Bar Apps

| Product | URL | What We Can Learn |
|---------|-----|-------------------|
| Stats | https://github.com/exelban/stats | **Visual hierarchy**: Uses colorful gauges in menu bar for quick status recognition. **Lightweight design**: Proves simplicity works. **Module-based**: Each metric can be shown/hidden independently. |
| iStat Menus | https://bjango.com/mac/istatmenus/ | **Combined mode**: Merges multiple items into single menu bar item to save space. **CPU efficiency**: Markets itself as "most CPU-friendly" - performance matters for always-on apps. **Privacy-first**: No ads, analytics, or tracking builds user trust. |
| MenuBar Stats | https://www.seense.com/menubarstats/ | **Notification Center integration**: Extends beyond menu bar to Widgets. **Smart alerts**: Proactive notifications (battery health alerts) add value. **Modular architecture**: 7 advanced modules with mix-and-match display options. |

### Claude API Usage Trackers (Direct Competitors)

| Product | URL | What We Can Learn |
|---------|-----|-------------------|
| Claude Usage Tracker (hamed-elfayome) | https://github.com/hamed-elfayome/Claude-Usage-Tracker | **Real-time monitoring**: Live updates of usage limits within 5-hour session window. **Dual tracking**: Monitors both web (claude.ai) AND API console simultaneously. **Native Swift/SwiftUI**: Fast, native performance with clean UI. |
| CCUsage Monitor | https://github.com/joachimBrindeau/ccusage-monitor | **Ultra-minimal**: 195 lines of code - proves less is more. **Reset countdown**: Shows time until usage resets, reducing user anxiety. **Percentage display**: Simple number is instantly comprehensible. |
| ClaudeUsageTracker (masorange) | https://github.com/masorange/ClaudeUsageTracker | **Cost tracking**: Shows actual dollars spent, not just API calls. **Project-level granularity**: Break down usage by project for better budgeting. **Automatic updates**: No manual refresh needed. |
| ccusage CLI | https://claudelog.com/claude-code-mcps/cc-usage/ | **Local-first**: Reads Claude's local JSONL files - no API required. **Pro/Max plan focus**: Tracks flat-rate subscriptions Anthropic Console doesn't. **CLI flexibility**: Power users can script/automate queries. |

### OpenAI & AI API Tracking Tools

| Product | URL | What We Can Learn |
|---------|-----|-------------------|
| OpenAI-Usage-Monitor | https://github.com/Jean-Zombie/OpenAI-Usage-Monitor | **API key integration**: Direct connection to billing endpoints. **Historical view**: Track usage over time, not just current state. **Multi-model support**: Handles different AI models in one interface. |
| Cursor Usage Widget | https://cursorusage.com/ | **Specialized focus**: Dedicated to one tool (Cursor AI) - deep integration vs. broad scope. **Widget format**: Sleek, minimal design aesthetic. **Real-time updates**: Immediate feedback on usage changes. |

### Menu Bar Management & UX Best Practices

| Product | URL | What We Can Learn |
|---------|-----|-------------------|
| Bartender | https://www.macstories.net/roundups/managing-your-mac-menu-bar-a-roundup-of-my-favorite-bartender-alternatives/ | **Industry standard**: Most widely-used menu bar manager shows proven UX patterns. **Customization depth**: Advanced users want granular control. **Show/hide states**: Users need quick toggle between minimal and full visibility. |
| Ice | https://github.com/jordanbaird/Ice | **Open source advantage**: Free alternative that's frequently updated. **Community-driven**: GitHub stars/issues show active user feedback loop. |
| Hidden Bar | https://www.igeeksblog.com/best-mac-menu-bar-apps/ | **One-click simplicity**: Quick hide/show is the core value proposition. **Visual cleanliness**: Users prioritize aesthetic minimalism. **Low cognitive load**: No complex settings to configure. |

---

## GitHub Repositories

### MenuBarExtra & Framework Libraries

| Repo | URL | Relevant For | Key Files |
|------|-----|--------------|-----------|
| orchetect/MenuBarExtraAccess | https://github.com/orchetect/MenuBarExtraAccess | MenuBarExtra control, Show/hide menu programmatically | Solves runloop blocking issues with native MenuBarExtra |
| wadetregaskis/FluidMenuBarExtra | https://github.com/wadetregaskis/FluidMenuBarExtra | Enhanced MenuBarExtra, Animations, Scene phase access | Drop-in replacement with animated resizing, persisted button highlighting |
| lfroms/fluid-menu-bar-extra | https://github.com/lfroms/fluid-menu-bar-extra | MenuBarExtra improvements, Lightweight wrapper | Fixes MenuBarExtra limitations, dynamic install/remove |
| jlehikoinen/SwiftUIMenuBarAppDemo | https://github.com/jlehikoinen/SwiftUIMenuBarAppDemo | MenuBarExtra demo | Complete demo showing both .menu and .window styles |
| stevenselcuk/Barmaid | https://github.com/stevenselcuk/Barmaid | Boilerplate/starter template | Ready-to-use boilerplate with popover and NSMenu support |

### Complete Reference Implementations

| Repo | URL | Relevant For | Key Files |
|------|-----|--------------|-----------|
| joachimBrindeau/ccusage-monitor | https://github.com/joachimBrindeau/ccusage-monitor | API usage monitoring, Real-time updates, Auto-refresh | Claude API usage monitor with percentage display, 30s auto-refresh |
| DamascenoRafael/reminders-menubar | https://github.com/DamascenoRafael/reminders-menubar | Data integration, View usage patterns | Menu bar app for Apple Reminders with SwiftUI |
| swiftbar/SwiftBar | https://github.com/swiftbar/SwiftBar | Plugin system, Refresh scheduling | Powerful menu bar customization tool with plugin support |

### Keychain & Security

| Repo | URL | Relevant For | Key Files |
|------|-----|--------------|-----------|
| kishikawakatsumi/KeychainAccess | https://github.com/kishikawakatsumi/KeychainAccess | Secure API key storage | Simple Swift wrapper for Keychain, works on all Apple platforms |
| evgenyneu/keychain-swift | https://github.com/evgenyneu/keychain-swift | API key storage | Helper functions for saving text securely, includes macOS demo |
| dm-zharov/swift-security | https://github.com/dm-zharov/swift-security | Modern keychain API | Modern framework compatible with SwiftUI, CryptoKit integration |
| danyaffff/KeychainStorage | https://github.com/danyaffff/KeychainStorage | SwiftUI property wrapper | @KeychainStorage property wrapper similar to @AppStorage |

### Progress Indicators & UI Components

| Repo | URL | Relevant For | Key Files |
|------|-----|--------------|-----------|
| exyte/ProgressIndicatorView | https://github.com/exyte/ProgressIndicatorView | Progress indicators, Usage visualization | SwiftUI progress indicator library with circular/linear options |
| AmeddahAchraf/Progress-Bar-SwifttUI | https://github.com/AmeddahAchraf/Progress-Bar-SwifttUI | Customizable progress bars | Circular/Linear progress with animated text support |

### Settings & User Defaults

| Repo | URL | Relevant For | Key Files |
|------|-----|--------------|-----------|
| sindresorhus/Defaults | https://github.com/sindresorhus/Defaults | Settings management | Swifty UserDefaults with SwiftUI support, 4M+ users, iCloud sync |
| orchetect/SettingsAccess | https://github.com/orchetect/SettingsAccess | Settings window access | Better SwiftUI Settings Scene access on macOS |
| sindresorhus/LaunchAtLogin-Modern | https://github.com/sindresorhus/LaunchAtLogin-Modern | Launch at Login | Swift package optimized for macOS 13+ with SwiftUI integration |

---

## Articles & Tutorials

### MenuBarExtra Implementation

| Title | URL | Key Insight |
|-------|-----|-------------|
| Build a macOS menu bar utility in SwiftUI | https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/ | MenuBarExtra scene provides simple integration with two styles: `.menu` for dropdown menus and `.window` for popover-like windows. Use `menuBarExtraStyle(.window)` for greater flexibility. |
| Create a mac menu bar app in SwiftUI with MenuBarExtra | https://sarunw.com/posts/swiftui-menu-bar-app/ | MenuBarExtra can be easily added as a new Scene with state variables for changeable labels. To hide from Dock, set "Application is agent (UIElement)" to YES in Info.plist. |
| Creating Menu Bar Apps in SwiftUI for macOS Ventura | https://blog.schurigeln.com/menu-bar-apps-swift-ui/ | Window style allows any SwiftUI views with dynamic or fixed frame sizing. Menu style is limited to text/buttons/dividers. |
| Showing Settings from macOS Menu Bar Items | https://steipete.me/posts/2025/showing-settings-from-macos-menu-bar-items | Real-world implementation challenges and solutions for showing settings windows from menu bar items in 2025. |

### Keychain Access

| Title | URL | Key Insight |
|-------|-----|-------------|
| Secure Storage with Keychain Access | https://softwarepatternslexicon.com/swift/security-patterns/secure-storage-with-keychain-access/ | Comprehensive guide covering SecItemAdd, SecItemUpdate, SecItemCopyMatching, and SecItemDelete APIs. Use SecItemCopyMatching with kSecReturnData to retrieve items. |
| Retrieving Keychain Passwords in Swift for macOS | https://www.junian.net/dev/swift-get-keychain-password/ | macOS-specific tutorial for password retrieval. Rely on default keychain implicitly. |
| security command - macOS | https://ss64.com/mac/security.html | Complete reference for the `security` CLI tool. Supports find-generic-password, add-generic-password, delete-generic-password operations. |

### System Notifications

| Title | URL | Key Insight |
|-------|-----|-------------|
| SwiftUI Notifications - Codecademy | https://www.codecademy.com/resources/docs/swiftui/notifications | Use UNUserNotificationCenter to manage content, request permission with `requestAuthorization(options: [.alert, .sound, .badge])`. |
| Learn Local Notifications | https://swiftinsg.org/learn/notifications | Modern authorization patterns using async/await: `try await center.requestAuthorization(options: [.alert, .sound, .badge])`. |
| Scheduling local notifications | https://www.hackingwithswift.com/books/ios-swiftui/scheduling-local-notifications | Notification structure: content (title/subtitle/sound), trigger (time/date), and request (combines content+trigger with unique identifier). |

### Launch at Login

| Title | URL | Key Insight |
|-------|-----|-------------|
| Add launch at login setting to a macOS app | https://nilcoalescing.com/blog/LaunchAtLoginSetting/ | January 2025 tutorial using modern SMAppService API. Import ServiceManagement, register app service object as login item when enabled. Simple and clean for macOS 13+. |
| macOS Service Management - SMAppService API | https://theevilbit.github.io/posts/smappservice/ | SMAppService introduced in macOS Ventura (13) replaces SMJobBless and SMLoginItemSetEnabled. API is "super easy to use" compared to older methods. |
| Implementing Launch at Login Feature | https://jogendra.dev/implementing-launch-at-login-feature-in-macos-apps | Step-by-step implementation guide using Service Management framework. Login items installed via this framework aren't visible in System Preferences. |

### SwiftUI Patterns (macOS 14+)

| Title | URL | Key Insight |
|-------|-----|-------------|
| Migrating to @Observable macro | https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro | @Observable (iOS 17+) replaces ObservableObject/@Published. Use @State with @Observable instead of @StateObject. |
| @Observable in SwiftUI explained | https://www.donnywals.com/observable-in-swiftui-explained/ | @Observable provides performance improvements: views only redraw for properties actually used, unlike ObservableObject which redraws on any @Published change. |
| @Observable Macro performance increase | https://www.avanderlee.com/swiftui/observable-macro-performance-increase-observableobject/ | Granular property-level reactivity reduces unnecessary view updates and improves app responsiveness. |
| SwiftUI Environment - Concepts and Practice | https://fatbobman.com/en/posts/swiftui-environment-concepts-and-practice/ | Environment is powerful dependency injection mechanism. Can hold value types, reference types, functions, factory methods, and protocol-constrained objects. |
| Custom Progress View in SwiftUI | https://swiftuirecipes.com/blog/custom-progress-view-in-swiftui | Create custom progress views by conforming to ProgressViewStyle protocol. Use tint(_:) to change colors. |

---

## Key UX Insights Summary

### Display Philosophy
- **Percentage wins**: Users instantly understand "75% used" vs. abstract numbers
- **Color coding**: Red (critical), Yellow (warning), Green (safe) is universal
- **Minimize text**: Menu bar space is precious - use icons + numbers only

### Interaction Patterns
- **Click to expand**: Menu bar icon shows summary, dropdown shows details
- **Real-time updates**: Polling every 30-60 seconds keeps data fresh without battery drain
- **Reset countdowns**: Show time until limits reset (reduces user anxiety)

### Information Architecture
- **Module-based design**: Let users choose what metrics to show
- **Combined mode**: Merge multiple items into one icon to save space
- **Notification Center**: Extend to widgets for additional detail without cluttering menu bar

### Performance Requirements
- **CPU efficiency**: Always-on apps must be lightweight
- **Native frameworks**: Swift/SwiftUI outperforms Electron for menu bar apps
- **Minimal code**: Proves simplicity works (ccusage-monitor is 195 lines)

### Trust & Transparency
- **Privacy-first**: No analytics/tracking
- **Open source**: Many successful apps are GitHub projects
- **Cost visibility**: Show actual usage, not just abstract API call counts

### User Anxiety Management
- **Proactive alerts**: Warn before hitting limits, not after
- **Historical data**: Let users see trends to predict future usage
- **Reset timers**: "Usage resets in 2h 34m" reduces constant checking

### Technical Best Practices
- **MenuBarExtra** is the modern SwiftUI approach (macOS 13+)
- **SMAppService** is the recommended API for launch at login
- **@Observable macro** (macOS 14+) offers better performance than ObservableObject
- **FluidMenuBarExtra** or **MenuBarExtraAccess** libraries solve native MenuBarExtra limitations
- Use `LSUIElement = YES` in Info.plist to hide from Dock

---

## Official Documentation

| Resource | URL | What We Can Learn |
|---------|-----|-------------------|
| Apple HIG - Menu Bar | https://developer.apple.com/design/human-interface-guidelines/the-menu-bar | Official standards for native macOS feel |
| MenuBarExtra Documentation | https://developer.apple.com/documentation/swiftui/menubarextra | Official SwiftUI MenuBarExtra API reference |
| SMAppService Documentation | https://developer.apple.com/documentation/servicemanagement/smappservice | Official Launch at Login API reference |
| UNUserNotificationCenter | https://developer.apple.com/documentation/usernotifications/unusernotificationcenter | Official notifications API reference |
| Keychain Services | https://developer.apple.com/documentation/security/keychain_services/keychain_items/searching_for_keychain_items | Official Keychain API reference |

---

## Sources

### System Monitoring Apps
- https://github.com/exelban/stats
- https://bjango.com/mac/istatmenus/
- https://www.seense.com/menubarstats/
- https://www.drbuho.com/how-to/best-mac-menu-bar-apps

### Claude API Usage Trackers
- https://github.com/hamed-elfayome/Claude-Usage-Tracker
- https://github.com/joachimBrindeau/ccusage-monitor
- https://github.com/masorange/ClaudeUsageTracker
- https://claudelog.com/claude-code-mcps/cc-usage/
- https://shipyard.build/blog/claude-code-track-usage/

### OpenAI & AI API Trackers
- https://github.com/Jean-Zombie/OpenAI-Usage-Monitor
- https://cursorusage.com/

### Menu Bar Management & Design
- https://www.macstories.net/roundups/managing-your-mac-menu-bar-a-roundup-of-my-favorite-bartender-alternatives/
- https://github.com/jordanbaird/Ice
- https://www.igeeksblog.com/best-mac-menu-bar-apps/

### MenuBarExtra & Framework Libraries
- https://github.com/orchetect/MenuBarExtraAccess
- https://github.com/wadetregaskis/FluidMenuBarExtra
- https://github.com/lfroms/fluid-menu-bar-extra
- https://github.com/jlehikoinen/SwiftUIMenuBarAppDemo
- https://github.com/stevenselcuk/Barmaid

### Security & Keychain
- https://github.com/kishikawakatsumi/KeychainAccess
- https://github.com/evgenyneu/keychain-swift
- https://github.com/dm-zharov/swift-security

### Settings & Preferences
- https://github.com/sindresorhus/Defaults
- https://github.com/orchetect/SettingsAccess
- https://github.com/sindresorhus/LaunchAtLogin-Modern

### Tutorial Resources
- https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/
- https://sarunw.com/posts/swiftui-menu-bar-app/
- https://blog.schurigeln.com/menu-bar-apps-swift-ui/
- https://steipete.me/posts/2025/showing-settings-from-macos-menu-bar-items

### Official Documentation
- https://developer.apple.com/design/human-interface-guidelines/the-menu-bar
- https://developer.apple.com/documentation/swiftui/menubarextra
- https://developer.apple.com/documentation/servicemanagement/smappservice
- https://developer.apple.com/documentation/usernotifications/unusernotificationcenter
