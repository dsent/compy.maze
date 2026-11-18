-- maze_constants.lua

-- Maze-only constants, plus the maze's additions to the
-- command sets defined in core_constants.lua (loaded
-- first).

-- Box sprite box. cell_fill = 1: box fully covers
-- its cell, matching the current rectangle behavior.

BOX = {
  sprite_w = 100,
  sprite_h = 100,
  cell_fill = 1
}

-- Target sprite box.

TARGET = {
  sprite_w = 100,
  sprite_h = 100,
  cell_fill = 0.9
}

-- Legend shown in the bottom-right corner.

LEGEND_FULL = readfile("legend.txt")

-- Keyboard macro limits.

MAX_MACRO_LEN = 7

-- Macro letters list above legend.

MACRO_LINE_LEN = 8

-- Maze-only navigation commands layered on the core set:
-- "." next level, "," previous level. Both silent (no
-- movement ping).

PRIMITIVES["."] = true
PRIMITIVES[","] = true
SILENT_CMDS["."] = true
SILENT_CMDS[","] = true

-- Plan-a-path buffer: tile capacity, tiles per row, and
-- the run prompt.

MAX_PLAN_LEN = 20
PLAN_ROW_LEN = 10
PLAN_PROMPT = "Press Enter to go!"

-- Gap between the field and the HUD zones that box it
-- in (plan dock, compass column, editor console).

FIELD_MARGIN = 3

-- How long a plan run that missed the goal holds the
-- robot at its end position before the level resets.

PLAN_MISS_HOLD = 1.0

-- Maze steps run ~20% slower than the shared core
-- default, tuned for the 4-6 bracket.

ANIM.move_time = 0.56
ANIM.turn_time = 0.56

-- Celebrate message: prefix + Tab keycap + suffix.

CELEBRATE_PREFIX = "Congratulations! Press "
CELEBRATE_SUFFIX = " to proceed."

-- Failed-run modal: prefix + Tab keycap + suffix.
-- A calm "not yet", never punitive.

FAILED_MISS_PREFIX = "Goal not reached. Press "
FAILED_CRASH_PREFIX = "Crashed. Press "
FAILED_SUFFIX = " to try again."
