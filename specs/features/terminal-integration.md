# Feature: Terminal Statusline Integration

## Overview

Provide usage data output for terminal statuslines (bash/zsh prompts, tmux, starship), enabling developers to see Claude usage directly in their terminal without leaving their workflow.

---

## Research References

> **Sources:**
> - [ccusage](https://github.com/ryoppippi/ccusage) (10K stars) - CLI tool with statusline integration
> - [Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor) (6.3K stars) - Terminal monitoring
> - [Starship](https://github.com/starship/starship) (53K stars) - Custom prompt modules pattern
> - Research document: `research/llm-usage-tracking-tools.md`, `research/claude-related-tools.md`

---

## User Story

**As a** developer who works primarily in the terminal
**I want to** see my Claude usage in my shell prompt
**So that** I can monitor usage without switching to the menu bar

---

## Output Formats

### Plain Text (Default)

```
86% (5h: 45%, 7d: 72%)
```

### JSON

```json
{"session":45,"weekly":72,"highest":72,"burnRate":"medium"}
```

### Minimal (for prompts)

```
86%
```

### Verbose

```
Claude Usage
  Session (5h):  45% ████████░░░░░░░░ (resets in 2h)
  Weekly:        72% ██████████████░░ (resets Fri)
  Burn Rate:     Medium (15%/hr)
```

---

## CLI Interface

### Command

ClaudeApp provides a CLI interface via the main binary:

```bash
# Basic usage (reads from cached data)
claudeapp --status

# With format option
claudeapp --status --format json
claudeapp --status --format minimal
claudeapp --status --format verbose

# Force refresh (fetches from API)
claudeapp --status --refresh

# Specific metric only
claudeapp --status --metric session
claudeapp --status --metric weekly
claudeapp --status --metric highest
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Not authenticated |
| 2 | API error |
| 3 | Stale data (>15 min old) |

---

## Implementation

### CLI Handler

```swift
import ArgumentParser

@main
struct ClaudeAppCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "claudeapp",
        abstract: "ClaudeApp - Claude Code usage monitor"
    )

    @Flag(name: .long, help: "Output usage status")
    var status = false

    @Option(name: .long, help: "Output format: plain, json, minimal, verbose")
    var format: OutputFormat = .plain

    @Option(name: .long, help: "Specific metric: session, weekly, highest")
    var metric: Metric?

    @Flag(name: .long, help: "Force refresh from API")
    var refresh = false

    enum OutputFormat: String, ExpressibleByArgument {
        case plain, json, minimal, verbose
    }

    enum Metric: String, ExpressibleByArgument {
        case session, weekly, highest
    }

    func run() throws {
        guard status else {
            // Launch GUI app normally
            launchGUI()
            return
        }

        // CLI mode: output status
        let usageData = try fetchUsageData(forceRefresh: refresh)
        let output = formatOutput(usageData, format: format, metric: metric)
        print(output)
    }

    private func fetchUsageData(forceRefresh: Bool) throws -> UsageData {
        // Read from shared cache or fetch fresh
        if forceRefresh {
            // Fetch from API
            let credentials = try KeychainCredentialsRepository().getCredentialsSync()
            let client = ClaudeAPIClient(credentials: credentials)
            return try client.fetchUsageSync()
        } else {
            // Read from shared UserDefaults cache
            guard let defaults = UserDefaults(suiteName: "group.com.kaduwaengertner.ClaudeApp"),
                  let data = defaults.data(forKey: "cachedUsageData"),
                  let usage = try? JSONDecoder().decode(UsageData.self, from: data) else {
                throw CLIError.noCache
            }
            return usage
        }
    }

    private func formatOutput(_ data: UsageData, format: OutputFormat, metric: Metric?) -> String {
        switch format {
        case .plain:
            if let metric = metric {
                return formatMetric(data, metric: metric)
            }
            return "\(Int(data.highestUtilization))% (5h: \(Int(data.fiveHour.utilization))%, 7d: \(Int(data.sevenDay.utilization))%)"

        case .json:
            let payload = [
                "session": Int(data.fiveHour.utilization),
                "weekly": Int(data.sevenDay.utilization),
                "highest": Int(data.highestUtilization),
                "burnRate": data.highestBurnRate?.level.rawValue ?? "unknown"
            ]
            let jsonData = try! JSONEncoder().encode(payload)
            return String(data: jsonData, encoding: .utf8)!

        case .minimal:
            if let metric = metric {
                return "\(Int(metricValue(data, metric: metric)))%"
            }
            return "\(Int(data.highestUtilization))%"

        case .verbose:
            return formatVerbose(data)
        }
    }

    private func formatMetric(_ data: UsageData, metric: Metric) -> String {
        let value = metricValue(data, metric: metric)
        return "\(Int(value))%"
    }

    private func metricValue(_ data: UsageData, metric: Metric) -> Double {
        switch metric {
        case .session: return data.fiveHour.utilization
        case .weekly: return data.sevenDay.utilization
        case .highest: return data.highestUtilization
        }
    }

    private func formatVerbose(_ data: UsageData) -> String {
        var output = "Claude Usage\n"
        output += "  Session (5h):  \(Int(data.fiveHour.utilization))% \(progressBar(data.fiveHour.utilization))\n"
        output += "  Weekly:        \(Int(data.sevenDay.utilization))% \(progressBar(data.sevenDay.utilization))\n"
        if let burnRate = data.highestBurnRate {
            output += "  Burn Rate:     \(burnRate.level.rawValue) (\(burnRate.displayString))"
        }
        return output
    }

    private func progressBar(_ value: Double, width: Int = 16) -> String {
        let filled = Int(value / 100 * Double(width))
        let empty = width - filled
        return String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
    }
}
```

### Shared Data with GUI

CLI reads from same cache as GUI app:

```swift
// In UsageManager (GUI app)
func updateCache(_ data: UsageData) {
    guard let defaults = UserDefaults(suiteName: "group.com.kaduwaengertner.ClaudeApp") else { return }
    if let encoded = try? JSONEncoder().encode(data) {
        defaults.set(encoded, forKey: "cachedUsageData")
        defaults.set(Date(), forKey: "cachedUsageTimestamp")
    }
}
```

---

## Shell Integration

### Bash Prompt

```bash
# ~/.bashrc
claude_usage() {
    /Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp --status --format minimal 2>/dev/null || echo "--"
}

# Add to PS1
PS1='\u@\h:\w [Claude: $(claude_usage)] \$ '
```

### Zsh Prompt

```zsh
# ~/.zshrc
claude_usage() {
    /Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp --status --format minimal 2>/dev/null || echo "--"
}

# With color
PROMPT='%n@%m:%~ [Claude: %F{yellow}$(claude_usage)%f] %# '
```

### Starship

```toml
# ~/.config/starship.toml
[custom.claude]
command = "/Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp --status --format minimal"
when = "test -f /Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp"
format = "[Claude: $output]($style) "
style = "yellow"
```

### Tmux

```bash
# ~/.tmux.conf
set -g status-right '#(/Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp --status --format minimal) | %H:%M'
set -g status-interval 60  # Update every minute
```

### Oh My Zsh Plugin

Create `~/.oh-my-zsh/custom/plugins/claudeapp/claudeapp.plugin.zsh`:

```zsh
# Claude usage prompt segment
function claude_usage_prompt_info() {
    local usage=$(/Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp --status --format minimal 2>/dev/null)
    if [[ -n "$usage" ]]; then
        local color="green"
        local value=${usage%\%}
        if [[ $value -ge 90 ]]; then
            color="red"
        elif [[ $value -ge 50 ]]; then
            color="yellow"
        fi
        echo "%{$fg[$color]%}⚡${usage}%{$reset_color%}"
    fi
}
```

---

## Caching Strategy

### Cache Location

```
~/Library/Application Support/ClaudeApp/usage-cache.json
```

### Cache Format

```json
{
  "data": { ... },
  "timestamp": "2026-01-26T12:00:00Z",
  "ttl": 300
}
```

### Stale Data Handling

| Age | Behavior |
|-----|----------|
| < 5 min | Return cached data |
| 5-15 min | Return cached with warning (exit code 3) |
| > 15 min | Return cached with warning, suggest `--refresh` |

---

## Performance Considerations

### Fast Path (No Network)

1. CLI reads from local cache file
2. No GUI launch required
3. Target: < 50ms response time

### Slow Path (Network)

1. `--refresh` flag triggers API call
2. Updates cache for future reads
3. Target: < 2s response time

### Background Updates

GUI app keeps cache fresh - CLI just reads.

---

## Acceptance Criteria

### Must Have

- [x] `--status` flag outputs usage data
- [x] `--format` option for plain/json/minimal/verbose
- [x] Reads from shared cache with GUI app
- [x] Exit codes indicate status

### Should Have

- [x] `--refresh` flag to force API update
- [x] `--metric` option for specific values
- [x] Documentation for shell integration
- [x] Color output for verbose mode

### Nice to Have

- [ ] Shell completion scripts
- [x] Oh My Zsh plugin
- [x] Starship custom module
- [ ] Man page

---

## Distribution

### Symlink Creation

Add to installation instructions:

```bash
# Create symlink for easier CLI access
sudo ln -sf /Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp /usr/local/bin/claudeapp
```

### Homebrew Formula

```ruby
# In Homebrew cask
postflight do
  system_command "/bin/ln",
    args: ["-sf", "#{appdir}/ClaudeApp.app/Contents/MacOS/ClaudeApp", "/usr/local/bin/claudeapp"],
    sudo: true
end
```

---

## Related Specifications

- [view-usage.md](./view-usage.md) - Usage data model
- [architecture.md](../architecture.md) - Shared data layer
- [toolchain.md](../toolchain.md) - Build configuration
