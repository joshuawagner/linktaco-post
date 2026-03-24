import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var draft = DraftBookmark(url: "", title: "", description: "", tags: "")
    @Published var searchQuery = ""
    @Published var searchResults: [BookmarkSearchResult] = []
    @Published var isPopupVisible = false
    @Published var isSearching = false
    @Published var statusMessage = ""
    @Published var searchStatusMessage = ""

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
        Task { @MainActor in
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

    func runSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            searchStatusMessage = "Enter a search term to find bookmarks."
            return
        }

        isSearching = true
        searchStatusMessage = config.hasSearchAPIConfig
            ? "Searching LinkTaco..."
            : "Search API not configured yet. Showing local placeholder results."

        Task { @MainActor in
            defer { isSearching = false }

            do {
                let results = try await BookmarkSearchService.search(query: query, config: config)
                searchResults = results
                searchStatusMessage = results.isEmpty
                    ? "No bookmarks matched \"\(query)\"."
                    : "Found \(results.count) bookmark\(results.count == 1 ? "" : "s")."
            } catch {
                searchResults = []
                searchStatusMessage = "Search failed: \(error.localizedDescription)"
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
