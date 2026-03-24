import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
    case quickSave = "Quick Save"
    case search = "Search"

    var id: String { rawValue }
}

@main
struct LinkTacoQuickSaveApp: App {
    @StateObject private var appState = AppState()
    @State private var selectedSection: AppSection = .quickSave
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
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Section", selection: $selectedSection) {
                        ForEach(AppSection.allCases) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch selectedSection {
                    case .quickSave:
                        VStack(spacing: 8) {
                            Text("LinkTaco Quick Save")
                                .font(.headline)
                            Text("Use ⌘⌥⇧H in Chrome to capture the active tab.")
                                .foregroundStyle(.secondary)
                            if !appState.statusMessage.isEmpty {
                                Text(appState.statusMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .search:
                        SearchView(appState: appState)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(20)
                .frame(width: 760, height: 480)
            }
        }
        .windowResizability(.contentSize)
    }
}
