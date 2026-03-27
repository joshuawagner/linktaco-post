# Architecture

## Components

### HotkeyMonitor
- Registers global hotkey (`cmd+shift+option+h`)
- Triggers callback

### ChromeClient
- Fetches active tab URL/title
- Optionally fetches selected text (best-effort, non-blocking)

### AppState
- Central state (SwiftUI ObservableObject)
- Controls popup visibility
- Stores token/orgSlug and debug settings

### PopupView
- UI for editing bookmark
- Sends save request
- Shows inline save error and fallback option

### BookmarkSaver
- Handles API calls
- Handles fallback logic
- Returns deterministic success/failure status

## Interfaces

Define protocol contracts so implementations can be swapped and tested.

### `HotkeyMonitoring`
- `start(handler: @escaping () -> Void)`
- `stop()`

### `BrowserTabCapturing`
- `captureActiveTab() async throws -> CapturedTab`
- `captureSelectedText(timeout: TimeInterval) async -> String?`

### `BookmarkSaving`
- `save(input: BookmarkDraft, token: String) async -> SaveResult`

### `OrganizationProviding`
- `fetchOrganizations(token: String) async throws -> [Organization]`

### `TokenStoring`
- `save(token: String) throws`
- `loadToken() throws -> String?`
- `clearToken() throws`

### `FallbackSaving`
- `openAddURL(from draft: BookmarkDraft) throws`

## Concrete Implementations (MVP)
- `CarbonHotkeyMonitor` (or equivalent global hotkey implementation) → `HotkeyMonitoring`
- `AppleScriptChromeClient` → `BrowserTabCapturing`
- `GraphQLBookmarkSaver` (URLSession) → `BookmarkSaving`
- `GraphQLOrganizationProvider` (URLSession) → `OrganizationProviding`
- `KeychainTokenStore` → `TokenStoring`
- `BrowserAddFallbackSaver` (NSWorkspace open URL) → `FallbackSaving`

## Flow
Hotkey → ChromeClient → AppState → PopupView → BookmarkSaver → API or fallback

## Save Flow Contract
1. Build GraphQL mutation payload from popup fields.
2. Submit API request with PAT.
3. If API succeeds, close popup and show success state.
4. If API fails, show inline error and offer fallback to `/add`.
5. If fallback is selected, open fallback URL and keep app responsive.

## Selected Text Capture Policy
- Attempt selected text capture only if it is fast and reliable in current session.
- Cap selected text attempt at **300 ms**.
- Never block popup display waiting for selected text.
- If unavailable, set description to blank.

## Organization Lifecycle
- Fetch organizations after token save and on explicit refresh.
- Cache selected `orgSlug` in UserDefaults.
- If cached `orgSlug` is missing/invalid at save time, force org selection in popup before save.

## Storage
- Token → Keychain
- orgSlug + debug/fallback toggles → UserDefaults

## Threading
- UI updates on main thread
- Network on background thread
