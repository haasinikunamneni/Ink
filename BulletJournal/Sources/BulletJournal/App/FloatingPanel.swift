import AppKit
import SwiftUI

/// The app's main window — a normal, standard macOS window: title bar with
/// working close/minimize/zoom buttons, resizable, minimizes to the Dock
/// like any other app instead of vanishing.
final class JournalWindow<Content: View>: NSWindow {
    init(contentRect: NSRect, view: Content) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        title = "Bullet Journal"
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovableByWindowBackground = true
        backgroundColor = NSColor(white: 0.07, alpha: 1)
        isOpaque = true
        hasShadow = true
        isReleasedWhenClosed = false
        minSize = NSSize(width: 420, height: 480)

        let hosting = NSHostingView(rootView: view)
        hosting.frame = contentRect
        contentView = hosting

        center()
    }
}
