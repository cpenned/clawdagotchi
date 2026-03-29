import SwiftUI

struct ClaudeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // Rounded organic blob — slight left-lean asymmetry
        path.move(to: CGPoint(x: w * 0.50, y: 0))

        // Top → right
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.44),
            control1: CGPoint(x: w * 0.78, y: 0),
            control2: CGPoint(x: w, y: h * 0.16)
        )

        // Right → bottom
        path.addCurve(
            to: CGPoint(x: w * 0.52, y: h),
            control1: CGPoint(x: w, y: h * 0.76),
            control2: CGPoint(x: w * 0.80, y: h)
        )

        // Bottom → left
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.48),
            control1: CGPoint(x: w * 0.22, y: h),
            control2: CGPoint(x: 0, y: h * 0.78)
        )

        // Left → top
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: 0),
            control1: CGPoint(x: 0, y: h * 0.14),
            control2: CGPoint(x: w * 0.20, y: 0)
        )

        path.closeSubpath()
        return path
    }
}

extension Color {
    static let claudeOrange = Color(red: 0xDA / 255.0, green: 0x77 / 255.0, blue: 0x56 / 255.0)
}
