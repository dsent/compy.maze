-- Runs in draw: every run draws its whole program from a clean
-- start, as maze runs its level, and the field keeps the
-- program. Shortcuts follow maze's rule: a run starts from the
-- picture's base, the program that completes a picture carries
-- its shortcuts to the next one, and Free draw has none to
-- carry. draw_main.lua runs here against the stand-in in
-- input_standin.lua, driven as a child drives it: a program
-- goes in through the field's Enter, the run goes on in
-- love.update, and Tab moves on.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
dofile(here .. "/support.lua")
assert(loadfile(here .. "/input_standin.lua"))(here)
dofile(here .. "/../draw_main.lua")

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
local real_draw_layout = draw_layout
draw_layout = function()
  return { }
end

-- The renderer, for what a frame would show: which echo
-- tokens are lit as executing, the partial stroke of the
-- step in flight, and the column Tab hint.

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
dofile(here .. "/../core_render.lua")
dofile(here .. "/../draw_render.lua")

local function has_text(prints, target)
  for _, s in ipairs(prints) do
    if s == target then
      return true
    end
  end
  return false
end

local function drawn_frame()
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

local function lit_tokens()
  local lit = { }
  local color = set_echo_color
  set_echo_color = function(line_idx, col, on)
    if on then
      lit[#lit + 1] = line_idx .. ":" .. col
    end
  end
  for i, line in ipairs(echo_lines) do
    draw_echo_line(line, i, 0)
  end
  set_echo_color = color
  return lit
end

local function partial_stroke()
  local seg
  gfx.line = function(...)
    seg = { ... }
  end
  draw_active_trace()
  rawset(gfx, "line", nil)
  return seg
end

-- Enter `text` in the field and let the run play out.

local function run(text)
  submit(text)
  tick(100)
end

local function trace_count()
  local n = 0
  for _ in pairs(player.traces) do
    n = n + 1
  end
  return n
end

print("== Draw runs ==")

T.it("a run clears the drawing and starts the robot over",
  function()
    startDrawMode("free")
    run("3e")
    T.eq({ player.col, player.row }, { 4, 8 })
    run("2n")
    T.eq({ player.col, player.row, player.dir }, { 1, 6, "N" })
    T.eq(trace_count(), 2)
  end)

T.it("C clears the drawing in the middle of a program",
  function()
    startDrawMode("free")
    run("3e;c;2n")
    T.eq({ player.col, player.row, player.dir }, { 1, 6, "N" })
    T.eq(trace_count(), 2)
  end)

T.it("the field keeps the program after a run", function()
  startDrawMode("free")
  run("3e")
  T.eq(widget.text, "3e")
end)

T.it("the field is away while the robot moves and comes back "
  .. "with the program", function()
    startDrawMode("free")
    submit("7n")
    tick(2)
    T.eq(widget.shown, false)
    tick(50)
    T.eq(widget.shown, true)
    T.eq(widget.text, "7n")
  end)

T.it("Enter and keys during a run change nothing", function()
  startDrawMode("free")
  submit("7n")
  tick(2)
  submit("3e")
  press({ }, "e")
  press({ }, "return")
  tick(50)
  T.eq({ player.col, player.row }, { 1, 1 })
  T.eq(widget.text, "7n")
end)

T.it("Esc during a run stops it and judges nothing; the next "
  .. "Esc empties the field and the one after leaves", function()
    startDrawMode("picture")
    submit("5e")
    tick(3)
    local col = player.col
    press({ }, "escape")
    T.eq(GS.running, false)
    T.eq(#player.queue, 0)
    T.eq(widget.shown, true)
    T.eq(widget.text, "5e")
    tick(20)
    T.eq(GS.won, false)
    T.eq(player.col, col)
    press({ }, "escape")
    T.eq(widget.text, "")
    T.eq(GS.screen, "game")
    press({ }, "escape")
    T.eq(GS.screen, "menu")
  end)

-- The step in flight stays as it looked at the Esc: the
-- robot half way and its half stroke, which the renderer
-- draws from the animation, until the next run resets it.

T.it("Esc in the middle of a step leaves it as it looked",
  function()
    startDrawMode("free")
    submit("7n")
    love.update(0.2)
    love.update(0.2)
    T.eq(player.anim.kind, "move")
    local t = player.anim.time
    T.eq(0 < t, true)
    local stroke = partial_stroke()
    T.eq(stroke ~= nil, true)
    press({ }, "escape")
    local tracks = { player.track_offset_l, player.track_offset_r }
    tick(20)
    T.eq(player.anim.kind, "move")
    T.eq(player.anim.time, t)
    T.eq({ player.track_offset_l, player.track_offset_r }, tracks)
    T.eq(partial_stroke(), stroke)
    T.eq({ player.col, player.row }, { 1, 8 })
    T.eq(trace_count(), 0)
    T.eq(GS.running, false)
    run("2e")
    T.eq({ player.col, player.row, player.dir }, { 3, 8, "E" })
    T.eq(trace_count(), 2)
  end)

T.it("after a stop, a refused program lights no token as "
  .. "executing", function()
    startDrawMode("free")
    submit("7n")
    love.update(0.2)
    love.update(0.2)
    T.eq(lit_tokens(), { "1:1", "1:2" })
    press({ }, "escape")
    submit("eesq")
    T.eq(GS.invalid.msg, "Unknown command: Q")
    T.eq(lit_tokens(), { })
  end)

T.it("a held Esc stops the run and does no more", function()
  startDrawMode("free")
  submit("7n")
  tick(2)
  press({ }, "escape")
  press({ }, "escape", true)
  press({ }, "escape", true)
  T.eq(widget.text, "7n")
  T.eq(GS.screen, "game")
end)

T.it("a run after a stop starts clean", function()
  startDrawMode("free")
  submit("7n")
  tick(3)
  press({ }, "escape")
  run("2e")
  T.eq({ player.col, player.row, player.dir }, { 3, 8, "E" })
  T.eq(trace_count(), 2)
end)

T.it("a win brings the field back empty", function()
  startDrawMode("picture")
  run("5e")
  T.eq(GS.won, true)
  T.eq(widget.shown, true)
  T.eq(widget.text, "")
end)

T.it("Free draw: a shortcut from one run is unknown in the next",
  function()
    startDrawMode("free")
    run("x=3e")
    run("x")
    T.eq(GS.invalid.msg, "Unknown command: X")
  end)

T.it("a shortcut is known inside its own program", function()
  startDrawMode("free")
  run("x=2e;x n x")
  T.eq(GS.invalid, nil)
  T.eq({ player.col, player.row }, { 5, 7 })
end)

T.it("a picture: a shortcut from a run that did not complete it "
  .. "is unknown in the next run", function()
    startDrawMode("picture")
    run("x=e;x")
    T.eq(GS.won, false)
    run("x")
    T.eq(GS.invalid.msg, "Unknown command: X")
  end)

T.it("the program that completes a picture carries its "
  .. "shortcuts to the next one", function()
    startDrawMode("picture")
    run("x=5e;x")
    T.eq(GS.won, true)
    press({ }, "tab")
    T.eq(GS.level_index, 2)
    run("x")
    T.eq(GS.invalid, nil)
  end)

T.it("a rejected program keeps the winning program's shortcuts",
  function()
    startDrawMode("picture")
    run("x=5e;x")
    T.eq(GS.won, true)
    run("q")
    T.eq(GS.invalid.msg, "Unknown command: Q")
    press({ }, "tab")
    T.eq(GS.level_index, 2)
    run("x")
    T.eq(GS.invalid, nil)
  end)

T.it("Enter after a win runs again and can win again; Tab "
  .. "moves on", function()
    startDrawMode("picture")
    run("5e")
    T.eq(GS.won, true)
    run("5e")
    T.eq(GS.won, true)
    run("3e")
    T.eq(GS.won, false)
    run("5e")
    T.eq(GS.won, true)
    press({ }, "tab")
    T.eq(GS.level_index, 2)
  end)

-- Only a win saves, as in maze: a jump opens the next picture
-- with the shortcuts the picture it left started with.

T.it("a jump carries none of the jumping program's shortcuts",
  function()
    startDrawMode("picture")
    run("x=e;.")
    T.eq(GS.level_index, 2)
    T.eq(widget.text, "")
    run("x")
    T.eq(GS.invalid.msg, "Unknown command: X")
    run(",;y=e")
    T.eq(GS.level_index, 1)
    run("y")
    T.eq(GS.invalid.msg, "Unknown command: Y")
  end)

T.it("a jump keeps the shortcuts its picture started with",
  function()
    startDrawMode("picture")
    run("x=5e;x")
    T.eq(GS.won, true)
    press({ }, "tab")
    run("y=e;.")
    T.eq(GS.level_index, 3)
    run("x")
    T.eq(GS.invalid, nil)
    run("y")
    T.eq(GS.invalid.msg, "Unknown command: Y")
  end)

T.it("every picture is one valid program on one field line",
  function()
    setPictureNavigationEnabled(true)
    for i, level in ipairs(DRAW_LEVELS) do
      T.eq(validate_program({ level.route }), nil, level.name)
      T.eq(#level.route <= 64, true, level.name)
      startDrawMode("picture")
      GS.level_index = i
      startPictureLevel()
      run(level.route)
      T.eq(GS.won, true, level.name)
    end
  end)

T.it("the Tab hint is absent before a win and at the banner",
  function()
    startDrawMode("picture")
    T.eq(drawn_tab_hint(), nil)
    run("e")
    T.eq(drawn_tab_hint(), nil)
    run("5e")
    T.eq(GS.won, true)
    T.eq(drawn_tab_hint(), nil)
  end)

T.it("Enter after a win shows the hint and keeps it across runs, "
  .. "stops and refusals", function()
    startDrawMode("picture")
    run("5e")
    submit("3e")
    tick(1)
    T.eq(GS.won, false)
    T.eq(drawn_tab_hint() ~= nil, true)
    press({ }, "tab")
    T.eq(GS.level_index, 1)
    tick(100)
    T.eq(drawn_tab_hint() ~= nil, true)
    submit("5e")
    tick(1)
    press({ }, "escape")
    T.eq(GS.running, false)
    T.eq(drawn_tab_hint() ~= nil, true)
    run("q")
    T.eq(GS.invalid.msg, "Unknown command: Q")
    T.eq(drawn_tab_hint() ~= nil, true)
    press({ }, "escape")
    T.eq(drawn_tab_hint() ~= nil, true)
    press({ }, "tab")
    T.eq(GS.level_index, 2)
    T.eq(drawn_tab_hint(), nil)
  end)

T.it("a second win after staying shows the banner again",
  function()
    startDrawMode("picture")
    run("5e")
    run("3e")
    T.eq(drawn_tab_hint() ~= nil, true)
    run("5e")
    T.eq(GS.won, true)
    T.eq(drawn_tab_hint(), nil)
    press({ }, "tab")
    T.eq(GS.level_index, 2)
  end)

T.it("staying carries the last winning program's shortcuts",
  function()
    startDrawMode("picture")
    run("x=5e;x")
    run("y=2e;y")
    run("q")
    press({ }, "tab")
    T.eq(GS.level_index, 2)
    run("x")
    T.eq(GS.invalid, nil)
    run("y")
    T.eq(GS.invalid.msg, "Unknown command: Y")
  end)

T.it("a later win replaces the carried shortcuts", function()
  startDrawMode("picture")
  run("x=5e;x")
  run("z=5e;z")
  run("y=2e;y")
  press({ }, "tab")
  T.eq(GS.level_index, 2)
  run("z")
  T.eq(GS.invalid, nil)
  run("x")
  T.eq(GS.invalid.msg, "Unknown command: X")
  run("y")
  T.eq(GS.invalid.msg, "Unknown command: Y")
end)

T.it("the Tab hint fits inside the right column without overlap",
  function()
    local legend = "  N \nW + E L:↺ R:↻\n  S   F:↑ B:↓\n"
    DRAW_LEGEND = legend
    for _, fh in ipairs({ 32, 37 }) do
      font.getHeight = function() return fh end
      font.getLineHeight = function() return 33 / fh end
      startDrawMode("picture")
      for i = 1, #DRAW_LEVELS do
        GS.level_index = i
        startPictureLevel()
        init_grid(CANVAS.rows, CANVAS.cols, real_draw_layout())
        GS.win_macros = { }
        local h = drawn_tab_hint()
        local geo = previewGeometry()
        local hw = width.tab + font:getWidth(h.text)
        local expected = i == #DRAW_LEVELS and " finish" or " next"
        T.eq(h.text, expected)
        T.eq(GRID.offset_x + GRID.cols * GRID.cell <= h.x, true)
        T.eq(legend_left(font) <= h.x, true)
        T.eq(h.x + hw <= 1024 - fh, true)
        T.eq(fh * 2.4 <= geo.top, true)
        T.eq(geo.top + CANVAS.rows * geo.cell <= h.y, true)
        T.eq(h.y + height.tab <= legend_top(font), true)
      end
    end
  end)

T.it("love.draw draws the banner or side Tab label, never both",
  function()
    startDrawMode("picture")
    local f0 = drawn_frame()
    T.eq(#f0.tab_keys, 0)
    T.eq(has_text(f0.prints, DRAW_COMPLETE_PREFIX), false)
    T.eq(has_text(f0.prints, " next"), false)
    run("5e")
    local f1 = drawn_frame()
    T.eq(#f1.tab_keys, 1)
    T.eq(has_text(f1.prints, DRAW_COMPLETE_PREFIX), true)
    T.eq(has_text(f1.prints, DRAW_COMPLETE_NEXT_SUFFIX), true)
    T.eq(has_text(f1.prints, " next"), false)
    submit("3e")
    tick(1)
    local f2 = drawn_frame()
    T.eq(#f2.tab_keys, 1)
    T.eq(has_text(f2.prints, DRAW_COMPLETE_PREFIX), false)
    T.eq(has_text(f2.prints, " next"), true)
    tick(100)
    local f3 = drawn_frame()
    T.eq(#f3.tab_keys, 1)
    T.eq(has_text(f3.prints, DRAW_COMPLETE_PREFIX), false)
    T.eq(has_text(f3.prints, " next"), true)
  end)

T.it("last picture side hint says finish and Tab goes to the menu",
  function()
    local legend = "  N \nW + E L:↺ R:↻\n  S   F:↑ B:↓\n"
    DRAW_LEGEND = legend
    startDrawMode("picture")
    GS.level_index = #DRAW_LEVELS
    startPictureLevel()
    run(DRAW_LEVELS[#DRAW_LEVELS].route)
    local f1 = drawn_frame()
    T.eq(#f1.tab_keys, 1)
    T.eq(has_text(f1.prints, DRAW_COMPLETE_FINAL_SUFFIX), true)
    T.eq(has_text(f1.prints, " finish"), false)
    run("e")
    local f2 = drawn_frame()
    T.eq(#f2.tab_keys, 1)
    T.eq(has_text(f2.prints, " finish"), true)
    T.eq(has_text(f2.prints, " next"), false)
    local h = f2.side_hint
    local hw = width.tab + font:getWidth(h.text)
    T.eq(legend_left(font) <= h.x, true)
    T.eq(h.x + hw <= 1024 - font:getHeight(), true)
    press({ }, "tab")
    T.eq(GS.screen, "menu")
  end)

T.run()
