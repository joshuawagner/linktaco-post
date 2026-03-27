# LinkTacoQuickSave

A macOS utility to quickly save bookmarks to LinkTaco using a global hotkey.

## Features (MVP)
- Global hotkey: ⌘⇧⌥H (Command+Shift+Option+H)
- Capture active Chrome tab (URL + title)
- Optional selected-text capture (best effort)
- Popup editor before save
- Edit URL, title, description, tags
- Select organization (default + per-save override)
- Background save via LinkTaco GraphQL API
- Browser fallback (`/add`) if API fails or token is unavailable

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

### 4. Configure Token
- Generate a Personal Access Token (PAT) from LinkTaco
- Required scopes:
  - LINKS:RW
  - ORGS:RO
- Paste token into app settings (stored in Keychain)

### 5. First Run
- App fetches organizations after PAT is saved
- Select default organization
- Save popup always allows org override

## Save Behavior
- API save is primary path
- Save is considered failed on transport error, timeout, GraphQL `errors`, or missing `data.addLink`
- On failure, app surfaces inline error and offers browser fallback

## Development Loop
1. Modify code
2. ⌘R to run
3. Test hotkey → popup → save
4. If issues: copy logs → fix

## Debugging
Enable debug mode in settings for API save-path diagnostics, and follow the
**Debug Logging Safety** policy in
[`docs/linktaco-api.md`](docs/linktaco-api.md#debug-logging-safety).

When debug logging is enabled:
- GraphQL operation and variables may be logged only with sensitive values redacted
- HTTP status may be logged
- Response bodies must be truncated/capped
- Save path should be logged (`api_success`, `api_failed_fallback_offered`, `fallback_used`)

## Notes
- GraphQL playground uses production data—be careful testing
- OAuth is intentionally out of scope for MVP
