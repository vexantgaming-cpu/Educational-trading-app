# Upwiq — Design Deck Brief

> **For: Claude Design.** Please create a **brand & product design deck** for Upwiq, a
> mobile app that teaches beginners to read financial markets and lets them compete in
> paper-money trading leagues. Everything you need is below. Where this brief gives exact
> values (colours, fonts, sizes), use them; where it gives directions, explore and pick
> the strongest option, and show your reasoning briefly on the slide.

---

## 1. The product in one minute

- **What it is:** an Android app (iOS later) that combines **bite-sized trading lessons**
  with a **trading game**. Learners study how to read charts, manage risk and handle
  emotions, then practise in realistic simulated trading days and compete in weekly
  leagues — all with **virtual money only**.
- **Who it's for:** adults (18+) in **Europe and the USA** who are curious about markets
  but new to trading — and people who tried trading, lost money, and want to learn
  properly. Many are mobile-first and used to apps like Duolingo and chess.com.
- **How it works:**
  - **Learn:** 65 lessons in 8 levels (Foundations → Market Structure → Risk Management →
    Patterns → Indicators → Market Context → Trading Plan → Trading Psychology). Each lesson
    is 3–5 minutes: short explanations with charts, quizzes, "tap the chart" questions.
  - **Practice:** interactive exercises, e.g. drag a stop-loss and take-profit on a chart,
    then watch the trade play out.
  - **League (the game):** once a day, pick a market (EUR/USD, Gold, US 500, Bitcoin, …),
    read the simulated **morning news** that sets a bias, and trade an 08:00–16:00 session
    at realistic bid/ask prices. A **13:30 news release** shakes things up. Weekly leagues
    (Bronze → Silver → Gold → Platinum → Diamond → Master) in groups of 30: **top 10 move
    up, bottom 10 move down**, like chess.com leagues.
- **Business model:** free lessons (Levels 0–2 plus 3 psychology lessons) and free daily
  league play; **Premium** subscription unlocks Levels 3–7, unlimited practice and
  advanced statistics.

## 2. The name

- **Upwiq** — pronounced **"up-wick"**.
  - **up** — progress, levelling up, a rising market.
  - **wiq** — a candlestick's **wick** (the thin line showing a price's high/low); the
    **"q"** hints at **IQ** — the learning side.
- Always written **Upwiq** in text (capital U only). The logo wordmark may be lowercase
  (`upwiq`) if it looks better — show both and recommend one.
- **Tagline options** (pick one, or propose better):
  1. *Learn the charts. Climb the leagues.* ← current favourite
  2. *Read the market. Rank up.*
  3. *Trading skills, levelled up.*

## 3. Brand personality

| We are | We are not |
|---|---|
| Encouraging, clear, beginner-friendly | Condescending or jargon-heavy |
| Competitive and fun (game energy) | Casino-like, flashy "get rich" hype |
| Honest about risk; calm under pressure | Fear-driven or sensational |
| Premium and modern (fintech-grade polish) | Childish or cartoonish |

**Visual mood:** a "night market" — deep, calm dark surfaces lit by warm gold-to-orange
highlights, like a trading floor at dusk. Inspired by the energy of crypto-exchange apps,
but clearly its own brand.

## 4. Existing design system (keep — this is already built)

The app is built (Flutter) with this system. Refine it, don't replace it, unless you
show a clearly better option side by side.

### Colours: dark theme (default)
| Token | Hex | Use |
|---|---|---|
| background | `#0B0F15` | App background |
| surface | `#131922` | Cards |
| surfaceHigh | `#1A222E` | Raised elements, banners |
| surfaceHighest | `#232D3B` | Tracks, disabled |
| outline | `#283343` | Borders, dividers |
| text | `#EAEEF3` | Primary text |
| textMuted | `#8A96A8` | Secondary text |
| **gold** (primary) | `#FFB627` | Accent, highlights |
| **orange** | `#FF7A2F` | Gradient partner (gold → orange) |
| onGold | `#1B1203` | Text on gold |
| up (market green) | `#19C98B` | Rising candles, profit, "Buy" |
| down (market red) | `#FF4D6A` | Falling candles, loss, "Sell", stop-loss |
| cyan | `#3CC8F0` | Info, support zones, entry markers |
| violet / violetDeep | `#A78BFA` / `#7C3AED` | **Premium** only |

### Colours: light theme (the app also has a light mode, switchable in Account)
| Token | Hex | Notes |
|---|---|---|
| background | `#F5F7FB` | Soft cool grey |
| surface | `#FFFFFF` | Cards |
| surfaceHigh | `#EEF1F6` | Raised elements, banners |
| surfaceHighest | `#E3E8F0` | Tracks, disabled |
| outline | `#D8DEE8` | Borders |
| text | `#111827` | Primary text |
| textMuted | `#5B6577` | Secondary text |
| gold (text/icons) | `#A86500` | Deeper gold for readable text on white |
| orange (text) | `#C2410C` | Warnings, breaking news |
| up | `#06855C` | Market green |
| down | `#D92D4A` | Market red |
| cyan | `#0A7EA4` | Info |
| violet / violetDeep | `#6D28D9` / `#5B21B6` | Premium |
| hero card gradient | `#FFFFFF → #EEF2F8` | |

Every text colour above is checked for at least 4.5:1 contrast on cards (WCAG AA).
The **gold → orange gradient on buttons is identical in both themes** (bright
`#FFB627 → #FF7A2F` with dark text `#1B1203`).

- **Signature:** the **gold → orange gradient** (`#FFB627 → #FF7A2F`, top-left to
  bottom-right) on primary buttons, highlights and the logo.
- **Premium gradient:** `#C4B5FD → #7C3AED`.
- **Hero card gradient:** `#1E2736 → #121820`.

### Typography (bundled in the app, SIL Open Font License)
- **Poppins** — headings, numbers that matter (600–700).
- **Inter** — body text and UI (400–600).

### Shape & spacing
- Radius: buttons 14, cards 18–20, hero cards 24, pills fully round.
- 8-point spacing grid; 16 px screen side margins.

### Level colours (each level has an icon on a 2-colour gradient tile)
| Level | Icon idea | Gradient |
|---|---|---|
| 0 Market Foundations | foundation / building blocks | `#38BDF8 → #2563EB` |
| 1 Market Structure | stacked line chart | `#34D399 → #059669` |
| 2 Risk Management | shield | `#FFC857 → #FF7A2F` |
| 3 Candlestick & Chart Patterns | candlesticks | `#F472B6 → #DB2777` |
| 4 Indicators | gauge | `#A78BFA → #7C3AED` |
| 5 Market Context | globe | `#22D3EE → #0E7490` |
| 6 Your Trading Plan | checklist | `#FB923C → #EA580C` |
| 7 Trading Psychology | head / brain | `#FB7185 → #BE185D` |

### League colours (crest = shield with a star; chevrons show the level)
| League | Gradient |
|---|---|
| Bronze | `#F0B27A → #9A5B2E` |
| Silver | `#F1F5F9 → #94A3B8` |
| Gold | `#FFE08A → #D99A00` |
| Platinum | `#99F6E4 → #14B8A6` |
| Diamond | `#BAE6FD → #3B82F6` |
| Master | `#F5D0FE → #9333EA` |

## 5. What the deck should contain

Please produce the deck in this order (one topic per slide unless noted):

1. **Cover** — Upwiq logo, tagline, phone mockup.
2. **Brand story** — one-liner, mission, audience, the name's meaning.
3. **Brand personality** — the "we are / we are not" table, mood words, a mood board.
4. **Logo exploration** — 3 directions (see §6), then the **recommended logo**:
   wordmark, symbol, lockups (horizontal + stacked), on dark **and light** backgrounds
   (the app has both themes).
5. **Logo usage** — clear space, minimum sizes, do's and don'ts.
6. **App icon** — final icon + Android **adaptive icon** (foreground/background layers)
   and **monochrome themed icon**; shown on a home screen.
7. **Colour system** — both palettes above (dark and light), gradients, usage
   proportions, and a **contrast check** (WCAG AA for text). Suggest refinements if any
   token fails.
8. **Typography** — type scale (display → caption) with sizes/weights/line heights.
9. **Iconography & illustration** — style rules + the 4 tab key visuals (§7).
10. **Level badges** — all 8 level tiles.
11. **League crests** — all 6 crests (Bronze → Master) + the promotion celebration.
12. **Core components** — buttons (gradient primary, outlined, buy/sell), pills
    (Free / Premium / "3 free" / Coming soon), cards, collapsible level card, stepper,
    segmented control, bid/ask ticker, news card, leaderboard row (promotion zone green,
    demotion zone red, "You" highlighted gold), chart line styles (§8).
13–14. **Key screens** (2 slides, phone frames 393 × 852) — see §9. Show the main
    screens in **dark**, and at least the Learn tab, League tab and trading session in
    **light** too.
15. **Motion** — short notes for: level card expand, XP gained, lesson complete, league
    promotion, "breaking news" banner.
16. **Google Play assets** — icon, feature graphic, screenshot set (§10).
17. **Do's & don'ts / compliance** — §11.
18. **Hand-off** — token table and asset list (§12).

## 6. Logo directions to explore

- **A — "The wick-q":** wordmark `upwiq` where the **descender of the q is a candle
  wick** (thin line) and the bowl reads as a candle body; optionally the dot of the **i**
  becomes a small gold flame/spark.
- **B — "Rising wick" symbol:** a single candlestick whose **upper wick extends into an
  upward arrow or spark** — simple enough for the app icon at 48 px.
- **C — "U-cup":** a **U** that doubles as a **trophy cup**, with a candle wick rising from
  its centre — combines *learning to rise* with *winning leagues*.

Requirements: legible at 24 px, works in one colour, built on the gold → orange
gradient over the dark background; geometric and clean (pairs with Poppins).

## 7. Tab key visuals (current, to be refined)

Each main tab opens with a hero card: headline (one word highlighted with the gradient)
plus a vector illustration on the right. Current concepts — keep the ideas, raise the craft:

| Tab | Headline | Illustration |
|---|---|---|
| Learn | "Learn to read **any market**" | An open book with candlesticks rising out of it and a gold trend arrow |
| Practice | "Practice **without risk**" | A phone showing a chart with stop (red) and target (green) lines, a crosshair, a gold \$ coin |
| League | "Bronze **League**" | The league crest (shield + star) with a glow |
| Account | "Your rank **Rookie**" | A trophy inside a gold progress ring, with confetti |

Style: flat vector with soft gradients and a subtle glow; 2–3 colours per illustration
from the palette; no photography; no people required (if people appear: diverse, adult).

## 8. Chart styling (inside the app)

- Candles: up `#19C98B`, down `#FF4D6A`; volume bars same colours at 35% opacity.
- Lines: **stop-loss** red, **take-profit** green, **entry** muted grey dashed, pending
  **order** cyan; draggable lines have a round grip handle at the right.
- Price tags on the right axis in the line's colour; moving average in gold.
- Support zone cyan, resistance zone orange (translucent bands).

## 9. Key screens to mock up

Use realistic content (below). Phone frame 393 × 852. Dark theme first; light variants
as listed in §5. The Account screen has an **Appearance** switch (Dark / Light / Auto).

1. **Learn tab** — brand bar (logo + "120 XP" pill), hero card, progress bar
   ("3 of 65 lessons"), "YOUR PATH": collapsible level cards (Level 0 open showing lessons
   with completed ✓, current ▶, locked 🔒).
2. **Lesson — quiz step** — progress bar, question "A stock shows bid 49.95 and ask 50.05.
   You buy at market. What price do you pay?", 4 options, "Correct!" feedback banner.
3. **Lesson complete** — trophy, "+25 XP", "Back to lessons".
4. **League tab** — crest hero ("Gold League · Week 40 · ends in 3d 5h"), rank pill
   "#7 of 30", "+3.4% this week", Today's session card, leaderboard preview, league ladder.
5. **Market picker** — cards per market with the morning headline, impact dots, spread,
   leverage (e.g. *Gold — "Central banks report continued gold buying" — 13:30 US jobs report*).
6. **Trading session** — bid/ask ticker (SELL 3715.50 | BUY 3715.80, spread \$0.30),
   morning news bar, chart with stop/target lines, account strip (balance, equity, today,
   margin level), order ticket (Buy/Sell, Mkt/Limit/Stop, stop-loss & take-profit steppers,
   size with 0.5% / 1% / 2% risk, a big green "BUY 0.06 @ 3715.80").
7. **Breaking news moment** — the 13:30 banner in orange, spread widened, replay paused.
8. **Day summary** — "+\$196.99 (+1.97%)", rank pill, chart with entry/exit markers,
   "What the news did", "Your trades", "Coach notes".
9. **Leaderboard** — 30 rows with promotion (top 10) and demotion (bottom 10) zones.
10. **Premium paywall** — value-led ("Unlock Levels 3–7, unlimited practice, advanced
    stats"), clear price and trial terms, restore purchases. Violet premium styling.

## 10. Google Play store assets

- **App icon:** 512 × 512 PNG (32-bit with alpha).
- **Feature graphic:** 1024 × 500 (JPEG or 24-bit PNG, no transparency) — logo, tagline,
  a phone with the trading session; keep key content away from the edges.
- **Phone screenshots:** a set of **6**, portrait 1080 × 1920 (9:16), each with a short
  caption on top, e.g.:
  1. "Learn to read any market" (Learn tab)
  2. "Bite-sized lessons, real charts" (lesson)
  3. "Trade a real market day — with virtual money" (session)
  4. "News moves markets. Can you read it?" (breaking news)
  5. "Climb weekly leagues" (league / leaderboard)
  6. "Master risk and emotions" (psychology level)
- **Store text (drafts — refine the tone):**
  - Title (≤ 30 chars): **Upwiq: Learn Trading & Play**
  - Short description (≤ 80 chars): *Learn to read any market, then compete in paper-money
    trading leagues.*

## 11. Do's, don'ts and compliance (important)

- **Virtual money only.** Wherever money or trading appears, the design must not suggest
  real-money trading or guaranteed profit. Use labels like "virtual \$10,000", "simulated".
- **No gambling imagery:** no slot machines, dice, poker chips, jackpots, money rain or
  "big win" casino effects. Celebrate **good decisions** (stop-loss used, plan followed),
  not just profit.
- **No real brands:** no broker, exchange or bank logos; no real company names in news
  mock-ups (the app's only company example is the fictional **Nova Robotics**).
- **Don't imitate Binance** (or any exchange): avoid flat yellow `#F0B90B` on black and
  diamond-style logos. Our identity is the **gold → orange gradient** + night palette.
- **Accessibility:** WCAG AA contrast for text; never rely on colour alone (pair red/green
  with icons, labels or arrows); minimum tap target 48 × 48 dp.
- **Tone in mock-up copy:** plain English, short sentences, encouraging; avoid hype
  ("10x your money", "get rich").

## 12. Hand-off format (so the app can be updated quickly)

- **Logo & icon:** SVG (vector) + PNG at 1×/2×/3×; Android adaptive icon as two
  108 × 108 dp layers (foreground with the symbol inside the 66 dp safe zone, background
  solid/gradient) + a monochrome version.
- **Illustrations:** SVG, each on a transparent background, in a square artboard.
- **Tokens:** a table (or JSON) of every colour (for **both** themes), gradient, font
  size/weight, radius and spacing value, using the token names in §4 (add new ones if
  needed).
- **Store assets:** final PNG/JPEG files at the sizes in §10.
- Keep layer and file names in English, lowercase-with-hyphens (e.g. `app-icon-foreground.svg`).

---

*Reference: current app screenshots are attached separately (learn, practice, league,
trading session, day summary). The product plan is in `docs/PLAN.md` of the app repository.*
