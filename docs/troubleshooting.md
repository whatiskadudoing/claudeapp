# Troubleshooting

## Common Issues

### "Claude Code not found"

**Cause**: ClaudeApp can't find Claude Code credentials in the macOS Keychain.

**Solutions**:
1. Ensure Claude Code is installed:
   ```bash
   claude --version
   ```
   If this fails, install Claude Code from https://claude.ai/code

2. Log in to Claude Code:
   ```bash
   claude login
   ```
   Follow the prompts to authenticate.

3. Click "Try Again" in ClaudeApp to re-check for credentials

**Note**: ClaudeApp reads credentials from the Keychain entry `Claude Code-credentials`. If you've logged in but still see this error, try logging out and back in:
```bash
claude logout
claude login
```

### Usage shows 0% or stale data

**Cause**: Unable to fetch data from the Claude API.

**Solutions**:
1. Check your internet connection
2. Click the refresh button (🔄) in the dropdown header
3. If the problem persists, re-authenticate:
   ```bash
   claude logout
   claude login
   ```

**Note**: When data is stale (older than 60 seconds), ClaudeApp continues showing the last known values. A "Data may be stale" indicator may appear.

### App won't open - "unidentified developer"

**Cause**: macOS Gatekeeper blocks apps that aren't signed with an Apple Developer ID.

**Solution A: Right-Click Method (Recommended)**
1. Locate ClaudeApp in your Applications folder
2. Right-click (or Control-click) the app
3. Select "Open" from the context menu
4. Click "Open" in the security dialog

**Solution B: System Settings Method**
1. Try to open the app normally (it will be blocked)
2. Open **System Settings** > **Privacy & Security**
3. Scroll down to the Security section
4. Click "Open Anyway" next to the ClaudeApp message
5. Click "Open" in the confirmation dialog

This only needs to be done once - subsequent launches work normally.

### Notifications not working

**Cause**: System notification permission not granted to ClaudeApp.

**Solutions**:
1. Open **System Settings** > **Notifications**
2. Find **ClaudeApp** in the app list
3. Enable "Allow Notifications"
4. Ensure the notification style is set to "Alerts" or "Banners"

If ClaudeApp doesn't appear in the list:
1. Open ClaudeApp Settings > Notifications
2. Toggle "Enable Notifications" off and on
3. When prompted, allow notifications

**In ClaudeApp**: If system permission is denied, a banner appears with a "System Settings" button to quickly grant permission.

### High CPU/memory usage

**Cause**: This could indicate a bug or runaway process.

**Workarounds**:
1. Quit ClaudeApp from the dropdown menu or using Cmd+Q
2. Restart ClaudeApp
3. Increase the refresh interval in Settings (reduces API polling frequency)

**If the problem persists**:
- Check Activity Monitor for ClaudeApp's CPU/memory usage
- Note the values and [report the issue](https://github.com/kaduwaengertner/claudeapp/issues)

**Expected resource usage**:
- Memory: ~15-25 MB
- CPU: <0.5% when idle

### Menu bar icon missing

**Cause**: The menu bar may be full, or macOS may have hidden the icon.

**Solutions**:
1. **Check if running**: Open Activity Monitor and search for "ClaudeApp"
2. **Reveal hidden items**: Hold `Cmd` and drag other menu bar icons to make room
3. **Restart the app**: Quit via Activity Monitor if needed, then relaunch
4. **Restart your Mac**: Some macOS issues resolve with a restart

**Tip**: macOS automatically hides menu bar items when space is limited. Consider removing unused menu bar apps.

### Settings not saving

**Cause**: Permissions issue with the preferences file.

**Solution**:
1. Quit ClaudeApp completely
2. Delete the preferences file:
   ```bash
   rm ~/Library/Preferences/com.kaduwaengertner.ClaudeApp.plist
   ```
3. Restart ClaudeApp

This resets all settings to defaults. You'll need to reconfigure your preferences.

### Rate limited by API

**Cause**: Too many API requests in a short period.

**What happens**: ClaudeApp shows a "Rate Limited" message and automatically waits before retrying.

**Solutions**:
1. Wait for the specified time (shown in the error)
2. Increase your refresh interval in Settings to reduce request frequency

**Note**: ClaudeApp uses exponential backoff on errors - it automatically increases wait times up to 15 minutes when repeated failures occur.

### Data shows "Unable to load"

**Cause**: Various API or network errors.

**Solutions based on error type**:

| Error | Solution |
|-------|----------|
| Connection Error | Check internet connection |
| Server Error (5xx) | Wait and retry - the API may be temporarily down |
| Authentication Error | Run `claude login` to re-authenticate |
| Data Format Error | Update ClaudeApp - the API format may have changed |

### Burn rate not showing

**Cause**: Insufficient data to calculate burn rate.

**Why this happens**: Burn rate requires at least 2 data points collected over time to calculate consumption velocity.

**Solution**: Wait for ClaudeApp to collect more data (usually 5-10 minutes at default refresh rate).

### Time-to-exhaustion not showing

**Cause**: Conditions not met for display.

Time-to-exhaustion only appears when:
- Usage is above 20% (avoids noise at low usage)
- Usage is below 100% (not already at limit)
- Burn rate can be calculated (requires 2+ data points)

---

## Reporting Issues

### Before Reporting

1. Check this troubleshooting guide
2. Search [existing issues](https://github.com/kaduwaengertner/claudeapp/issues) for your problem
3. Update to the latest version (Settings > About > Check for Updates)

### How to Report

1. Go to [GitHub Issues](https://github.com/kaduwaengertner/claudeapp/issues/new)
2. Include:
   - **macOS version**: (e.g., macOS 14.2)
   - **ClaudeApp version**: Found in Settings > About
   - **Steps to reproduce**: What you did before the issue occurred
   - **Expected behavior**: What should have happened
   - **Actual behavior**: What actually happened
   - **Screenshots**: If applicable

### Getting System Information

To find your macOS version:
1. Click the Apple menu ()
2. Select "About This Mac"
3. Note the macOS version number

To find your ClaudeApp version:
1. Click the ClaudeApp menu bar icon
2. Click the Settings button (⚙️)
3. The version is shown in the About section at the bottom

---

## Getting Help

- **Bug Reports**: [GitHub Issues](https://github.com/kaduwaengertner/claudeapp/issues)
- **Questions & Discussions**: [GitHub Discussions](https://github.com/kaduwaengertner/claudeapp/discussions)
- **Usage Guide**: [docs/usage.md](usage.md)
- **Installation**: [docs/installation.md](installation.md)
