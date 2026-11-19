-- main.lua

-- Maze game: guide a player to the destination!

require("core_constants")
require("maze_constants")
require("controls")
require("core_sprites")
require("maze_decorations")
require("core_render")
require("maze_render")
require("core_editor")
require("levels")
require("player")
require("core_anim")
require("maze_logic")
require("keyboard_graphics")
require("macro")
require("maze_plan")
require("script")
require("menu")

sfx = compy.audio

-- The Compy runtime font, captured before any drawing
-- swaps fonts in; layout math that runs outside the draw
-- pass (grid_opts) measures with it.

hud_font = gfx.getFont()

-- Echo of entered commands (one line per Enter).

echo_lines = { }

-- Marker for queue entries with no source (keyboard
-- input on non-editor levels).

NO_REF = { }

-- Game State

macros = { }

level_index = 1
maze = levels[level_index]
cur_controls = editor
cur_progression = portal
cur_legend = nil
cur_grid = false
cur_background = nil

GS = {
  init = false,
  mode = "menu",
  grid = nil,
  goal_map = { },
  box_map = { },
  box_goal_map = { },
  box_goal_count = 0,
  filled_count = 0,
  won = false,
  celebrating = false,
  running = false,
  base_macros = { }
}

function ensure_init()
  GS.init = true
end

-- Main Loop

-- Tab moves the level on: forward after a win, back to the
-- start after a failed run, and a plain restart otherwise.
-- While a program or a plan runs it does nothing: Esc stops
-- a run.
--
-- ignore_repeat, or a held Tab walks through the levels.
-- side_run, so the press travels on afterwards and still
-- reaches the command widget on editor levels.
--
-- Every modifier combination is listed because a shortcut
-- matches its modifiers exactly, and this gesture answers
-- to all of them. Drop the ones nobody meant, if any.
-- alt+tab is listed for completeness -- the desktop
-- usually takes it before any program sees it.

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

function tab_progression()
  if GS.mode ~= "game" or GS.running then
    return
  end
  if GS.celebrating or GS.won then
    next_level()
  elseif GS.failed then
    reset_after_fail()
  else
    reset_level()
  end
end

for _, combo in ipairs(TAB_COMBOS) do
  compy.input.shortcuts.keypressed[combo] =
      compy.input.fn.side_run(
        compy.input.fn.ignore_repeat(tab_progression))
end

-- Return to the start menu, dropping game input. The
-- command widget goes with it: nothing else can hide one,
-- so a widget left shown here would sit over the menu for the
-- rest of the session, taking a share of every key the menu
-- is trying to read.

function to_menu()
  GS.mode = "menu"
  ctrl_update = nil
  ctrl_pressed = nil
  compy.input.hide()
end

-- Advance the running program one frame: progress any
-- animation, then either keep its tracks turning or pull
-- the next command. Stepping pauses during a win.

function step_program(dt)
  if player.anim then
    advance_anim(dt)
  end
  if player.anim then
    update_track_offsets(dt)
  elseif not GS.celebrating then
    execute_next()
  end
end

function love.update(dt)
  ensure_init()
  if GS.mode ~= "game" then
    return
  end
  step_program(dt)
  if ctrl_update then
    ctrl_update(dt)
  end
end

function love.draw()
  if not GS.init then
    return
  end
  if GS.mode == "menu" then
    menu_draw()
  else
    draw_scene()
  end
end

SYSTEM_KEYS = { }

-- The Menu key toggles the grid. A click is no command: the
-- program takes no mouse hook, so a click reaches the command
-- field, where it places the cursor.

function SYSTEM_KEYS.menu()
  cur_grid = not cur_grid
  sfx.sword()
end

-- Esc while the robot runs a program stops it and brings the
-- field back with the program (stop_run); while it runs a
-- plan, it stops the plan (plan_stop). At the miss or crash
-- banner it does what Tab does there (reset_after_fail): the
-- banner is a level, and Esc goes one back. Then it empties the command field when it holds text, and
-- a plan that holds keys; from an empty one, or a level with
-- neither, it steps back to the track menu, as the editor
-- first drops the edit and then leaves the file. The menu is
-- the top level, where Esc leaves the game for the console,
-- as Ctrl+Q does from anywhere.
--
-- One shortcut decides every step. A combo is offered the key
-- before the command widget is, so a shown widget cannot hide
-- the gesture. It takes only a bare Esc, and only its press:
-- a chord with Esc is no command here, and a held Esc that
-- stopped a run, emptied the field or reached the menu goes
-- no further.

function on_escape()
  local typed = (compy.input.get_text() or "") ~= ""
  if GS.running and cur_controls == plan then
    plan_stop()
  elseif GS.running then
    stop_run()
  elseif GS.failed then
    reset_after_fail()
  elseif typed then
    clear_field()
  elseif plan_holds_keys() then
    plan_reset()
  elseif GS.mode == "game" then
    to_menu()
  else
    stop()
  end
end

compy.input.shortcuts.keypressed["escape"] =
    compy.input.fn.stop_here(compy.input.fn.ignore_repeat(on_escape))

-- The whole press is passed on, not just the key name: the
-- plan buffer needs to know whether it is a fresh press or
-- the keyboard repeating, and only the press itself can say
-- so. Direct-control levels ignore the extra arguments and
-- keep repeating, which is how holding a direction has
-- always queued a run of moves there.

function game_key(k, sk, isrepeat)
  local fn = SYSTEM_KEYS[k]
  if fn then
    fn()
  elseif ctrl_pressed then
    ctrl_pressed(k, sk, isrepeat)
  end
end

-- A hook rather than love.keypressed, because combos are
-- registered on this same channel above: Esc and the Tab
-- family are offered every press first and may take it,
-- so this does not see them all -- and a plain callback
-- would read as though it did. The other channels stay
-- callbacks; nothing is registered ahead of them.
--
-- A chord with Esc does nothing here, nor in the field; a
-- bare Esc was taken by its shortcut before this ran.

compy.input.hooks.keypressed = function(k, sk, isrepeat)
  if k == "escape" then
    return
  end
  if GS.mode == "menu" then
    menu_key(k)
  else
    game_key(k, sk, isrepeat)
  end
end

-- Also a hook, and deliberately WITHOUT a return. Releasing
-- Shift ENDS a macro recording (macro.lua, release_shift):
-- an edge, not remembered state -- whether Shift is down is
-- asked of the keyboard, in handle_key. So this claims
-- nothing and the release goes on to whatever is below it.
-- As love.keyreleased it would have consumed the channel
-- (doc/input_api.md, "Event hooks and shortcuts -- when to use
-- which").
compy.input.hooks.keyreleased = function(k)
  release_shift(k)
end

function love.resize()
  if GS.init and GS.mode == "game" then
    init_grid(GRID.rows, GRID.cols, grid_opts())
  end
end
