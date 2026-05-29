import AppKit
import SwiftUI

/// A multi-line text view that distinguishes Return (submit) from Shift+Return
/// (insert newline) and Escape (cancel).
struct KeyCaptureTextView: NSViewRepresentable {
    @Binding var text: String
    var focusNonce: Int
    var onSubmit: () -> Void
    var onCancel: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let textView = SubmitTextView()
        textView.delegate = context.coordinator
        textView.onSubmit = onSubmit
        textView.onCancel = onCancel
        textView.font = .systemFont(ofSize: 20, weight: .regular)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.borderType = .noBorder

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        textView.onSubmit = onSubmit
        textView.onCancel = onCancel
        if textView.string != text {
            textView.string = text
        }

        if context.coordinator.lastFocusNonce != focusNonce {
            context.coordinator.lastFocusNonce = focusNonce
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
                textView.selectAll(nil)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: KeyCaptureTextView
        fileprivate weak var textView: SubmitTextView?
        var lastFocusNonce = -1

        init(_ parent: KeyCaptureTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

private final class SubmitTextView: NSTextView {
    var onSubmit: (() -> Void)?
    var onCancel: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case 53: // Escape
            onCancel?()
        case 36, 76: // Return, keypad Enter
            if event.modifierFlags.contains(.shift) {
                super.keyDown(with: event) // insert a newline
            } else {
                onSubmit?()
            }
        default:
            super.keyDown(with: event)
        }
    }
}
