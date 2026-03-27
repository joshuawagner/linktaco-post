# LinkTacoQuickSave

A macOS SwiftUI prototype for quickly capturing the active Chrome tab and preparing a LinkTaco bookmark save.

## Current Prototype
- Global hotkey: `⌘⇧⌥H` (`Command+Shift+Option+H`)
- Captures the active Chrome tab URL and title
- Prefills the popup with captured data
- Lets you edit URL, title, description, and tags before saving
- Opens a browser fallback (`/add`) when save is unavailable or fails
- Includes a simple in-app search screen backed by either configured API access or local placeholder results

## What Is Not Implemented Yet
- PAT settings UI
- Keychain token storage
- Organization picker
- GraphQL save flow
- Debug mode toggle
- Reliable selected-text capture

## Setup

### 1. Requirements
- macOS 13+
- Xcode 15+
- Chrome (MVP browser integration)

### 2. Run
Open `Package.swift` in Xcode and press Run.

### 3. Permissions
Grant:
- Accessibility (global hotkey)
- Automation (Chrome tab access)

### 4. Optional Environment Configuration
The current prototype reads API settings from environment variables when they are present:

- `LINKTACO_CREATE_ENDPOINT`
- `LINKTACO_SEARCH_ENDPOINT`
- `LINKTACO_BEARER_TOKEN`

If these are not set, the app still runs, but save/search behavior falls back to local placeholder behavior where available.

### 5. First Run
- Open the app and use the hotkey in Chrome to capture the current tab
- Review or edit the popup fields before saving
- If API access is not configured, the app opens the browser fallback path

## Save Behavior
- Save currently uses the app's configured endpoint if one is provided
- If save cannot proceed, the app opens the browser fallback path
- The prototype does not yet implement the full LinkTaco GraphQL contract described in `docs/linktaco-api.md`

## Development Loop
1. Modify code
2. ⌘R to run
3. Test hotkey → popup → save
4. If issues: copy logs → fix

## Search
- The app includes a search tab in the window
- When search API settings are not provided, it shows local placeholder results
- Search is a prototype surface and not yet the final LinkTaco bookmark search experience

## Debugging
- There is no debug toggle UI yet
- If you add logging, follow the **Debug Logging Safety** policy in
  [`docs/linktaco-api.md`](docs/linktaco-api.md#debug-logging-safety)

## Notes
- The long-term target remains the LinkTaco GraphQL/PAT workflow described in `docs/decisions.md`
- OAuth is intentionally out of scope for the MVP
- The prototype is intentionally lightweight while the API and save flow are still being wired up
- Search is currently exposed as a prototype screen even though the planned bookmark search feature is still future work
