import SwiftUI

@main
struct ClaudeApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Label("ClaudeApp", systemImage: "chart.bar.fill")
        }
        .menuBarExtraStyle(.window)
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("ClaudeApp")
                .font(.headline)
            Text("Usage Monitor")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 280)
    }
}
