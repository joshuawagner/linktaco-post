# LinkTaco API Reference (Project-Specific)

## Official Docs
- GraphQL: https://man.code.netlandish.com/~netlandish/links/graphql.md
- OAuth: https://man.code.netlandish.com/~netlandish/links/oauth.md
- Schema: https://api.linktaco.com/linktaco/

## Endpoint
POST https://api.linktaco.com/query

## UI Trigger Context
- Save flow is initiated by the global shortcut `cmd+shift+option+h` in the desktop app.

## Auth
- Authorization: Bearer <TOKEN>
- Use Personal Access Token (PAT)
- OAuth NOT used for MVP
- Never log raw token values

## Required Scopes
- LINKS:RW
- ORGS:RO

## GraphQL Request Format
```json
{
  "query": "...",
  "variables": { ... }
}
```

## Bookmark Creation

### Mutation
`addLink`

### Input: `LinkInput`
Required:
- url
- title
- orgSlug
- unread (false)
- starred (false)
- archive (false)

Optional:
- description
- tags (string)
- visibility

Ignore:
- override
- parseBaseUrl

### Operation String (Centralized)
Keep this operation string in one place in code so it can be updated quickly during live testing.

```graphql
mutation AddLink($input: LinkInput) {
  addLink(input: $input) {
    id
    title
    description
    url
    hash
    visibility
    unread
    starred
    archiveUrl
    type
    tags { name slug }
    author
    orgSlug
    createdOn
    updatedOn
    baseUrlHash
  }
}
```

### Example Variables
```json
{
  "input": {
    "url": "https://example.com",
    "title": "Example title",
    "description": "Optional description",
    "tags": "tag1,tag2",
    "orgSlug": "<ORG_SLUG>",
    "unread": false,
    "starred": false,
    "archive": false
  }
}
```

## Organization Discovery

### Query
```graphql
query GetOrganizations($input: GetOrganizationsInput) {
  getOrganizations(input: $input) {
    id
    ownerId
    orgType
    name
    slug
    image
    timezone
    isActive
    visibility
    createdOn
    updatedOn
    ownerName
  }
}
```

### Caching Rules
- Fetch after PAT entry/update.
- Fetch on explicit manual refresh.
- Cache org list for current app session.
- Persist selected `orgSlug` in UserDefaults.
- If persisted slug is not returned by `getOrganizations`, block save and require a new selection.

## Search (Future)
- `getOrgLinks`
- `getBookmarks`

## Save Failure Policy
- Request timeout: **3 seconds**.
- Automatic retries: **none in MVP** (avoid accidental duplicate saves).
- Fallback trigger conditions:
  - network transport error,
  - timeout,
  - non-2xx HTTP,
  - GraphQL `errors` present,
  - missing `data.addLink`.
- If token is missing, skip API and offer direct fallback.
- Always show clear inline error before fallback action.

## Error Handling
- HTTP 200 may still contain GraphQL errors.
- If `errors` is present, treat as failed save.
- If `data.addLink` is missing/null, treat as failed save.

## Operational Constraints
- Complexity limit: 200
- Time limit: ~3s
- Default page size: 40

## Debug Logging Safety
Debug mode may log request/response metadata, but must avoid sensitive leakage.

- Redact full `Authorization` header.
- Do not log PAT in any form.
- Log GraphQL query and variables with sensitive values stripped.
- Optionally hash or truncate URL query strings in logs.
- Truncate/cap long response bodies (e.g., 4 KB max).
- Include per-save-attempt correlation ID in logs.
- Disable verbose payload logs by default; only emit when explicit debug toggle is enabled.
- Log path used: `api_success`, `api_failed_fallback_offered`, or `fallback_used`.

## Browser Fallback Contract (`/add`)
When API save is unavailable, clients MUST open a browser URL against LinkTaco's add page using the following client-side contract.
This section defines what the desktop app sends; it does not assert undocumented server-side guarantees beyond observed current behavior.

### Endpoint and query shape

- **Method:** `GET`
- **Base URL:** `https://linktaco.com/add`
- **Required query params (in this order for deterministic generation):**
  1. `next=same`
  2. `url=<encoded source URL>`
  3. `description=<encoded description>`
  4. `title=<encoded title>`
- **Optional query params:**
  - `tags=<encoded tags>`
  - `org=<encoded org override>`

If `tags` is empty, omit `tags`. If `org` is empty, omit `org`.

### Encoding rules

All fallback values MUST be UTF-8 encoded and URL query encoded (RFC 3986 semantics for query values).

- `url`: Full absolute URL string of the source page.
- `title`: Human-readable bookmark title.
- `description`: Free-text notes/selection.
- `tags`: Comma-separated tag list (for example: `swift,macos,bookmarking`) encoded as a single query value.
- `org`: Organization slug (for example: `acme-dev`) encoded as a single query value.

Encoding requirements:

- Percent-encode reserved characters such as space (`%20`), comma (`%2C`), ampersand (`%26`), and plus (`%2B`) in query values.
- Do not double-encode values.
- Preserve Unicode characters via UTF-8 percent encoding.

### Maximum lengths and truncation behavior

Apply limits **before** query encoding:

- `url`: max **2048** characters
- `title`: max **300** characters
- `description`: max **2000** characters
- `tags`: max **500** characters total (comma-separated form)
- `org`: max **64** characters

If a field exceeds its maximum length, the client truncates to max length, then encodes.

Additional tag normalization before the 500-character total limit check:

1. Split on commas.
2. Trim whitespace around each tag.
3. Remove empty tags.
4. Re-join with `,`.

### Org override behavior

The LinkTaco UI has a user default org context.
Client requirement: include `org` when user-selected org override differs from default org; otherwise omit it.

- If `org` is **omitted**, `/add` uses the authenticated user's default org.
- If `org` is provided and **matches** the current default org, `/add` behaves identically to omission.
- If `org` is provided and **differs** from the default org, current UI behavior is expected to preselect the provided org for this add flow.
- If `org` is invalid or inaccessible to the user, current UI behavior is expected to use default org (and may surface a non-blocking notice).

### Concrete example (encoded)

```text
https://linktaco.com/add?next=same&url=https%3A%2F%2Fexample.com%2Fpost%3Fa%3D1%26b%3D2&description=Deep%20dive%20on%20Swift%20concurrency%20%26%20actors&title=Swift%20Concurrency%20Guide&tags=swift%2Cmacos%2Casync-await&org=engineering-core
```

This example is intended as an implementation verification fixture for fallback URL construction.

## Known Unknowns
- Rate limits
- PAT expiration
- Tag limits
