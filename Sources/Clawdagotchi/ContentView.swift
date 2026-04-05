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
                simonSaysActive: viewModel.simonSaysActive,
                simonPromptActive: viewModel.simonPromptActive,
                simonShowingPattern: viewModel.simonShowingPattern,
                simonHighlight: viewModel.simonHighlight,
                onApprove: { viewModel.approvePermission() },
                onDeny: { viewModel.denyPermission() },
                onPoke: { viewModel.pokeCrab() },
                onFeed: { viewModel.feedCrab() },
                onPet: { viewModel.petCrab() },
                onSimonInput: { viewModel.simonInput($0) },
                onSimonPromptAccept: { viewModel.acceptSimonPrompt() },
                onSimonPromptDecline: { viewModel.declineSimonPrompt() }
            )
            .scaleEffect(widgetScale)

            if viewModel.isDead, let stats = viewModel.deathStats {
                DeathRebirthOverlay(stats: stats) { newName in
                    viewModel.rebirth(newName: newName)
                }
            }
        }
        .frame(width: baseWidth * widgetScale, height: baseHeight * widgetScale)
    }
}
