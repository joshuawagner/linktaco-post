# LinkTaco Quick Save (macOS)

A tiny local macOS app prototype for quickly saving bookmarks to LinkTaco with a global hotkey.

## What this prototype includes

- Global hotkey: `⌘⌥⇧H`
- Reads active Google Chrome tab metadata (URL + title)
- Opens a popup editor where you can:
  - modify title
  - modify description
  - add tags
- Attempts background save via API (when configured)
- Fallback behavior if API is not configured
- Search tab scaffold for future bookmark lookup

## Why API details are needed

Your current bookmarklet works by redirecting the browser to LinkTaco's `/add` URL while authenticated.
For true **background saving** without opening a visible browser tab, this app needs a proper API endpoint and auth mechanism.

Without API details, the app can still prefill data and prepare payloads, but final save must use a browser redirect.

The search view is also wired for a future API integration. Until the search endpoint is configured, it shows placeholder local results so the UI flow can be developed now.

## Build notes

This repository is designed for building on macOS with Xcode 15+.

```bash
swift build
```

## GitHub workflow

The repository already has an `origin` remote configured. A good next-step flow is:

```bash
git push -u origin <branch-name>
```

Then open a pull request from that branch on GitHub when you want review or a mergeable checkpoint.

## Next step for you

Please provide details requested in `docs/API_INFO_REQUEST.md`.
