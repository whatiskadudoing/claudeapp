# Terminal Integration Guide

ClaudeApp provides a command-line interface (CLI) for monitoring Claude Code usage directly in your terminal. This enables usage visibility in shell prompts, tmux status bars, and scripts without leaving your command-line workflow.

## Quick Start

```bash
# Install CLI symlink (one-time setup)
./scripts/install-cli.sh

# Check usage
claudeapp --status

# Add to your prompt
# See shell-specific sections below
```

## CLI Reference

### Basic Usage

```bash
# Output usage status (reads from cached data)
claudeapp --status

# Force refresh from API (updates cache)
claudeapp --status --refresh

# Show version
claudeapp --version

# Show help
claudeapp --help
```

### Output Formats

Use `--format` to control output format:

| Format | Description | Example Output |
|--------|-------------|----------------|
| `plain` (default) | Human-readable | `86% (5h: 45%, 7d: 72%)` |
| `minimal` | Single value | `86%` |
| `json` | Structured JSON | `{"session":45,"weekly":72,...}` |
| `verbose` | Multi-line with bars | See below |

#### Plain Format (Default)

```bash
$ claudeapp --status
86% (5h: 45%, 7d: 72%)
```

#### Minimal Format

```bash
$ claudeapp --status --format minimal
86%
```

#### JSON Format

```bash
$ claudeapp --status --format json
{"burnRate":"medium","burnRatePerHour":15.5,"fetchedAt":"2026-01-30T10:30:00Z","freshness":"fresh","highest":72,"opus":15,"session":45,"sonnet":68,"weekly":72}
```

#### Verbose Format

```bash
$ claudeapp --status --format verbose
Claude Usage

  Session (5h)  45% ███████░░░░░░░░░ (resets in 2 hr)
  Weekly        72% ███████████░░░░░ (resets in 3 days)
  Opus          15% ██░░░░░░░░░░░░░░ (resets in 3 days)
  Sonnet        68% ██████████░░░░░░ (resets in 3 days)

  Burn Rate:     Medium (15%/hr)
```

### Metric Selection

Use `--metric` to output a specific value:

```bash
# Session (5-hour window)
claudeapp --status --metric session
# Output: 45%

# Weekly (7-day window)
claudeapp --status --metric weekly
# Output: 72%

# Highest across all windows
claudeapp --status --metric highest
# Output: 72%

# Opus-specific weekly quota
claudeapp --status --metric opus
# Output: 15%

# Sonnet-specific weekly quota
claudeapp --status --metric sonnet
# Output: 68%
```

### Color Output

Verbose output uses ANSI colors when running in a terminal:
- **Green**: 0-49% usage (safe)
- **Yellow**: 50-89% usage (moderate)
- **Red**: 90-100% usage (critical)

Disable colors with `--no-color`:

```bash
claudeapp --status --format verbose --no-color
```

### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | Data retrieved successfully |
| 1 | Not authenticated | Run `claude login` to connect |
| 2 | API error | Check network/credentials |
| 3 | Stale data | Cache is >15 min old |

Use exit codes in scripts:

```bash
if claudeapp --status --format minimal > /dev/null 2>&1; then
    echo "Claude connected"
else
    case $? in
        1) echo "Not authenticated" ;;
        2) echo "API error" ;;
        3) echo "Data is stale" ;;
    esac
fi
```

---

## Installation

### Option 1: Install Script (Recommended)

```bash
# From the ClaudeApp directory
./scripts/install-cli.sh

# Or specify a custom location
./scripts/install-cli.sh /usr/local/bin
```

This creates a symlink at `/usr/local/bin/claudeapp` pointing to the ClaudeApp binary.

### Option 2: Manual Symlink

```bash
sudo ln -sf /Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp /usr/local/bin/claudeapp
```

### Option 3: Shell Alias

Add to your shell config (`~/.bashrc`, `~/.zshrc`):

```bash
alias claudeapp='/Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp'
```

### Verify Installation

```bash
claudeapp --version
# Output: ClaudeApp 1.9.0
```

---

## Shell Prompt Integration

### Bash

Add to `~/.bashrc`:

```bash
# Claude usage function
claude_usage() {
    claudeapp --status --format minimal 2>/dev/null || echo "--"
}

# Add to prompt
PS1='\u@\h:\w [Claude: $(claude_usage)] \$ '
```

**With color:**

```bash
claude_usage_colored() {
    local usage=$(claudeapp --status --format minimal 2>/dev/null)
    if [[ -n "$usage" ]]; then
        local value=${usage%\%}
        local color=""
        if [[ $value -ge 90 ]]; then
            color="\033[31m"  # Red
        elif [[ $value -ge 50 ]]; then
            color="\033[33m"  # Yellow
        else
            color="\033[32m"  # Green
        fi
        echo -e "${color}${usage}\033[0m"
    else
        echo "--"
    fi
}

PS1='\u@\h:\w [Claude: $(claude_usage_colored)] \$ '
```

### Zsh

Add to `~/.zshrc`:

```zsh
# Claude usage function
claude_usage() {
    claudeapp --status --format minimal 2>/dev/null || echo "--"
}

# Add to prompt (right side)
RPROMPT='[Claude: %F{yellow}$(claude_usage)%f]'

# Or left side
PROMPT='%n@%m:%~ [Claude: %F{yellow}$(claude_usage)%f] %# '
```

**With dynamic color:**

```zsh
claude_usage_prompt() {
    local usage=$(claudeapp --status --format minimal 2>/dev/null)
    if [[ -n "$usage" ]]; then
        local value=${usage%\%}
        local color="green"
        if [[ $value -ge 90 ]]; then
            color="red"
        elif [[ $value -ge 50 ]]; then
            color="yellow"
        fi
        echo "%F{$color}${usage}%f"
    else
        echo "--"
    fi
}

RPROMPT='[Claude: $(claude_usage_prompt)]'
```

### Fish

Add to `~/.config/fish/config.fish`:

```fish
function claude_usage
    set -l usage (claudeapp --status --format minimal 2>/dev/null)
    if test -n "$usage"
        set -l value (string replace '%' '' $usage)
        if test $value -ge 90
            set_color red
        else if test $value -ge 50
            set_color yellow
        else
            set_color green
        end
        echo -n $usage
        set_color normal
    else
        echo -n "--"
    end
end

function fish_right_prompt
    echo -n "[Claude: "
    claude_usage
    echo "]"
end
```

---

## Starship Integration

[Starship](https://starship.rs) is a cross-shell prompt that supports custom modules.

Add to `~/.config/starship.toml`:

```toml
[custom.claude]
command = "claudeapp --status --format minimal"
when = "test -x /Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp"
format = "[Claude: $output]($style) "
style = "yellow"
```

**With conditional styling:**

```toml
[custom.claude]
command = """
usage=$(claudeapp --status --format minimal 2>/dev/null)
value=${usage%\%}
if [ "$value" -ge 90 ]; then
    echo "🔴 $usage"
elif [ "$value" -ge 50 ]; then
    echo "🟡 $usage"
else
    echo "🟢 $usage"
fi
"""
when = "test -x /Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp"
shell = ["bash", "--noprofile", "--norc"]
format = "[$output]($style) "
style = "bold"
```

---

## Tmux Integration

Add to `~/.tmux.conf`:

```bash
# Show usage in status bar (right side)
set -g status-right '#(claudeapp --status --format minimal 2>/dev/null || echo "--") | %H:%M'

# Update every 60 seconds
set -g status-interval 60
```

**With color:**

```bash
# Claude usage with color
set -g status-right '#[fg=yellow]Claude: #(claudeapp --status --format minimal 2>/dev/null || echo "--")#[default] | %H:%M'
```

**With detailed info:**

```bash
# Show more detail
set -g status-right '#(claudeapp --status --format plain 2>/dev/null || echo "Claude: --") | %H:%M'
```

Reload tmux config: `tmux source-file ~/.tmux.conf`

---

## Oh My Zsh Plugin

Create a custom plugin for Oh My Zsh.

### Installation

```bash
# Create plugin directory
mkdir -p ~/.oh-my-zsh/custom/plugins/claudeapp

# Create plugin file
cat > ~/.oh-my-zsh/custom/plugins/claudeapp/claudeapp.plugin.zsh << 'EOF'
# ClaudeApp Oh My Zsh Plugin
# Provides claude_usage_prompt_info function for prompt integration

# Claude usage prompt segment
function claude_usage_prompt_info() {
    local usage=$(claudeapp --status --format minimal 2>/dev/null)
    if [[ -n "$usage" ]]; then
        local value=${usage%\%}
        local color="green"
        if [[ $value -ge 90 ]]; then
            color="red"
        elif [[ $value -ge 50 ]]; then
            color="yellow"
        fi
        echo "%{$fg[$color]%}⚡${usage}%{$reset_color%}"
    fi
}

# Alias for quick status check
alias claude-usage='claudeapp --status --format verbose'
alias cu='claudeapp --status --format minimal'
EOF
```

### Enable Plugin

Edit `~/.zshrc`:

```zsh
plugins=(
    git
    # ... other plugins
    claudeapp
)
```

### Use in Theme

Add to your prompt theme:

```zsh
PROMPT='$(claude_usage_prompt_info) %n@%m:%~ %# '
# Or
RPROMPT='$(claude_usage_prompt_info)'
```

---

## Scripting Examples

### Watch Usage

```bash
# Update every 30 seconds
watch -n 30 'claudeapp --status --format verbose'
```

### Log Usage Over Time

```bash
#!/bin/bash
# Log usage to CSV file
LOG_FILE="$HOME/.claude-usage.csv"

# Create header if file doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    echo "timestamp,session,weekly,highest,burnRate" > "$LOG_FILE"
fi

# Get JSON and parse with jq
JSON=$(claudeapp --status --format json 2>/dev/null)
if [ -n "$JSON" ]; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    SESSION=$(echo "$JSON" | jq -r '.session')
    WEEKLY=$(echo "$JSON" | jq -r '.weekly')
    HIGHEST=$(echo "$JSON" | jq -r '.highest')
    BURNRATE=$(echo "$JSON" | jq -r '.burnRate')
    echo "$TIMESTAMP,$SESSION,$WEEKLY,$HIGHEST,$BURNRATE" >> "$LOG_FILE"
fi
```

### Alert on High Usage

```bash
#!/bin/bash
# Send notification when usage exceeds threshold
THRESHOLD=90

usage=$(claudeapp --status --format minimal 2>/dev/null)
value=${usage%\%}

if [ "$value" -ge "$THRESHOLD" ]; then
    osascript -e "display notification \"Claude usage at ${usage}\" with title \"Usage Warning\""
fi
```

### Pre-Commit Hook

```bash
#!/bin/bash
# Warn before commit if Claude usage is high
# Save as .git/hooks/pre-commit

usage=$(claudeapp --status --format minimal 2>/dev/null)
value=${usage%\%}

if [ "$value" -ge 90 ]; then
    echo "⚠️  Claude usage is at ${usage} - approaching limit"
    read -p "Continue with commit? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
```

---

## Caching Behavior

### How It Works

1. The **GUI app** fetches usage data and writes it to a shared cache
2. The **CLI** reads from this shared cache for fast, instant responses
3. Cache is stored in App Group UserDefaults (`group.com.kaduwaengertner.ClaudeApp`)

### Freshness States

| Age | State | Exit Code | Behavior |
|-----|-------|-----------|----------|
| < 5 min | Fresh | 0 | Normal operation |
| 5-15 min | Stale | 3 | Returns data with `[stale]` warning |
| > 15 min | Expired | 3 | Returns data with `[expired]` warning |

### Force Refresh

If data is stale or you need the latest:

```bash
claudeapp --status --refresh
```

This fetches directly from the API and updates the cache.

### Keeping Cache Fresh

For the best CLI experience, keep the GUI app running in the menu bar. It automatically refreshes the cache at your configured interval (default: 5 minutes).

---

## Troubleshooting

### Command Not Found

```bash
# Check if symlink exists
ls -la /usr/local/bin/claudeapp

# Reinstall symlink
./scripts/install-cli.sh
```

### Not Authenticated

```bash
$ claudeapp --status
Error: Not authenticated. Run 'claude login' to connect.
```

Run `claude login` in your terminal to authenticate Claude Code.

### Stale Data Warning

```bash
$ claudeapp --status
72% (5h: 45%, 7d: 72%) [stale]
```

The GUI app hasn't refreshed recently. Either:
- Launch ClaudeApp GUI to refresh cache
- Use `--refresh` flag to fetch directly

### No Output in Prompt

Check that:
1. ClaudeApp is installed in `/Applications/`
2. Symlink or alias is configured
3. Function is defined before prompt variable
4. Shell config is sourced (`source ~/.zshrc`)

### Slow Prompt

The CLI reads from cache and should respond in <50ms. If slow:
1. Check if `--refresh` is accidentally being used (causes API call)
2. Verify ClaudeApp is installed on fast storage
3. Consider caching the output in your prompt function:

```bash
# Cache output for 60 seconds
_claude_cache=""
_claude_cache_time=0

claude_usage_cached() {
    local now=$(date +%s)
    if [ $((now - _claude_cache_time)) -gt 60 ]; then
        _claude_cache=$(claudeapp --status --format minimal 2>/dev/null)
        _claude_cache_time=$now
    fi
    echo "${_claude_cache:-"--"}"
}
```

---

## Related Documentation

- [Installation Guide](installation.md) - Install ClaudeApp
- [Usage Guide](usage.md) - GUI features
- [Troubleshooting](troubleshooting.md) - Common issues
- [FAQ](faq.md) - Frequently asked questions
