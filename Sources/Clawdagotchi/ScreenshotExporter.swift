import SwiftUI
import AppKit

struct ShareCard: View {
    var body: some View {
        let settings = AppSettings.shared
        let level = settings.level
        let accessories = CrabAccessory.allUnlocked(for: level, seasonalEnabled: settings.seasonalAccessories)

        VStack(spacing: 12) {
            CrabView(
                size: 80,
                color: settings.activeCrabColor,
                eyeColor: Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0),
                eyeStyle: .normal,
                accessories: accessories,
                accessoryColor: .white
            )

            Text(settings.botName)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            Text("LV \(level)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))

            Spacer().frame(height: 4)

            Text("clawdagotchi")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(24)
        .frame(width: 220, height: 220)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0))
        )
    }
}

@MainActor
struct ScreenshotExporter {
    static func export() {
        let card = ShareCard()
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2.0

        guard let image = renderer.cgImage else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "\(AppSettings.shared.botName)-lv\(AppSettings.shared.level).png"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
    }
}
