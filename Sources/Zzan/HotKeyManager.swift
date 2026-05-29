import AppKit
import Carbon.HIToolbox

/// Registers a single global hotkey via Carbon and invokes `onHotKey` when pressed.
///
/// Carbon hotkeys don't require Accessibility permission (unlike CGEventTap).
/// Caveat: `RegisterEventHotKey` does not fail when another app already owns the
/// same combination — multiple registrants simply each receive the event — so
/// true cross-app conflict detection isn't possible here. See `ShortcutValidator`.
final class HotKeyManager {
    // The Carbon event handler fires on the main run loop; access is single-threaded.
    nonisolated(unsafe) static let shared = HotKeyManager()

    var onHotKey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: 0x5A5A_414E /* "ZZAN" */, id: 1)

    private init() {
        installHandler()
    }

    private func installHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.onHotKey?()
                return noErr
            },
            1,
            &spec,
            userData,
            &eventHandler
        )
    }

    /// Re-registers the global hotkey for the given combo, replacing any previous one.
    func apply(_ combo: KeyCombo) {
        if let existing = hotKeyRef {
            UnregisterEventHotKey(existing)
            hotKeyRef = nil
        }
        var newRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &newRef
        )
        if status == noErr {
            hotKeyRef = newRef
        } else {
            NSLog("Zzan: failed to register hotkey \(combo.displayString) (status \(status))")
        }
    }
}
