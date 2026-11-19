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

-- All mazes, level n, reached from level 4 so that it keeps
-- the command field, as the . jump reaches it.

local function on_level(n)
  on_field_level()
  level_index = n
  maze = levels[n]
  start_level()
end

-- Tick until the robot's animation is of `kind`.

local function tick_until(kind)
  for _ = 1, 200 do
    if player.anim and player.anim.kind == kind then
      return
    end
    tick(1)
  end
end

-- Enter `text` in the field and let the run play out.

local function run(text)
  submit(text)
  tick(100)
end

print("== Maze shortcut carry ==")

-- A level is judged once per run from the field: entering it
-- judges nothing before the first Enter.

T.it("Maze 4 is not judged on entry, before any Enter", function()
  on_field_level()
  tick(5)
  T.eq(GS.failed, nil)
  T.eq(level_index, 4)
end)

T.it("a shortcut from an earlier run is unknown", function()
  on_field_level()
  run("x=e")
  press({ }, "tab")
  run("x")
  T.eq(GS.invalid.msg, "Unknown command: X")
end)

T.it("after a miss the field stays away until Tab; the run "
  .. "after Tab is judged", function()
    on_field_level()
    run("n")
    T.eq(GS.failed, "miss")
    run("2n")
    T.eq({ player.col, player.row }, { 3, 4 })
    press({ }, "tab")
    run("2n")
    T.eq({ player.col, player.row }, { 3, 3 })
    T.eq(GS.failed, "miss")
  end)

T.it("the field is away while the robot moves; a miss brings "
  .. "it back with the program after Tab", function()
    on_field_level()
    submit("n")
    tick(1)
    T.eq(widget.shown, false)
    tick(50)
    T.eq(GS.failed, "miss")
    T.eq(widget.shown, false)
    press({ }, "tab")
    T.eq(widget.shown, true)
    T.eq(widget.text, "n")
  end)

T.it("a crash ends as before and Tab brings the program back",
  function()
    on_field_level()
    run("e")
    T.eq(GS.failed, "crash")
    press({ }, "tab")
    T.eq(widget.text, "e")
  end)

T.it("Enter, keys and Tab during a run change nothing", function()
  on_field_level()
  submit("2n2w")
  tick(1)
  submit("e")
  press({ }, "e")
  press({ }, "tab")
  tick(50)
  T.eq({ player.col, player.row }, { 1, 3 })
  T.eq(GS.failed, "miss")
end)

T.it("Esc during a run stops it and judges nothing", function()
  on_field_level()
  submit("2n2w")
  tick(2)
  press({ }, "escape")
  T.eq(GS.running, false)
  T.eq(widget.shown, true)
  T.eq(widget.text, "2n2w")
  tick(20)
  T.eq(GS.failed, nil)
  T.eq(level_index, 4)
  press({ }, "escape")
  T.eq(widget.text, "")
  press({ }, "escape")
  T.eq(GS.mode, "menu")
end)

T.it("Esc as a winning run reaches the goal judges nothing",
  function()
    on_field_level()
    submit("2n2w2n")
    for _ = 1, 50 do
      tick(1)
      if player.anim and player.anim.kind == "win" then
        break
      end
    end
    T.eq(player.anim.kind, "win")
    love.update(0.2)
    press({ }, "escape")
    tick(20)
    T.eq(level_index, 4)
    T.eq(GS.goal_map[pos_key(1, 1)].radius, 1)
  end)

T.it("Esc in the middle of a step leaves the robot as it looked",
  function()
    on_field_level()
    submit("2n")
    love.update(0.2)
    love.update(0.2)
    T.eq(player.anim.kind, "move")
    local t = player.anim.time
    press({ }, "escape")
    tick(20)
    T.eq(player.anim.time, t)
    T.eq({ player.col, player.row }, { 3, 5 })
    T.eq(GS.failed, nil)
  end)

T.it("Maze 5: a celebration brings the field back empty; Tab "
  .. "moves on", function()
    on_level(5)
    run("ne2n2en")
    T.eq(GS.celebrating, true)
    T.eq(widget.shown, true)
    T.eq(widget.text, "")
    press({ }, "tab")
    T.eq(level_index, 6)
  end)

T.it("Maze 14: Esc in the pause of a box-goal win stops the run",
  function()
    on_level(14)
    submit("snwwennseel")
    tick_until("win")
    T.eq(player.anim.kind, "win")
    T.eq(GS.running, true)
    press({ }, "escape")
    T.eq(GS.mode, "game")
    T.eq(level_index, 14)
    T.eq(widget.shown, true)
    T.eq(widget.text, "snwwennseel")
  end)

T.it("Maze 14: Tab in the pause of a box-goal win waits for it",
  function()
    on_level(14)
    submit("snwwennseel")
    tick_until("win")
    press({ }, "tab")
    T.eq(GS.running, true)
    T.eq(player.anim.kind, "win")
    tick(5)
    T.eq(GS.celebrating, true)
  end)

T.it("Esc during a plan run stops it: robot home, plan kept, "
  .. "no step shown as run",
  function()
    start_track(TRACKS[2])
    press({ }, "n")
    press({ }, "n")
    press({ }, "return")
    tick(1)
    T.eq(GS.running, true)
    press({ }, "escape")
    T.eq(GS.running, false)
    T.eq(GS.mode, "game")
    T.eq(#GS.plan.buf, 2)
    T.eq(GS.plan.ran, nil)
    T.eq(GS.plan.done, 0)
    T.eq({ player.col, player.row }, { 1, 3 })
    tick(20)
    T.eq(GS.won, false)
    T.eq(level_index, 1)
  end)

T.it("a jump carries the jumping program's shortcuts", function()
  on_field_level()
  run("x=e;.")
  T.eq(level_index, 5)
  run("x")
  T.eq(GS.invalid, nil)
end)

T.it("a win carries the winning program's shortcuts, and Maze 5 "
  .. "is not judged on arrival", function()
  on_field_level()
  run("x=2n;x2wx")
  T.eq(level_index, 5)
  T.eq(GS.failed, nil)
  run("x")
  T.eq(GS.invalid, nil)
end)

T.run()
