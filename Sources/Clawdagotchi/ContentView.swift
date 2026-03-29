import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: TamagotchiViewModel

    private let baseWidth: CGFloat = 290
    private let baseHeight: CGFloat = 350

    private var widgetScale: Double { AppSettings.shared.widgetScale }

    var body: some View {
        ZStack {
            TamagotchiView(
                state: viewModel.displayState,
                sessionCount: viewModel.activeSessionCount,
                pendingPermission: viewModel.pendingPermission,
                pendingPermissionCount: viewModel.pendingPermissionCount,
                hunger: viewModel.hunger,
                happiness: viewModel.happiness,
                moodState: viewModel.moodState,
                poopCount: viewModel.poopCount,
                greetingMessage: viewModel.greetingMessage,
                funReaction: viewModel.funReaction,
                level: viewModel.currentLevel,
                xpProgress: viewModel.xpProgress,
                justLeveledUp: viewModel.justLeveledUp,
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
    func makeNSView(context: Context) -> RightClickView { RightClickView() }
    func updateNSView(_ nsView: RightClickView, context: Context) {}
}

class RightClickView: NSView {
    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

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

    @objc private func checkUpdates() {
        UpdateChecker.shared.checkNow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
