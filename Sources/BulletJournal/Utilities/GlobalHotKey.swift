import Carbon
import AppKit

/// Registers a system-wide keyboard shortcut (works even when the app
/// isn't focused), the same mechanism apps like Spotlight-style launchers use.
final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let onTrigger: () -> Void

    init(keyCode: UInt32, modifiers: UInt32, onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        register(keyCode: keyCode, modifiers: modifiers)
    }

    private func register(keyCode: UInt32, modifiers: UInt32) {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: OSType(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                guard let userData = userData else { return noErr }
                let me = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                me.onTrigger()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(signature: OSType(0x424A4B31), id: 1) // 'BJK1'
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregister()
    }
}
