-- draw_main.lua

-- Draw contains two mini-games on the shared command core:
-- the free canvas and 20 picture tasks. Each run draws its
-- whole program from a clean start, as maze runs its level.

require("core_constants")
require("draw_constants")
require("core_sprites")
require("core_render")
require("draw_render")
require("core_editor")
require("player")
require("core_anim")
require("script")
require("keyboard_graphics")
require("draw_levels")
require("draw_menu")

sfx = compy.audio

echo_lines = { }
macros = { }
cur_controls = nil
cur_legend = DRAW_LEGEND

GS = {
  init = false,
  screen = "menu",
  draw_mode = nil,
  level_index = nil,
  hint = false,
  won = false,
  running = false,
  base_macros = { }
}

function currentDrawLevel()
  if GS.draw_mode ~= "picture" then
    return nil
  end
  return DRAW_LEVELS[GS.level_index]
end

function activeStart()
  local level = currentDrawLevel()
  if level then
    return level.col, level.row, level.dir
  end
  return START.col, START.row, START.dir
end

-- App hooks named by the shared editor and animation core.

function blocked(tc, tr)
  return tc < 1 or GRID.cols < tc or tr < 1 or GRID.rows < tr
end

-- A validated program runs from a clean start, as maze
-- resets its level: the drawing goes, the robot is back on
-- its start cell and heading, and nothing of an earlier run
-- is queued. The field keeps the program, so the child edits
-- it and runs it again.

function before_run()
  local col, row, dir = activeStart()
  player_reset(col, row, dir)
  GS.won = false
end

function after_step()
end

function finish_run()
  GS.running = false
  local level = currentDrawLevel()
  local matched = level and
      tracesMatchTarget(player.traces, level)
  if not matched then
    return
  end
  GS.won = true
  ctrl_update = nil
  sfx.win()
end

function draw_move(cmd, ref)
  local tc, tr = move_cmd_target(cmd)
  if blocked(tc, tr) then
    return
  end
  start_forward(cmd, ref, tc, tr)
end

function clear_canvas()
  local col, row, dir = activeStart()
  reset_robot(col, row, dir)
  GS.won = false
end

function takeDrawLevelRepeats(cmd)
  local count = 1
  while player.queue[1] == cmd do
    table.remove(player.queue, 1)
    table.remove(player.queue_refs, 1)
    count = count + 1
  end
  return count
end

function jumpPictureLevel(delta)
  if GS.draw_mode ~= "picture" then
    return
  end
  local index = clampDrawLevelIndex(GS.level_index + delta)
  if index ~= GS.level_index then
    GS.base_macros = clone_macros(macros)
    GS.level_index = index
  end
  startPictureLevel()
end

function stepPictureLevel(cmd)
  local sign = (cmd == ",") and -1 or 1
  jumpPictureLevel(sign * takeDrawLevelRepeats(cmd))
end

CMD_HANDLERS = {
  ["."] = stepPictureLevel,
  [","] = stepPictureLevel,
  F = draw_move,
  B = draw_move,
  L = start_turn,
  R = start_turn,
  C = clear_canvas
}

-- Layout

-- The grid keeps clear of the FIELD_ROWS the runtime covers.
-- Two of the font's own heights are taller than those rows,
-- the status line's extra pixels and the bottom strip
-- included, so the 8x8 grid, whose robot starts bottom-left,
-- sits above the band.

function editor_band_h()
  return FIELD_ROWS * gfx.getFont():getHeight()
end

function legend_band_w()
  local font = gfx.getFont()
  local wide = 0
  for line in (cur_legend .. "\n"):gmatch("(.-)\n") do
    wide = math.max(wide, font:getWidth(line))
  end
  return wide + 2 * font:getHeight()
end

function picturePanelWidth()
  local preview_w = gfx.getHeight() * PREVIEW_WIDTH_FRAC
  return math.max(legend_band_w(), preview_w)
end

function draw_layout()
  local right = legend_band_w()
  if GS.draw_mode == "picture" then
    right = picturePanelWidth()
  end
  return {
    pad_bottom = editor_band_h(),
    pad_right = right,
    margin = gfx.getFont():getHeight()
  }
end

-- Mini-game lifecycle

function resetDrawProgramState()
  echo_lines = { }
  GS.invalid = nil
  GS.program = nil
  GS.running = false
  GS.won = false
  cur_controls = editor
  cur_legend = DRAW_LEGEND
  macros = clone_macros(GS.base_macros)
end

function startFreeDraw()
  setPictureNavigationEnabled(false)
  GS.level_index = nil
  GS.hint = false
  GS.base_macros = { }
  resetDrawProgramState()
  init_grid(CANVAS.rows, CANVAS.cols, draw_layout())
  player_reset(START.col, START.row, START.dir)
  editor()
end

function startPictureLevel()
  local level = currentDrawLevel()
  resetDrawProgramState()
  GS.hint = level.hint
  init_grid(CANVAS.rows, CANVAS.cols, draw_layout())
  player_reset(level.col, level.row, level.dir)
  editor()
end

function startPictureTasks()
  setPictureNavigationEnabled(true)
  GS.level_index = 1
  GS.base_macros = { }
  startPictureLevel()
end

function startDrawMode(mode)
  GS.screen = "game"
  GS.draw_mode = mode
  if mode == "free" then
    startFreeDraw()
  else
    startPictureTasks()
  end
end

-- The command widget goes with the screen: nothing else can
-- hide one, so a widget left shown here would sit over the
-- menu for the rest of the session, taking a share of every
-- key the menu is trying to read.

function toDrawMenu()
  setPictureNavigationEnabled(false)
  GS.screen = "menu"
  GS.draw_mode = nil
  GS.won = false
  player.queue = { }
  player.queue_refs = { }
  ctrl_update = nil
  ctrl_pressed = nil
  compy.input.hide()
  armDrawMenuGuards()
end

function nextPictureLevel()
  GS.base_macros = clone_macros(macros)
  GS.level_index = GS.level_index + 1
  if #DRAW_LEVELS < GS.level_index then
    toDrawMenu()
    return
  end
  startPictureLevel()
end

-- Main loop and input

function ensure_init()
  if GS.init then
    return
  end
  prepareDrawLevels()
  GS.init = true
end

function stepDrawProgram(dt)
  if player.anim then
    advance_anim(dt)
  end
  if player.anim then
    update_track_offsets(dt)
  else
    execute_next()
  end
end

-- Tab moves on to the next picture once this one is done.
-- A shortcut reaches it even while the command editor is
-- open, which Free draw never closes.
--
-- ignore_repeat, or a held Tab walks through the pictures;
-- side_run, so the press still travels on to the widget.
-- Every modifier combination is listed because a shortcut
-- matches its modifiers exactly, and this gesture answers
-- to all of them. alt+tab is listed for completeness; the
-- desktop usually takes it first.

TAB_COMBOS = {
  "tab",
  "shift+tab",
  "ctrl+tab",
  "alt+tab",
  "ctrl+shift+tab",
  "ctrl+alt+tab",
  "alt+shift+tab",
  "ctrl+alt+shift+tab"
}

function tabProgression()
  if GS.screen ~= "game" then
    return
  end
  if GS.won then
    nextPictureLevel()
  end
end

for _, combo in ipairs(TAB_COMBOS) do
  compy.input.shortcuts.keypressed[combo] =
      compy.input.fn.side_run(
        compy.input.fn.ignore_repeat(tabProgression))
end

function love.update(dt)
  ensure_init()
  if GS.screen ~= "game" then
    return
  end
  stepDrawProgram(dt)
  if ctrl_update then
    ctrl_update(dt)
  end
end

function love.draw()
  ensure_init()
  if GS.screen == "menu" then
    drawMenu()
  else
    draw_scene()
  end
end

SYSTEM_KEYS = { }

-- The Menu key toggles the picture hint. A click is no
-- command: the program takes no mouse hook, so a click
-- reaches the command field, where it places the cursor.

function SYSTEM_KEYS.menu()
  if GS.draw_mode ~= "picture" then
    return
  end
  GS.hint = not GS.hint
  sfx.sword()
end

-- Esc empties the command field when it holds text, so the
-- next step starts on a clean line: Esc, C, Enter. From an
-- empty field Esc steps back to this program's menu, as the
-- editor first drops the edit and then leaves the file. The
-- menu is the top level, where Esc leaves Draw for the
-- console, as Ctrl+Q does from anywhere.
--
-- One shortcut decides every step. A combo is offered the key
-- before the widget is, which is what makes it reach Free
-- draw at all: that mode keeps its field shown the whole
-- time. It takes only a bare Esc, and only its press: a chord
-- with Esc is no command here, and a held Esc that emptied
-- the field or reached the menu goes no further.

function on_escape()
  local typed = (compy.input.get_text() or "") ~= ""
  if typed then
    clear_field()
  elseif GS.screen == "game" then
    toDrawMenu()
  else
    stop()
  end
end

compy.input.shortcuts.keypressed["escape"] =
    compy.input.fn.stop_here(compy.input.fn.ignore_repeat(on_escape))

function drawGameKey(key)
  local fn = SYSTEM_KEYS[key]
  if fn then
    fn()
  elseif ctrl_pressed then
    ctrl_pressed(key)
  end
end

-- A hook rather than love.keypressed, because combos are
-- registered on this same channel above: Esc and the Tab
-- family are offered every press first and may take it, so
-- this does not see them all. A chord with Esc does nothing
-- here, nor in the field.

compy.input.hooks.keypressed = function(key)
  if key == "escape" then
    return
  end
  if GS.screen == "menu" then
    drawMenuKey(key)
  else
    drawGameKey(key)
  end
end

-- The game boots on the menu, so its echo guards are armed once
-- here at load; toDrawMenu re-arms them on every return.
armDrawMenuGuards()

function love.resize()
  local active = GS.init and GS.screen == "game"
  if active then
    init_grid(CANVAS.rows, CANVAS.cols, draw_layout())
  end
end
