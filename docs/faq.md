# Frequently Asked Questions

## General

### What is ClaudeApp?

ClaudeApp is a macOS menu bar application that monitors your Claude Code API usage limits. It helps you track your capacity in real-time and avoid hitting limits unexpectedly during coding sessions.

### Is ClaudeApp official?

No, ClaudeApp is an independent open-source project. It is not affiliated with or endorsed by Anthropic. It's built by the community for Claude Code users.

### Is ClaudeApp free?

Yes, ClaudeApp is completely free and open source under the MIT license. You can use it, modify it, and contribute to it.

### Where can I see the source code?

ClaudeApp is fully open source on GitHub: [github.com/kaduwaengertner/claudeapp](https://github.com/kaduwaengertner/claudeapp)

---

## Privacy & Security

### What data does ClaudeApp access?

ClaudeApp reads:
- Your Claude Code OAuth token from the macOS Keychain (to authenticate API requests)
- Usage statistics from the Anthropic API (utilization percentages and reset times)
- Your local preferences file (settings you configure)

### What data does ClaudeApp NOT access?

ClaudeApp does NOT:
- Access your Claude conversations or chat history
- Read your code or project files
- Store any data externally or in the cloud
- Send data to third parties
- Include analytics, telemetry, or crash reporting

### Is my data secure?

Yes. ClaudeApp:
- Only reads credentials from the secure macOS Keychain (the same place Claude Code stores them)
- Uses HTTPS for all API communication with Anthropic
- Stores only local preferences on your machine
- Never transmits data to any server other than api.anthropic.com

### Where is my data stored?

| Data | Location |
|------|----------|
| Credentials | macOS Keychain (managed by Claude Code) |
| Preferences | `~/Library/Preferences/com.kaduwaengertner.ClaudeApp.plist` |
| Usage data | Runtime memory only (not persisted) |

---

## Usage

### Why do I need Claude Code installed?

ClaudeApp reads authentication credentials that Claude Code stores in your macOS Keychain. Without Claude Code authenticated, there's no way to access the Anthropic API to fetch your usage data.

### What are the usage windows?

| Window | Description |
|--------|-------------|
| **5-hour Session** | Rolling window that resets continuously as time passes |
| **7-day Total** | Weekly limit across all models, resets once per week |
| **7-day Opus** | Separate weekly limit for Opus model usage |
| **7-day Sonnet** | Separate weekly limit for Sonnet model usage |

Not all windows appear for all users - Opus and Sonnet windows only show if you have model-specific quotas based on your plan.

### What do the percentages mean?

The percentage shows how much of your limit you've used:
- **0%** = No usage, full capacity available
- **50%** = Half of your capacity used
- **90%** = Approaching limit, consider slowing down
- **100%** = Limit reached, Claude Code paused until reset

### How often does data refresh?

By default, every 5 minutes. You can change this in Settings:
- **Minimum**: 1 minute (more frequent updates, more API calls)
- **Maximum**: 30 minutes (less frequent, lower API usage)
- **Default**: 5 minutes (balanced)

### What is the burn rate?

Burn rate shows how fast you're consuming your quota, measured in percent per hour:

| Level | Rate | Meaning |
|-------|------|---------|
| **Low** | <10%/hr | Sustainable pace, plenty of time |
| **Med** | 10-25%/hr | Moderate consumption, monitor usage |
| **High** | 25-50%/hr | Heavy usage, will hit limits within hours |
| **V.High** | >50%/hr | Will exhaust quota quickly |

### What is time-to-exhaustion?

Time-to-exhaustion predicts when you'll hit 100% usage based on your current burn rate. For example:
- "~3h until limit" means at your current pace, you'll hit the limit in about 3 hours

This helps you plan your coding sessions and take breaks strategically.

---

## Troubleshooting

### Why does it show "Claude Code not found"?

Claude Code is either not installed or not authenticated. To fix:
```bash
claude login
```

If you already ran `claude login`, try logging out and back in:
```bash
claude logout
claude login
```

### Why isn't the app showing in my menu bar?

Possible causes:
- **App not running**: Check Activity Monitor for "ClaudeApp"
- **Menu bar full**: Hold `Cmd` and drag other icons to make room
- **Gatekeeper blocked**: Right-click the app and select "Open"

See [Troubleshooting Guide](troubleshooting.md) for detailed solutions.

### Can I use ClaudeApp without a Claude subscription?

No. ClaudeApp monitors usage for Claude Code, which requires an active Claude subscription. Supported plans:
- Claude Pro
- Claude Max 5x
- Claude Max 20x

### Why do I need to bypass Gatekeeper?

ClaudeApp is open-source and not signed with an Apple Developer ID (which costs $99/year). macOS protects you from running unsigned apps by default. The bypass is a one-time step to tell macOS you trust this app.

---

## Technical

### Why macOS 14 (Sonoma) or later only?

ClaudeApp uses modern Swift and SwiftUI features that require macOS 14:
- Observation framework (`@Observable`)
- Modern MenuBarExtra API
- Latest SwiftUI components

This allows us to provide the best experience with minimal code complexity.

### Why isn't it on the Mac App Store?

The Mac App Store requires:
- Apple Developer ID ($99/year)
- App review process
- Sandboxing restrictions (which would prevent Keychain access)

As an open-source project, we distribute directly via GitHub and Homebrew to avoid these barriers.

### How do I install via Homebrew?

```bash
brew tap kaduwaengertner/tap
brew install --cask claudeapp
```

**Note**: Homebrew distribution is coming soon. For now, download from GitHub Releases.

### Can I contribute?

Absolutely! We welcome contributions. See our [Contributing Guide](../CONTRIBUTING.md) for:
- How to set up the development environment
- Code style guidelines
- Pull request process
- Ways to help (code, translations, documentation)

### What languages are supported?

ClaudeApp is available in:
- English (default)
- Portuguese (Brazil)
- Spanish (Latin America)

The app automatically uses your macOS system language. More languages planned for future releases.

### How can I help with translations?

Translations are managed via String Catalogs. See the [Internationalization Spec](../specs/internationalization.md) for guidelines on adding new languages.

---

## More Questions?

- **Installation help**: [Installation Guide](installation.md)
- **Feature details**: [Usage Guide](usage.md)
- **Common problems**: [Troubleshooting](troubleshooting.md)
- **Ask the community**: [GitHub Discussions](https://github.com/kaduwaengertner/claudeapp/discussions)
