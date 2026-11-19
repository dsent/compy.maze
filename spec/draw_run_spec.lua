-- Runs in draw: in default mode every run draws its whole
-- program from a clean start and keeps it in the field, with
-- winning shortcuts carrying on Tab. Step-by-step mode
-- (toggled on the menu) draws each step on top of the last,
-- empties the field after a step, and keeps all shortcuts
-- across steps, jumps and Tab. draw_main.lua runs here against
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
draw_layout = function()
  return { }
end

-- The renderer, for what a frame would show: which echo
-- tokens are lit as executing, the partial stroke of the
-- step in flight, and the completion banner.

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
  local frame = { prints = { } }
  local prev_print = gfx.print
  active_font = font
  gfx.print = function(text)
    frame.prints[#frame.prints + 1] = text
  end
  local ok, err = pcall(love.draw)
  rawset(gfx, "print", prev_print)
  if not ok then
    error(err)
  end
  T.eq(active_font, font)
  return frame
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

-- Step-by-step mode ------------------------------------------

local function drawn_menu()
  local lines = { }
  local prev = gfx.printf
  gfx.printf = function(text, _, y)
    lines[#lines + 1] = { text = text, y = y }
  end
  local ok, err = pcall(love.draw)
  rawset(gfx, "printf", prev)
  if not ok then
    error(err)
  end
  return lines
end

local function menu_line_y(lines, text)
  for _, item in ipairs(lines) do
    if item.text == text then
      return item.y
    end
  end
end

local function step_mode_on(mode)
  GS.step_by_step = false
  toDrawMenu()
  press({ }, "s")
  startDrawMode(mode)
end

T.it("menu starts with step-by-step off, S toggles it, "
  .. "and guards stay armed", function()
    GS.step_by_step = false
    toDrawMenu()
    local m0 = drawn_menu()
    local y1 = menu_line_y(m0, "1.  Free draw")
    local y2 = menu_line_y(m0, "2.  Draw the picture")
    local y_off = menu_line_y(m0, "S  Step by step: off")
    T.eq(y1 < y2, true)
    T.eq(y2 < y_off, true)
    press({ }, "3")
    press({ }, "a")
    T.eq(GS.screen, "menu")
    T.eq(GS.step_by_step, false)
    press({ }, "s")
    T.eq(GS.step_by_step, true)
    T.eq(compy.input.shortcuts.textinput["1"] ~= nil, true)
    T.eq(compy.input.shortcuts.textinput["2"] ~= nil, true)
    T.eq(compy.input.shortcuts.textinput["s"], nil)
    local m1 = drawn_menu()
    T.eq(menu_line_y(m1, "S  Step by step: on"), y_off)
    press({ }, "s", true)
    T.eq(GS.step_by_step, true)
    for _, chord in ipairs({
      { "ctrl" },
      { "alt" },
      { "ctrl", "shift" },
      { "ctrl", "alt" }
    }) do
      press(chord, "s")
      T.eq(GS.step_by_step, true)
    end
    press({ "shift" }, "s", true)
    T.eq(GS.step_by_step, true)
    press({ "shift" }, "s")
    T.eq(GS.step_by_step, false)
    local m2 = drawn_menu()
    T.eq(menu_line_y(m2, "S  Step by step: off"), y_off)
    startDrawMode("free")
    press({ }, "s")
    T.eq(GS.step_by_step, false)
    press({ "shift" }, "s")
    T.eq(GS.step_by_step, false)
    GS.step_by_step = false
  end)

T.it("step-by-step holds across games until toggled off",
  function()
    step_mode_on("free")
    T.eq(GS.step_by_step, true)
    press({ }, "escape")
    T.eq(GS.screen, "menu")
    T.eq(GS.step_by_step, true)
    press({ }, "2")
    T.eq(GS.screen, "game")
    T.eq(GS.draw_mode, "picture")
    T.eq(GS.step_by_step, true)
    press({ }, "escape")
    T.eq(GS.screen, "menu")
    press({ }, "s")
    press({ }, "1")
    T.eq(GS.step_by_step, false)
    T.eq(widget.flags.prompt, "Commands:")
    GS.step_by_step = false
  end)

T.it("Free draw step-by-step accumulates position, traces "
  .. "and shortcuts", function()
    step_mode_on("free")
    T.eq(widget.flags.prompt, "Next step:")
    T.eq(widget.text, "")
    run("x=2e;x")
    T.eq({ player.col, player.row, player.dir }, { 3, 8, "E" })
    T.eq(trace_count(), 2)
    T.eq(widget.shown, true)
    T.eq(widget.text, "")
    T.eq(widget.flags.prompt, "Next step:")
    widget.flags.on_limit_reached("up")
    T.eq(widget.text, "x=2e;x")
    run("n")
    T.eq({ player.col, player.row, player.dir }, { 3, 7, "N" })
    T.eq(trace_count(), 3)
    run("x")
    T.eq({ player.col, player.row, player.dir }, { 5, 7, "E" })
    T.eq(trace_count(), 5)
    run("c")
    T.eq({ player.col, player.row, player.dir }, { 1, 8, "N" })
    T.eq(trace_count(), 0)
    run("x")
    T.eq({ player.col, player.row, player.dir }, { 3, 8, "E" })
    T.eq(trace_count(), 2)
    press({ }, "escape")
    T.eq(GS.screen, "menu")
    press({ }, "1")
    T.eq({ player.col, player.row, player.dir }, { 1, 8, "N" })
    T.eq(trace_count(), 0)
    run("x")
    T.eq(GS.invalid.msg, "Unknown command: X")
    GS.step_by_step = false
  end)

T.it("step-by-step Esc stops a step cleanly and refused "
  .. "steps change nothing", function()
    step_mode_on("free")
    run("x=2e;x")
    submit("2n")
    tick(1)
    T.eq(widget.shown, false)
    tick(100)
    T.eq(widget.shown, true)
    T.eq(widget.text, "")
    submit("3n")
    love.update(0.2)
    love.update(0.2)
    T.eq(player.anim.kind, "move")
    local col, row = player.col, player.row
    local dir, traces = player.dir, trace_count()
    press({ }, "escape")
    T.eq(GS.running, false)
    T.eq(player.anim.frozen, true)
    T.eq(widget.shown, true)
    T.eq(widget.text, "3n")
    T.eq(widget.flags.prompt, "Next step:")
    run("e")
    T.eq(player.anim, nil)
    T.eq({ player.col, player.row, player.dir },
      { col + 1, row, "E" })
    T.eq(trace_count(), traces + 1)
    submit("q")
    T.eq(GS.invalid.msg, "Unknown command: Q")
    T.eq(widget.text, "q")
    T.eq(widget.flags.prompt, "Unknown command: Q")
    T.eq({ player.col, player.row, player.dir },
      { col + 1, row, "E" })
    T.eq(trace_count(), traces + 1)
    press({ }, "escape")
    T.eq(widget.text, "")
    T.eq(widget.flags.prompt, "Next step:")
    T.eq(GS.screen, "game")
    run("x")
    T.eq(GS.invalid, nil)
    T.eq({ player.col, player.row }, { col + 3, row })
    press({ }, "escape")
    T.eq(GS.screen, "menu")
    GS.step_by_step = false
  end)

T.it("step-by-step keeps text after stop through the "
  .. "three-Esc sequence", function()
    step_mode_on("free")
    submit("4n")
    love.update(0.2)
    press({ }, "escape")
    T.eq(widget.text, "4n")
    T.eq(widget.flags.prompt, "Next step:")
    press({ }, "escape")
    T.eq(widget.text, "")
    T.eq(widget.flags.prompt, "Next step:")
    T.eq(GS.screen, "game")
    press({ }, "escape")
    T.eq(GS.screen, "menu")
    GS.step_by_step = false
  end)

T.it("Draw the picture step-by-step completes across steps "
  .. "and carries all macros on Tab and jump", function()
    step_mode_on("picture")
    T.eq(widget.flags.prompt, "Next step:")
    run("x=2e;x")
    T.eq(GS.won, false)
    run("y=3e;y")
    T.eq(GS.won, true)
    T.eq(widget.text, "")
    T.eq(widget.flags.prompt, "Next step:")
    T.eq(has_text(drawn_frame().prints, DRAW_COMPLETE_PREFIX),
      true)
    press({ }, "tab")
    T.eq(GS.level_index, 2)
    run("z=n")
    run(".")
    T.eq(GS.level_index, 3)
    run("x")
    T.eq(GS.invalid, nil)
    run("y")
    T.eq(GS.invalid, nil)
    run("z")
    T.eq(GS.invalid, nil)
    run(",")
    T.eq(GS.level_index, 2)
    run("z")
    T.eq(GS.invalid, nil)
    GS.step_by_step = false
  end)

T.it("post-win stray step drops win, Tab stays, and returning "
  .. "to menu resets picture macros", function()
    step_mode_on("picture")
    run("x=2e;x")
    run("3e")
    T.eq(GS.won, true)
    run("y=n;y")
    T.eq(GS.won, false)
    T.eq(widget.text, "")
    T.eq(widget.flags.prompt, "Next step:")
    T.eq(has_text(drawn_frame().prints, DRAW_COMPLETE_PREFIX),
      false)
    press({ }, "tab")
    T.eq(GS.level_index, 1)
    press({ }, "escape")
    press({ }, "2")
    run("x")
    T.eq(GS.invalid.msg, "Unknown command: X")
    GS.step_by_step = false
  end)

T.it("last picture step-by-step Tab goes to the menu keeping "
  .. "step mode", function()
    step_mode_on("picture")
    GS.level_index = #DRAW_LEVELS
    startPictureLevel()
    run(DRAW_LEVELS[#DRAW_LEVELS].route)
    local f1 = drawn_frame()
    T.eq(has_text(f1.prints, DRAW_COMPLETE_FINAL_SUFFIX), true)
    press({ }, "tab")
    T.eq(GS.screen, "menu")
    T.eq(GS.step_by_step, true)
    GS.step_by_step = false
  end)

T.it("Esc while backing up after drawing target keeps first "
  .. "win reachable on next step", function()
    local wins = 0
    local prev_win = sfx.win
    sfx.win = function()
      wins = wins + 1
    end
    step_mode_on("picture")
    submit("5e;2b")
    for _ = 1, 6 do
      tick(1)
    end
    love.update(0.2)
    T.eq(trace_count(), 5)
    T.eq(GS.running, true)
    press({ }, "escape")
    T.eq(GS.won, false)
    T.eq(wins, 0)
    press({ }, "escape")
    T.eq(widget.text, "")
    run("r")
    T.eq(wins, 1)
    T.eq(GS.won, true)
    T.eq(has_text(drawn_frame().prints, DRAW_COMPLETE_PREFIX),
      true)
    press({ }, "tab")
    T.eq(GS.level_index, 2)
    sfx.win = prev_win
    GS.step_by_step = false
  end)

T.it("typed s and Shift+s reach the field in both draw "
  .. "games without flipping the mode", function()
    for _, step_on in ipairs({ false, true }) do
      for _, choice in ipairs({ "1", "2" }) do
        GS.step_by_step = false
        toDrawMenu()
        if step_on then
          type_key({ }, "s", "s")
        end
        T.eq(GS.step_by_step, step_on)
        type_key({ }, choice, choice)
        T.eq(widget.text, "")
        type_key({ }, "n", "n")
        T.eq(type_key({ }, "s", "s"), false)
        T.eq(type_key({ "shift" }, "s", "S"), false)
        T.eq(GS.step_by_step, step_on)
        T.eq(widget.text, "nsS")
      end
    end
    GS.step_by_step = false
  end)

T.it("default mode keeps Commands: prompt and resets "
  .. "shortcuts between runs", function()
    GS.step_by_step = false
    toDrawMenu()
    startDrawMode("picture")
    T.eq(widget.flags.prompt, "Commands:")
    run("x=e;x")
    T.eq(widget.text, "x=e;x")
    T.eq(widget.flags.prompt, "Commands:")
    run("x")
    T.eq(GS.invalid.msg, "Unknown command: X")
  end)

T.run()
