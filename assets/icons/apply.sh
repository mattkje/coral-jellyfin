#!/bin/sh
# Copies the Coral icons over jellyfin-web's icons (originals saved to ./orig the first time).
set -e
SRC=/opt/coral-jellyfin-branding; WEB=/usr/share/jellyfin/web
[ -d "$WEB" ] || exit 0
put() { for f in $WEB/$2; do [ -e "$f" ] || continue; mkdir -p "$SRC/orig"; [ -e "$SRC/orig/$(basename "$f")" ] || cp -a "$f" "$SRC/orig/"; cp "$SRC/$1" "$f"; done; }
put favicon.ico 'favicon.*.ico'
put touchicon.png 'touchicon.*.png'
put touchicon144.png 'touchicon144.*.png'
put icon-transparent.png 'icon-transparent.*.png'
put notificationicon.png 'notificationicon.*.png'
for s in 72 114 144 512; do put favicons/touchicon$s.png favicons/touchicon$s.png; done
put favicons/touchicon.png favicons/touchicon.png
sed -i 's/"theme_color": *"[^"]*"/"theme_color": "#0D0B0A"/; s/"background_color": *"[^"]*"/"background_color": "#0D0B0A"/' $WEB/manifest.json
# startup loading screen (shown before custom CSS loads)
put banner-light.png 'banner-light.*.png'
put banner-dark.png 'banner-dark.*.png'
[ -e "$SRC/orig/index.html" ] || cp -a $WEB/index.html "$SRC/orig/index.html"
sed -i 's/html{background-color:#101010;/html{background-color:#0D0B0A;/g; s/name="theme-color" content="#202020"/name="theme-color" content="#0D0B0A"/' $WEB/index.html
