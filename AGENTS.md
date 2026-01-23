# AGENTS.md - Operational Guide

<!-- KEEP THIS FILE BRIEF (~60 lines max). It loads every iteration. -->
<!-- Only operational commands and patterns. NO status updates here. -->

## Commands

- **Build:** `swift build` or `make build`
- **Test:** `swift test` or `make test`
- **Lint:** `make lint` (requires swiftlint)
- **Format:** `make format` (requires swiftformat)
- **Clean:** `make clean`
- **Run:** `make run`
- **Dev:** `make dev` (opens in Xcode)

## Validation (Backpressure)

Before marking task complete, ALL must pass:
1. Build succeeds (`swift build`)
2. Tests pass (`swift test`)
3. No compile errors

If any fail → fix before committing.

## Patterns

- Package structure: Domain → Services → Core → UI (dependencies flow downward)
- Domain is LEAF (no internal deps)
- Main app in `App/ClaudeApp.swift`
- Each package: `Packages/{Name}/Sources/{Name}/` and `Packages/{Name}/Tests/{Name}Tests/`
- Tests use Swift Testing framework (`@Suite`, `@Test`, `#expect`)

## Notes

- SPM doesn't allow Info.plist as a resource; MenuBarExtra works without explicit plist
- `xcbeautify` is optional for prettier build output
- Use `swift test --filter {PackageName}Tests` to run specific package tests

## Localization

- SPM doesn't compile `.xcstrings` to runtime format - use `scripts/compile-strings.py`
- App target uses `L("key")` helper for localized strings (uses `Bundle.module`)
- UI package uses `Bundle.main.localizedString()` - works because release bundle has compiled strings
- Release builds: `make release` runs `compile-strings.py` automatically
