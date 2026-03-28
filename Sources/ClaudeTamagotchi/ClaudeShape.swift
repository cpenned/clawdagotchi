import SwiftUI

struct ClaudeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // Pixel-art Claude mascot outline (head + body + arms + 3 legs)
        // Traced clockwise from top-left of head
        path.move(to: CGPoint(x: w * 0.24, y: 0))
        path.addLine(to: CGPoint(x: w * 0.76, y: 0))          // head top
        path.addLine(to: CGPoint(x: w * 0.76, y: h * 0.36))   // head right edge
        path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.36))   // step out to body
        path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.40))   // body right, arm start
        path.addLine(to: CGPoint(x: w * 1.00, y: h * 0.40))   // right arm out
        path.addLine(to: CGPoint(x: w * 1.00, y: h * 0.56))   // right arm bottom
        path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.56))   // right arm back in
        path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.66))   // body right bottom
        path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.66))   // right leg top-right
        path.addLine(to: CGPoint(x: w * 0.82, y: h * 1.00))   // right leg bottom-right
        path.addLine(to: CGPoint(x: w * 0.66, y: h * 1.00))   // right leg bottom-left
        path.addLine(to: CGPoint(x: w * 0.66, y: h * 0.66))   // gap
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.66))   // center leg top-right
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 1.00))   // center leg bottom-right
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 1.00))   // center leg bottom-left
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.66))   // gap
        path.addLine(to: CGPoint(x: w * 0.34, y: h * 0.66))   // left leg top-right
        path.addLine(to: CGPoint(x: w * 0.34, y: h * 1.00))   // left leg bottom-right
        path.addLine(to: CGPoint(x: w * 0.18, y: h * 1.00))   // left leg bottom-left
        path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.66))   // left leg top-left
        path.addLine(to: CGPoint(x: w * 0.10, y: h * 0.66))   // body left bottom
        path.addLine(to: CGPoint(x: w * 0.10, y: h * 0.56))   // left arm start
        path.addLine(to: CGPoint(x: w * 0.00, y: h * 0.56))   // left arm out
        path.addLine(to: CGPoint(x: w * 0.00, y: h * 0.40))   // left arm top
        path.addLine(to: CGPoint(x: w * 0.10, y: h * 0.40))   // left arm back in
        path.addLine(to: CGPoint(x: w * 0.10, y: h * 0.36))   // body left top
        path.addLine(to: CGPoint(x: w * 0.24, y: h * 0.36))   // step in to head
        path.closeSubpath()

        return path
    }
}

extension Color {
    static let claudePink = Color(red: 0xF0 / 255.0, green: 0x90 / 255.0, blue: 0x80 / 255.0)
}
