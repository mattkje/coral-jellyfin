# Coral for Jellyfin — notes for Claude

Custom CSS theme + branding assets for the Jellyfin **12.4** web client, styled after the Coral
music app (accent `#FF6B4A`, warm near-black `#0D0B0A`, Figtree, Tabler icons).

## How it ships
- Servers put one line in Custom CSS: `@import url("https://mattkje.github.io/coral-jellyfin/dist/coral.css");`
  GitHub Pages serves it with a 10-minute cache. (jsDelivr was tried and dropped: 7-day browser cache.)
- So a CSS change = edit → `./build.sh` → commit `dist/` → push. No server action, no Jellyfin restart.
- `install.sh` (run once per server, as root) writes `branding.xml` (the @import, splashscreen) and copies
  favicon / app icons / loading-screen banners into jellyfin-web via `/opt/coral-jellyfin-branding/apply.sh`,
  plus an apt hook that re-applies them after Jellyfin upgrades. Only re-run when `assets/` changes.
  Changing `branding.xml` on disk needs a Jellyfin restart (install.sh does it).

## Build
- `build.sh` → `dist/coral.css` (served) and `dist/coral-holiday.css` (always with the holiday layer, for previews).
- `src/theme.css` has `LOGO_URI` / `GLYPH_URI` placeholders filled from `src/*.svg`.
- Icons: `tabler/map.py` maps Jellyfin `material-icons` class names and MUI `data-testid` icons to Tabler
  names; `tabler/gen.py` emits CSS masks (filled variant when Tabler has one). `@tabler/icons` pinned to 3.24.0.
- Holiday layer: `tools/gen-holiday.py` → `src/holiday.css` (lights, Santa hat, glow, greeting — no snow,
  the user rejected it). Included 1 Dec – 2 Jan (Europe/Oslo) when `holiday.mode` is `auto`; `on`/`off` force it.
  `.github/workflows/seasonal.yml` rebuilds nightly and on pushes to source files, committing only on change.

## Previewing changes before pushing
Signed-in pages can't be checked against a real server without credentials. Approach used so far:
spin up a throwaway Jellyfin (separate data/config dir, different port, a few media folders symlinked),
complete the startup wizard via the API with a dummy user, then run `tools/preview-pages.js`
(Playwright) which injects the local `dist/coral.css` by intercepting **`/Branding/Configuration`**
(12.4 reads Custom CSS from there, not `/Branding/Css`). Always stop and delete the throwaway server after.

## Gotchas learned the hard way
- Jellyfin keeps hidden pages (incl. `#loginPage`) in the DOM: scope page rules with `:not(.hide)`.
- Never force `display: … !important` on things Jellyfin toggles with `.hide`; add a `.hide` override.
- Detail page selectors: artist = `.detailImageContainer .squareCard` without `.musicParentName`;
  show/movie/season = `.detailPagePrimaryContainer > .detailImageContainer .portraitCard`;
  backdrop present = `html:has(.displayingBackdropImage)` (desktop) / `.itemBackdrop[style*="url"]` (mobile).
- `.itemDetailPage` is only one viewport tall; put scrolling gradients on `.detailPageWrapperContainer`.
- `.layout-desktop .detailRibbon` gets a large left padding (poster column) — reset it when hiding the poster.
- `wc -c` counts bytes; the CSS has a few multi-byte characters, so byte and char lengths differ.

## Conventions
- Commits are authored by the repo owner only — no Claude co-author trailer.
- Keep server hostnames/IPs and personal details out of this public repo.
