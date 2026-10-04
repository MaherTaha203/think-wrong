# THINK WRONG — Design Validation Gate

This document records the **Phase 1 design validation evidence** against the shipped P01–P05 implementation. The evidence below is historical and remains useful; current repository status is tracked by the Phase 2 audit.

Phase 1 code baseline: commit 0e5f706. The current master is 085dca0255ee247bbcc089df8e0ad2de97388f3b. Each
puzzle is assessed against the 10 fairness/clarity criteria. A puzzle passes only
if it misdirects **expectation** without ever hiding required information or
requiring luck.

Evidence basis (Phase 1 historical baseline):
- Logic: `tests/gdscript/run_tests.gd`, **318 checks, 0 failures**, identical in
  forward / reverse / shuffled order. Includes exhaustive completion-integrity
  (every action sequence up to length 4 per puzzle) proving **no side path**
  reaches completion, determinism, interaction bindings, and WAIT edge cases.
- On-screen reality: `tests/visual/qa_tour.gd` boots the real game under a
  display, drives it with injected touch, and asserts each clue is rendered and
  each solving control is a real enabled button — **175 checks, 0 failures** at
  720×1280, 720×1600 and 960×1280.
- Save: `tests/integration/save_io_test.gd`, **20 checks, 0 failures**.

Criteria: (1) objective clear · (2) natural assumption · (3) assumption obvious ·
(4) sufficient clue to break it · (5) discoverable without luck · (6) interaction
clear · (7) solution logical · (8) real "aha" · (9) replayable · (10) never "how
was I supposed to know?".

> Correction vs. the Phase 1 draft: the draft claimed clues were "shown by glyph"
> and that P05's button honestly reported "no power". In the shipped code the
> clues were **not rendered at all** and P05's objective was **literally false**
> (only the lever opened the door). Both were fixed; the tables below describe the
> audited, tested code.

## Per-puzzle results

Every row below is backed by a test named in the "Evidence" column of the audit
report (`docs/PHASE_1_FINAL_AUDIT.md`).

### Puzzle 01 — DON'T TOUCH — PASS
- **Objective:** "Open the door." · **Assumption:** the loud "DO NOT TOUCH"
  button is the mechanism.
- **Clue (rendered caption):** button — "Wired to a buzzer."; door — "Closed. It
  has a handle." Tapping the button honestly reports the buzzer; the door stays
  shut.
- **Solution:** tap the door (`open_door`). · **Aha:** "It just said open the
  door." No pixel hunting, no outside knowledge.

### Puzzle 02 — THE KEY — PASS
- **Objective:** "Unlock the lock." · **Assumption:** move the key to the lock.
- **Clue:** key — "Bolted to the wall."; lock — "On a sliding rail." Tapping the
  bolted key says it won't move.
- **Solution:** move the lock to the key (`move_lock_to_key`). The anchored item
  is provably **not** in the solution; the movable item **is** (asserted).

### Puzzle 03 — WAIT — PASS
- **Objective:** "Get through the door." (the dishonest "before it's too late"
  deadline was removed — there is no fail state). · **Assumption:** a countdown
  means act fast.
- **Clue:** timer — "At zero, the door opens."; HURRY! — "No wires attached."
- **Solution:** do nothing; the door opens at the threshold. Uses an **injected
  clock** (no real time). The HURRY! decoy never completes early nor blocks
  completion. Edge cases tested: t=0, just-before, exact threshold, after, reset,
  replay, negative/NaN/INF dt. The clock is **frozen while an overlay is open**
  (verified: opening Pause during the wait does not auto-complete).

### Puzzle 04 — THE BOX — PASS
- **Objective:** "Put the object in the box." · **Assumption:** move the object
  into the box.
- **Clue:** object — "Pinned to the floor."; box — "On casters."
- **Solution:** move the box onto the object (`move_box_to_object`).

### Puzzle 05 — THE BUTTON — PASS (after a fairness + honesty redesign)
- **The twist is misdirection, not concealment.** Both controls are full-size,
  labelled, captioned, and on screen from the start.
- **Objective:** "Press the button to open the door." — now **literally true**:
  pressing OPEN *does* open the door, once it has power.
- **Clue:** button OPEN — caption "Power light: off." → "Power light: on." after
  power; lever — "Down: power off." → "Up: power on." Pressing OPEN with no power
  says "Click. Nothing. The power light is off." (a `fail_feedback`, not a success
  message).
- **Solution (2 steps, order matters):** pull the **Power lever**, then press
  **OPEN** (`["pull_lever", "press_button"]`). Neither step alone completes it
  (both asserted); the exhaustive test confirms no other sequence completes it.
- **Aha:** "The button was never broken — I just hadn't powered it."

### Puzzle 05 special audit (per the task)
| Check | Result | Evidence |
| --- | --- | --- |
| Button is a clear, labelled control | PASS | qa_tour: OPEN rendered as enabled button, ≥96 px |
| "No power" clue is clear | PASS | caption "Power light: off." rendered (qa_tour); fail_feedback on press |
| Lever actually visible | PASS | qa_tour screenshot `07_puzzle_05.png`; rendered enabled button |
| Lever has a clear affordance | PASS | label "Power lever" + caption "Down: power off." |
| No secret area / hidden click target | PASS | only declared interactables exist; completion-integrity over all sequences |
| No external knowledge needed | PASS | objective + captions fully specify the mechanism |
| Lever size / position adequate | PASS | 112 px tall control (> 96 px min) at (0.72, 0.53); not tiny, not off-screen |

## Gate result

All five puzzles **PASS** the fairness/clarity criteria against the tested code.
No puzzle requires luck, invisible interaction, or outside knowledge, and no
completion side path exists.

## Current status after Phase 1 closure

The project has accepted the human/mobile gate as complete by project decision. This is a project-status decision, **not fabricated human measurement**; this document does not assign human PASS/FAIL results to individual puzzles.

The following remain separate release-readiness items and are not claimed as complete:
- Production-signed Android release/AAB.
- iOS export/signing and store review.
- Any future content/UX changes arising from evidence.
