import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

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
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func makeCrabMenubarImage() -> NSImage {
        // Match CrabView geometry: viewBox 66w x 52h
        let iconSize: CGFloat = 18
        let s = iconSize / 52.0
        let xOff = (iconSize - 66 * s) / 2

        let image = NSImage(size: NSSize(width: iconSize, height: iconSize))
        image.lockFocus()

        NSColor.white.setFill()

        func fill(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
            // Flip Y for NSImage (origin bottom-left)
            let rect = NSRect(x: xOff + x * s, y: iconSize - (y + h) * s, width: w * s, height: h * s)
            NSBezierPath(rect: rect).fill()
        }

        // Antennae
        fill(0, 13, 6, 13)
        fill(60, 13, 6, 13)

        // Body
        fill(6, 0, 54, 39)

        // Legs (4, static)
        for lx: CGFloat in [6, 18, 42, 54] {
            fill(lx, 39, 6, 13)
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
