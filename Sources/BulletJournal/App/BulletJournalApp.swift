import SwiftUI
import AppKit

@main
struct BulletJournalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.store)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let store = JournalStore()
    private var window: JournalWindow<AnyView>?
    private var hotKey: GlobalHotKey?
    private var archiveTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Regular app: Dock icon present, so a minimized window has
        // somewhere to go and can be restored the normal way.
        NSApp.setActivationPolicy(.regular)

        store.checkForNewDay()
        setupHotKey()
        scheduleDayRolloverCheck()

        showWindow()
    }

    /// Clicking the Dock icon while the window is minimized/hidden restores it,
    /// same as any standard Mac app.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    /// Closing the window (red button, or ⌘W) quits the whole app cleanly —
    /// this is a single-window utility, so there's no reason for the process
    /// to linger invisibly in the background afterward. Minimizing (yellow
    /// button) is unaffected and still just sends it to the Dock.
    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }

    /// Safety net covering any other path that might close the last window.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func setupHotKey() {
        hotKey = GlobalHotKey(
            keyCode: store.settings.hotKeyCode,
            modifiers: store.settings.hotKeyModifiers
        ) { [weak self] in
            self?.showWindow()
        }
    }

    /// Re-checks the date every minute so a long-idle launch still rolls
    /// today's page into Apple Notes at the right moment, even without reopening.
    private func scheduleDayRolloverCheck() {
        archiveTimer?.invalidate()
        archiveTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.store.checkForNewDay()
        }
    }

    /// Brings the window to front, un-minimizing it if needed, or creates
    /// it if this is the first launch. The keyboard shortcut now behaves
    /// like ⌘-Tab-ing to the app rather than toggling a popup.
    func showWindow() {
        store.checkForNewDay()

        if let window = window {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let content = AnyView(ContentView().environmentObject(store))
        let size = NSSize(width: 600, height: 760)
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.midY - size.height / 2 + 40
        )
        let rect = NSRect(origin: origin, size: size)

        let newWindow = JournalWindow(contentRect: rect, view: content)
        newWindow.delegate = self
        window = newWindow

        NSApp.activate(ignoringOtherApps: true)
        newWindow.makeKeyAndOrderFront(nil)
    }
}
