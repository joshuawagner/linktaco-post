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

## Assumptions
- 2026-03-27: PAT storage and organization-selection foundation may land before the GraphQL save path. Until `addLink` is implemented, the prototype save flow may continue using the configured prototype endpoint/browser fallback and does not yet require or transmit the selected org.

## Future
- Search feature planned
- Keep architecture modular for GraphQL search UI later

## Documentation
- 2026-03-27: Expanded `docs/architecture.md` interface contracts to include method signatures, model I/O expectations, explicit error surfaces, and a protocol-to-concrete implementation mapping table.
- 2026-03-27: Reconciled `README.md`, `docs/architecture.md`, and `NEXT_STEPS.md` so they describe the current prototype honestly while preserving the agreed MVP target.
- 2026-03-27: Updated docs after implementing the PAT, Keychain, and organization-selection foundation in the current prototype.
