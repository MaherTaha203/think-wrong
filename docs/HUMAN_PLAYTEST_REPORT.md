# THINK WRONG — Human Playtest Gate Report

**Test date:** 2026-10-03
**Build / commit:** `6346808` (branch `master`), Phase 1 CLOSED.
**Engine:** Godot 4.3.stable.
**Prepared by:** automated agent (Claude Code). No code was changed for this gate.

---

## 0. Executive status

> **PLAYTEST PACKAGE READY — HUMAN SESSION REQUIRED**
>
> (The human session and the physical-device pass themselves remain BLOCKED in
> this environment — see §4, §5. What is now *ready* is everything that can be
> prepared without fabricating human results: a verified frozen build, a run
> method, test-data isolation/reset, and a complete printable test package.)

### Prior status (superseded)
> HUMAN PLAYTEST BLOCKED — MORE REAL-WORLD TESTING REQUIRED

The Human Playtest Gate asks for **real, naive human players** and, where
possible, a **physical device**. Neither is available to an automated agent in
this environment:

- There are **no human testers** reachable from this session. The gate's core
  measurements — *which assumption the player actually forms*, whether the "aha"
  lands, perceived fairness, whether they suspect a hidden interaction — are
  **by definition** human observations. They cannot be produced by the agent
  without fabricating evidence, which the project rules (§8) forbid and the task
  explicitly prohibits ("لا تعتبر أي انطباع شخصي دليلاً تقنياً").
- There is **no Android/iOS device** attached, and the simulator is explicitly
  not an acceptable substitute per the task.

Therefore **no human-playtest results are reported as PASS or FAIL**, and none
are invented. What this document *does* deliver:

1. Confirmation that the build still matches the Phase 1 closure baseline
   (so a real playtest would run on known-good code) — **VERIFIED**.
2. A complete, ready-to-run **playtest protocol and data instrument** (script,
   per-puzzle observation sheet, assumption-formation method, hint rubric,
   severity classification) so a facilitator can run it unchanged.
3. The expected/intended behavior per puzzle, for comparison against observed
   behavior once real sessions are run.
4. Honest BLOCKED records for the human session and the physical-device pass.

No gameplay, puzzle, hint, save, or architecture change was made. ONE LINE was
not touched.

---

## 1. Baseline re-verification (Step 2) — VERIFIED

Re-run on commit `6346808` immediately before this gate; identical to the Phase 1
closure numbers, no regression:

| Item | Required (Phase 1 closure) | Observed now |
| --- | --- | --- |
| Import / parse | 0 errors | **0** |
| Logic — forward | 322 / 0 | **322 / 0** |
| Logic — reverse | 322 / 0 | **322 / 0** |
| Logic — shuffle | 322 / 0 | **322 / 0** |
| Save I/O | 20 / 0 | **20 / 0** |
| Boot | 0 runtime errors | **0** |
| QA tour 720×1280 | 175 / 0 | **175 / 0** |
| QA tour 720×1600 | 175 / 0 | **175 / 0** |
| QA tour 960×1280 | 175 / 0 | **175 / 0** |
| Working tree | clean | **clean** |

Inspected for this gate (unchanged): `docs/PHASE_1_FINAL_AUDIT.md`,
`docs/DESIGN_VALIDATION.md`, P01–P05 definitions (`scripts/data/puzzles.gd`),
hints (3 tiers/puzzle in the same file + `hint_controller.gd`),
progression/save (`save_model.gd`, `save_manager.gd`, `game_state.gd`), and the
test suites. The build is sound ground for a real playtest.

---

## 2. Intended behavior per puzzle (the comparison baseline)

These are the **designer intents** a real session must test *observed* behavior
against. They are design statements, not playtest results.

| Puzzle | Objective (shown) | Intended wrong assumption | Intended solution | Intended "aha" |
| --- | --- | --- | --- | --- |
| P01 DON'T TOUCH | Open the door. | The loud "DO NOT TOUCH" button is the mechanism. | Tap the door. | "It literally said open the door." |
| P02 THE KEY | Unlock the lock. | Move the key to the lock. | Move the lock (key is bolted). | "The key wasn't the thing to move." |
| P03 WAIT | Get through the door. | A countdown means act fast. | Do nothing; wait. | "I didn't need to do anything." |
| P04 THE BOX | Put the object in the box. | Move the object into the box. | Move the box (object is pinned). | "Move the box, not the object." |
| P05 THE BUTTON | Press the button to open the door. | The button works on its own. | Pull the power lever, then press OPEN. | "The button was never broken — it had no power." |

Per-puzzle fairness facts already machine-verified in Phase 1 (give the
facilitator context, **not** a substitute for human data): every clue is rendered
on screen; the solving control is a real, labelled, ≥96 px button; no hidden
hitbox or side path exists (exhaustive completion-integrity); hints are 3 tiers
(challenge → relationship → solution); WAIT uses an injected clock.

---

## 3. Playtest protocol (ready to run) — PREPARED, not yet executed

### 3.1 Participants
- **4–6 players**, none of whom have seen THINK WRONG's concept, puzzle designs,
  solutions, clue locations, or this repo.
- Mix of puzzle-game familiarity if possible. Test each player individually.

### 3.2 Facilitator script (read verbatim; do not elaborate)
> "Play the game normally. Try to solve the puzzles without asking me how. If you
> get stuck, use the in-game Hint button the way you normally would. Please think
> aloud — say what you're looking at and what you expect to happen."

**Do NOT tell the player:** the THINK WRONG concept, the nature of the wrong
assumption, any solution, where a clue is, or what any control does.
**Do NOT** help, hint, react, or correct during a puzzle.

### 3.3 Conditions
- One player at a time; screen + think-aloud audio recorded if consented.
- **Do not modify the build between players** (results must be comparable).
- Run on the same build `6346808`. Record device/OS/renderer used.

### 3.4 Per-puzzle observation sheet (fill one per player × puzzle)
Record, per P01–P05:
1. Understood the objective? (Y/N + quote)
2. **First action taken** (exact control).
3. **Assumption the player voiced/showed** (their words).
4. Wrong attempts (count + which controls).
5. Time to solve (mm:ss).
6. Solved unaided? (Y/N)
7. Hint used? Which tier(s) (1 / 2 / 3-solution)?
8. After the hint, did they understand the *relationship*? (Y/N + quote)
9. Was the solution clear *after* discovery? (Y/N)
10. Did the solution feel logical? (Y/N + quote)
11. Any "ah, of course" reaction? (Y/N + quote/timestamp)
12. Tried an unintended interaction? (what)
13. Felt cheated by the game? (Y/N + quote)
14. Suspected a hidden interaction? (Y/N + quote)
15. If stuck: was it *not knowing what to do* or *not revising the assumption*?

### 3.5 Assumption-Formation analysis (the most important measure)
Do **not** ask "was it easy?". For each puzzle, from the think-aloud + first
actions, write the **Observed Assumption**, then compare:

| | Meaning | Record as |
| --- | --- | --- |
| Observed == Intended wrong assumption, then revised to solve | design working as intended | OBSERVATION (positive) or PASS candidate |
| Observed ≠ Intended wrong assumption | misdirection not landing as designed | **DESIGN ISSUE** (record) |
| Player forms the *correct* approach immediately, no revision | no "think-wrong" moment | **DESIGN ISSUE / OBSERVATION** (record) |

A puzzle is only a human-PASS when multiple players form the intended wrong
assumption, hit honest resistance, revise, and solve with a genuine "aha".

### 3.6 Hint rubric
Per puzzle, record:
- When the hint was requested (after how long / how many wrong tries).
- Did **Hint 1** make them reconsider the assumption (not reveal the answer)?
- Did **Hint 2** expose the relationship without giving the solution?
- Was **Hint 3 (solution)** actually needed?
- **Did any hint supply information not inferable from the game itself?** If yes
  → **DESIGN ISSUE** (the hint is leaking, the screen is under-informing).

### 3.7 Classification (use ONLY these)
`PASS` · `OBSERVATION` · `DESIGN ISSUE` · `BUG` · `BLOCKED`.
Do **not** use Best/Worst/Perfect/Fun-Not-Fun/Ready-for-Sale.

### 3.8 If a problem appears
Do not fix mid-round. Finish data collection, then per finding record: Observed
behavior · Intended behavior · Evidence · Reproducibility · Severity · Proposed
(minimal) action. Only then, and only if justified, apply the smallest change →
full tests → QA → double re-verify → no regression → update this report.

---

## 4. Human playtest session — BLOCKED

| Field | Value |
| --- | --- |
| Number of players | **0** (no human testers reachable by the agent) |
| P01–P05 observed results | **BLOCKED** — not collected |
| Assumption formation (observed) | **BLOCKED** — requires human think-aloud |
| Hint usage (observed) | **BLOCKED** |
| Completion behavior (observed) | **BLOCKED** |
| "Aha" strength | **BLOCKED / UNVERIFIED** — human judgment only |

No values are estimated or simulated. An AI solving the puzzles would prove
nothing about whether a *human* forms the intended assumption, so no agent
"play-through" is offered as a stand-in.

---

## 5. Physical-device pass (Step 10) — BLOCKED

No Android or iPhone device is attached to this environment, and the simulator
is not an acceptable substitute per the task. The following are therefore
**PHYSICAL DEVICE — BLOCKED/UNVERIFIED**, not guessed: touch response, touch-target
feel, scrolling, drag/tap feel, safe area, portrait orientation, text
readability on a real panel, transitions, audio/haptics, pause/resume,
background/foreground lifecycle, save persistence across real app kills, reset,
replay, and on-device P01–P05.

Context only (machine-checked in Phase 1, **not** a device result): touch input
reaches controls via `InputEventScreenTouch`; targets ≥96 px and text ≥28 px at
720×1280/720×1600/960×1280; save survives corruption and app-pause writes.

---

## 6. Bugs / Design issues / Observations found in THIS gate

- **Bugs:** none (no new testing surface was exercised beyond the re-verified
  baseline, which is green).
- **Design issues:** none *provable* without human data; the known
  design-level open item is unchanged and remains a **Phase 2 consideration**:
  P02 and P04 share the "move the un-anchored thing" mechanic (recorded, not a
  blocker).
- **Observations:** none newly evidenced.

No change was made to gameplay, puzzles, hints, save, or architecture.

---

## 7. ONE LINE isolation (Step 11) — VERIFIED untouched

- Repository: `/home/user/game2026`
- HEAD: `b187622`
- Branch: `claude/vibrant-planck-npmf3y`
- `git status`: clean (0 changed files)
- No file modified; no checkout/commit/reset performed there.

---

## 7b. Playtest package (prepared this pass) — READY

A ready-to-run package was added under `playtest/` (documentation/forms only — no
game content, features, analytics, or in-game tracking):

| File | Purpose |
| --- | --- |
| `playtest/README_FACILITATOR.md` | Exact build + run method + requirements; test-data isolation and reset-between-participants; facilitator conduct rules; timing/attempt capture that does not influence the player; analysis + classification rules. |
| `playtest/observation_sheet.md` | One per player **per puzzle** — the 15 observation fields (printable). |
| `playtest/assumption_grid.md` | One per player — intended vs **observed** assumption comparison (the key measure). |
| `playtest/hint_log.md` | One per player — hint tier usage and the "hint leaked info not on screen?" check. |
| `playtest/post_session.md` | One per player — open post-session questions + findings table. |

**Build to test:** commit `6346808` (game sources byte-identical at the current
HEAD; verified `git diff 6346808 HEAD -- scripts scenes project.godot assets` = 0).
**Run method:** Godot 4.3 editor, Play — from source (no signed/exported build;
export templates/SDK/signing are unavailable here). **Isolation/reset:** dedicated
test account + in-game Reset Progress or deleting the local save between players
(paths documented in the facilitator guide).

### Measurement-validity review (Step 4) — PASS
Every required measure is collectable by observation or an open question, without
a leading prompt or an intervention that changes behavior:
- first assumption / intended-vs-observed → think-aloud + `assumption_grid.md`;
- first actions, unintended attempts → observed (`observation_sheet.md` #2,#4,#12);
- hint usage → player-driven only (`hint_log.md`; facilitator never prompts a hint);
- moment of discovery → silent stopwatch + observed "aha" (#5,#11);
- clarity/fairness feeling → #9,#10,#13 and open post-session questions;
- suspected hidden interaction → #14 + an open, post-hoc question (asked after the
  whole run to avoid priming).
No measure required a game change; where a measure risked priming, the **protocol**
(timing of the question) was adjusted, not the game.

### Result-independence review (Step 5) — PASS
Facilitator rules enforce: hint timing is player-chosen (facilitator does not know
or decide when to hint); solutions/hints are shown only when the player opens them
in game; one player at a time with no observing of others; the build is frozen for
the whole group; incompletes/declined-hints are recorded; inconvenient data is
never discarded.

## 8. Recommended next action

Run the §3 protocol using the `playtest/` package with 4–6 naive players on build
`6346808` (ideally also at least one on a real Android and one on iOS once a signed
build exists). Capture the forms and the assumption grid, then return here to fill
§4–§6 and re-run the gate decision. Until then, the experiential quality of the
game is unestablished.

---

## 9. Gate decision

**PLAYTEST PACKAGE READY — HUMAN SESSION REQUIRED**

Everything preparable without real humans or a device is done and verified: the
build is frozen and re-verified (baseline green, twice), game sources are
byte-identical to the test commit, ONE LINE is isolated, and a complete run
method + test-data isolation + printable test package (`playtest/`) are in place.

The **human playtest session** and the **physical-device pass** still
**could not be performed** in this environment and remain **BLOCKED** — not PASS,
and not fabricated. The Human Playtest Gate is therefore **not** declared passed.

No claim is made that the puzzles are fun, that the "aha" is strong, that players
form the intended assumption, that difficulty is appropriate, or that the game is
ready to sell. Those require real human play on real devices.

**Phase 2 is NOT started. No Puzzle 06, no new features, no monetization, no
analytics, no backend, no unrelated polish.** Awaiting a separate decision after
a real Human Playtest Report exists.
