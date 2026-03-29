import SwiftUI

enum ShellStyle: String, CaseIterable, Sendable {
    case clearRetro
    case salmonPink
    case hotPink
    case iceBlue
    case frost
    case midnight

    var displayName: String {
        switch self {
        case .clearRetro: "Clear Retro"
        case .salmonPink: "Salmon"
        case .hotPink: "Pink"
        case .iceBlue: "Ice Blue"
        case .frost: "Frost"
        case .midnight: "Midnight"
        }
    }

    var tintColor: Color {
        switch self {
        case .clearRetro: Color(white: 0.85)
        case .salmonPink: Color(red: 0.98, green: 0.42, blue: 0.35)
        case .hotPink: Color(red: 0.95, green: 0.30, blue: 0.65)
        case .iceBlue: Color(red: 0.30, green: 0.65, blue: 0.98)
        case .frost: Color(white: 0.92)
        case .midnight: Color(white: 0.25)
        }
    }

    var tintOpacity: CGFloat {
        switch self {
        case .clearRetro: 0.18
        case .salmonPink: 0.50
        case .hotPink: 0.48
        case .iceBlue: 0.45
        case .frost: 0.60
        case .midnight: 0.55
        }
    }

    var highlightColor: Color {
        switch self {
        case .clearRetro: Color(white: 0.95)
        case .salmonPink: Color(red: 1.0, green: 0.55, blue: 0.48)
        case .hotPink: Color(red: 1.0, green: 0.50, blue: 0.75)
        case .iceBlue: Color(red: 0.50, green: 0.78, blue: 1.0)
        case .frost: Color(white: 0.98)
        case .midnight: Color(white: 0.40)
        }
    }

    var shadowColor: Color {
        switch self {
        case .clearRetro: Color(white: 0.60)
        case .salmonPink: Color(red: 0.82, green: 0.28, blue: 0.22)
        case .hotPink: Color(red: 0.72, green: 0.15, blue: 0.45)
        case .iceBlue: Color(red: 0.15, green: 0.42, blue: 0.78)
        case .frost: Color(white: 0.72)
        case .midnight: Color(white: 0.12)
        }
    }

    var edgeHighlight: Color {
        switch self {
        case .clearRetro: Color.white
        case .salmonPink: Color(red: 1.0, green: 0.85, blue: 0.80)
        case .hotPink: Color(red: 1.0, green: 0.75, blue: 0.88)
        case .iceBlue: Color(red: 0.85, green: 0.95, blue: 1.0)
        case .frost: Color.white
        case .midnight: Color(white: 0.50)
        }
    }

    var specularIntensity: CGFloat {
        switch self {
        case .clearRetro: 0.50
        case .salmonPink: 0.35
        case .hotPink: 0.38
        case .iceBlue: 0.40
        case .frost: 0.55
        case .midnight: 0.20
        }
    }

    var internalsOpacity: CGFloat {
        switch self {
        case .clearRetro: 1.0
        case .salmonPink: 0.7
        case .hotPink: 0.65
        case .iceBlue: 0.75
        case .frost: 0.5
        case .midnight: 0.4
        }
    }

    var crabColor: Color {
        switch self {
        case .clearRetro: Color(white: 0.55)
        case .salmonPink: Color(red: 0.94, green: 0.56, blue: 0.50)
        case .hotPink: Color(red: 0.95, green: 0.45, blue: 0.70)
        case .iceBlue: Color(red: 0.50, green: 0.72, blue: 0.95)
        case .frost: Color(white: 0.70)
        case .midnight: Color(red: 0.45, green: 0.35, blue: 0.65)
        }
    }

    var labelColor: Color {
        switch self {
        case .clearRetro: Color.white.opacity(0.5)
        case .salmonPink: Color.white.opacity(0.4)
        case .hotPink: Color.white.opacity(0.45)
        case .iceBlue: Color.white.opacity(0.45)
        case .frost: Color.black.opacity(0.2)
        case .midnight: Color.white.opacity(0.2)
        }
    }
}
