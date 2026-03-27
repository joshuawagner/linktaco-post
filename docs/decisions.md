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
- Selected text capture is best-effort and non-blocking

## UX
- Popup before save
- Tags editable
- Org selectable
- Inline save errors before fallback

## Fallback
- Keep `/add` browser fallback
- Trigger fallback when API is unavailable, errors, or token is missing
- Fallback URL contract is client-defined (base path, param order, encoding, truncation, org override handling)
- `/add` UI outcomes in docs are treated as expected current behavior, not hard undocumented server guarantees

## Reliability
- Deterministic save policy: no auto-retry in MVP
- Treat GraphQL `errors` or missing `data.addLink` as save failure

## Logging
- Debug mode is opt-in
- Never log PAT
- Redact sensitive request metadata
- Adopt the **Debug Logging Safety** policy defined in [`docs/linktaco-api.md`](./linktaco-api.md#debug-logging-safety) for API save-path logging
- Treat log safety requirements as a non-optional baseline for networking and observability changes

## Future
- Search feature planned
- Keep architecture modular for GraphQL search UI later
