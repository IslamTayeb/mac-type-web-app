import SwiftUI
import AppKit
import os.log

@main
struct WPMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var eventMonitor: EventMonitor?
    var keyboardMonitor: KeyboardMonitor!
    var statsManager: StatsManager!
    var timer: Timer?
    private let logger = Logger(subsystem: "com.wpmonitor", category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("WPMonitor starting...")

        // Initialize managers
        statsManager = StatsManager.shared
        keyboardMonitor = KeyboardMonitor(statsManager: statsManager)

        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "0 WPM"
            button.action = #selector(togglePopover(_:))
            button.target = self
            logger.info("Menu bar item created")
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: StatsView())

        // Setup event monitor for clicks outside popover
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: nil)
            }
        }

        // Start keyboard monitoring
        logger.info("Starting keyboard monitor...")
        keyboardMonitor.startMonitoring()

        // Update menu bar item periodically
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateMenuBarItem()
        }

        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        logger.info("WPMonitor initialization complete")
    }

    func updateMenuBarItem() {
        let wpm = statsManager.currentWPM
        let totalKeystrokes = statsManager.totalKeystrokes

        statusItem.button?.title = "\(wpm) WPM"

        // Log the first few updates to verify it's working
        if totalKeystrokes < 50 && totalKeystrokes % 10 == 0 && totalKeystrokes > 0 {
            logger.debug("Stats update - WPM: \(wpm), Total keystrokes: \(totalKeystrokes)")
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }

    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            eventMonitor?.start()
        }
    }

    func closePopover(sender: Any?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }

    func applicationWillTerminate(_ notification: Notification) {
        keyboardMonitor.stopMonitoring()
        timer?.invalidate()
    }
}
