// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClaudeApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClaudeApp", targets: ["ClaudeApp"])
    ],
    dependencies: [],
    targets: [
        // Main app executable
        .executableTarget(
            name: "ClaudeApp",
            dependencies: [
                "Domain",
                "Services",
                "Core",
                "UI"
            ],
            path: "App",
            resources: [
                .process("Localizable.xcstrings")
            ]
        ),

        // Domain package - Core business models (LEAF - no internal deps)
        .target(
            name: "Domain",
            dependencies: [],
            path: "Packages/Domain/Sources/Domain"
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"],
            path: "Packages/Domain/Tests/DomainTests"
        ),

        // Services package - External integrations
        .target(
            name: "Services",
            dependencies: ["Domain"],
            path: "Packages/Services/Sources/Services"
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["Services"],
            path: "Packages/Services/Tests/ServicesTests"
        ),

        // Core package - Business logic & use cases
        .target(
            name: "Core",
            dependencies: ["Domain", "Services"],
            path: "Packages/Core/Sources/Core"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Packages/Core/Tests/CoreTests"
        ),

        // UI package - SwiftUI presentation layer
        .target(
            name: "UI",
            dependencies: ["Domain", "Core"],
            path: "Packages/UI/Sources/UI"
        ),
        .testTarget(
            name: "UITests",
            dependencies: ["UI"],
            path: "Packages/UI/Tests/UITests"
        )
    ]
)
