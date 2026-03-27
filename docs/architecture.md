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

## Protocol to Implementation (MVP)
| Protocol | Concrete implementation |
| --- | --- |
| `HotkeyMonitoring` | `CarbonHotkeyMonitor` (or equivalent global hotkey implementation) |
| `BrowserTabCapturing` | `AppleScriptChromeClient` (Chrome-only) |
| `BookmarkSaving` | `URLSessionBookmarkSaver` (GraphQL) |
| `OrganizationProviding` | `URLSessionOrganizationProvider` (GraphQL) |
| `TokenStoring` | `KeychainTokenStore` |
| `FallbackSaving` | `BrowserAddFallbackSaver` (NSWorkspace open URL) |

## Flow
Hotkey → ChromeClient → AppState → PopupView → BookmarkSaver → API or fallback

## Save Flow Contract
1. Build GraphQL mutation payload from popup fields.
2. Submit API request with PAT.
3. If API succeeds, close popup and show success state.
4. If API fails, show inline error and offer fallback to `/add`.
5. If fallback is selected, open fallback URL and keep app responsive.

## Selected Text Capture Policy
- Attempt selected text capture only when it is obtainable with current permissions and expected low latency.
- Use a hard timeout of **300 ms** for any selected text capture attempt.
- Never block popup display on selected text capture.
- Default description to empty when selected text is unavailable.

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
