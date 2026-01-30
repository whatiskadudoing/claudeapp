import Foundation

// MARK: - Application Entry Point
//
// This is the main entry point for ClaudeApp.
// It detects whether to run in CLI mode or GUI mode based on command-line arguments.
//
// CLI mode: When --status, --version, or --help flags are present
// GUI mode: Normal menu bar app launch
//
// This approach allows us to use ArgumentParser for CLI while maintaining
// the SwiftUI App lifecycle for the GUI.

/// Check if we should run in CLI mode based on command-line arguments.
/// CLI mode is triggered by: --status, --version, --help, -h
private func shouldRunCLI() -> Bool {
    let args = CommandLine.arguments

    // Skip the first argument (executable path)
    let flags = args.dropFirst()

    // CLI mode if any of these flags are present
    let cliFlags = ["--status", "--version", "--help", "-h"]

    for flag in flags {
        if cliFlags.contains(flag) {
            return true
        }
    }

    return false
}

// Route to appropriate entry point
if shouldRunCLI() {
    // Run CLI mode
    CLIHandler.main()
} else {
    // Run GUI mode
    ClaudeAppMain.main()
}
