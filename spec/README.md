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
    lua spec/draw_escape_spec.lua
    lua spec/maze_escape_spec.lua

Output ends with a summary line:

    29 passed, 0 failed, 0 pending
    10 passed, 0 failed, 0 pending
    3 passed, 0 failed, 0 pending
    4 passed, 0 failed, 0 pending
    20 passed, 0 failed, 0 pending
    26 passed, 0 failed, 0 pending

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
- `draw_escape_spec.lua`, `maze_escape_spec.lua` — Esc in each
  program: a bare Esc empties a field that holds text (and
  maze's plan when it holds keys) and steps back to the menu
  from an empty one or a level with neither; at the menu it
  does nothing; Esc with Ctrl, Alt or Shift held does none of
  this and leaves the field shown; a held Esc acts once; the
  field is given no cancel flag of its own.
- `input_standin.lua` — the stand-in for the runtime's input
  routing the two Escape specs run the programs against,
  with the field's cancel as the IDE has it: a bare Esc,
  acting only under `clear_on_cancel` or `hide_on_cancel`.

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
