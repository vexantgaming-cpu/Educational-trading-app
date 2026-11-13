// Regenerates the Google Play graphics in docs/play-store/graphics/:
// eight captioned phone screenshots (1080 x 1920) and the feature graphic
// (1024 x 500), taken from the app itself running as a web preview.
//
//   flutter build web --profile --no-web-resources-cdn
//   (cd build/web && python3 -m http.server 8766) &
//   node tool/store_graphics.mjs
//
// Needs Playwright with Chromium, and Python with Pillow for the last step
// (Play wants PNGs without transparency). Set PLAYWRIGHT to the module path
// and PYTHON to the interpreter if they are not on the default paths.
// Change the captions below; the screens come from the routes listed.

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const { chromium } = await import(process.env.PLAYWRIGHT ?? 'playwright');
const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const base = process.env.PREVIEW_URL ?? 'http://localhost:8766';
const outDir = path.join(repo, 'docs/play-store/graphics');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'upwiq-store-'));

// A phone of 380 x 735 at 2x is 760 x 1470 px: it sits in the panel 1:1.
const phone = { width: 380, height: 735 };
const gpu = ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'];

/** Some progress, so the Learn tab doesn't look empty. */
const saved = {
  welcome_seen: 'true',
  theme_mode: '"dark"',
  completed_lessons: JSON.stringify(['L0-01', 'L0-02', 'L0-03', 'L0-04', 'L0-05', 'L0-06', 'L0-07', 'L1-01', 'L1-02', 'L1-03']),
  xp: '185',
};

// file name, route, caption (<em> = highlighted), line under the caption
const shots = [
  ['learn', '/', 'Learn to read<br><em>any market</em>', '28 free lessons, starting from zero'],
  ['touch', '/lesson/L1-02?step=2', 'Lessons you<br><em>can touch</em>', 'A chart and a question at every step'],
  ['simple', '/lesson/L0-05?step=1', 'Every idea,<br><em>explained simply</em>', 'Plain words and clear pictures'],
  ['practice', '/exercise/place-trade', 'Practise<br><em>without risk</em>', 'Plan a trade with a stop-loss and a target'],
  ['daily', '/daily', 'A new challenge<br><em>every day</em>', 'Three quick rounds and a streak to keep'],
  ['session', '/play/EURUSD?day=272', 'Trade a full session<br>with <em>virtual money</em>', 'Simulated markets, news and spread'],
  ['league', '/league', 'Climb the<br><em>weekly league</em>', 'Steady risk beats lucky bets. Rivals are simulated.'],
  ['mind', '/lesson/L7-01?step=1', 'Train your<br><em>mindset</em> too', 'Free lessons on fear, greed and losses'],
];

const browser = await chromium.launch({ args: gpu });

async function openApp(route) {
  const context = await browser.newContext({ viewport: phone, deviceScaleFactor: 2, locale: 'en-US' });
  await context.addInitScript((prefs) => {
    for (const [key, value] of Object.entries(prefs)) localStorage.setItem('flutter.' + key, value);
  }, saved);
  const page = await context.newPage();
  await page.goto(base + '/#' + route);
  await page.waitForTimeout(5000);
  return page;
}

/** The centre of the button whose label starts with [text]. */
async function button(page, text) {
  const spot = await page.evaluate((t) => {
    const element = [...document.querySelectorAll('flt-semantics[role="button"]')].find((e) =>
      (e.innerText || e.getAttribute('aria-label') || '').trim().startsWith(t));
    if (!element) return null;
    const r = element.getBoundingClientRect();
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  }, text);
  if (!spot) throw new Error(`No "${text}" button on screen`);
  return spot;
}

/** Plays the session until the market is open, buys, and pauses. */
async function openATrade(page) {
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(800);
  for (const label of ['1×', 'Play']) {
    const b = await button(page, label);
    await page.mouse.click(b.x, b.y);
    await page.waitForTimeout(300);
  }
  for (let i = 0; i < 60; i++) {
    await page.waitForTimeout(700);
    const preMarket = await page.evaluate(() => document.body.innerText.includes('Pre-market'));
    if (!preMarket && i > 14) break;
  }
  const buy = await button(page, 'BUY');
  await page.mouse.click(buy.x, buy.y);
  await page.waitForTimeout(1800);
  const pause = await button(page, 'Pause');
  await page.mouse.click(pause.x, pause.y);
  await page.mouse.move(4, 420); // away from buttons, so no tooltip shows
  await page.waitForTimeout(900);
}

for (const [name, route] of shots) {
  const page = await openApp(route);
  if (name === 'session') await openATrade(page);
  await page.screenshot({ path: path.join(work, `${name}.png`) });
  await page.context().close();
  console.log('captured', name);
}

const font = (file) => 'file://' + path.join(repo, 'assets/fonts', file);
const css = `
@font-face { font-family: Poppins; font-weight: 600; src: url("${font('Poppins_600SemiBold.ttf')}"); }
@font-face { font-family: Inter; font-weight: 500; src: url("${font('Inter_500Medium.ttf')}"); }
* { box-sizing: border-box; margin: 0; }
body { background: #0b0f15; color: #eaeef3; font-family: Inter, sans-serif; overflow: hidden; }
em { font-style: normal; background: linear-gradient(135deg, #ffb627, #ff7a2f); -webkit-background-clip: text; background-clip: text; color: transparent; }
`;

/** Renders [html] from a real file, so local images and fonts may load. */
async function render(size, html, file) {
  const page = await browser.newPage({ viewport: size, deviceScaleFactor: 1 });
  const source = path.join(work, '_page.html');
  fs.writeFileSync(source, '<!doctype html><meta charset="utf-8">' + html);
  await page.goto('file://' + source);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForFunction(() => [...document.images].every((i) => i.complete && i.naturalWidth > 0));
  await page.screenshot({ path: path.join(work, file) });
  await page.close();
}

for (const [index, [name, , title, subtitle]] of shots.entries()) {
  await render({ width: 1080, height: 1920 }, `<style>${css}
    body { width: 1080px; height: 1920px; background:
      radial-gradient(900px 520px at 50% -60px, rgba(255, 150, 40, 0.20), transparent 70%),
      radial-gradient(700px 700px at 110% 105%, rgba(124, 58, 237, 0.16), transparent 70%),
      linear-gradient(180deg, #111823, #0b0f15 55%); }
    h1 { font: 600 74px/1.12 Poppins; text-align: center; padding-top: 64px; letter-spacing: -0.5px; }
    p { font: 500 35px/1.3 Inter; color: #9aa6b8; text-align: center; margin-top: 20px; }
    .phone { position: absolute; left: 148px; top: 392px; width: 784px; height: 1494px; padding: 12px; border-radius: 56px;
      background: #1b2431; box-shadow: 0 0 0 2px #2c394b, 0 30px 80px rgba(0, 0, 0, 0.55); }
    .phone img { display: block; width: 760px; height: 1470px; border-radius: 44px; }
  </style><h1>${title}</h1><p>${subtitle}</p>
  <div class="phone"><img src="file://${path.join(work, name + '.png')}"></div>`, `screenshot-${index + 1}.png`);
}

const logo = fs
  .readFileSync(path.join(repo, 'docs/brand/logo/upwiq-lockup-horizontal-on-dark.svg'), 'utf8')
  .replace(/<title>.*?<\/title>/, '');
// x, top of body, body height, 1 = up candle
const candles = [[40, 150, 60, 1], [80, 135, 70, 0], [120, 110, 80, 1], [160, 120, 55, 0], [200, 85, 85, 1], [240, 60, 70, 1], [280, 75, 50, 0], [320, 35, 80, 1]];
const candleArt = candles.map(([x, y, h, up]) => {
  const colour = up ? '#19c98b' : '#ff4d6a';
  return `<line x1="${x + 11}" y1="${y - 18}" x2="${x + 11}" y2="${y + h + 16}" stroke="${colour}" stroke-width="3" stroke-linecap="round"/>` +
    `<rect x="${x}" y="${y}" width="22" height="${h}" rx="5" fill="${colour}"/>`;
}).join('');
await render({ width: 1024, height: 500 }, `<style>${css}
  body { width: 1024px; height: 500px; background:
    radial-gradient(520px 380px at 78% 45%, rgba(255, 150, 40, 0.22), transparent 70%),
    radial-gradient(500px 400px at 0% 110%, rgba(124, 58, 237, 0.18), transparent 70%),
    linear-gradient(160deg, #141c28, #0b0f15 60%); }
  .left { position: absolute; left: 72px; top: 96px; width: 520px; }
  .logo svg { height: 78px; width: auto; display: block; }
  h1 { font: 600 54px/1.12 Poppins; margin-top: 44px; letter-spacing: -0.5px; }
  p { font: 500 24px/1.35 Inter; color: #9aa6b8; margin-top: 16px; }
  .art { position: absolute; right: 64px; top: 92px; }
</style>
<div class="left"><div class="logo">${logo}</div><h1>Learn to read<br><em>any market</em></h1><p>Short lessons. Practice trades.<br>Virtual money only.</p></div>
<svg class="art" width="400" height="320" viewBox="0 0 400 320">${candleArt}
  <defs><linearGradient id="t" x1="0" y1="1" x2="1" y2="0"><stop offset="0" stop-color="#FFB627"/><stop offset="1" stop-color="#FF7A2F"/></linearGradient></defs>
  <path d="M20 250 C 110 240, 190 190, 250 130 S 340 50, 372 30" fill="none" stroke="url(#t)" stroke-width="6" stroke-linecap="round"/>
  <path d="M344 26 L374 28 L366 58" fill="none" stroke="url(#t)" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
</svg>`, 'feature-graphic.png');

await browser.close();

// Play accepts 24-bit PNG only: drop the transparency channel.
const finish = spawnSync(process.env.PYTHON ?? 'python3', ['-c', `
import glob, os, sys
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
for f in sorted(glob.glob(os.path.join(src, 'screenshot-*.png')) + [os.path.join(src, 'feature-graphic.png')]):
    Image.open(f).convert('RGB').save(os.path.join(dst, os.path.basename(f)), optimize=True)
    print('wrote', os.path.basename(f))
`, work, outDir], { stdio: 'inherit' });
fs.rmSync(work, { recursive: true, force: true });
if (finish.status !== 0) {
  console.error('Could not write the final PNGs. Is Pillow installed for this Python?');
  process.exit(1);
}
