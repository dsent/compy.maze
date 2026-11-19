# Headless specs

Headless tests for the shared command core and Draw picture
data. They run under plain `lua` 5.1.5 — no LÖVE, no device —
so a failing case shows up in the terminal in under a second.

## Run

From the repository root (also works from inside `spec/`):

    lua spec/script_spec.lua
    lua spec/draw_levels_spec.lua
    lua spec/draw_mode_spec.lua
    lua spec/draw_menu_guard_spec.lua
    lua spec/draw_run_spec.lua
    lua spec/maze_run_spec.lua
    lua spec/draw_escape_spec.lua
    lua spec/maze_escape_spec.lua

Output ends with a summary line:

    30 passed, 0 failed, 0 pending
    10 passed, 0 failed, 0 pending
    3 passed, 0 failed, 0 pending
    4 passed, 0 failed, 0 pending
    28 passed, 0 failed, 0 pending
    29 passed, 0 failed, 0 pending
    31 passed, 0 failed, 0 pending
    36 passed, 0 failed, 0 pending

Exit code is `0` when nothing failed, non-zero otherwise,
so the same command works in a CI check. A failure prints
the case name and the expected vs. actual value, e.g.:

    FAIL  validate: stray letter -> Unknown at col  --  ...
          expected {... msg="Unknwn command: Q"}
          actual   {... msg="Unknown command: Q"}

## Active vs. pending

Active cases capture today's behavior and must stay green
through the core extraction and the whitespace change —
this is the "maze plays identically" guarantee.

Pending cases name target behavior that lands in later
steps (whitespace-as-separator; draw's `C` command). They
are recorded, not run, so the baseline stays green until
the feature exists. When a feature lands, its
`T.pending(...)` line becomes a real `T.it(...)` case.

## Files

- `support.lua` — runtime stubs the core reads at call
  time (`PRIMITIVES`, `SILENT_CMDS`, `macros`, `player`,
  `sfx`, `readfile`) plus a tiny assert/runner framework
  (`T.it`, `T.eq`, `T.pending`, `T.run`).
- `script_spec.lua` — the command-core cases. It loads the real
  `script.lua` and `constants.lua`, never a copy.
- `draw_levels_spec.lua` — exact target count, order, bounds,
  trail-only routes, and target-edge matching.
- `draw_mode_spec.lua` — Free draw's preserved command set and
  picture mode's scoped next/previous commands.
- `draw_menu_guard_spec.lua` — the menu key's one-time echo
  guards: armed per menu key, all cleared by the first fire.
- `draw_run_spec.lua` — every draw run starts from a clean
  canvas and the robot's start, and `C` clears in the middle
  of a program. The field is away while the robot moves,
  Enter and keys then change nothing, and the field comes
  back with the program, or empty after a win. Esc during a
  run stops it where it is, the step in flight frozen as it
  looked (its time, the track offsets and the partial stroke
  stay fixed) and lighting no token, and judges nothing; the next
  Esc empties the field
  and the one after leaves; a held Esc only stops; the run
  after a stop starts clean. A shortcut lives in its own
  program; only the program that completes a picture carries
  its shortcuts to the next one, and a jump opens its picture
  with the shortcuts the picture it left started with. Every
  picture's route is one valid program on one field line
  that completes it. Enter after a win runs again, moves the
  Tab hint to the right column (absent before a win and at the
  banner, kept across non-winning, stopped and refused runs,
  saying `finish` on the last picture, clear of preview and
  legend), and can win again to show the banner; Tab moves on
  when idle, carrying the last winning program's shortcuts
  even after later runs defined others or were rejected.
- `maze_run_spec.lua` — maze's shortcut rule, which draw
  follows: an earlier run's shortcut is unknown, a win
  carries the last winning program's shortcuts to the next
  level, and a jump carries none of them. The field is away
  while the robot moves, and after a miss or a crash until Tab
  or Esc brings it back with the program; a celebration brings
  it back empty. Enter, keys and Tab change nothing during a
  run, and Tab waits for an active win animation on
  direct-control levels too, where shortcuts recorded with Shift
  at a celebration also carry on Tab. Enter after a celebration clears
  the banner and moves the Tab hint to the right column
  (absent before a win and at celebration, miss and crash
  banners, kept across non-winning, stopped and refused runs,
  saying `finish` on the last level, clear of title, 3-line
  shortcut list, legend, plan prompt and all level grids); a
  miss or crash banner still takes Tab first for "try again",
  and Tab from the hint advances with the last winning
  program's shortcuts. Esc stops a run, the step in flight
  frozen, even one whose last step reached the goal or put the
  last box on its target, and Tab waits for such a win; it
  judges nothing. Esc stops a plan run with the robot home,
  the plan kept and no step shown as run. A level is judged
  once per run, never on entry, Maze 5 included right after
  Maze 4's automatic advance.
- Both run specs drive the program as a child does: a
  program goes in through the field's Enter (`submit`), the
  run goes on in `love.update` (`tick`), Tab moves on, and
  `love.draw` checks which Tab labels the frame draws.
- `draw_escape_spec.lua`, `maze_escape_spec.lua` — Esc in each
  program, as the keys are delivered to it: a bare Esc
  empties a field that holds text (and maze's plan when it
  holds keys) and steps back to the menu from an empty one
  or a level with neither; emptying a refused program also
  puts the prompt back to "Commands:" and empties the echo,
  while a field emptied by hand still steps back; at the menu
  it leaves the program; Esc with Ctrl, Alt or Shift held,
  when it reaches the program, does none of this and leaves
  the field shown
  (Ctrl+Esc never reaches it: the IDE keeps that chord and
  quits on it); a held Esc acts once, so one that reached the
  menu stays there; the field is given no cancel flag of its
  own, and no mouse hook takes a click from it.
- `input_standin.lua` — the stand-in for the runtime's input
  routing the Escape and run specs run the programs against,
  with the field's cancel as the IDE has it: a bare Esc,
  acting only under `clear_on_cancel` or `hide_on_cancel`;
  its Enter empties the field before `on_text_entered`, as
  the IDE's `clear_on_submit` does. Its `stop()` counts its
  calls in `stops`.

## Scope

Dev-side only. The build step copies the core and per-app
files into the emitted `maze/` and `draw/` folders; it
never copies `spec/`, so these tests do not ship to the
device.

## Adding a case

    T.it("what it checks", function()
      T.eq(actual_value, expected_value)
    end)

Write `expected_value` as a literal, not derived from the
code under test — a computed expectation can hide a shared
bug.
