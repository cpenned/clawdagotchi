import SwiftUI
import AppKit

@main
struct ClawdagotchiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = TamagotchiViewModel()

    var body: some Scene {
        Window("Clawdagotchi", id: "main") {
            ContentView(viewModel: viewModel)
                .background(WindowConfigurator(hasPermissionPending: viewModel.pendingPermission != nil))
                .onAppear { viewModel.start() }
                .onDisappear { viewModel.stop() }
        }
        .windowStyle(.plain)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 290, height: 350)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .windowList) {}
            CommandGroup(replacing: .windowArrangement) {}
            CommandGroup(replacing: .help) {}
            CommandGroup(after: .appInfo) {
                Button("Star on GitHub") {
                    if let url = URL(string: "https://github.com/cpenned/clawdagotchi") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }

        Settings {
            SettingsView()
        }
    }
}

struct WindowConfigurator: NSViewRepresentable {
    let hasPermissionPending: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
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
            applyFloatLevel(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        applyFloatLevel(to: window)
    }

    private func applyFloatLevel(to window: NSWindow) {
        let policy = AppSettings.shared.floatPolicy
        switch policy {
        case .always:
            window.level = .floating
        case .permissionOnly:
            window.level = hasPermissionPending ? .floating : .normal
        case .never:
            window.level = .normal
        }
    }
}
