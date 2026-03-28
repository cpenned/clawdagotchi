import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: TamagotchiViewModel

    var body: some View {
        TamagotchiView(
            state: viewModel.displayState,
            sessionCount: viewModel.activeSessionCount,
            pendingPermission: viewModel.pendingPermission,
            funReaction: viewModel.funReaction,
            onApprove: { viewModel.approvePermission() },
            onDeny: { viewModel.denyPermission() },
            onPoke: { viewModel.pokeCrab() },
            onPet: { viewModel.petCrab() }
        )
        .contextMenu {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
