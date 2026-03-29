import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenubar()
        AppSettings.shared.applyDockPolicy()
    }

    func setupMenubar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = makeCrabMenubarImage()
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide Widget", action: #selector(toggleWidget), keyEquivalent: "w"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Clawdagotchi", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem?.menu = menu
    }

    @objc private func toggleWidget() {
        AppSettings.shared.showWidget.toggle()
        if let window = NSApp.windows.first(where: { $0.title != "Settings" && !$0.title.isEmpty || $0.level == .floating }) {
            if AppSettings.shared.showWidget {
                window.orderFront(nil)
            } else {
                window.orderOut(nil)
            }
        }
    }

    func openSettingsFromKeyboard() {
        openSettings()
    }

    @objc private func openSettings() {
        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 380, height: 480)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func makeCrabMenubarImage() -> NSImage {
        // Pixel grid: 14 wide x 10 tall
        // 1 = crab pixel, 0 = transparent, 2 = eye (dark)
        let grid: [[Int]] = [
            [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,1,1,2,2,1,2,2,1,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
            [1,1,1,1,1,1,1,1,1,1,1,1,1,1],
            [1,1,1,1,1,1,1,1,1,1,1,1,1,1],
            [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,1,1,0,1,1,0,1,1,0,0,0],
            [0,0,0,1,1,0,1,1,0,1,1,0,0,0],
        ]

        let iconSize: CGFloat = 18
        let gridCols: CGFloat = 14
        let gridRows: CGFloat = 10
        let pixelW = iconSize / gridCols
        let pixelH = iconSize / gridRows

        let image = NSImage(size: NSSize(width: iconSize, height: iconSize))
        image.lockFocus()

        NSColor.white.setFill()

        for (rowIdx, row) in grid.enumerated() {
            for (colIdx, cell) in row.enumerated() {
                guard cell != 0 else { continue }
                // NSImage coordinate origin is bottom-left; flip row
                let x = CGFloat(colIdx) * pixelW
                let y = iconSize - CGFloat(rowIdx + 1) * pixelH
                let rect = NSRect(x: x, y: y, width: pixelW, height: pixelH)
                NSBezierPath(rect: rect).fill()
            }
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
