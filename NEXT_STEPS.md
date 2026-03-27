# Next Steps

## Immediate
- Verify the existing hotkey → popup flow end to end
- Verify PAT save/load, org refresh, cache reuse, and org selection behavior
- Replace the prototype Chrome capture with reliable URL + title capture
- Decide whether the prototype Search tab should stay visible until the real GraphQL search path exists

## GraphQL Save Path
- Replace the prototype request with the GraphQL `addLink` mutation
- Submit the saved PAT and selected `orgSlug`
- Block save when org selection is missing, invalid, or inactive
- Handle GraphQL and transport errors without auto-retrying

## Save Flow
- Preserve the `/add` browser fallback contract
- Add org-aware fallback behavior only where it matches the documented client contract
- Add inline save errors before offering fallback

## Debugging
- Add a debug mode toggle
- Log request/response metadata safely, with PAT redaction
- Keep verbose payload logging opt-in only

## After MVP
- Revisit bookmark search as a separate feature
- Polish the popup UI after the MVP save path is complete
