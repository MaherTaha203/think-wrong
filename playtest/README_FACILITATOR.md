# THINK WRONG — Facilitator Guide (Human Playtest)

This package lets one facilitator run a controlled playtest of THINK WRONG with
naive players and capture comparable, honest data. It adds **no** game content,
features, analytics, or in-game tracking — all data is captured on paper/forms by
the facilitator.

> Read this fully before the first session. Print the forms in this folder:
> `observation_sheet.md` (one per player **per puzzle**), `hint_log.md` (one per
> player), `post_session.md` (one per player), `assumption_grid.md` (one per
> player).

---

## 1. Exact build under test

- **Repository:** THINK WRONG (independent of ONE LINE).
- **Commit:** `6346808` (game code identical at report commit `27db2e9`; the only
  later commits are documentation, verified byte-identical game sources).
- **Engine:** Godot **4.3.stable** (must match; other versions are not validated).
- Confirm before testing:
  ```bash
  git -C <repo> rev-parse --short HEAD      # expect 27db2e9 (or 6346808)
  git -C <repo> status --porcelain          # expect empty (clean tree)
  ```
  Do **not** modify any file during a test group.

## 2. How to run the game

No store/signed build exists (export templates and signing are not available in
the build environment). Run from source — this is the supported method:

1. Install **Godot 4.3 stable** (standard editor build) from godotengine.org.
2. First run only, build the asset/class cache (either is fine):
   - GUI: open the project in the editor once, or
   - CLI: `godot --headless --editor --quit --path <repo>`
3. Launch the game:
   - GUI: open the project, press **Play** (F5), or
   - CLI: `godot --path <repo>`
4. The window is **portrait** (720×1280 base). For a phone-like feel, resize the
   window tall, or launch at a fixed size:
   `godot --path <repo> --resolution 720x1280`

**Requirements:** a desktop OS with Godot 4.3, mouse or touchscreen. A real phone
build is **not** part of this package (see §7). Mouse works because touch↔mouse
is enabled; a touchscreen laptop/monitor gives a more realistic feel.

## 3. Test-data isolation and reset between participants

The game stores one local save: `think_wrong_save.json` under Godot's per-user
app data:
- **Windows:** `%APPDATA%\Godot\app_userdata\THINK WRONG\`
- **macOS:** `~/Library/Application Support/Godot/app_userdata/THINK WRONG/`
- **Linux:** `~/.local/share/godot/app_userdata/THINK WRONG/`

Use a **dedicated test machine or OS user account** so there is no real player
save to collide with. **Between participants, reset to the start state** one of
two ways (both verified by QA):
1. In game: **Settings → Reset Progress → Reset** (fastest; keeps A/V settings).
2. Or quit and **delete** `think_wrong_save.json` (a fully clean slate incl.
   settings). The game recreates defaults on next launch.

After reset, only **Puzzle 1** should be unlocked. Verify this before seating the
next participant.

## 4. Recruiting

- **4–6 players**, none of whom have seen THINK WRONG's concept, any puzzle, any
  solution, clue location, or this repository.
- Test **one player at a time**. A waiting player must not watch another's session.
- Note each player's puzzle-game familiarity (low / medium / high) on their form.

## 5. Running a session (facilitator conduct)

Read this **verbatim** to the player, then stop talking:

> "Play the game normally. Try to solve the puzzles without asking me how. If you
> get stuck, use the in-game Hint button the way you normally would. Please think
> aloud — say what you're looking at and what you expect to happen."

**You must NOT, at any point:**
- explain the THINK WRONG concept, or that the "obvious" solution is wrong;
- name or hint the wrong assumption, the solution, or a clue's location;
- say what any control does, or react to right/wrong actions;
- tell the player when to use a hint, or push them toward one;
- answer "is this right?" — reply only: *"Play it however feels natural."*

**You only:** observe, let the player drive, and record. If the player asks to
stop or truly cannot proceed and declines hints, record it as **incomplete** (do
not solve it for them). Let the player decide entirely when (and whether) to open
Hints — hint timing is a measurement, not something you prompt.

### Capturing timing & attempts without influencing the player
- Start a stopwatch (phone/watch, silent) when the puzzle screen appears; stop at
  the completion screen. Record mm:ss on the observation sheet.
- Count **wrong attempts** by watching the screen: a wrong tap shows an honest
  feedback line at the bottom (e.g. "A buzzer sounds. The door stays shut."). Tally
  these; note which control each time. Do **not** lean in or comment.
- Capture the player's **words** (think-aloud) verbatim where the form asks for a
  quote. Screen+audio recording (with consent) makes this far more reliable than
  live notes — prefer it.

## 6. Forms (in this folder)
- `observation_sheet.md` — **one per player per puzzle** (P01–P05). The 15 fields.
- `assumption_grid.md` — **one per player**; the intended-vs-observed assumption
  comparison (the most important analysis — see §8).
- `hint_log.md` — **one per player**; hint tier usage and whether hints leaked.
- `post_session.md` — **one per player**; overall reflection, collected only
  **after** all five puzzles (never before/between, to avoid priming).

## 7. Physical device — not in this package

No Android/iOS build is provided (no export templates / SDK / signing in the
build environment, and a simulator is not an acceptable substitute). On-device
touch feel, safe area, lifecycle, haptics, persistence, etc. remain
**PHYSICAL DEVICE — BLOCKED/UNVERIFIED**. If you later have a signed build on a
real phone, use the same forms and record the device/OS at the top of each.

## 8. After the group: analysis (do not change the game mid-group)

Collect all forms first. Then, per puzzle, compare **intended vs observed**:

| Intended wrong assumption | If observed assumption matches, player resists, revises, solves | PASS candidate / OBSERVATION |
| --- | --- | --- |
| If most players form a **different** assumption | misdirection isn't landing | **DESIGN ISSUE** |
| If players jump to the **correct** approach with no revision | no "think-wrong" moment | **DESIGN ISSUE / OBSERVATION** |
| If a **hint** gave info not inferable from the screen | hint leaking / screen under-informs | **DESIGN ISSUE** |
| If a control misbehaved or state was wrong | **BUG** |

Use **only** these labels: `PASS` · `OBSERVATION` · `DESIGN ISSUE` · `BUG` ·
`BLOCKED`. Do not use Best/Worst/Perfect/Fun-Not-Fun/Ready-for-Sale. Record every
session, including incompletes and failed attempts — never discard inconvenient
data. For each finding write: Observed · Intended · Evidence · Reproducibility ·
Severity · Proposed minimal action.

Only after analysis, and only if a change is justified by evidence, may the game
be changed — then: full tests → QA tour → **double** re-verify → no regression →
update `docs/HUMAN_PLAYTEST_REPORT.md`. Never fix mid-group.

## 9. Intended behavior (facilitator reference — do NOT reveal to players)

Kept in `assumption_grid.md` so it is only in the facilitator's hands. This is the
designer intent each puzzle is being tested against; it is **not** a script to
feed the player.
