# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

Only the latest release receives security updates. We recommend always running the most recent version.

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in ClaudeApp, please report it responsibly.

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email the maintainer directly at the email listed in the repository
3. Or use [GitHub's private vulnerability reporting](https://github.com/kaduwaengertner/claudeapp/security/advisories/new)

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 7 days
- **Resolution Target**: Within 30 days for critical issues

### What to Expect

1. We will acknowledge receipt of your report
2. We will investigate and validate the issue
3. We will work on a fix and coordinate disclosure
4. We will credit you in the release notes (unless you prefer anonymity)

## Security Considerations

### Data Handling

ClaudeApp:
- Reads OAuth credentials from macOS Keychain (read-only, never stored)
- Communicates only with `api.anthropic.com` over HTTPS
- Stores user preferences locally in UserDefaults
- Does NOT access conversation content
- Does NOT send data to third parties

### Permissions

ClaudeApp requires:
- Keychain access (to read Claude Code credentials)
- Network access (to fetch usage data from Anthropic API)
- Notification permission (optional, for usage alerts)

### Code Signing

ClaudeApp is currently distributed unsigned. Users must bypass Gatekeeper on first launch. We recommend:
- Downloading only from official GitHub releases
- Verifying the SHA256 checksum listed in release notes

## Acknowledgments

We appreciate security researchers who help keep ClaudeApp safe. Contributors who report valid vulnerabilities will be acknowledged in our release notes.
