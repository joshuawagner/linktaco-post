import AppKit
import Foundation
import OSLog
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var draft = DraftBookmark(url: "", title: "", description: "", tags: "")
    @Published var searchQuery = ""
    @Published var searchResults: [BookmarkSearchResult] = []
    @Published var tokenInput = ""
    @Published var organizations: [Organization] = []
    @Published var selectedOrganizationSlug = "" {
        didSet {
            persistSelectedOrganizationSlug()
        }
    }
    @Published var isPopupVisible = false
    @Published var isSearching = false
    @Published var isRefreshingOrganizations = false
    @Published var isSaving = false
    @Published var isShowingBrowserFallbackOption = false
    @Published var statusMessage = ""
    @Published var searchStatusMessage = ""
    @Published var configurationStatusMessage = ""
    @Published private(set) var activeCaptureID = UUID().uuidString

    private let config = AppConfig.loadFromEnvironment()
    private let tokenStore = KeychainTokenStore()
    private let organizationService = OrganizationService()
    private let userDefaults = UserDefaults.standard
    private var savedBearerToken = ""

    private enum StorageKey {
        static let selectedOrganizationSlug = "selectedOrgSlug"
        static let organizationCache = "cachedOrganizations"
        static let organizationCacheTimestamp = "cachedOrganizationsTimestamp"
    }

    private let organizationCacheTTL: TimeInterval = 5 * 60

    init() {
        selectedOrganizationSlug = userDefaults.string(forKey: StorageKey.selectedOrganizationSlug) ?? ""

        do {
            savedBearerToken = (try tokenStore.loadToken())?.trimmedForAppUse ?? config.bearerToken?.trimmedForAppUse ?? ""
            tokenInput = savedBearerToken
        } catch {
            savedBearerToken = config.bearerToken?.trimmedForAppUse ?? ""
            tokenInput = savedBearerToken
            configurationStatusMessage = "Could not read the saved PAT from Keychain."
        }

        if let cachedOrganizations = loadCachedOrganizationsIfFresh() {
            applyOrganizations(cachedOrganizations)
            if configurationStatusMessage.isEmpty {
                configurationStatusMessage = "Loaded organizations from the local cache."
            }
        } else if savedBearerToken.isEmpty {
            configurationStatusMessage = "Save a PAT to Keychain to load organizations."
        }

        if !savedBearerToken.isEmpty && organizations.isEmpty {
            Task {
                await refreshOrganizations(force: true)
            }
        }
    }

    var activeOrganizations: [Organization] {
        organizations
            .filter(\.isActive)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var hasSavedPAT: Bool {
        !savedBearerToken.isEmpty
    }

    var organizationPickerHint: String {
        if isRefreshingOrganizations {
            return "Refreshing organizations..."
        }

        if !hasSavedPAT {
            return "Save a PAT with LINKS:RW and ORGS:RO scopes to load organizations."
        }

        if organizations.isEmpty {
            return "No organizations are loaded yet. Use Refresh Orgs and check the status message below for the exact result."
        }

        if activeOrganizations.isEmpty {
            return "Organizations loaded, but none are active for this PAT."
        }

        if selectedOrganizationSlug.isEmpty {
            return "Choose an organization now so the future GraphQL save path has a valid org target."
        }

        if let selectedOrganization {
            return "Selected organization: \(selectedOrganization.name)."
        }

        return "Choose an active organization."
    }

    var selectedOrganization: Organization? {
        activeOrganizations.first { $0.slug == selectedOrganizationSlug }
    }

    var hasValidActiveOrganizationSelection: Bool {
        !activeOrganizations.isEmpty && selectedOrganization != nil
    }

    var canSaveDraft: Bool {
        !isSaving
            && !draft.url.trimmedForAppUse.isEmpty
            && !draft.title.trimmedForAppUse.isEmpty
            && hasValidActiveOrganizationSelection
    }

    var isDebugLoggingEnabled: Bool {
        config.debugLoggingEnabled
    }

    func captureFromChromeAndShowPopup() {
        activeCaptureID = UUID().uuidString
        isShowingBrowserFallbackOption = false
        logDebug(
            "capture_started id=\(activeCaptureID) popupVisible=\(isPopupVisible)"
        )

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
            logDebug(
                "capture_succeeded id=\(activeCaptureID) titleLength=\(draft.title.count) descriptionLength=\(draft.description.count)"
            )
            presentAppWindow()
        } catch {
            statusMessage = "Could not read active Chrome tab: \(error.localizedDescription)"
            isPopupVisible = true
            logDebug(
                "capture_failed id=\(activeCaptureID) error=\(String(describing: error))"
            )
            presentAppWindow()
        }
    }

    func presentStartupWindow() {
        presentAppWindow()
    }

    func savePAT() {
        let trimmedToken = tokenInput.trimmedForAppUse

        Task { @MainActor in
            do {
                if trimmedToken.isEmpty {
                    try tokenStore.clearToken()
                    savedBearerToken = ""
                    tokenInput = ""
                    organizations = []
                    clearCachedOrganizations()
                    configurationStatusMessage = "Cleared the saved PAT."
                    return
                }

                try tokenStore.save(token: trimmedToken)
                savedBearerToken = trimmedToken
                tokenInput = trimmedToken
                configurationStatusMessage = "Saved PAT to Keychain."
                await refreshOrganizations(force: true)
            } catch {
                configurationStatusMessage = "Could not save the PAT to Keychain: \(error.localizedDescription)"
            }
        }
    }

    func clearPAT() {
        tokenInput = ""
        savePAT()
    }

    func refreshOrganizationsManually() {
        Task { @MainActor in
            await refreshOrganizations(force: true)
        }
    }

    func handleSelectedOrganizationChange(_ slug: String) {
        logDebug(
            "org_selection_changed id=\(activeCaptureID) hasSelection=\(!slug.isEmpty)"
        )

        guard !slug.isEmpty else {
            configurationStatusMessage = "Select an active organization before the GraphQL save path is enabled."
            return
        }

        if let organization = activeOrganizations.first(where: { $0.slug == slug }) {
            configurationStatusMessage = "Selected organization: \(organization.name)."
        } else {
            selectedOrganizationSlug = ""
            configurationStatusMessage = "Choose an active organization from the list."
        }
    }

    func save() {
        logDebug(
            "save_tapped id=\(activeCaptureID) popupVisible=\(isPopupVisible) hasOrgSelection=\(!selectedOrganizationSlug.isEmpty)"
        )

        Task { @MainActor in
            isShowingBrowserFallbackOption = false

            guard !draft.url.trimmedForAppUse.isEmpty, !draft.title.trimmedForAppUse.isEmpty else {
                statusMessage = "URL and title are required before saving."
                return
            }

            if hasSavedPAT, isOrganizationCacheStale {
                statusMessage = "Refreshing organizations before saving..."
                await refreshOrganizations(force: true)
            }

            guard hasValidActiveOrganizationSelection else {
                statusMessage = activeOrganizations.isEmpty
                    ? "No active organizations are available yet. Refresh or verify account access."
                    : "Choose a valid active organization before saving."
                return
            }

            guard !savedBearerToken.isEmpty else {
                statusMessage = "No saved PAT is available. Open the browser fallback instead."
                isShowingBrowserFallbackOption = true
                return
            }

            isSaving = true
            defer { isSaving = false }

            do {
                let result = try await BookmarkSaver.save(
                    draft,
                    context: BookmarkSaveContext(orgSlug: selectedOrganizationSlug),
                    config: resolvedAppConfig()
                )
                switch result {
                case .success:
                    statusMessage = "Saved to LinkTaco."
                    isPopupVisible = false
                    logDebug(
                        "save_completed id=\(activeCaptureID) path=api_success popupVisible=\(isPopupVisible)"
                    )
                case .fallbackRequired(let reason):
                    statusMessage = "\(reason). Open the browser fallback below."
                    isShowingBrowserFallbackOption = true
                    logDebug(
                        "save_completed id=\(activeCaptureID) path=api_failed_fallback_offered popupVisible=\(isPopupVisible)"
                    )
                }
            } catch {
                statusMessage = "Save failed: \(error.localizedDescription). Open the browser fallback below."
                isShowingBrowserFallbackOption = true
                logDebug(
                    "save_completed id=\(activeCaptureID) path=api_failed_fallback_offered popupVisible=\(isPopupVisible)"
                )
            }
        }
    }

    func openBrowserFallback() {
        BookmarkSaver.openBrowserFallback(draft, orgSlug: selectedOrganizationSlug)
        isShowingBrowserFallbackOption = false
        isPopupVisible = false
        statusMessage = "Opened browser fallback."
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
                let results = try await BookmarkSearchService.search(query: query, config: resolvedAppConfig())
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

    private func resolvedAppConfig() -> AppConfig {
        AppConfig(
            createBookmarkEndpoint: config.createBookmarkEndpoint,
            searchBookmarksEndpoint: config.searchBookmarksEndpoint,
            bearerToken: savedBearerToken.isEmpty ? nil : savedBearerToken,
            debugLoggingEnabled: config.debugLoggingEnabled
        )
    }

    private var isOrganizationCacheStale: Bool {
        guard let timestamp = userDefaults.object(forKey: StorageKey.organizationCacheTimestamp) as? Date else {
            return true
        }

        return Date().timeIntervalSince(timestamp) >= organizationCacheTTL
    }

    private func refreshOrganizations(force: Bool) async {
        guard !savedBearerToken.isEmpty else {
            organizations = []
            clearCachedOrganizations()
            configurationStatusMessage = "Save a PAT to Keychain to load organizations."
            return
        }

        if !force, let cachedOrganizations = loadCachedOrganizationsIfFresh() {
            applyOrganizations(cachedOrganizations)
            configurationStatusMessage = "Loaded organizations from the local cache."
            return
        }

        isRefreshingOrganizations = true
        defer { isRefreshingOrganizations = false }

        do {
            let fetchedOrganizations = try await organizationService.fetchOrganizations(
                token: savedBearerToken,
                endpoint: config.graphqlEndpoint
            )
            applyOrganizations(fetchedOrganizations)
            persistOrganizationsCache(fetchedOrganizations)

            if organizations.isEmpty {
                configurationStatusMessage = "Organization refresh succeeded, but the API returned 0 organizations."
            } else if activeOrganizations.isEmpty {
                configurationStatusMessage = "Loaded \(organizations.count) organization\(organizations.count == 1 ? "" : "s"), but none are active for this PAT."
            } else if selectedOrganizationSlug.isEmpty {
                configurationStatusMessage = "Loaded \(activeOrganizations.count) active organization\(activeOrganizations.count == 1 ? "" : "s"). Choose one to continue."
            } else if let selectedOrganization {
                configurationStatusMessage = "Organizations refreshed. Using \(selectedOrganization.name). Loaded \(activeOrganizations.count) active organization\(activeOrganizations.count == 1 ? "" : "s")."
            }
        } catch {
            if organizations.isEmpty, let cachedOrganizations = loadCachedOrganizationsIfFresh() {
                applyOrganizations(cachedOrganizations)
                configurationStatusMessage = "Could not refresh organizations: \(error.localizedDescription). Using cached data for now."
                return
            }

            configurationStatusMessage = "Could not refresh organizations: \(error.localizedDescription)"
        }
    }

    private func applyOrganizations(_ incomingOrganizations: [Organization]) {
        organizations = incomingOrganizations.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        guard !selectedOrganizationSlug.isEmpty else {
            return
        }

        if !activeOrganizations.contains(where: { $0.slug == selectedOrganizationSlug }) {
            selectedOrganizationSlug = ""
            configurationStatusMessage = activeOrganizations.isEmpty
                ? "No active organizations are available yet."
                : "Your saved organization is no longer valid. Choose another active organization."
        }
    }

    private func loadCachedOrganizationsIfFresh() -> [Organization]? {
        guard let timestamp = userDefaults.object(forKey: StorageKey.organizationCacheTimestamp) as? Date,
              Date().timeIntervalSince(timestamp) < organizationCacheTTL,
              let data = userDefaults.data(forKey: StorageKey.organizationCache),
              let decodedOrganizations = try? JSONDecoder().decode([Organization].self, from: data)
        else {
            return nil
        }

        return decodedOrganizations
    }

    private func persistOrganizationsCache(_ organizations: [Organization]) {
        guard let encodedOrganizations = try? JSONEncoder().encode(organizations) else {
            return
        }

        userDefaults.set(encodedOrganizations, forKey: StorageKey.organizationCache)
        userDefaults.set(Date(), forKey: StorageKey.organizationCacheTimestamp)
    }

    private func clearCachedOrganizations() {
        userDefaults.removeObject(forKey: StorageKey.organizationCache)
        userDefaults.removeObject(forKey: StorageKey.organizationCacheTimestamp)
    }

    private func persistSelectedOrganizationSlug() {
        if selectedOrganizationSlug.isEmpty {
            userDefaults.removeObject(forKey: StorageKey.selectedOrganizationSlug)
        } else {
            userDefaults.set(selectedOrganizationSlug, forKey: StorageKey.selectedOrganizationSlug)
        }
    }

    private func presentAppWindow() {
        logDebug(
            "present_window id=\(activeCaptureID) windowCount=\(NSApp.windows.count)"
        )
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

    private func logDebug(_ message: String) {
        guard config.debugLoggingEnabled else {
            return
        }

        AppLogger.logger.debug("\(message, privacy: .public)")
    }
}
