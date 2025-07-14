import Cocoa
import Carbon
import os.log

class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let statsManager: StatsManager
    private var lastKeyTime: Date = Date()
    private var wordBuffer: String = ""
    private let logger = Logger(subsystem: "com.wpmonitor", category: "KeyboardMonitor")

    init(statsManager: StatsManager) {
        self.statsManager = statsManager
    }

    func startMonitoring() {
        logger.info("Starting keyboard monitoring...")

        // Check if we already have accessibility permissions
        let trusted = AXIsProcessTrusted()
        logger.info("Current accessibility status: \(trusted)")

        if !trusted {
            // Request accessibility permissions
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            let accessEnabled = AXIsProcessTrustedWithOptions(options)

            if !accessEnabled {
                logger.error("Accessibility permissions needed. Please grant access in System Preferences > Security & Privacy > Privacy > Accessibility")

                // Open System Preferences to the right pane
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)

                // Keep checking for permissions
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    if AXIsProcessTrusted() {
                        timer.invalidate()
                        self.startMonitoring()
                    }
                }
                return
            }
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue)

        logger.info("Creating event tap...")

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if type == .keyDown {
                    let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                    monitor.handleKeyEvent(event)
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            logger.error("Failed to create event tap - make sure accessibility permissions are granted")
            return
        }

        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        logger.info("Keyboard monitoring started successfully")

        // Start a timer to check if the event tap is still enabled
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self, let eventTap = self.eventTap else { return }

            if !CGEvent.tapIsEnabled(tap: eventTap) {
                self.logger.warning("Event tap was disabled, re-enabling...")
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
        }
    }

    func stopMonitoring() {
        logger.info("Stopping keyboard monitoring...")

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.eventTap = nil
            self.runLoopSource = nil
        }
    }

    private func handleKeyEvent(_ event: CGEvent) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let currentTime = Date()

        // Log first few keystrokes for debugging
        if statsManager.totalKeystrokes < 10 {
            logger.debug("Key pressed: code=\(keyCode)")
        }

        // Increment keystroke count
        statsManager.incrementKeystroke()

        // Handle character input for WPM calculation
        if let chars = event.getCharacters() {
            processCharacters(chars, at: currentTime)
        }

        // Check for word boundaries (space, enter, tab)
        if keyCode == 49 || keyCode == 36 || keyCode == 48 { // space, return, tab
            if !wordBuffer.isEmpty {
                statsManager.addWord(at: currentTime)
                wordBuffer = ""
            }
        }

        lastKeyTime = currentTime
    }

    private func processCharacters(_ chars: String, at time: Date) {
        for char in chars {
            if char.isLetter || char.isNumber {
                wordBuffer.append(char)
            }
        }
    }
}

extension CGEvent {
    func getCharacters() -> String? {
        var length = 0
        self.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)

        let buffer = UnsafeMutablePointer<UniChar>.allocate(capacity: length)
        defer { buffer.deallocate() }

        self.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: buffer)
        return String(utf16CodeUnits: buffer, count: length)
    }
}
