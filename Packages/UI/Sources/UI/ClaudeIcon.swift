import SwiftUI

/// Claude brand icon rendered as a SwiftUI Shape.
/// Uses the official Claude icon SVG path from lobe-icons.
/// Color: #D97757 (Claude coral/terracotta)
public struct ClaudeIconShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        // Original viewBox: 0 0 24 24
        let scale = min(rect.width, rect.height) / 24.0
        let xOffset = (rect.width - 24 * scale) / 2
        let yOffset = (rect.height - 24 * scale) / 2

        var path = Path()

        // Claude icon SVG path data
        path.move(to: CGPoint(x: 4.709 * scale + xOffset, y: 15.955 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.429 * scale + xOffset, y: 13.308 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.509 * scale + xOffset, y: 13.078 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.429 * scale + xOffset, y: 12.95 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.2 * scale + xOffset, y: 12.95 * scale + yOffset))
        path.addLine(to: CGPoint(x: 8.41 * scale + xOffset, y: 12.902 * scale + yOffset))
        path.addLine(to: CGPoint(x: 5.712 * scale + xOffset, y: 12.829 * scale + yOffset))
        path.addLine(to: CGPoint(x: 3.373 * scale + xOffset, y: 12.732 * scale + yOffset))
        path.addLine(to: CGPoint(x: 1.107 * scale + xOffset, y: 12.61 * scale + yOffset))
        path.addLine(to: CGPoint(x: 0.536 * scale + xOffset, y: 12.489 * scale + yOffset))
        path.addLine(to: CGPoint(x: 0 * scale + xOffset, y: 11.784 * scale + yOffset))
        path.addLine(to: CGPoint(x: 0.055 * scale + xOffset, y: 11.432 * scale + yOffset))
        path.addLine(to: CGPoint(x: 0.535 * scale + xOffset, y: 11.111 * scale + yOffset))
        path.addLine(to: CGPoint(x: 1.221 * scale + xOffset, y: 11.171 * scale + yOffset))
        path.addLine(to: CGPoint(x: 2.741 * scale + xOffset, y: 11.274 * scale + yOffset))
        path.addLine(to: CGPoint(x: 5.019 * scale + xOffset, y: 11.432 * scale + yOffset))
        path.addLine(to: CGPoint(x: 6.671 * scale + xOffset, y: 11.529 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.12 * scale + xOffset, y: 11.784 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.509 * scale + xOffset, y: 11.784 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.564 * scale + xOffset, y: 11.627 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.43 * scale + xOffset, y: 11.529 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.327 * scale + xOffset, y: 11.432 * scale + yOffset))
        path.addLine(to: CGPoint(x: 6.969 * scale + xOffset, y: 9.836 * scale + yOffset))
        path.addLine(to: CGPoint(x: 4.417 * scale + xOffset, y: 8.148 * scale + yOffset))
        path.addLine(to: CGPoint(x: 3.081 * scale + xOffset, y: 7.176 * scale + yOffset))
        path.addLine(to: CGPoint(x: 2.357 * scale + xOffset, y: 6.685 * scale + yOffset))
        path.addLine(to: CGPoint(x: 1.993 * scale + xOffset, y: 6.223 * scale + yOffset))
        path.addLine(to: CGPoint(x: 1.835 * scale + xOffset, y: 5.215 * scale + yOffset))
        path.addLine(to: CGPoint(x: 2.491 * scale + xOffset, y: 4.493 * scale + yOffset))
        path.addLine(to: CGPoint(x: 3.372 * scale + xOffset, y: 4.553 * scale + yOffset))
        path.addLine(to: CGPoint(x: 3.597 * scale + xOffset, y: 4.614 * scale + yOffset))
        path.addLine(to: CGPoint(x: 4.49 * scale + xOffset, y: 5.3 * scale + yOffset))
        path.addLine(to: CGPoint(x: 6.398 * scale + xOffset, y: 6.776 * scale + yOffset))
        path.addLine(to: CGPoint(x: 8.889 * scale + xOffset, y: 8.609 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.254 * scale + xOffset, y: 8.913 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.399 * scale + xOffset, y: 8.81 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.418 * scale + xOffset, y: 8.737 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.254 * scale + xOffset, y: 8.463 * scale + yOffset))
        path.addLine(to: CGPoint(x: 7.899 * scale + xOffset, y: 6.017 * scale + yOffset))
        path.addLine(to: CGPoint(x: 6.453 * scale + xOffset, y: 3.527 * scale + yOffset))
        path.addLine(to: CGPoint(x: 5.809 * scale + xOffset, y: 2.495 * scale + yOffset))
        path.addLine(to: CGPoint(x: 5.639 * scale + xOffset, y: 1.876 * scale + yOffset))
        path.addLine(to: CGPoint(x: 5.535 * scale + xOffset, y: 1.147 * scale + yOffset))
        path.addLine(to: CGPoint(x: 6.283 * scale + xOffset, y: 0.134 * scale + yOffset))
        path.addLine(to: CGPoint(x: 6.696 * scale + xOffset, y: 0 * scale + yOffset))
        path.addLine(to: CGPoint(x: 7.692 * scale + xOffset, y: 0.134 * scale + yOffset))
        path.addLine(to: CGPoint(x: 8.112 * scale + xOffset, y: 0.498 * scale + yOffset))
        path.addLine(to: CGPoint(x: 8.732 * scale + xOffset, y: 1.912 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.734 * scale + xOffset, y: 4.141 * scale + yOffset))
        path.addLine(to: CGPoint(x: 11.289 * scale + xOffset, y: 7.171 * scale + yOffset))
        path.addLine(to: CGPoint(x: 11.745 * scale + xOffset, y: 8.069 * scale + yOffset))
        path.addLine(to: CGPoint(x: 11.988 * scale + xOffset, y: 8.901 * scale + yOffset))
        path.addLine(to: CGPoint(x: 12.079 * scale + xOffset, y: 9.156 * scale + yOffset))
        path.addLine(to: CGPoint(x: 12.237 * scale + xOffset, y: 9.156 * scale + yOffset))
        path.addLine(to: CGPoint(x: 12.237 * scale + xOffset, y: 9.01 * scale + yOffset))
        path.addLine(to: CGPoint(x: 12.365 * scale + xOffset, y: 7.304 * scale + yOffset))
        path.addLine(to: CGPoint(x: 12.602 * scale + xOffset, y: 5.209 * scale + yOffset))
        path.addLine(to: CGPoint(x: 12.832 * scale + xOffset, y: 2.514 * scale + yOffset))
        path.addLine(to: CGPoint(x: 12.912 * scale + xOffset, y: 1.754 * scale + yOffset))
        path.addLine(to: CGPoint(x: 13.288 * scale + xOffset, y: 0.844 * scale + yOffset))
        path.addLine(to: CGPoint(x: 14.035 * scale + xOffset, y: 0.352 * scale + yOffset))
        path.addLine(to: CGPoint(x: 14.619 * scale + xOffset, y: 0.632 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.099 * scale + xOffset, y: 1.317 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.032 * scale + xOffset, y: 1.761 * scale + yOffset))
        path.addLine(to: CGPoint(x: 14.746 * scale + xOffset, y: 3.612 * scale + yOffset))
        path.addLine(to: CGPoint(x: 14.187 * scale + xOffset, y: 6.515 * scale + yOffset))
        path.addLine(to: CGPoint(x: 13.823 * scale + xOffset, y: 8.457 * scale + yOffset))
        path.addLine(to: CGPoint(x: 14.035 * scale + xOffset, y: 8.457 * scale + yOffset))
        path.addLine(to: CGPoint(x: 14.278 * scale + xOffset, y: 8.215 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.263 * scale + xOffset, y: 6.909 * scale + yOffset))
        path.addLine(to: CGPoint(x: 16.915 * scale + xOffset, y: 4.845 * scale + yOffset))
        path.addLine(to: CGPoint(x: 17.645 * scale + xOffset, y: 4.025 * scale + yOffset))
        path.addLine(to: CGPoint(x: 18.495 * scale + xOffset, y: 3.121 * scale + yOffset))
        path.addLine(to: CGPoint(x: 19.042 * scale + xOffset, y: 2.69 * scale + yOffset))
        path.addLine(to: CGPoint(x: 20.075 * scale + xOffset, y: 2.69 * scale + yOffset))
        path.addLine(to: CGPoint(x: 20.835 * scale + xOffset, y: 3.819 * scale + yOffset))
        path.addLine(to: CGPoint(x: 20.495 * scale + xOffset, y: 4.985 * scale + yOffset))
        path.addLine(to: CGPoint(x: 19.431 * scale + xOffset, y: 6.332 * scale + yOffset))
        path.addLine(to: CGPoint(x: 18.55 * scale + xOffset, y: 7.474 * scale + yOffset))
        path.addLine(to: CGPoint(x: 17.286 * scale + xOffset, y: 9.174 * scale + yOffset))
        path.addLine(to: CGPoint(x: 16.496 * scale + xOffset, y: 10.534 * scale + yOffset))
        path.addLine(to: CGPoint(x: 16.569 * scale + xOffset, y: 10.644 * scale + yOffset))
        path.addLine(to: CGPoint(x: 16.757 * scale + xOffset, y: 10.624 * scale + yOffset))
        path.addLine(to: CGPoint(x: 19.613 * scale + xOffset, y: 10.018 * scale + yOffset))
        path.addLine(to: CGPoint(x: 21.156 * scale + xOffset, y: 9.738 * scale + yOffset))
        path.addLine(to: CGPoint(x: 22.997 * scale + xOffset, y: 9.423 * scale + yOffset))
        path.addLine(to: CGPoint(x: 23.83 * scale + xOffset, y: 9.811 * scale + yOffset))
        path.addLine(to: CGPoint(x: 23.921 * scale + xOffset, y: 10.206 * scale + yOffset))
        path.addLine(to: CGPoint(x: 23.593 * scale + xOffset, y: 11.013 * scale + yOffset))
        path.addLine(to: CGPoint(x: 21.624 * scale + xOffset, y: 11.499 * scale + yOffset))
        path.addLine(to: CGPoint(x: 19.315 * scale + xOffset, y: 11.961 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.876 * scale + xOffset, y: 12.774 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.834 * scale + xOffset, y: 12.804 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.883 * scale + xOffset, y: 12.865 * scale + yOffset))
        path.addLine(to: CGPoint(x: 17.432 * scale + xOffset, y: 13.011 * scale + yOffset))
        path.addLine(to: CGPoint(x: 18.094 * scale + xOffset, y: 13.047 * scale + yOffset))
        path.addLine(to: CGPoint(x: 19.716 * scale + xOffset, y: 13.047 * scale + yOffset))
        path.addLine(to: CGPoint(x: 22.736 * scale + xOffset, y: 13.272 * scale + yOffset))
        path.addLine(to: CGPoint(x: 23.526 * scale + xOffset, y: 13.794 * scale + yOffset))
        path.addLine(to: CGPoint(x: 24 * scale + xOffset, y: 14.432 * scale + yOffset))
        path.addLine(to: CGPoint(x: 23.921 * scale + xOffset, y: 14.917 * scale + yOffset))
        path.addLine(to: CGPoint(x: 22.706 * scale + xOffset, y: 15.537 * scale + yOffset))
        path.addLine(to: CGPoint(x: 21.066 * scale + xOffset, y: 15.148 * scale + yOffset))
        path.addLine(to: CGPoint(x: 17.237 * scale + xOffset, y: 14.238 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.925 * scale + xOffset, y: 13.909 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.743 * scale + xOffset, y: 13.909 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.743 * scale + xOffset, y: 14.019 * scale + yOffset))
        path.addLine(to: CGPoint(x: 16.836 * scale + xOffset, y: 15.087 * scale + yOffset))
        path.addLine(to: CGPoint(x: 18.842 * scale + xOffset, y: 16.897 * scale + yOffset))
        path.addLine(to: CGPoint(x: 21.351 * scale + xOffset, y: 19.227 * scale + yOffset))
        path.addLine(to: CGPoint(x: 21.478 * scale + xOffset, y: 19.805 * scale + yOffset))
        path.addLine(to: CGPoint(x: 21.156 * scale + xOffset, y: 20.26 * scale + yOffset))
        path.addLine(to: CGPoint(x: 20.816 * scale + xOffset, y: 20.211 * scale + yOffset))
        path.addLine(to: CGPoint(x: 18.611 * scale + xOffset, y: 18.554 * scale + yOffset))
        path.addLine(to: CGPoint(x: 17.76 * scale + xOffset, y: 17.807 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.834 * scale + xOffset, y: 16.187 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.706 * scale + xOffset, y: 16.187 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.706 * scale + xOffset, y: 16.357 * scale + yOffset))
        path.addLine(to: CGPoint(x: 16.15 * scale + xOffset, y: 17.006 * scale + yOffset))
        path.addLine(to: CGPoint(x: 18.495 * scale + xOffset, y: 20.527 * scale + yOffset))
        path.addLine(to: CGPoint(x: 18.617 * scale + xOffset, y: 21.607 * scale + yOffset))
        path.addLine(to: CGPoint(x: 18.447 * scale + xOffset, y: 21.96 * scale + yOffset))
        path.addLine(to: CGPoint(x: 17.839 * scale + xOffset, y: 22.173 * scale + yOffset))
        path.addLine(to: CGPoint(x: 17.171 * scale + xOffset, y: 22.051 * scale + yOffset))
        path.addLine(to: CGPoint(x: 15.797 * scale + xOffset, y: 20.126 * scale + yOffset))
        path.addLine(to: CGPoint(x: 14.382 * scale + xOffset, y: 17.959 * scale + yOffset))
        path.addLine(to: CGPoint(x: 13.239 * scale + xOffset, y: 16.016 * scale + yOffset))
        path.addLine(to: CGPoint(x: 13.099 * scale + xOffset, y: 16.096 * scale + yOffset))
        path.addLine(to: CGPoint(x: 12.425 * scale + xOffset, y: 23.35 * scale + yOffset))
        path.addLine(to: CGPoint(x: 12.109 * scale + xOffset, y: 23.72 * scale + yOffset))
        path.addLine(to: CGPoint(x: 11.38 * scale + xOffset, y: 24 * scale + yOffset))
        path.addLine(to: CGPoint(x: 10.773 * scale + xOffset, y: 23.539 * scale + yOffset))
        path.addLine(to: CGPoint(x: 10.451 * scale + xOffset, y: 22.792 * scale + yOffset))
        path.addLine(to: CGPoint(x: 10.773 * scale + xOffset, y: 21.316 * scale + yOffset))
        path.addLine(to: CGPoint(x: 11.162 * scale + xOffset, y: 19.392 * scale + yOffset))
        path.addLine(to: CGPoint(x: 11.477 * scale + xOffset, y: 17.862 * scale + yOffset))
        path.addLine(to: CGPoint(x: 11.763 * scale + xOffset, y: 15.962 * scale + yOffset))
        path.addLine(to: CGPoint(x: 11.933 * scale + xOffset, y: 15.33 * scale + yOffset))
        path.addLine(to: CGPoint(x: 11.921 * scale + xOffset, y: 15.288 * scale + yOffset))
        path.addLine(to: CGPoint(x: 11.781 * scale + xOffset, y: 15.306 * scale + yOffset))
        path.addLine(to: CGPoint(x: 10.347 * scale + xOffset, y: 17.273 * scale + yOffset))
        path.addLine(to: CGPoint(x: 8.167 * scale + xOffset, y: 20.218 * scale + yOffset))
        path.addLine(to: CGPoint(x: 6.441 * scale + xOffset, y: 22.063 * scale + yOffset))
        path.addLine(to: CGPoint(x: 6.027 * scale + xOffset, y: 22.227 * scale + yOffset))
        path.addLine(to: CGPoint(x: 5.31 * scale + xOffset, y: 21.857 * scale + yOffset))
        path.addLine(to: CGPoint(x: 5.377 * scale + xOffset, y: 21.195 * scale + yOffset))
        path.addLine(to: CGPoint(x: 5.778 * scale + xOffset, y: 20.606 * scale + yOffset))
        path.addLine(to: CGPoint(x: 8.166 * scale + xOffset, y: 17.57 * scale + yOffset))
        path.addLine(to: CGPoint(x: 9.606 * scale + xOffset, y: 15.688 * scale + yOffset))
        path.addLine(to: CGPoint(x: 10.536 * scale + xOffset, y: 14.602 * scale + yOffset))
        path.addLine(to: CGPoint(x: 10.53 * scale + xOffset, y: 14.444 * scale + yOffset))
        path.addLine(to: CGPoint(x: 10.475 * scale + xOffset, y: 14.444 * scale + yOffset))
        path.addLine(to: CGPoint(x: 4.132 * scale + xOffset, y: 18.56 * scale + yOffset))
        path.addLine(to: CGPoint(x: 3.002 * scale + xOffset, y: 18.706 * scale + yOffset))
        path.addLine(to: CGPoint(x: 2.515 * scale + xOffset, y: 18.25 * scale + yOffset))
        path.addLine(to: CGPoint(x: 2.576 * scale + xOffset, y: 17.504 * scale + yOffset))
        path.addLine(to: CGPoint(x: 2.807 * scale + xOffset, y: 17.261 * scale + yOffset))
        path.addLine(to: CGPoint(x: 4.715 * scale + xOffset, y: 15.949 * scale + yOffset))
        path.closeSubpath()

        return path
    }
}

/// A view that displays the Claude brand icon.
/// Uses Canvas for reliable rendering in all contexts including menu bar.
public struct ClaudeIcon: View {
    let size: CGFloat
    let color: Color

    public init(size: CGFloat = 24, color: Color = Theme.Colors.primary) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
            let path = ClaudeIconShape().path(in: rect)
            context.fill(path, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

/// Alternative icon view using Image for contexts where Canvas doesn't work.
public struct ClaudeIconImage: View {
    let size: CGFloat
    let color: Color

    public init(size: CGFloat = 24, color: Color = Theme.Colors.primary) {
        self.size = size
        self.color = color
    }

    @MainActor
    public var body: some View {
        if let nsImage = createNSImage() {
            Image(nsImage: nsImage)
                .resizable()
                .frame(width: size, height: size)
        } else {
            // Fallback to SF Symbol if image creation fails
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.7))
                .foregroundStyle(color)
        }
    }

    @MainActor
    private func createNSImage() -> NSImage? {
        let renderer = ImageRenderer(content:
            Canvas { context, canvasSize in
                let rect = CGRect(origin: .zero, size: canvasSize)
                let path = ClaudeIconShape().path(in: rect)
                context.fill(path, with: .color(color))
            }
            .frame(width: size * 2, height: size * 2) // 2x for retina
        )
        renderer.scale = 2.0
        return renderer.nsImage
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        ClaudeIcon(size: 16)
        ClaudeIcon(size: 24)
        ClaudeIcon(size: 48)
        ClaudeIcon(size: 64, color: .orange)
    }
    .padding()
}
#endif
