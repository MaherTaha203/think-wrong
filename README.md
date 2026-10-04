# THINK WRONG

A premium, **offline-first** mobile lateral-thinking puzzle prototype built with
**Godot 4.3**. Each puzzle pushes you toward an obvious assumption — the real
solution comes from realizing that assumption was never a rule.

> The obvious solution is usually wrong.

This is a **prototype** (first 5 puzzles) proving the core loop is fair,
repeatable, and genuinely delivers the "aha" moment. It is an **independent
project** and shares no runtime code with the ONE LINE game.

Premium concept: no ads, no subscription, no forced account, no backend, no
multiplayer, no virtual currency, no store integration in the prototype.

## Status

**Phase 2 — Productization / Release Readiness — Audit in progress.**

Current repository baseline is master commit 46df640aa5610e9ea562b9d87374f1994a576d24.

The Phase 1 automated and deployment gates are now verified on GitHub:
- CI regression suite: **PASS** — parse, deterministic logic, save I/O, boot smoke, graphical QA, Android SDK/export, and artifact upload.
- Web Playtest workflow: **PASS** — web build, tests, export, and deployment.
- Android debug APK export gate: **PASS**.
- Application ID: com.mahertaha.thinkwrong.
- App version: 0.1.0; content version: 1; save-data version: 1.

The project decision for this phase accepts the human/mobile playtest gate as complete. This README does **not** invent human observations or measurements; those are not represented as automated evidence.

The current phase is an **audit and release-readiness pass**, not a feature-development pass. No new puzzle, monetization, analytics, backend, account system, multiplayer, or unrelated polish is being added.

**Current release-readiness limitation:** the repository has a verified Android **debug APK** export, not a production-signed Android release/AAB, and no iOS/store submission gate is being claimed.
## Run

Open in **Godot 4.3** and press Play, or headless:

```bash
godot --headless --editor --quit --path .   # first run: import assets + build class cache
godot --path .                              # run
```

## Test

```bash
# deterministic logic (also: -- --order=reverse / --order=shuffle:SEED)
godot --headless --path . --script tests/gdscript/run_tests.gd
# save file I/O with the real autoloads (isolated temp save)
godot --headless --path . res://tests/integration/save_io_test.tscn
# graphical QA tour: real game, injected touch, screenshots to $TW_QA_OUT
TW_QA_OUT=/tmp/qa xvfb-run -a -s "-screen 0 1280x1800x24" \
  godot --path . --display-driver x11 --rendering-driver opengl3 \
  --audio-driver Dummy --resolution 720x1280 res://tests/visual/qa_tour.tscn
python3 tools/gen_audio.py                  # regenerate original SFX (rarely needed)
```

## Architecture

A minimal, data-driven puzzle framework (logic separate from UI, fully
headless-testable):

```
scripts/
  core/versions.gd
  framework/
    puzzle_state.gd        # mutable per-attempt facts + injected clock
    interactable.gd        # declarative, visible, clued controls (no invisible hitboxes)
    puzzle_definition.gd   # a puzzle = data (objective, interactables, actions, completion, hints)
    hint_controller.gd     # progressive offline hints (assumption -> relationship -> solution)
    puzzle_controller.gd   # generic deterministic engine (attempt/reset/complete/time)
  data/puzzles.gd          # the 5 prototype puzzles as data
  state/game_state.gd      # session + progression bridge (autoload)
  persistence/
    save_model.gd          # pure, tested save logic (versioned, corruption-safe, migratable)
    save_manager.gd        # autoload file-I/O wrapper (atomic writes)
  services/{audio_manager,haptics}.gd
  i18n/localization.gd
  ui/{style,screen_manager,main,main_menu,level_select,puzzle,puzzle_complete,settings}.gd
scenes/   # thin Control wrappers; UI is built in code
assets/   # original SVG icon + 4 procedural SFX
tests/gdscript/run_tests.gd   # framework + 5 puzzles + save + WAIT clock
```

New puzzles are added as data in `scripts/data/puzzles.gd` without touching core
code.

## The five prototype puzzles

1. **DON'T TOUCH** — a loud "DO NOT TOUCH" button; the objective is to open the
   door, which is right there.
2. **THE KEY** — the key is bolted; move the *lock* to the key.
3. **WAIT** — urgency is a feeling, not a rule; do nothing and the door opens.
4. **THE BOX** — the object is pinned; move the *box* to the object.
5. **THE BUTTON** — the labelled button has no power; a visible power lever is the
   real control (overlooked, never hidden — no pixel hunting).

Each is fair: every solving interaction is visible and clued; no invisible
hitboxes, no random tapping, no outside knowledge. See
`docs/DESIGN_VALIDATION.md`.

## Not in scope (prototype)

Payments/commercial model (deliberately not hard-coded), additional puzzles,
multiplayer, backend, accounts, store builds.
