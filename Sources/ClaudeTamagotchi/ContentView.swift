import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: TamagotchiViewModel

    var body: some View {
        TamagotchiView(
            state: viewModel.displayState,
            sessionCount: viewModel.activeSessionCount
        )
        .contextMenu {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
