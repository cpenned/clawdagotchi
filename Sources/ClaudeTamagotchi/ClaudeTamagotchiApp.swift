import SwiftUI
import AppKit

@main
struct ClaudeTamagotchiApp: App {
    @State private var viewModel = TamagotchiViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .background(WindowConfigurator())
                .onAppear { viewModel.start() }
                .onDisappear { viewModel.stop() }
        }
        .windowStyle(.plain)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 250, height: 310)
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.level = .floating
            window.isMovableByWindowBackground = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
