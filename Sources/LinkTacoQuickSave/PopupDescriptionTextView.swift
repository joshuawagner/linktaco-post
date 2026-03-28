import AppKit
import SwiftUI

struct PopupDescriptionTextView: NSViewRepresentable {
    @Binding var text: String
    let captureID: String
    let isDebugLoggingEnabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = FocusLoggingTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.drawsBackground = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.string = text
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.focusDelegate = context.coordinator

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            textView.string = text
        }

        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, NSTextViewDelegate, FocusLoggingTextViewDelegate {
        var parent: PopupDescriptionTextView

        init(_ parent: PopupDescriptionTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            parent.text = textView.string

            guard parent.isDebugLoggingEnabled else {
                return
            }

            AppLogger.logger.debug(
                "popup_description_changed id=\(self.parent.captureID, privacy: .public) length=\(textView.string.count, privacy: .public)"
            )
        }

        func focusLoggingTextView(_ textView: FocusLoggingTextView, didChangeFocus focused: Bool) {
            logFocusChange(focused)
        }

        private func logFocusChange(_ focused: Bool) {
            guard parent.isDebugLoggingEnabled else {
                return
            }

            AppLogger.logger.debug(
                "popup_description_focus_changed id=\(self.parent.captureID, privacy: .public) focused=\(focused, privacy: .public)"
            )
        }
    }
}

protocol FocusLoggingTextViewDelegate: AnyObject {
    func focusLoggingTextView(_ textView: FocusLoggingTextView, didChangeFocus focused: Bool)
}

final class FocusLoggingTextView: NSTextView {
    weak var focusDelegate: FocusLoggingTextViewDelegate?

    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        if didBecomeFirstResponder {
            focusDelegate?.focusLoggingTextView(self, didChangeFocus: true)
        }
        return didBecomeFirstResponder
    }

    override func resignFirstResponder() -> Bool {
        let didResignFirstResponder = super.resignFirstResponder()
        if didResignFirstResponder {
            focusDelegate?.focusLoggingTextView(self, didChangeFocus: false)
        }
        return didResignFirstResponder
    }
}
