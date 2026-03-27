# Next Steps

## Immediate
- Verify the existing hotkey → popup flow end to end
- Replace the prototype Chrome capture with reliable URL + title capture
- Keep popup editing behavior stable while adding the missing org/token UI
- Decide whether the prototype Search tab should stay visible until the real GraphQL search path exists

## API
- Add PAT input and Keychain storage
- Fetch organizations after token save and on refresh
- Persist the selected `orgSlug`

## Save Flow
- Replace the prototype request with the GraphQL `addLink` mutation
- Handle GraphQL and transport errors without auto-retrying
- Preserve the `/add` browser fallback contract
- Add org-aware fallback behavior only where it matches the documented client contract

## Debugging
- Add a debug mode toggle
- Log request/response metadata safely, with PAT redaction
- Keep verbose payload logging opt-in only

## After MVP
- Revisit bookmark search as a separate feature
- Polish the popup UI after the MVP save path is complete
