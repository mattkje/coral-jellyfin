#!/bin/sh
# Builds the theme:
#   dist/coral.css          what servers load; includes the holiday layer only from 1 Dec to 2 Jan (Europe/Oslo)
#   dist/coral-holiday.css  always includes the holiday layer (for previewing it any time of year)
# holiday.mode decides: auto (date range), on, or off. HOLIDAY=on|off in the environment overrides it.
# Needs node + python3; installs @tabler/icons into ./tabler on first run.
set -e; cd "$(dirname "$0")"
[ -d tabler/node_modules/@tabler/icons ] || (cd tabler && npm install --silent)
python3 tabler/gen.py > dist/icons.css
python3 tools/gen-holiday.py > /dev/null

[ -n "$HOLIDAY" ] || HOLIDAY=$(tr -d ' \n' < holiday.mode 2>/dev/null || echo auto)
if [ "$HOLIDAY" = auto ]; then
  md=$(TZ=Europe/Oslo date +%m%d)
  if [ "$md" -ge 1201 ] || [ "$md" -le 0102 ]; then HOLIDAY=on; else HOLIDAY=off; fi
fi

node -e '
const fs=require("fs");
const enc=s=>"data:image/svg+xml;charset=utf-8,"+encodeURIComponent(s).replace(/%20/g," ").replace(/%3D/g,"=").replace(/%3A/g,":").replace(/%2F/g,"/");
const base=fs.readFileSync("src/theme.css","utf8")
  .split("LOGO_URI").join(enc(fs.readFileSync("src/logo-dark.svg","utf8")))
  .split("GLYPH_URI").join(enc(fs.readFileSync("src/glyph.svg","utf8")))
  +"\n"+fs.readFileSync("dist/icons.css","utf8");
const holiday=base+"\n"+fs.readFileSync("src/holiday.css","utf8");
fs.writeFileSync("dist/coral-holiday.css",holiday);
fs.writeFileSync("dist/coral.css",process.argv[1]==="on"?holiday:base);' "$HOLIDAY"
rm dist/icons.css
echo "built dist/coral.css ($(wc -c < dist/coral.css) bytes, holiday $HOLIDAY) and dist/coral-holiday.css"
