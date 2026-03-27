# Architecture

## Current Prototype

This repo currently contains a working macOS SwiftUI prototype, not the full MVP architecture described in the target docs.

### Implemented Today

### HotkeyMonitor
- Registers the global hotkey `cmd+shift+option+h`
- Triggers the capture flow in the app

### ChromeClient
- Reads the active Google Chrome tab URL and title via AppleScript
- Does not yet capture selected text

### AppState
- Central SwiftUI `ObservableObject`
- Controls popup visibility and basic status text
- Holds the current draft in memory
- Loads API-related configuration from environment variables

### PopupView
- Basic save form for URL, title, description, and tags
- Closes the popup after save
- Shows a single status message

### BookmarkSaver
- Sends a simple request to a configured endpoint
- Falls back to opening LinkTaco `/add` when API configuration is missing or the request fails

### SearchView / BookmarkSearchService
- Provides a local prototype search screen
- Falls back to sample results when no search endpoint is configured

## Current Flow
Hotkey → ChromeClient → AppState → PopupView → prototype save path or browser fallback

## Current Implementation Notes
- Selected text capture is not implemented yet.
- PAT storage is not implemented yet.
- Org selection is not implemented yet.
- GraphQL save is not implemented yet.
- Debug logging toggles are not implemented yet.
- Search is prototype-only and is not wired to a documented LinkTaco API contract yet.

## Target MVP Architecture

The following architecture is the agreed direction for the MVP, even though several pieces are still pending implementation.

### Components

### HotkeyMonitor
- Registers global hotkey (`cmd+shift+option+h`)
- Triggers callback

### ChromeClient
- Fetches active tab URL/title
- Optionally fetches selected text as a best-effort, non-blocking step

### AppState
- Central state (`SwiftUI ObservableObject`)
- Controls popup visibility
- Stores token, `orgSlug`, and debug settings

### PopupView
- UI for editing bookmark
- Sends save request
- Shows inline save error and fallback option

### BookmarkSaver
- Handles GraphQL API calls
- Handles fallback logic
- Returns deterministic success/failure status

## Planned Interfaces

These protocol contracts describe the intended MVP boundaries. They are not all present in code yet.

### `HotkeyMonitoring`
- Primary methods:
  - `start(handler: @escaping () -> Void) throws`
  - `stop()`
- Input/Output:
  - Input: callback closure for hotkey activation
  - Output: none (callback-driven behavior)
- Error surface:
  - `HotkeyMonitoringError.registrationFailed`
  - `HotkeyMonitoringError.permissionDenied`

### `BrowserTabCapturing`
- Primary methods:
  - `captureActiveTab() async throws -> CapturedTab`
  - `captureSelectedText(timeout: TimeInterval) async -> String?`
- Input/Output:
  - Input: optional selected-text timeout (`TimeInterval`)
  - Output: `CapturedTab` (`url: URL`, `title: String`, optional `selectedText`)
- Error surface:
  - `BrowserTabCapturingError.noSupportedBrowser` (non-Chrome active browser)
  - `BrowserTabCapturingError.scriptExecutionFailed`
  - `BrowserTabCapturingError.noActiveTab`

### `BookmarkSaving`
- Primary methods:
  - `save(input: BookmarkDraft, token: String) async -> SaveResult`
- Input/Output:
  - Input: `BookmarkDraft` (`url`, `title`, `description`, `tags`, `orgSlug?`), PAT token
  - Output: `SaveResult` (`success`, `errorMessage`, optional server metadata)
- Error surface:
  - `SaveResult.failure(.unauthorized)`
  - `SaveResult.failure(.networkFailure)`
  - `SaveResult.failure(.graphqlError)`
  - `SaveResult.failure(.invalidResponse)`

### `OrganizationProviding`
- Primary methods:
  - `fetchOrganizations(token: String) async throws -> [Organization]`
- Input/Output:
  - Input: PAT token
  - Output: `[Organization]` (with `slug`, `name`, `isActive`)
- Error surface:
  - `OrganizationProvidingError.unauthorized`
  - `OrganizationProvidingError.networkFailure`
  - `OrganizationProvidingError.decodingFailure`

### `TokenStoring`
- Primary methods:
  - `save(token: String) throws`
  - `loadToken() throws -> String?`
  - `clearToken() throws`
- Input/Output:
  - Input: PAT token string for save
  - Output: optional PAT token for load
- Error surface:
  - `TokenStoringError.writeFailed`
  - `TokenStoringError.readFailed`
  - `TokenStoringError.deleteFailed`

### `FallbackSaving`
- Primary methods:
  - `openAddURL(from draft: BookmarkDraft) throws`
- Input/Output:
  - Input: `BookmarkDraft`
  - Output: none (attempt to open fallback URL)
- Error surface:
  - `FallbackSavingError.invalidURL`
  - `FallbackSavingError.openFailed`

## Planned Protocol To Implementation
| Protocol | Concrete implementation |
| --- | --- |
| `HotkeyMonitoring` | `CarbonHotkeyMonitor` (or equivalent global hotkey implementation) |
| `BrowserTabCapturing` | `AppleScriptChromeClient` (Chrome-only) |
| `BookmarkSaving` | `URLSessionBookmarkSaver` (GraphQL) |
| `OrganizationProviding` | `URLSessionOrganizationProvider` (GraphQL) |
| `TokenStoring` | `KeychainTokenStore` |
| `FallbackSaving` | `BrowserAddFallbackSaver` (NSWorkspace open URL) |

## Planned Save Flow
1. Build a GraphQL mutation payload from popup fields.
2. Submit the API request with PAT auth.
3. If API succeeds, close popup and show success state.
4. If API fails, show inline error and offer fallback to `/add`.
5. If fallback is selected, open the fallback URL and keep the app responsive.

## Planned Selected Text Policy
- Attempt selected text capture only when it is obtainable with current permissions and expected low latency.
- Use a hard timeout of **300 ms** for any selected text capture attempt.
- Never block popup display on selected text capture.
- Default description to empty when selected text is unavailable.

## Planned Organization Lifecycle
- Fetch organizations after token save and on explicit refresh.
- Cache selected `orgSlug` in UserDefaults.
- If cached `orgSlug` is missing or invalid at save time, force org selection in popup before save.

## Planned Storage
- Token → Keychain
- `orgSlug` + debug/fallback toggles → UserDefaults

## Threading
- UI updates on the main thread
- Network on a background thread
