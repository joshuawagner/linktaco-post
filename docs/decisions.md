# Decisions

## API
- GraphQL only
- No REST

## Auth
- PAT for MVP
- No OAuth
- Token stored in Keychain

## Browser
- Chrome only (MVP)
- Canonical shortcut is `cmd+shift+option+h`
- Selected text capture is attempted only when obtainable with current permissions and expected low latency
- Selected text capture attempt has a hard timeout of 300 ms
- Popup display must never block on selected text capture
- Description defaults to empty when selected text is unavailable

## UX
- Popup before save
- Tags editable
- Org selectable
- Inline save errors before fallback
- Organization list refreshes on app launch, settings open, and explicit manual refresh
- Cache org list with a TTL of 5 minutes
- If stored `orgSlug` is missing from `getOrganizations`, clear invalid selection, force org picker, and block save until a valid active org is selected
- If org list is empty (or all returned orgs are inactive), block save and show actionable guidance to refresh or update account access
- Inactive orgs are never valid save targets and must not be auto-selected

## Fallback
- Keep `/add` browser fallback
- Trigger fallback when API is unavailable, errors, or token is missing
- Fallback URL contract is client-defined (base path, param order, encoding, truncation, org override handling)
- `/add` UI outcomes in docs are treated as expected current behavior, not hard undocumented server guarantees
- Org-selection problems (missing/invalid/inactive/empty org set) are handled in-app first (forced picker + blocked save), not by silently bypassing to fallback

## Reliability
- Deterministic save policy: no auto-retry in MVP
- Treat GraphQL `errors` or missing `data.addLink` as save failure

## Logging
- Debug mode is opt-in
- Never log PAT
- Redact sensitive request metadata
- Adopt the **Debug Logging Safety** policy defined in [`docs/linktaco-api.md`](./linktaco-api.md#debug-logging-safety) for API save-path logging
- Treat log safety requirements as a non-optional baseline for networking and observability changes
- 2026-03-27: Added opt-in popup lifecycle diagnostics behind `LINKTACO_DEBUG_LOGS=1` to trace capture, popup presentation, description editing, org selection, and save/fallback flow without logging PATs or raw bookmark contents
- 2026-03-27: Replaced the popup description `TextEditor` with an AppKit-backed `NSTextView` wrapper as an experiment after correlating `TUINSRemoteViewController` faults with description-field focus teardown
- 2026-03-27: Replaced popup URL, title, and tags `TextField`s with AppKit-backed `NSTextField` wrappers after remaining `TUINSRemoteViewController` faults appeared during field-to-field focus transitions

## Assumptions
- 2026-03-27: The save path is expected to use the documented GraphQL `addLink` mutation with the saved PAT and selected active org; browser fallback remains an explicit user action when save fails.
- 2026-03-27: The in-app PAT settings copy points users to `https://linktaco.com/oauth2/personal` for PAT management.

## Future
- Search feature planned
- Keep architecture modular for GraphQL search UI later

## Documentation
- 2026-03-27: Expanded `docs/architecture.md` interface contracts to include method signatures, model I/O expectations, explicit error surfaces, and a protocol-to-concrete implementation mapping table.
- 2026-03-27: Reconciled `README.md`, `docs/architecture.md`, and `NEXT_STEPS.md` so they describe the current prototype honestly while preserving the agreed MVP target.
- 2026-03-27: Updated docs after implementing the PAT, Keychain, and organization-selection foundation in the current prototype.
- 2026-03-27: Aligned the browser fallback URL builder with the documented `/add` contract by forwarding normalized `tags` and the selected `org` slug from the popup save flow.
- 2026-03-27: Added the LinkTaco PAT management URL (`https://linktaco.com/oauth2/personal`) to the in-app PAT settings copy and setup documentation.
- 2026-03-27: Improved org-refresh UI messaging so the app distinguishes request failures, zero returned organizations, and non-empty but fully inactive organization lists.
