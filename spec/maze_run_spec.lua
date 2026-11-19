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
gfx.getWidth = function()
  return 1024
end
gfx.getHeight = function()
  return 600
end

local function utf8_cols(s)
  local _, n = s:gsub("[\128-\191]", "")
  return #s - n
end

local function text_cols(s)
  local best = 0
  for line in (s .. "\n"):gmatch("(.-)\n") do
    best = math.max(best, utf8_cols(line))
  end
  return best
end

love.graphics = gfx
local font = {
  getWidth = function(_, s)
    return 16 * text_cols(s)
  end,
  getHeight = function()
    return 37
  end,
  getLineHeight = function()
    return 33 / 37
  end,
  getWrap = function(_, s, lim)
    local cols = math.max(1, math.floor(lim / 16))
    local lines = { }
    for i = 1, #s, cols do
      lines[#lines + 1] = s:sub(i, i + cols - 1)
    end
    return lim, lines
  end
}
local active_font = font
gfx.getFont = function()
  return active_font
end
gfx.setFont = function(f)
  active_font = f
end
gfx.newFont = function()
  return {
    getWidth = function() return 10 end,
    getHeight = function() return 14 end
  }
end
hud_font = font
STD_W = 15
STD_H = 12.5
Color = setmetatable({
  black = 0,
  white = 7,
  red = 1,
  green = 2,
  blue = 4,
  cyan = 6,
  bright = 8
}, {
  __index = function()
    return { 0, 0, 0 }
  end
})
robot_back = function() end
robot_track_l = function() end
robot_track_r = function() end
robot_front = function() end
box_sprite = function() end
target_sprite = function() end
utf8 = { char = function() return "" end }
local base_require = require
function require(name)
  if name == "utf8" then
    return utf8
  end
  return base_require(name)
end
dofile(here .. "/../keyboard_graphics.lua")
require = base_require
local real_grid_opts = grid_opts
grid_opts = function()
  return { }
end
dofile(here .. "/../core_render.lua")
dofile(here .. "/../maze_render.lua")

local function has_text(prints, target)
  for _, s in ipairs(prints) do
    if s == target then
      return true
    end
  end
  return false
end

local function drawn_frame()
  ensure_init()
  local frame = { tab_keys = { }, prints = { } }
  local prev_key = draw_key
  local prev_print = gfx.print
  active_font = font
  draw_key = function(x, y, name)
    if name == "tab" then
      frame.tab_keys[#frame.tab_keys + 1] = { x = x, y = y }
    end
    prev_key(x, y, name)
  end
  gfx.print = function(text, x, y)
    frame.prints[#frame.prints + 1] = text
    if text == " next" or text == " finish" then
      local k = frame.tab_keys[#frame.tab_keys]
      if k then
        frame.side_hint = {
          x = k.x, y = k.y, text = text, tx = x, ty = y
        }
      end
    end
  end
  local ok, err = pcall(love.draw)
  draw_key = prev_key
  rawset(gfx, "print", prev_print)
  if not ok then
    error(err)
  end
  T.eq(active_font, font)
  return frame
end

local function drawn_tab_hint()
  return drawn_frame().side_hint
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

T.it("Esc at the miss banner does what Tab does; the next Esc "
  .. "empties the field and the one after leaves", function()
    on_field_level()
    run("n")
    T.eq(GS.failed, "miss")
    press({ }, "escape")
    T.eq(GS.failed, nil)
    T.eq(GS.mode, "game")
    T.eq({ player.col, player.row }, { 3, 5 })
    T.eq(widget.shown, true)
    T.eq(widget.text, "n")
    press({ }, "escape")
    T.eq(widget.text, "")
    T.eq(GS.mode, "game")
    press({ }, "escape")
    T.eq(GS.mode, "menu")
  end)

T.it("Esc at the crash banner does what Tab does", function()
  on_field_level()
  run("e")
  T.eq(GS.failed, "crash")
  press({ }, "escape")
  T.eq(GS.failed, nil)
  T.eq(GS.mode, "game")
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
    local tracks = { player.track_offset_l, player.track_offset_r }
    tick(20)
    T.eq(player.anim.time, t)
    T.eq({ player.track_offset_l, player.track_offset_r }, tracks)
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
    press({ }, "tab")
    T.eq(level_index, 14)
    T.eq(player.anim, nil)
    T.eq(GS.filled_count, 0)
    run("snwwennseel")
    T.eq(GS.celebrating, true)
    submit("snwwennseel")
    tick_until("win")
    press({ }, "escape")
    T.eq(player.anim.frozen, true)
    T.eq(drawn_tab_hint() ~= nil, true)
    press({ }, "tab")
    T.eq(level_index, 15)
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

-- Only a win saves: a jump opens the next level with the
-- shortcuts the level it left started with.

T.it("a jump carries none of the jumping program's shortcuts",
  function()
    on_field_level()
    run("x=e;.")
    T.eq(level_index, 5)
    run("x")
    T.eq(GS.invalid.msg, "Unknown command: X")
    on_field_level()
    run(".;y=e")
    T.eq(level_index, 5)
    run("y")
    T.eq(GS.invalid.msg, "Unknown command: Y")
  end)

T.it("a jump keeps the shortcuts its level started with",
  function()
    on_field_level()
    run("x=2n;x2wx")
    T.eq(level_index, 5)
    run("y=e;.")
    T.eq(level_index, 6)
    run("x")
    T.eq(GS.invalid, nil)
    press({ }, "tab")
    run("y")
    T.eq(GS.invalid.msg, "Unknown command: Y")
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

T.it("Maze 5: Tab hint is absent before a win and at the banner",
  function()
    on_level(5)
    T.eq(drawn_tab_hint(), nil)
    run("n")
    press({ }, "tab")
    T.eq(drawn_tab_hint(), nil)
    run("ne2n2en")
    T.eq(GS.celebrating, true)
    T.eq(drawn_tab_hint(), nil)
  end)

T.it("Maze 5: Enter after a win shows the hint and stays through "
  .. "runs, stops, failures and refusals", function()
    on_level(5)
    run("ne2n2en")
    submit("2n")
    tick(1)
    T.eq(GS.celebrating, false)
    T.eq(drawn_tab_hint() ~= nil, true)
    press({ }, "tab")
    T.eq(level_index, 5)
    press({ }, "escape")
    T.eq(GS.running, false)
    T.eq(drawn_tab_hint() ~= nil, true)
    run("n")
    T.eq(GS.failed, "miss")
    T.eq(drawn_tab_hint(), nil)
    press({ }, "tab")
    T.eq(level_index, 5)
    T.eq(GS.failed, nil)
    T.eq(widget.text, "n")
    T.eq(drawn_tab_hint() ~= nil, true)
    run("e")
    T.eq(GS.failed, "crash")
    T.eq(drawn_tab_hint(), nil)
    press({ }, "tab")
    T.eq(level_index, 5)
    T.eq(GS.failed, nil)
    T.eq(drawn_tab_hint() ~= nil, true)
    run("q")
    T.eq(GS.invalid.msg, "Unknown command: Q")
    T.eq(drawn_tab_hint() ~= nil, true)
    press({ }, "tab")
    T.eq(level_index, 6)
    T.eq(drawn_tab_hint(), nil)
  end)

T.it("Maze 5: Esc at the miss banner dismisses it and keeps the hint",
  function()
    on_level(5)
    run("ne2n2en")
    run("n")
    T.eq(GS.failed, "miss")
    T.eq(drawn_tab_hint(), nil)
    press({ }, "escape")
    T.eq(GS.failed, nil)
    T.eq(level_index, 5)
    T.eq(drawn_tab_hint() ~= nil, true)
    press({ }, "tab")
    T.eq(level_index, 6)
  end)

T.it("Maze 5: a second win shows the celebration banner again",
  function()
    on_level(5)
    run("ne2n2en")
    run("n")
    press({ }, "tab")
    T.eq(drawn_tab_hint() ~= nil, true)
    run("ne2n2en")
    T.eq(GS.celebrating, true)
    T.eq(drawn_tab_hint(), nil)
    press({ }, "tab")
    T.eq(level_index, 6)
  end)

T.it("Maze 5: staying carries the last winning program's shortcuts",
  function()
    on_level(5)
    run("x=n;xe2n2en")
    run("y=e;n")
    press({ }, "tab")
    press({ }, "tab")
    T.eq(level_index, 6)
    run("y")
    T.eq(GS.invalid.msg, "Unknown command: Y")
    run("x")
    T.eq(GS.invalid, nil)
  end)

T.it("Maze 5: a stopped run or later win updates carry only on win",
  function()
    on_level(5)
    run("x=n;xe2n2en")
    run("z=n;ze2n2en")
    submit("y=e;2n")
    tick(1)
    press({ }, "escape")
    press({ }, "tab")
    T.eq(level_index, 6)
    run("x")
    T.eq(GS.invalid.msg, "Unknown command: X")
    run("y")
    T.eq(GS.invalid.msg, "Unknown command: Y")
    run("z")
    T.eq(GS.invalid, nil)
  end)

T.it("Maze: Tab hint clears title, 3-line shortcuts, legend and "
  .. "all level grids", function()
    local legend = "  N \nW + E L:↺ R:↻\n  S   F:↑ B:↓\n"
    for _, fh in ipairs({ 32, 37 }) do
      font.getHeight = function() return fh end
      font.getLineHeight = function() return 33 / fh end
      on_level(5)
      run("ne2n2en")
      submit("a=n;c=n;d=n;g=n;h=n;i=n;j=n;k=n;m=n;"
        .. "o=n;p=n;q=n;t=n;u=n;v=n;x=n;y=n;z=n;2n")
      tick(1)
      press({ }, "escape")
      cur_legend = legend
      local h = drawn_tab_hint()
      local hw = width.tab + font:getWidth(h.text)
      local row = text_row(font)
      T.eq(h.text, " next")
      T.eq(legend_left(font) <= h.x, true)
      T.eq(h.x + hw <= 1024 - fh, true)
      T.eq(fh * 1.5 <= h.y, true)
      T.eq(h.y + height.tab <= legend_top(font) - 3 * row, true)
      for _, track in ipairs(TRACKS) do
        start_track(track)
        for i, lvl in ipairs(track.levels) do
          level_index = i
          maze = lvl
          start_level()
          cur_legend = legend
          init_grid(#maze, #(maze[1]), real_grid_opts())
          T.eq(GRID.offset_x + GRID.cols * GRID.cell <= h.x, true)
          if cur_controls == plan then
            local _, lim = prompt_column()
            local _, lines = font:getWrap(PLAN_PROMPT, lim)
            local ptop = prompt_top(font, lim)
            local pbot = ptop + #lines * fh
            T.eq(fh * 1.5 <= ptop, true)
            T.eq(pbot <= hud_corner_top(), true)
            GS.win_macros = { }
            local ph = drawn_tab_hint()
            local ptop_w = prompt_top(font, lim)
            T.eq(fh * 1.5 <= ptop_w, true)
            T.eq(ptop_w + #lines * fh <= ph.y, true)
          end
        end
      end
    end
  end)

T.it("Maze 5: love.draw draws only the matching Tab label per state",
  function()
    on_level(5)
    local f0 = drawn_frame()
    T.eq(#f0.tab_keys, 0)
    T.eq(has_text(f0.prints, CELEBRATE_PREFIX), false)
    T.eq(has_text(f0.prints, " next"), false)
    run("ne2n2en")
    local f1 = drawn_frame()
    T.eq(#f1.tab_keys, 1)
    T.eq(has_text(f1.prints, CELEBRATE_PREFIX), true)
    T.eq(has_text(f1.prints, CELEBRATE_SUFFIX), true)
    T.eq(has_text(f1.prints, " next"), false)
    submit("n")
    tick(1)
    local f2 = drawn_frame()
    T.eq(#f2.tab_keys, 1)
    T.eq(has_text(f2.prints, CELEBRATE_PREFIX), false)
    T.eq(has_text(f2.prints, " next"), true)
    tick(50)
    local f3 = drawn_frame()
    T.eq(#f3.tab_keys, 1)
    T.eq(has_text(f3.prints, FAILED_MISS_PREFIX), true)
    T.eq(has_text(f3.prints, FAILED_SUFFIX), true)
    T.eq(has_text(f3.prints, " next"), false)
    press({ }, "tab")
    local f4 = drawn_frame()
    T.eq(#f4.tab_keys, 1)
    T.eq(has_text(f4.prints, FAILED_MISS_PREFIX), false)
    T.eq(has_text(f4.prints, " next"), true)
    run("e")
    local f5 = drawn_frame()
    T.eq(#f5.tab_keys, 1)
    T.eq(has_text(f5.prints, FAILED_CRASH_PREFIX), true)
    T.eq(has_text(f5.prints, " next"), false)
    press({ }, "tab")
    local f6 = drawn_frame()
    T.eq(#f6.tab_keys, 1)
    T.eq(has_text(f6.prints, FAILED_CRASH_PREFIX), false)
    T.eq(has_text(f6.prints, " next"), true)
  end)

T.it("Drive the robot Maze 1: Tab waits for an active win animation",
  function()
    start_track(TRACKS[1])
    press({ }, "n")
    press({ }, "n")
    press({ }, "n")
    tick_until("win")
    T.eq(player.anim.kind, "win")
    love.update(0.2)
    T.eq(player.anim.kind, "win")
    press({ }, "tab")
    T.eq(level_index, 1)
    T.eq(GS.celebrating, false)
    T.eq(player.anim.kind, "win")
    T.eq(player.row, 1)
    tick(5)
    T.eq(GS.celebrating, true)
    press({ }, "tab")
    T.eq(level_index, 2)
  end)

T.it("All mazes last level side hint says finish and Tab goes to menu",
  function()
    local legend = "  N \nW + E L:↺ R:↻\n  S   F:↑ B:↓\n"
    on_level(15)
    level_index = #levels
    maze = levels[level_index]
    start_level()
    cur_legend = legend
    submit("3e2s2e2nw2n4w3s3n4e2s3w3e2n4w2s"
      .. "6enws6wse3n4eses4wsn3e2n4w2swsen3e2senen4w3e2n4w2s")
    tick(1000)
    T.eq(GS.celebrating, true)
    local f1 = drawn_frame()
    T.eq(#f1.tab_keys, 1)
    T.eq(has_text(f1.prints, " finish"), false)
    run("n")
    press({ }, "tab")
    local f2 = drawn_frame()
    T.eq(#f2.tab_keys, 1)
    T.eq(has_text(f2.prints, " finish"), true)
    T.eq(has_text(f2.prints, " next"), false)
    local h = f2.side_hint
    local hw = width.tab + font:getWidth(h.text)
    T.eq(legend_left(font) <= h.x, true)
    T.eq(h.x + hw <= 1024 - font:getHeight(), true)
    press({ }, "tab")
    T.eq(GS.mode, "menu")
  end)

local function release(key)
  local hook = compy.input.hooks.keyreleased
  if hook then
    hook(key)
  end
end

T.it("Drive the robot Maze 1: shortcut recorded at celebration "
  .. "carries to Maze 2", function()
    start_track(TRACKS[1])
    press({ }, "n")
    press({ }, "n")
    press({ }, "n")
    tick(10)
    T.eq(GS.celebrating, true)
    press({ "shift" }, "x")
    press({ "shift" }, "n")
    release("lshift")
    T.eq(macros.X, "N")
    press({ }, "tab")
    T.eq(level_index, 2)
    T.eq({ player.col, player.row }, { 1, 4 })
    press({ }, "x")
    tick(5)
    T.eq({ player.col, player.row }, { 1, 3 })
  end)

T.run()
