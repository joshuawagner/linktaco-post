# Kickoff Plan: Move Project from "initialized" to "in progress"

## MVP Scope (2-week target)

### Goal
Ship a usable first version of LinkTaco that lets a user save links with lightweight metadata, browse saved links, and manage items.

### In Scope (MVP)
- Basic project scaffolding and runtime setup.
- Minimal API/service layer for links:
  - Create a link.
  - List links.
  - Update link metadata.
  - Archive/delete a link.
- Data model for link records:
  - URL
  - title
  - notes
  - tags (simple list)
  - status (`active` / `archived`)
  - created/updated timestamps
- Simple UI (or CLI fallback) to:
  - Add a link.
  - See the saved-link list.
  - Filter by tag/status.
- Basic quality gates:
  - lint + format configuration
  - smoke tests for core create/list flow
  - README with local run instructions

### Out of Scope (Post-MVP)
- Authentication/authorization.
- Browser extension ingestion.
- Full-text search and ranking.
- Sharing/collaboration.
- Analytics dashboard.

### Definition of Done (MVP)
- Team can run the app locally in under 10 minutes from clone.
- User can complete save → view → update → archive flow end-to-end.
- Core flows covered by basic automated tests.
- Initial backlog exists for next milestone.

## Execution Approach

### Milestones
1. **Foundation (Days 1-3):** scaffold, lint/test baseline, data model.
2. **Core Flow (Days 4-8):** create/list/update/archive endpoints + minimal UI path.
3. **Stabilize (Days 9-10):** tests, bugfix pass, README polish, backlog grooming.

### Working Cadence
- Daily async standup in thread.
- Mid-sprint MVP demo.
- End-sprint ship check against Definition of Done.

## First 3 Tickets (ready to start now)

### Ticket 1 — Project skeleton + dev workflow baseline
**Type:** Engineering setup  
**Priority:** P0  
**Estimate:** 1 day

**Scope**
- Set up app skeleton (service + interface layer).
- Add formatter/linter config and scripts.
- Add test runner with one smoke test.
- Add `.env.example` and local startup docs.

**Acceptance Criteria**
- `install`, `run`, `test`, and `lint` commands are documented and working.
- CI-ready script commands exist in the repository.
- One smoke test passes in local execution.

**Deliverables**
- Scaffolded source tree.
- Tooling config.
- Updated README quickstart.

---

### Ticket 2 — Link domain model + persistence + CRUD API
**Type:** Backend core feature  
**Priority:** P0  
**Estimate:** 2–3 days

**Scope**
- Implement `Link` model with required fields.
- Add storage layer (SQLite/file-backed/in-memory with clean abstraction).
- Implement endpoints or commands for create/list/update/archive.
- Validate URL input and enforce required fields.

**Acceptance Criteria**
- Link can be created and returned with generated ID + timestamps.
- List returns all active links and supports status filtering.
- Update modifies title/notes/tags.
- Archive marks status and excludes from default active list.
- Basic API/command tests cover happy path + validation failures.

**Deliverables**
- Model + repository/storage implementation.
- CRUD handlers.
- Unit/integration tests for core operations.

---

### Ticket 3 — Minimal user surface for add + browse + filter
**Type:** Frontend/UX (or CLI UX)  
**Priority:** P1  
**Estimate:** 2 days

**Scope**
- Build basic interaction surface for:
  - Add link form/input.
  - List view of saved links.
  - Filter by tag/status.
- Show validation and empty states.
- Wire to core CRUD endpoints/commands.

**Acceptance Criteria**
- User can add link and immediately see it in list.
- User can filter by one tag and by archived/active status.
- Empty states are explicit and actionable.
- No blocking console/runtime errors in default flow.

**Deliverables**
- MVP interaction surface.
- Basic UX copy for errors/empty states.
- Short usage section in README.

## Immediate Next Step
Start **Ticket 1** now, and open **Ticket 2** in parallel with final API contract drafted before implementation.
