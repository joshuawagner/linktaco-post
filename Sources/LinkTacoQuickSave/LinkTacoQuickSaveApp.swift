import SwiftUI

@main
struct LinkTacoQuickSaveApp: App {
    @StateObject private var appState = AppState()
    private let monitor: HotkeyMonitor

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        monitor = HotkeyMonitor {
            Task { @MainActor in
                state.captureFromChromeAndShowPopup()
            }
        }
        do {
            try monitor.start()
        } catch {
            state.statusMessage = error.localizedDescription
            Task { @MainActor in
                state.presentStartupWindow()
            }
        }
    }

    var body: some Scene {
        WindowGroup("LinkTaco Quick Save") {
            if appState.isPopupVisible {
                PopupView(appState: appState)
            } else {
                VStack(spacing: 8) {
                    Text("LinkTaco Quick Save")
                        .font(.headline)
                    Text("Use ⌘⌥⇧G in Chrome to capture the active tab.")
                        .foregroundStyle(.secondary)
                    if !appState.statusMessage.isEmpty {
                        Text(appState.statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(20)
                .frame(width: 420, height: 120)
            }
        }
        .windowResizability(.contentSize)
    }
}
