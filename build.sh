#!/bin/sh
# Builds dist/coral.css from src/theme.css, the logos and the Tabler icon map.
# Needs node + python3; installs @tabler/icons into ./tabler on first run.
set -e; cd "$(dirname "$0")"
[ -d tabler/node_modules/@tabler/icons ] || (cd tabler && npm install --silent)
python3 tabler/gen.py > dist/icons.css
node -e '
const fs=require("fs");
const enc=s=>"data:image/svg+xml;charset=utf-8,"+encodeURIComponent(s).replace(/%20/g," ").replace(/%3D/g,"=").replace(/%3A/g,":").replace(/%2F/g,"/");
const css=fs.readFileSync("src/theme.css","utf8")
  .split("LOGO_URI").join(enc(fs.readFileSync("src/logo-dark.svg","utf8")))
  .split("GLYPH_URI").join(enc(fs.readFileSync("src/glyph.svg","utf8")));
fs.writeFileSync("dist/coral.css", css+"\n"+fs.readFileSync("dist/icons.css","utf8"));'
rm dist/icons.css
echo "built dist/coral.css ($(wc -c < dist/coral.css) bytes)"
