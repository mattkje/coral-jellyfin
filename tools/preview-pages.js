// node pages.js <prefix> [d|m|dm]  — screenshots detail pages with local CSS injected
const { chromium, devices } = require('playwright'); const fs = require('fs');
// Screenshots item pages of a Jellyfin server with the local dist/coral.css injected (no deploy needed).
// usage: JF_URL=http://host:8096 JF_USER=u JF_PASS=p ONLY=series,album node tools/preview-pages.js out-prefix [d|m|dm]
const BASE = (process.env.JF_URL || 'http://localhost:8096') + '/web/';
const pages = JSON.parse(process.env.PAGES || '{}'); // e.g. {"series":"<item id>"}
const only = process.env.ONLY ? process.env.ONLY.split(',') : Object.keys(pages);
const pre = process.argv[2] || 'p', modes = process.argv[3] || 'dm';
async function run(opts, tag) {
  const b = await chromium.launch(); const p = await (await b.newContext(opts)).newPage();
  const css = () => fs.readFileSync(require('path').join(__dirname, '../dist/coral.css'), 'utf8');
  await p.route('**/Branding/Css*', r => r.fulfill({ contentType: 'text/css', body: css() }));
  await p.route('**/Branding/Configuration*', async r => { const j = await (await r.fetch()).json(); j.CustomCss = css(); r.fulfill({ json: j }); });
  await p.goto(BASE + '#/login', { waitUntil: 'networkidle' }); await p.waitForTimeout(1500);
  await p.fill('#txtManualName', process.env.JF_USER || ''); await p.fill('#txtManualPassword', process.env.JF_PASS || '');
  await p.click('.manualLoginForm button[type=submit]'); await p.waitForTimeout(3500);
  for (const k of only) {
    await p.goto(BASE + '#/details?id=' + pages[k]); await p.waitForTimeout(3500);
    await p.screenshot({ path: `${pre}-${tag}-${k}.png`, fullPage: !!process.env.FULL });
    if (process.env.SCROLL) { await p.evaluate(y => { const s = document.querySelector('.itemDetailPage:not(.hide)'); window.scrollTo(0, y); (s && s.closest('.scrollY') || document.scrollingElement).scrollTop = y; }, +process.env.SCROLL); await p.waitForTimeout(1500); await p.screenshot({ path: `${pre}-${tag}-${k}-s.png` }); }
    if (process.env.DUMP) fs.writeFileSync(`${pre}-${tag}-${k}.html`, await p.evaluate(() => { const e = document.querySelector('.itemDetailPage:not(.hide)') || document.body; return e.outerHTML.replace(/ d="[^"]*"/g, '').slice(0, 40000); }));
  }
  await b.close();
}
(async () => { if (modes.includes('d')) await run({ viewport: { width: 1440, height: 900 } }, 'd'); if (modes.includes('m')) await run({ ...devices['iPhone 13'] }, 'm'); })();
