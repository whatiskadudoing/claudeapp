# Privacy Policy

**Last updated**: January 2026

## Overview

ClaudeApp is committed to protecting your privacy. This document explains what data ClaudeApp accesses, how it's used, and your rights.

ClaudeApp is a local-only macOS application that monitors your Claude Code API usage. It prioritizes privacy by keeping all data on your device and making only essential network requests.

---

## Data Collection

### What We Access

| Data | Purpose | Storage |
|------|---------|---------|
| Claude Code OAuth Token | Authenticate with Anthropic API to fetch usage | Read-only from Keychain, never stored by ClaudeApp |
| Usage Statistics | Display usage percentages and calculate burn rates | Runtime memory only, not persisted |
| User Preferences | Save your settings (refresh interval, notifications, display options) | Local UserDefaults |

### What We Do NOT Access

ClaudeApp does **NOT** access:
- Your Claude conversations or chat history
- Your code, project files, or filesystem contents
- Your personal information (name, email, etc.)
- Your browsing history or other application data
- Any data from other applications on your system

---

## Data Storage

### Local Only

All data stays on your device. ClaudeApp stores:

| Data | Location |
|------|----------|
| Credentials | macOS Keychain (managed by Claude Code, read-only by ClaudeApp) |
| Settings | `~/Library/Preferences/com.claudeapp.ClaudeApp.plist` |
| Usage History | Runtime memory only (for burn rate calculation) |

### No Cloud Sync

- No data is synced to any cloud service
- No user accounts or registration required
- No external databases or storage

### No Analytics

ClaudeApp does **NOT** include:
- Analytics tracking (no Amplitude, Mixpanel, etc.)
- Crash reporting services (no Sentry, Crashlytics, etc.)
- Usage telemetry of any kind
- Advertising SDKs
- User behavior monitoring
- Tracking pixels or beacons

---

## Network Communication

### Anthropic API

ClaudeApp communicates with `api.anthropic.com` to:
- Fetch your usage statistics (utilization percentages, reset times)

**Details:**
- **Endpoint**: `GET https://api.anthropic.com/api/oauth/usage`
- **Authentication**: Uses your existing Claude Code OAuth token
- **Frequency**: Every 5 minutes by default (configurable: 1-30 minutes)
- **Data sent**: Only authentication headers, no personal data
- **Data received**: Usage percentages and reset timestamps

ClaudeApp does **NOT**:
- Send any additional data to Anthropic beyond authentication
- Create new API sessions or conversations
- Access your chat history or conversations
- Store or forward your credentials to any third party

### GitHub API (Optional)

If you enable "Check for Updates" in Settings, ClaudeApp queries:
- `api.github.com` to check for new app versions
- **Frequency**: Once per day, in the background
- **Data sent**: None (unauthenticated GET request)
- **Data received**: Latest release version and download URL

This feature is optional and can be disabled in Settings.

---

## Your Rights

### Data Access

You can view all data ClaudeApp stores:

**View preferences:**
```bash
defaults read com.claudeapp.ClaudeApp
```

**View what's in Keychain (Claude Code credentials):**
```bash
security find-generic-password -s "Claude Code-credentials" -w
```
(This shows credentials managed by Claude Code, not by ClaudeApp)

### Data Deletion

To completely remove all ClaudeApp data:

```bash
# 1. Quit ClaudeApp
# (Click menu bar icon > Quit, or use Activity Monitor)

# 2. Remove the app
rm -rf /Applications/ClaudeApp.app

# 3. Remove preferences
rm ~/Library/Preferences/com.claudeapp.ClaudeApp.plist

# 4. Remove cached data (if any)
rm -rf ~/Library/Caches/com.claudeapp.ClaudeApp
```

**Note**: Claude Code credentials in Keychain are managed by Claude Code, not ClaudeApp. Removing ClaudeApp does not affect your Claude Code authentication.

### No Account Required

ClaudeApp requires no registration, account creation, or personal information. It simply reads credentials that Claude Code has already stored securely in your macOS Keychain.

---

## Security

### Credential Handling

- OAuth tokens are read from the macOS Keychain (Apple's secure credential storage)
- Tokens are held in memory only while the app runs
- Tokens are never written to disk, logged, or transmitted to third parties
- Tokens are sent only to `api.anthropic.com` for usage data retrieval

### Network Security

- All API communication uses HTTPS (TLS encrypted)
- Certificate pinning is handled by macOS system libraries
- No insecure HTTP connections

### Open Source

ClaudeApp is fully open source. You can audit the code yourself:

- **Repository**: [github.com/kaduwaengertner/claudeapp](https://github.com/kaduwaengertner/claudeapp)
- **License**: MIT

Every line of code is available for inspection. There are no hidden binaries, obfuscated code, or closed-source components.

---

## Third-Party Services

ClaudeApp connects only to:

| Service | Purpose | Required |
|---------|---------|----------|
| api.anthropic.com | Fetch usage statistics | Yes |
| api.github.com | Check for updates | No (optional) |

No other third-party services, SDKs, or libraries are used for tracking, analytics, or data collection.

---

## Children's Privacy

ClaudeApp does not collect any personal information from anyone, including children. The app displays only usage statistics from Anthropic's API.

---

## Changes to This Policy

We may update this privacy policy as the app evolves. Changes will be posted to:
- This document in the repository
- Release notes for the relevant version

The "Last updated" date at the top indicates when changes were made.

---

## Contact

For privacy questions or concerns:
- **GitHub Issues**: [github.com/kaduwaengertner/claudeapp/issues](https://github.com/kaduwaengertner/claudeapp/issues)
- **GitHub Discussions**: [github.com/kaduwaengertner/claudeapp/discussions](https://github.com/kaduwaengertner/claudeapp/discussions)

---

## Summary

| Question | Answer |
|----------|--------|
| Does ClaudeApp collect personal data? | No |
| Does ClaudeApp track user behavior? | No |
| Does ClaudeApp use analytics? | No |
| Does ClaudeApp share data with third parties? | No |
| Is data stored in the cloud? | No |
| Can I audit the code? | Yes, it's open source |
| Can I delete all my data? | Yes, see instructions above |
