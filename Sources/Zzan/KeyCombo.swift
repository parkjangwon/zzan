import AppKit
import Carbon.HIToolbox

/// A keyboard shortcut: a virtual key code plus Cocoa modifier flags.
struct KeyCombo: Codable, Equatable {
    var keyCode: UInt32
    /// Raw value of an `NSEvent.ModifierFlags` set (device-independent subset).
    var modifiers: UInt

    /// Default shortcut: ⌃⌥⌘T ("Translate"). Uncommon enough to rarely collide.
    static let defaultCombo = KeyCombo(
        keyCode: UInt32(kVK_ANSI_T),
        modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue
    )

    var flags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
    }

    /// Modifier bitmask in Carbon's encoding, for `RegisterEventHotKey`.
    var carbonModifiers: UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }

    /// Human-readable representation, e.g. "⌃⌥⌘T".
    var displayString: String {
        var parts = ""
        if flags.contains(.control) { parts += "⌃" }
        if flags.contains(.option) { parts += "⌥" }
        if flags.contains(.shift) { parts += "⇧" }
        if flags.contains(.command) { parts += "⌘" }
        parts += KeyCombo.keyName(for: keyCode)
        return parts
    }

    private static func keyName(for code: UInt32) -> String {
        if let named = specialKeyNames[Int(code)] { return named }
        if let char = characterKeyNames[Int(code)] { return char }
        return "Key\(code)"
    }

    private static let specialKeyNames: [Int: String] = [
        kVK_Space: "Space",
        kVK_Return: "↩",
        kVK_Tab: "⇥",
        kVK_Delete: "⌫",
        kVK_Escape: "⎋",
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_UpArrow: "↑",
        kVK_DownArrow: "↓",
        kVK_Home: "↖",
        kVK_End: "↘",
        kVK_PageUp: "⇞",
        kVK_PageDown: "⇟",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
        kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    private static let characterKeyNames: [Int: String] = [
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
        kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
        kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
        kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
        kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
        kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
        kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
        kVK_ANSI_8: "8", kVK_ANSI_9: "9",
        kVK_ANSI_Minus: "-", kVK_ANSI_Equal: "=",
        kVK_ANSI_LeftBracket: "[", kVK_ANSI_RightBracket: "]",
        kVK_ANSI_Semicolon: ";", kVK_ANSI_Quote: "'",
        kVK_ANSI_Comma: ",", kVK_ANSI_Period: ".", kVK_ANSI_Slash: "/",
        kVK_ANSI_Backslash: "\\", kVK_ANSI_Grave: "`",
    ]
}

/// Rejects shortcuts that are unusable or known to clash with the system.
///
/// Note: there is no public API to enumerate every globally-registered
/// shortcut, so this is a best-effort blocklist of the well-known reserved
/// combinations plus a rule requiring a non-Shift modifier.
enum ShortcutValidator {
    /// Returns a human-readable reason if the combo should be rejected, else nil.
    static func reject(_ combo: KeyCombo) -> String? {
        let flags = combo.flags
        let hasStrongModifier =
            flags.contains(.command) || flags.contains(.option) || flags.contains(.control)
        guard hasStrongModifier else {
            return "Use at least one of ⌘ ⌥ ⌃."
        }

        for reserved in reservedCombos where reserved.matches(combo) {
            return "\(combo.displayString) is reserved by macOS."
        }
        return nil
    }

    private struct Reserved {
        let keyCode: Int
        let flags: NSEvent.ModifierFlags
        func matches(_ combo: KeyCombo) -> Bool {
            Int(combo.keyCode) == keyCode
                && combo.flags.intersection([.command, .option, .control, .shift]) == flags
        }
    }

    private static let reservedCombos: [Reserved] = [
        Reserved(keyCode: kVK_Space, flags: [.command]),            // Spotlight
        Reserved(keyCode: kVK_Space, flags: [.control]),            // input source
        Reserved(keyCode: kVK_Tab, flags: [.command]),             // app switcher
        Reserved(keyCode: kVK_Tab, flags: [.command, .shift]),     // app switcher (reverse)
        Reserved(keyCode: kVK_Escape, flags: [.command, .option]), // Force Quit
        Reserved(keyCode: kVK_ANSI_Q, flags: [.command]),          // Quit
        Reserved(keyCode: kVK_ANSI_W, flags: [.command]),          // Close window
        Reserved(keyCode: kVK_ANSI_H, flags: [.command]),          // Hide
        Reserved(keyCode: kVK_ANSI_M, flags: [.command]),          // Minimize
        Reserved(keyCode: kVK_ANSI_Comma, flags: [.command]),      // Preferences
        Reserved(keyCode: kVK_ANSI_C, flags: [.command]),          // Copy
        Reserved(keyCode: kVK_ANSI_V, flags: [.command]),          // Paste
        Reserved(keyCode: kVK_ANSI_X, flags: [.command]),          // Cut
        Reserved(keyCode: kVK_ANSI_Z, flags: [.command]),          // Undo
        Reserved(keyCode: kVK_ANSI_A, flags: [.command]),          // Select all
    ]
}
