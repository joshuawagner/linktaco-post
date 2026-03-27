# AGENTS.md

## Fixed Decisions
- Swift macOS app (SwiftUI)
- Chrome-only MVP
- Hotkey: cmd+opt+shift+h
- Popup before save
- Tags supported
- Organization picker included
- GraphQL API only
- PAT authentication (no OAuth)
- Browser fallback retained

## Source of Truth
- API + contract: docs/linktaco-api.md
- Architecture: docs/architecture.md
- Roadmap: docs/roadmap.md
- Decisions: docs/decisions.md

## Constraints
- Do NOT build REST client
- Do NOT implement OAuth in MVP
- Do NOT remove fallback behavior
- Do NOT assume undocumented API behavior

## Working Rules
- Always consult docs before coding
- Update docs/decisions.md for changes
- Keep changes small and isolated
- Log assumptions explicitly

## Parallel Work
- One agent per task
- Avoid editing same files
- Shared files require coordination

## File Ownership (initial)
- API + networking: one agent
- UI + popup: one agent
- Chrome capture + hotkey: one agent
