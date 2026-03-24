import Carbon
import Foundation

enum HotkeyMonitorError: LocalizedError {
    case installHandlerFailed(OSStatus)
    case registerHotkeyFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .installHandlerFailed(let status):
            return "Failed to install hotkey handler (OSStatus \(status))."
        case .registerHotkeyFailed(let status):
            return "Failed to register global shortcut (OSStatus \(status)). The shortcut may already be in use."
        }
    }
}

final class HotkeyMonitor {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
    }

    func start() throws {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4C544351), id: 1) // LTCQ

        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData in
                guard let eventRef else { return noErr }
                var eventHotKeyID = EventHotKeyID()
                GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &eventHotKeyID
                )

                if eventHotKeyID.id == 1,
                   let userData {
                    let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(userData).takeUnretainedValue()
                    monitor.callback()
                }
                return noErr
            },
            1,
            [eventType],
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )
        guard installStatus == noErr else {
            throw HotkeyMonitorError.installHandlerFailed(installStatus)
        }

        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_H),
            UInt32(cmdKey | optionKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else {
            throw HotkeyMonitorError.registerHotkeyFailed(registerStatus)
        }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }
}
