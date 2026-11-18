-- Shortcuts in maze, the rule draw follows: a run starts from
-- the level's base, so a shortcut from an earlier run is
-- unknown; a jump and a win carry the program's shortcuts to
-- the next level. maze_main.lua runs here against the
-- stand-in in input_standin.lua, driven as a child drives it:
-- a program goes in through the field's Enter and the run
-- goes on in love.update.

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
-- Its robot starts bottom right facing north, and the goal is
-- top left; it moves on to level 5 as soon as it is won.

local function on_field_level()
  start_track(TRACKS[3])
  level_index = 4
  maze = levels[4]
  start_level()
end

-- Enter `text` in the field and let the run play out.

local function run(text)
  submit(text)
  tick(100)
end

print("== Maze shortcut carry ==")

T.it("a shortcut from an earlier run is unknown", function()
  on_field_level()
  run("x=e")
  press({ }, "tab")
  run("x")
  T.eq(GS.invalid.msg, "Unknown command: X")
end)

T.it("Enter in place of Tab after a miss runs and is judged",
  function()
    on_field_level()
    run("n")
    T.eq(GS.failed, "miss")
    run("n")
    T.eq(GS.failed, "miss")
  end)

T.it("a jump carries the jumping program's shortcuts", function()
  on_field_level()
  run("x=e;.")
  T.eq(level_index, 5)
  run("x")
  T.eq(GS.invalid, nil)
end)

T.it("a win carries the winning program's shortcuts", function()
  on_field_level()
  run("x=2n;x2wx")
  T.eq(level_index, 5)
  run("x")
  T.eq(GS.invalid, nil)
end)

T.run()
