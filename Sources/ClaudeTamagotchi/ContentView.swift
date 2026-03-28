import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: TamagotchiViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 12, y: 4)

            TamagotchiView(
                state: viewModel.displayState,
                sessionCount: viewModel.activeSessionCount
            )
        }
        .frame(width: 220, height: 260)
        .contextMenu {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
