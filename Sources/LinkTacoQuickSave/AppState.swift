import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var draft = DraftBookmark(url: "", title: "", description: "", tags: "")
    @Published var isPopupVisible = false
    @Published var statusMessage = ""

    private let config = AppConfig.loadFromEnvironment()

    func captureFromChromeAndShowPopup() {
        do {
            let tab = try ChromeClient.getActiveTab()
            draft = DraftBookmark(
                url: tab.url,
                title: tab.title,
                description: tab.selectedText,
                tags: ""
            )
            statusMessage = ""
            isPopupVisible = true
            presentAppWindow()
        } catch {
            statusMessage = "Could not read active Chrome tab: \(error.localizedDescription)"
            isPopupVisible = true
            presentAppWindow()
        }
    }

    func presentStartupWindow() {
        presentAppWindow()
    }

    func save() {
        Task {
            do {
                let result = try await BookmarkSaver.save(draft, config: config)
                switch result {
                case .success:
                    statusMessage = "Saved in background."
                case .fallbackRequired(let reason):
                    statusMessage = "API not configured (\(reason)). Opening browser fallback."
                    BookmarkSaver.openBrowserFallback(draft)
                }
                isPopupVisible = false
            } catch {
                statusMessage = "Save failed: \(error.localizedDescription). Opening browser fallback."
                BookmarkSaver.openBrowserFallback(draft)
                isPopupVisible = false
            }
        }
    }

    private func presentAppWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        for window in NSApp.windows {
            window.center()
            if window.canBecomeKey {
                window.makeKeyAndOrderFront(nil)
            } else {
                window.orderFrontRegardless()
            }
        }
    }
}
