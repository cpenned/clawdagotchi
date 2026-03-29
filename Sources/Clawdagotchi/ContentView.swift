import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: TamagotchiViewModel

    private let baseWidth: CGFloat = 270
    private let baseHeight: CGFloat = 330

    private var widgetScale: Double { AppSettings.shared.widgetScale }

    var body: some View {
        TamagotchiView(
            state: viewModel.displayState,
            sessionCount: viewModel.activeSessionCount,
            pendingPermission: viewModel.pendingPermission,
            pendingPermissionCount: viewModel.pendingPermissionCount,
            moodState: viewModel.moodState,
            poopCount: viewModel.poopCount,
            greetingMessage: viewModel.greetingMessage,
            funReaction: viewModel.funReaction,
            onApprove: { viewModel.approvePermission() },
            onDeny: { viewModel.denyPermission() },
            onPoke: { viewModel.pokeCrab() },
            onFeed: { viewModel.feedCrab() },
            onPet: { viewModel.petCrab() }
        )
        .scaleEffect(widgetScale)
        .frame(width: baseWidth * widgetScale, height: baseHeight * widgetScale)
    }
}
