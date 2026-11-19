# Coral for Jellyfin

A warm, modern theme for the Jellyfin web client, based on the Coral app: coral accent (`#FF6B4A`),
Figtree type, Tabler icons (filled where available), a streaming-app style hero on show/movie pages,
a centred full-bleed artist page, a frosted side menu and a mobile-friendly layout.

Built for and tested on **Jellyfin 12.4** (web client). Older versions get the colours and most styling,
but some layout rules target 12.x markup.

## Install on a server

The theme has two parts:

| Part | How it gets there | Updates |
|---|---|---|
| Theme CSS (`dist/coral.css`) | One `@import` line in **Dashboard → General → Custom CSS** | Automatic: push to `main` |
| Splashscreen, favicon, app icons, loading screen | `install.sh` copies files into the server | Re-run `install.sh` |

On a Debian/Ubuntu package install, clone the repo on the server and run:

```sh
sudo ./install.sh            # links the CSS from the CDN, installs splash + icons, restarts Jellyfin
sudo ./install.sh --inline   # embeds the CSS instead (no CDN dependency, no automatic updates)
```

The installer backs up `branding.xml`, keeps any login disclaimer, saves the original jellyfin-web
icons in `/opt/coral-jellyfin-branding/orig/`, and adds an apt hook that re-applies the icons after
Jellyfin upgrades.

**CSS only** (any install type, including Docker): paste this into Custom CSS and save:

```css
@import url("https://cdn.jsdelivr.net/gh/mattkje/coral-jellyfin@main/dist/coral.css");
```

## Updating the theme

```sh
# edit src/theme.css (or tabler/map.py for icons), then
./build.sh
git commit -am "…" && git push
curl -s https://purge.jsdelivr.net/gh/mattkje/coral-jellyfin@main/dist/coral.css   # skip jsDelivr's cache
```

jsDelivr caches `@main` files for up to 12 hours unless purged. Browsers may also keep the old file
for a while, so use a hard refresh (Ctrl+Shift+R) to check a change.

## Layout

```
src/theme.css        the theme (LOGO_URI / GLYPH_URI are filled in by build.sh)
src/*.svg            Coral logos used in the header, side menu and sign-in card
tabler/map.py        Jellyfin icon name -> Tabler icon name
tabler/gen.py        turns the map into CSS masks (run by build.sh)
dist/coral.css       built theme (commit it; this is what servers load)
assets/              splashscreen and the web-client icon files used by install.sh
tools/               preview script that screenshots a server with the local CSS injected
```

## Credits

Icons: [Tabler Icons](https://tabler.io/icons) (MIT). Font: [Figtree](https://fonts.google.com/specimen/Figtree) (OFL).
Artist page layout inspired by [ElegantFin](https://github.com/lscambo13/ElegantFin).
