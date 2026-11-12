# Linux Essentials animations — desktop layout (phase 1)

Same player, stylesheet, JSON schema and look as the Git & GitHub and Docker sets.

| File | What it is |
|---|---|
| `linux-animations.json` | 6 lessons, 40 subtopics, 143 steps (desktop / landscape layout, 1000x400 stage) |
| `LinuxAnimation.jsx` | Drop-in wrapper: `<LinuxAnimation id="02.4" />` (title match also works) |
| `StepAnimation.jsx`, `StepAnimation.css`, `stepEngine.js` | Unchanged copies of the shared player, so this folder is self-contained |
| `preview.html` | Demo with Git / Docker / Linux switch (needs internet for React/Babel from cdnjs) |
| `generators/` | Source. Edit `m1.js`-`m6.js` (one per lesson), run `node build-linux.js` to regenerate the JSON |
| `tools/` | Layout checks: `check.py` renders every step in headless Chromium and reports overlaps, clipped text, items outside the stage; `edges.mjs` checks every arrow can be drawn |

## Subtopic ids
01 Linux Fundamentals (01.1-01.10) · 02 Permissions (02.1-02.6) · 03 Processes, Services & Logs (03.1-03.7)
04 Networking & Remote Access (04.1-04.6) · 05 Packages & Editing (05.1-05.5) · 06 Shell Scripting (06.1-06.6)

## Phone layout
Not included yet (phase 2). Until `linux-animations.mobile.json` exists, a phone shows the desktop stage with
horizontal scrolling. The phone pass will add one 360-wide portrait layout per subtopic.
