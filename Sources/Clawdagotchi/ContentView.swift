import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: TamagotchiViewModel

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 270, geo.size.height / 330)
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
            .scaleEffect(scale)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(minWidth: 150, minHeight: 186)
        .contextMenu {
            Button("Settings...") {
                if let delegate = NSApp.delegate as? AppDelegate {
                    delegate.openSettingsFromKeyboard()
                }
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
