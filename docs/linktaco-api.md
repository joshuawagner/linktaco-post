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
- Truncate long response bodies (e.g., 4 KB max).
- Include per-request correlation ID in logs.
- Log path used: `api_success`, `api_failed_fallback_offered`, or `fallback_used`.

## Browser Fallback Contract (`/add`)
When API is unavailable or fails, construct browser fallback URL using percent-encoding for each field.

- Base: `/add`
- Suggested params:
  - `url`
  - `title`
  - `description`
  - `tags`
  - `org` (optional)

### Example
```text
https://linktaco.com/add?url=https%3A%2F%2Fexample.com&title=Example%20title&description=Optional%20description&tags=tag1%2Ctag2&org=my-org
```

## Known Unknowns
- Rate limits
- PAT expiration
- Tag limits
