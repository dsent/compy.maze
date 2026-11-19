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
gfx.getFont = function()
  return font
end
hud_font = font
SCALE = 960 / 201.5
STD_W = 15
STD_H = 12.5
width = { tab = 19 * SCALE }
height = { tab = 12.5 * SCALE }
Color = setmetatable({ black = 0 }, {
  __index = function()
    return { 0, 0, 0 }
  end
})
draw_key = function() end
local real_grid_opts = grid_opts
grid_opts = function()
  return { }
end
dofile(here .. "/../core_render.lua")
dofile(here .. "/../maze_render.lua")

local function drawn_tab_hint()
  local shown
  local prev_key = draw_key
  local prev_print = gfx.print
  draw_key = function(x, y, name)
    if name == "tab" then
      shown = { x = x, y = y }
    end
  end
  gfx.print = function(text, x, y)
    if shown and text == TAB_HINT_TEXT then
      shown.text = text
      shown.tx = x
      shown.ty = y
    end
  end
  draw_hud_corner()
  draw_key = prev_key
  rawset(gfx, "print", prev_print)
  return shown
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
    T.eq(drawn_tab_hint() ~= nil, true)
    press({ }, "tab")
    T.eq(level_index, 5)
    T.eq(GS.failed, nil)
    T.eq(widget.text, "n")
    T.eq(drawn_tab_hint() ~= nil, true)
    run("e")
    T.eq(GS.failed, "crash")
    press({ }, "tab")
    T.eq(level_index, 5)
    T.eq(GS.failed, nil)
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
      run("a=n;c=n;d=n;g=n;h=n;i=n;j=n;k=n;m=n;"
        .. "o=n;p=n;q=n;t=n;u=n;v=n;x=n;y=n;z=n;n")
      cur_legend = legend
      local h = drawn_tab_hint()
      local hw = width.tab + font:getWidth(h.text)
      local row = text_row(font)
      T.eq(h.text, TAB_HINT_TEXT)
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

T.run()
