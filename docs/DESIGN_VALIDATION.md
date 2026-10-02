# THINK WRONG — Design Validation Gate

Evaluated after implementing the five prototype puzzles, before any expansion.
Each puzzle is assessed against the 10 fairness/clarity criteria. A puzzle passes
only if it misdirects **expectation** without ever hiding required information or
requiring luck. Logic for every puzzle is covered by deterministic headless tests
(`tests/gdscript/run_tests.gd`, 106 checks, 0 failures).

Criteria: (1) objective clear · (2) natural assumption · (3) assumption obvious ·
(4) sufficient clue to break it · (5) discoverable without luck · (6) interaction
clear · (7) solution logical · (8) real "aha" · (9) replayable · (10) never
"how was I supposed to know?".

## Puzzle 01 — DON'T TOUCH — **PASS**
- Objective: "Open the door." (clear)
- Assumption: the big "DO NOT TOUCH" button is the mechanism.
- Clue: the objective names the door; the door is a visible, labelled control with
  a handle. Tapping the button gives honest feedback ("buzzer; door stays shut").
- Solution: tap the door itself. Logical, discoverable, no luck.
- Aha: "It just said open the door — so I open the door." ✓
- Tests: initial not-complete, wrong action (button) no-progress, solve, reset,
  replay. ✓
- No "how was I supposed to know?": the door is the named objective and visible. ✓

## Puzzle 02 — THE KEY — **PASS**
- Objective: "Unlock the lock." (clear)
- Assumption: move the key to the lock.
- Clue: affordances shown by glyph + text (key is anchored ⚓; lock is on a rail
  ↔), never colour alone. Tapping the anchored key says "bolted down".
- Solution: move the lock to the key. Logical; the movable object is clearly the
  lock.
- Aha: "The key wasn't the thing to move." ✓
- Tests: full set. ✓

## Puzzle 03 — WAIT — **PASS (with injected-clock tests)**
- Objective: stated with urgency; the timer text says the door opens when the
  timer ends.
- Assumption: urgency ⇒ act fast / tap the HURRY button.
- Clue: the literal instruction ("opens when the timer ends") makes waiting
  discoverable; the HURRY button honestly reports "can't be rushed".
- Solution: do nothing; wait. Deterministic; the only "action" is a decoy that
  never blocks completion.
- Aha: "I didn't need to do anything." ✓
- Tests: before threshold not complete; decoy tap doesn't complete early or block;
  completes at/after threshold; reset zeroes the clock; replay. Uses an injected
  clock (no real time). ✓

## Puzzle 04 — THE BOX — **PASS**
- Objective: "Put the object in the box." (clear)
- Assumption: move the object into the box.
- Clue: object is pinned (⚓), box is on casters (↔); tapping the pinned object
  says "won't budge".
- Solution: move the box to the object. ✓
- Aha: "Move the box, not the object." ✓
- Tests: full set. ✓

## Puzzle 05 — THE BUTTON — **PASS after a fairness redesign (flagged)**
- **Flag:** the original concept ("the visible information may not be the complete
  interaction space") risked a hidden/secondary interaction → pixel hunting, which
  violates the fairness rules.
- **Redesign:** the secondary control is **visible, not hidden** — a labelled power
  lever on the wall. The obvious "OPEN" button is a decoy that honestly reports
  "no power", a *logical* clue pointing to the lever. The twist is that attention
  is misdirected to the obvious button, not that anything is concealed.
- Objective: "Press the button to open the door." (clear)
- Assumption: the labelled button works.
- Clue: button says "no power"; a visible lever exists. No invisible hitbox, no
  arbitrary tap.
- Solution: pull the lever. ✓
- Aha: "The real control was right there; I fixated on the obvious one." ✓
- Tests: wrong action (button, no power) no-progress; solve via lever; reset;
  replay. ✓

## Gate result

All five puzzles **PASS** the fairness/clarity criteria; Puzzle 05 passes only
because it was redesigned away from a hidden interaction. No puzzle requires luck,
invisible interaction, or outside knowledge.

**Not validated here (UNVERIFIED — require a human/device):** the *felt* strength
of each "aha", readability and touch feel on real phones, and whether playtesters
form the intended assumption. Those need human playtesting on devices and are out
of scope for this environment.
