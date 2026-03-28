# LinkTacoQuickSave

A macOS SwiftUI prototype for quickly capturing the active Chrome tab and preparing a LinkTaco bookmark save.

## Current Prototype
- Global hotkey: `⌘⇧⌥H` (`Command+Shift+Option+H`)
- Captures the active Chrome tab URL and title
- Prefills the popup with captured data
- Lets you edit URL, title, description, and tags before saving
- Supports PAT entry in the app and stores the PAT in Keychain
- Loads organizations from LinkTaco and lets you select an active org in the app
- Opens a browser fallback (`/add`) when save is unavailable or fails
- Includes a simple in-app search screen backed by either configured API access or local placeholder results

## What Is Not Implemented Yet
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

- `LINKTACO_SEARCH_ENDPOINT`
- `LINKTACO_BEARER_TOKEN`

If these are not set, the app still runs, but search behavior falls back to local placeholder behavior where available. `LINKTACO_BEARER_TOKEN` can also seed the initial token field when no Keychain PAT has been saved yet.

### 5. First Run
- Create or manage your PAT at `https://linktaco.com/oauth2/personal`
- Open the app and use the hotkey in Chrome to capture the current tab
- Save a PAT and refresh organizations
- Choose an active organization in the main view or popup
- Review or edit the popup fields before saving
- If save cannot proceed, the app offers the browser fallback path

## Save Behavior
- Save uses the LinkTaco GraphQL `addLink` mutation with the saved PAT and selected org
- Save blocks when the selected org is missing, invalid, or inactive
- If save cannot proceed because the PAT is missing or the API returns an error, the app offers the browser fallback path

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
