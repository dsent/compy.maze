# Build & verify

This one source tree produces two Compy projects, `maze` and
`draw`. A Compy project is a flat, self-contained folder
launched by `run("name")`; there is no runtime sharing
between projects, so the shared command core is physically
copied into each folder by the build step.

## Build

The host build calls this repo's emit script (the
`.compy/build` convention):

    cd <repo> && .compy/build <out-dir>

with an absolute, fresh `<out-dir>`. It populates
`<out-dir>/maze/` and `<out-dir>/draw/`, each a valid Compy
project (a direct `main.lua`) named exactly as its manifest
entry; it works relative to its own location, is
deterministic, and needs no network. `.compy/build`
classifies every source file as:

- **CORE** -> copied into *both* folders: `core_*`, `player`,
  `script`, and the four `ROBOT_03_*` sprite parts.
- **MAZE** -> `maze/` only: `maze_*`, `controls`, `levels`,
  `menu`, `macro`, `keyboard_graphics`, the box / target /
  background sprites, `legend.txt`, and `maze_main.lua`,
  emitted as the project's `main.lua`.
- **DRAW** -> `draw/` only: `draw_constants`, `draw_levels`,
  `draw_menu`, `draw_render`, `keyboard_graphics`, and
  `draw_main.lua`, emitted as the project's `main.lua`.

The source root has no `main.lua`, so it is not itself a
runnable project: both `maze/` and `draw/` are produced only
by the build step. Each program's child-facing readme
(`README_maze.md` / `README_draw.md`) is emitted as that
folder's `README.md`.

`assets/fonts/` is copied into both folders when an `assets/`
tree is present; the Sarasa Gothic font is runtime-provided
here, so none is committed. The emit is idempotent: re-running
it reproduces identical folders.

## Verify (headless)

    ./verify.sh

Emits both projects to a scratch dir and checks, with no LOVE
and no device:

1. every `.lua` compiles (`luac -p`), generated sprites aside;
2. the command-core spec passes (`lua spec/script_spec.lua`,
   expect `30 passed, 0 failed, 0 pending`);
3. the Draw level-data spec passes
   (`lua spec/draw_levels_spec.lua`, expect
   `10 passed, 0 failed, 0 pending`);
4. the Draw mini-game command-scope spec passes
   (`lua spec/draw_mode_spec.lua`, expect
   `3 passed, 0 failed, 0 pending`);
5. the Draw menu echo-guard spec passes
   (`lua spec/draw_menu_guard_spec.lua`, expect
   `4 passed, 0 failed, 0 pending`);
6. the Draw run spec passes
   (`lua spec/draw_run_spec.lua`, expect
   `28 passed, 0 failed, 0 pending`);
7. the Maze shortcut-carry spec passes
   (`lua spec/maze_run_spec.lua`, expect
   `29 passed, 0 failed, 0 pending`);
8. the Draw Escape spec passes
   (`lua spec/draw_escape_spec.lua`, expect
   `31 passed, 0 failed, 0 pending`);
9. the Maze Escape spec passes
   (`lua spec/maze_escape_spec.lua`, expect
   `36 passed, 0 failed, 0 pending`);
10. each project is self-contained -- every `require`
    resolves inside its own folder, except the runtime
    modules (`utf8`, `gfx`, `Color`, `compy.audio`).

`spec/` stays at the repo root and runs on the host; it is
not shipped into the emitted projects. Run each spec directly
from the repo root with `lua spec/<name>.lua`;
`spec/README.md` lists them.

## Verify (on device)

Rendering, sound, ~0.45 s/step timing, the editor, and
host exit can only be checked on Compy. Deploy the
emitted `maze/` and `draw/` folders, then walk **TEST-PLAN.md**
-- section A is the maze regression, section B is the draw
acceptance against the behaviour spec.
