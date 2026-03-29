import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: TamagotchiViewModel

    private let baseWidth: CGFloat = 270
    private let baseHeight: CGFloat = 330

    private var widgetScale: Double { AppSettings.shared.widgetScale }

    var body: some View {
        ZStack {
            TamagotchiView(
                state: viewModel.displayState,
                sessionCount: viewModel.activeSessionCount,
                pendingPermission: viewModel.pendingPermission,
                pendingPermissionCount: viewModel.pendingPermissionCount,
                moodState: viewModel.moodState,
                greetingMessage: viewModel.greetingMessage,
                funReaction: viewModel.funReaction,
                onApprove: { viewModel.approvePermission() },
                onDeny: { viewModel.denyPermission() },
                onPoke: { viewModel.pokeCrab() },
                onFeed: { viewModel.feedCrab() },
                onPet: { viewModel.petCrab() }
            )
            .scaleEffect(widgetScale)

            RightClickOverlay()
        }
        .frame(width: baseWidth * widgetScale, height: baseHeight * widgetScale)
    }
}

struct RightClickOverlay: NSViewRepresentable {
    func makeNSView(context: Context) -> RightClickView {
        RightClickView()
    }
    func updateNSView(_ nsView: RightClickView, context: Context) {}
}

class RightClickView: NSView {
    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Clawdagotchi", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func openSettings() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.openSettingsFromKeyboard()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
