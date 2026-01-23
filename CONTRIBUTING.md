# Contributing to ClaudeApp

Thank you for your interest in contributing to ClaudeApp! This guide will help you get started with development and make your first contribution.

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing. We're committed to providing a welcoming and inclusive environment for everyone.

## Ways to Contribute

### Bug Reports

1. Check [existing issues](https://github.com/kaduwaengertner/claudeapp/issues) first
2. Create a new issue with:
   - macOS version
   - ClaudeApp version (from Settings > About)
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable

### Feature Requests

1. Check [existing discussions](https://github.com/kaduwaengertner/claudeapp/discussions) first
2. Open a new discussion describing:
   - The problem you're trying to solve
   - Your proposed solution
   - Alternative approaches considered

### Code Contributions

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Run `make check` (must pass)
5. Submit a pull request

## Development Setup

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| macOS | 14.0+ (Sonoma) | Target platform |
| Xcode | 15.0+ | Swift compiler, SDKs |
| Swift | 5.9+ | Language version |
| Make | Any | Build automation |

### Optional Tools

```bash
brew install swiftformat   # Code formatting
brew install swiftlint     # Code linting
brew install xcbeautify    # Pretty build output
brew install fswatch       # Hot reload mode
```

### Initial Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/claudeapp.git
cd claudeapp

# Set up git hooks and resolve dependencies
make setup

# Build and run
make run
```

### Available Commands

```bash
# Building
make build           # Debug build
make build-release   # Release build
make run             # Build and run
make dev             # Open in Xcode

# Testing
make test            # Run all tests
make test-verbose    # Verbose output
make test-domain     # Domain package only
make test-services   # Services package only
make test-core       # Core package only
make test-ui         # UI package only

# Code Quality
make format          # Auto-format code
make lint            # Check linting
make lint-fix        # Auto-fix lint issues
make check           # Format + lint + test (CI gate)

# Cleaning
make clean           # Clean build artifacts
make reset           # Full reset + resolve deps

# Release
make release         # Build .app bundle
make dmg             # Create distributable DMG
```

## Project Architecture

ClaudeApp uses a modular multi-package architecture inspired by Domain-Driven Design:

```
Packages/
├── Domain/      # Models, protocols, errors (zero dependencies)
├── Services/    # API client, Keychain, external integrations
├── Core/        # Business logic, managers, use cases
└── UI/          # SwiftUI views, components, theme
```

**Dependency flow:** `App → UI → Core → Services → Domain`

The Domain package is a **leaf node** with no internal dependencies. Dependencies only flow downward—no circular dependencies allowed.

For detailed architecture documentation, see [specs/architecture.md](specs/architecture.md).

## Code Style

### SwiftFormat

We use SwiftFormat for consistent code formatting:

- 4-space indentation
- 120 character line limit
- Sorted imports
- Blank line after imports

Configuration is in `.swiftformat`. Run `make format` to auto-format.

### SwiftLint

We use SwiftLint for code quality:

- Force cast/try are errors
- Force unwrapping is a warning
- Function body limit: 50 lines (warning), 100 (error)
- Type body limit: 300 lines (warning), 500 (error)

Configuration is in `.swiftlint.yml`. Run `make lint` to check.

### Concurrency

- Use Swift Concurrency (`async/await`, `Task`)
- Use `actor` for thread-safe shared state
- Use `@MainActor` for UI state
- Mark models as `Sendable`
- Avoid completion handlers

### Testing

- Use Swift Testing framework (`@Test`, `@Suite`, `#expect`)
- Test files: `<SourceFile>Tests.swift`
- Group tests in suites by functionality
- Test edge cases and boundaries

Example:

```swift
@Suite("MyFeature Tests")
struct MyFeatureTests {
    @Test("Feature handles edge case correctly")
    func handlesEdgeCase() {
        let result = MyFeature.process(input: 0)
        #expect(result == expectedValue)
    }
}
```

## Commit Guidelines

### Message Format

Write clear, concise commit messages that explain **why** the change was made:

```
Add burn rate calculation to track usage velocity

The burn rate helps users understand how quickly they're consuming
their quota, enabling better planning of Claude Code usage sessions.
```

### Before Committing

The pre-commit hook (installed via `make setup`) will automatically:
1. Format staged Swift files with SwiftFormat
2. Lint staged files with SwiftLint

If linting fails, the commit will be blocked. Fix the issues and try again.

## Pull Request Process

### Before Submitting

- [ ] Code follows our style guide (run `make format`)
- [ ] All tests pass (run `make test`)
- [ ] Linting passes (run `make lint`)
- [ ] New features have tests
- [ ] Documentation updated if needed
- [ ] `make check` passes completely

### PR Guidelines

1. **Title**: Use a clear, descriptive title
2. **Description**: Explain what changes and why
3. **Reference**: Link related issues with "Closes #123" or "Fixes #456"
4. **Screenshots**: Include for UI changes
5. **Tests**: Describe how you tested the changes

### Review Process

1. Automated CI checks must pass
2. One maintainer review required
3. Address feedback promptly
4. Squash commits before merge

## Testing Requirements

### Coverage Goals

| Package | Target |
|---------|--------|
| Domain | 100% |
| Services | 90%+ |
| Core | 90%+ |
| UI | 70%+ |

### Running Specific Tests

```bash
# Run all tests
make test

# Run package-specific tests
make test-domain
make test-services
make test-core
make test-ui

# Run with verbose output
make test-verbose

# Filter specific tests
swift test --filter "BurnRateTests"
```

## Localization

ClaudeApp supports multiple languages. See [specs/internationalization.md](specs/internationalization.md) for the full guide.

### Currently Supported

| Language | Code |
|----------|------|
| English | en |
| Portuguese (Brazil) | pt-BR |
| Spanish (Latin America) | es |

### Adding Translations

1. Open `App/Localizable.xcstrings` in Xcode
2. Click "+" to add a new language
3. Translate all keys (105 strings)
4. Follow the glossary in `specs/internationalization.md`
5. Test with launch arguments: `-AppleLanguages "(pt-BR)"`
6. Submit PR with screenshots showing the new language

## Documentation

### Specifications

Technical specifications are in `specs/`:

- [architecture.md](specs/architecture.md) - Package structure and design
- [toolchain.md](specs/toolchain.md) - Build workflow and tooling
- [design-system.md](specs/design-system.md) - UI/UX specifications
- [api-documentation.md](specs/api-documentation.md) - API integration
- [accessibility.md](specs/accessibility.md) - WCAG 2.1 AA compliance
- [internationalization.md](specs/internationalization.md) - Localization
- [performance.md](specs/performance.md) - Performance requirements

### User Documentation

User-facing docs are in `docs/`:

- [installation.md](docs/installation.md) - How to install
- [usage.md](docs/usage.md) - How to use the app
- [troubleshooting.md](docs/troubleshooting.md) - Common issues
- [faq.md](docs/faq.md) - Frequently asked questions
- [privacy.md](docs/privacy.md) - Privacy policy

## Release Process

Releases are managed by maintainers:

1. Update version in `App/Info.plist`
2. Update `CHANGELOG.md`
3. Run `make clean && make check`
4. Run `make release && make dmg`
5. Tag: `git tag -a v1.x.0 -m "Release v1.x.0"`
6. Push: `git push origin v1.x.0`
7. GitHub Actions creates the release automatically

## Getting Help

- **Questions**: Open a [GitHub Discussion](https://github.com/kaduwaengertner/claudeapp/discussions)
- **Bugs**: Create a [GitHub Issue](https://github.com/kaduwaengertner/claudeapp/issues)
- **Security**: See [SECURITY.md](SECURITY.md) for reporting vulnerabilities

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

Thank you for contributing to ClaudeApp!
