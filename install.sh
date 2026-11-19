#!/bin/sh
# Coral theme for Jellyfin — one-time server install.
#
#   sudo ./install.sh                 # link the theme CSS from the CDN (updates follow the repo)
#   sudo ./install.sh --inline        # embed dist/coral.css instead (works offline, no auto-updates)
#   sudo ./install.sh --no-restart    # write everything but don't restart Jellyfin
#   CSS_URL=https://... sudo ./install.sh   # link a different CSS URL (e.g. a pinned tag)
#
# What it does (Debian/Ubuntu package installs of Jellyfin):
#   1. Custom CSS in branding.xml  -> @import of the theme (or the whole file with --inline)
#   2. Splashscreen                -> assets/splashscreen.png
#   3. Favicon, app icons, loading screen -> copied into jellyfin-web by /opt/coral-jellyfin-branding/apply.sh
#      (originals saved in /opt/coral-jellyfin-branding/orig), plus an apt hook that re-applies them after upgrades
#   4. Restarts Jellyfin so the new branding.xml is loaded
set -e
REPO_URL_DEFAULT="https://mattkje.github.io/coral-jellyfin/dist/coral.css"
CSS_URL="${CSS_URL:-$REPO_URL_DEFAULT}"
INLINE=0; RESTART=1
for a in "$@"; do case "$a" in
  --inline) INLINE=1 ;; --no-restart) RESTART=0 ;;
  -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
  *) echo "unknown option: $a" >&2; exit 1 ;;
esac; done
[ "$(id -u)" = 0 ] || { echo "run as root (sudo)" >&2; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"

# Jellyfin paths (from /etc/default/jellyfin when present)
JELLYFIN_CONFIG_DIR=/etc/jellyfin; JELLYFIN_DATA_DIR=/var/lib/jellyfin
[ -r /etc/default/jellyfin ] && . /etc/default/jellyfin
CONF="$JELLYFIN_CONFIG_DIR"; DATA="$JELLYFIN_DATA_DIR"; WEB=/usr/share/jellyfin/web
[ -d "$CONF" ] && [ -d "$WEB" ] || { echo "Jellyfin not found ($CONF, $WEB)" >&2; exit 1; }
OWNER="$(stat -c %U "$DATA" 2>/dev/null || echo jellyfin)"

# 1+2: branding.xml (keeps the login disclaimer if one is set)
SPLASH="$DATA/data/splashscreen-upload.png"
install -o "$OWNER" -g "$OWNER" -m 644 "$HERE/assets/splashscreen.png" "$SPLASH"
[ -f "$CONF/branding.xml" ] && cp -a "$CONF/branding.xml" "$CONF/branding.xml.bak-$(date +%Y%m%d-%H%M%S)"
if [ "$INLINE" = 1 ]; then CSS_FILE="$HERE/dist/coral.css"; else CSS_FILE=""; fi
python3 - "$CONF/branding.xml" "$SPLASH" "$CSS_URL" "$CSS_FILE" <<'PY'
import sys, os, re
from xml.sax.saxutils import escape
path, splash, url, css_file = sys.argv[1:5]
disclaimer = ''
if os.path.exists(path):
    m = re.search(r'<LoginDisclaimer>(.*?)</LoginDisclaimer>', open(path, encoding='utf-8').read(), re.S)
    disclaimer = m.group(1) if m else ''
css = open(css_file, encoding='utf-8').read() if css_file else f'@import url("{url}");\n'
open(path, 'w', encoding='utf-8').write(f'''<?xml version="1.0" encoding="utf-8"?>
<BrandingOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <LoginDisclaimer>{disclaimer}</LoginDisclaimer>
  <CustomCss>{escape(css)}</CustomCss>
  <SplashscreenEnabled>true</SplashscreenEnabled>
  <SplashscreenLocation>{escape(splash)}</SplashscreenLocation>
</BrandingOptions>
''')
PY
chown "$OWNER:$OWNER" "$CONF/branding.xml"

# 3: icons, loading screen, apt hook
DEST=/opt/coral-jellyfin-branding
mkdir -p "$DEST"
cp -r "$HERE/assets/icons/." "$DEST/"
chmod +x "$DEST/apply.sh"
"$DEST/apply.sh"
if [ -d /etc/apt/apt.conf.d ]; then
  echo "DPkg::Post-Invoke { \"[ -x $DEST/apply.sh ] && $DEST/apply.sh || true\"; };" > /etc/apt/apt.conf.d/99coral-jellyfin
fi

# 4: restart
if [ "$RESTART" = 1 ]; then
  systemctl restart jellyfin
  echo "Jellyfin restarted."
else
  echo "Restart Jellyfin to load the new branding.xml."
fi
if [ "$INLINE" = 1 ]; then echo "Custom CSS: embedded dist/coral.css"; else echo "Custom CSS: @import $CSS_URL"; fi
