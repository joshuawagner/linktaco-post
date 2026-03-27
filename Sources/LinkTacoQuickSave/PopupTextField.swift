import AppKit
import SwiftUI

struct PopupTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let fieldName: String
    let captureID: String
    let isDebugLoggingEnabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = FocusLoggingNSTextField(string: text)
        textField.placeholderString = placeholder
        textField.isBordered = true
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel
        textField.font = .systemFont(ofSize: NSFont.systemFontSize)
        textField.delegate = context.coordinator
        textField.focusDelegate = context.coordinator
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, NSTextFieldDelegate, FocusLoggingNSTextFieldDelegate {
        var parent: PopupTextField

        init(_ parent: PopupTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }

            parent.text = textField.stringValue
        }

        func focusLoggingTextField(_ textField: FocusLoggingNSTextField, didChangeFocus focused: Bool) {
            guard parent.isDebugLoggingEnabled else {
                return
            }

            AppLogger.logger.debug(
                "popup_field_focus_changed id=\(self.parent.captureID, privacy: .public) field=\(self.parent.fieldName, privacy: .public) focused=\(focused, privacy: .public)"
            )
        }
    }
}

protocol FocusLoggingNSTextFieldDelegate: AnyObject {
    func focusLoggingTextField(_ textField: FocusLoggingNSTextField, didChangeFocus focused: Bool)
}

final class FocusLoggingNSTextField: NSTextField {
    weak var focusDelegate: FocusLoggingNSTextFieldDelegate?

    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        if didBecomeFirstResponder {
            focusDelegate?.focusLoggingTextField(self, didChangeFocus: true)
        }
        return didBecomeFirstResponder
    }

    override func resignFirstResponder() -> Bool {
        let didResignFirstResponder = super.resignFirstResponder()
        if didResignFirstResponder {
            focusDelegate?.focusLoggingTextField(self, didChangeFocus: false)
        }
        return didResignFirstResponder
    }
}
