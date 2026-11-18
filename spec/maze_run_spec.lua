-- Shortcuts in maze, the rule draw follows: a run starts from
-- the level's base, so a shortcut from an earlier run is
-- unknown; a jump and a win carry the program's shortcuts to
-- the next level. maze_main.lua runs here against the
-- stand-in in input_standin.lua; whole runs step through the
-- real animation code.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
dofile(here .. "/support.lua")
assert(loadfile(here .. "/input_standin.lua"))(here)
dofile(here .. "/../maze_main.lua")

-- The grid's pixel layout needs the runtime's font; the
-- cells are what this checks, so the screen is a fixed size
-- with no padding.

gfx.getDimensions = function()
  return 1024, 600
end
grid_opts = function()
  return { }
end

-- All mazes, level 4: the first level with the command field.

local function on_field_level()
  start_track(TRACKS[3])
  level_index = 4
  maze = levels[4]
  start_level()
  GS.base_macros = { }
  macros = { }
end

local function run(text)
  start_program(text)
  for _ = 1, 1000 do
    if editor_idle() or GS.failed then
      break
    end
    step_program(1)
  end
end

print("== Maze shortcut carry ==")

T.it("a shortcut from an earlier run is unknown", function()
  on_field_level()
  run("x=e")
  run("x")
  T.eq(GS.invalid.msg, "Unknown command: X")
end)

T.it("a jump carries the jumping program's shortcuts", function()
  on_field_level()
  run("x=e;.")
  T.eq(level_index, 5)
  run("x")
  T.eq(GS.invalid, nil)
end)

-- next_level is what a win calls (on_win, through the
-- level's progression); here it is called as the win would.

T.it("a win carries the winning program's shortcuts", function()
  on_field_level()
  start_program("x=e")
  next_level()
  T.eq(level_index, 5)
  run("x")
  T.eq(GS.invalid, nil)
end)

T.run()
