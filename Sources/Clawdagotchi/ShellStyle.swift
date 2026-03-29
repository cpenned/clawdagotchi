import SwiftUI

enum ShellStyle: String, CaseIterable, Sendable {
    case clearRetro
    case salmonPink
    case iceBlue
    case midnight

    var displayName: String {
        switch self {
        case .clearRetro: "Clear Retro"
        case .salmonPink: "Salmon Pink"
        case .iceBlue: "Ice Blue"
        case .midnight: "Midnight"
        }
    }

    // Main tint color for the translucent shell
    var tintColor: Color {
        switch self {
        case .clearRetro: Color(white: 0.85)
        case .salmonPink: Color(red: 0.94, green: 0.56, blue: 0.50)
        case .iceBlue: Color(red: 0.55, green: 0.75, blue: 0.92)
        case .midnight: Color(white: 0.25)
        }
    }

    // How much shell tint to apply (lower = more transparent)
    var tintOpacity: CGFloat {
        switch self {
        case .clearRetro: 0.18
        case .salmonPink: 0.42
        case .iceBlue: 0.35
        case .midnight: 0.55
        }
    }

    // Lighter tint for the top-left highlight zone
    var highlightColor: Color {
        switch self {
        case .clearRetro: Color(white: 0.95)
        case .salmonPink: Color(red: 0.98, green: 0.72, blue: 0.66)
        case .iceBlue: Color(red: 0.75, green: 0.88, blue: 0.98)
        case .midnight: Color(white: 0.40)
        }
    }

    // Darker tint for the bottom-right shadow zone
    var shadowColor: Color {
        switch self {
        case .clearRetro: Color(white: 0.60)
        case .salmonPink: Color(red: 0.78, green: 0.40, blue: 0.34)
        case .iceBlue: Color(red: 0.35, green: 0.55, blue: 0.72)
        case .midnight: Color(white: 0.12)
        }
    }

    // Edge highlight color (lit rim)
    var edgeHighlight: Color {
        switch self {
        case .clearRetro: Color.white
        case .salmonPink: Color(red: 1.0, green: 0.85, blue: 0.80)
        case .iceBlue: Color(red: 0.85, green: 0.95, blue: 1.0)
        case .midnight: Color(white: 0.50)
        }
    }

    // How bright the specular highlight is
    var specularIntensity: CGFloat {
        switch self {
        case .clearRetro: 0.50
        case .salmonPink: 0.35
        case .iceBlue: 0.40
        case .midnight: 0.20
        }
    }

    // How visible the internals are (higher = brighter)
    var internalsOpacity: CGFloat {
        switch self {
        case .clearRetro: 1.0
        case .salmonPink: 0.7
        case .iceBlue: 0.75
        case .midnight: 0.4
        }
    }

    // Brand label color
    var labelColor: Color {
        switch self {
        case .clearRetro: Color.white.opacity(0.5)
        case .salmonPink: Color.white.opacity(0.4)
        case .iceBlue: Color.white.opacity(0.45)
        case .midnight: Color.white.opacity(0.2)
        }
    }
}
