-- Escape in draw: bare Escape empties the command field, and
-- Escape with Ctrl, Alt or Shift held leaves it alone. The
-- widget lives in the Compy runtime, so draw_main.lua runs
-- here against a stand-in that follows the runtime's
-- documented contract (doc/input_api.md): a key press goes to
-- its exact combo shortcut, then the hook, then the shown
-- widget, stopping at the first that takes it; the widget
-- empties its field on an Escape without Ctrl once the program
-- sets clear_on_cancel.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
dofile(here .. "/support.lua")

-- The stand-in widget and the input surface draw_main.lua
-- writes to at load.

local widget = { shown = false, text = "", flags = { } }

local function stop_here(f)
  return function(...)
    if f then
      f(...)
    end
    return true
  end
end

local function side_run(f)
  return function(...)
    if f then
      f(...)
    end
    return false
  end
end

compy = {
  audio = setmetatable({ }, {
    __index = function()
      return function() end
    end
  }),
  input = {
    shortcuts = { keypressed = { }, textinput = { } },
    hooks = { },
    fn = {
      stop_here = stop_here,
      side_run = side_run,
      ignore_repeat = function(f)
        return f
      end
    },
    configure = function(flags)
      for k, v in pairs(flags) do
        widget.flags[k] = v
      end
    end,
    hide = function()
      widget.shown = false
    end
  }
}

love = { }
gfx = setmetatable({ }, {
  __index = function()
    return function() end
  end
})

-- Rendering and sprites are not needed to route a key.
local skipped = {
  core_sprites = true,
  core_render = true,
  draw_render = true,
  keyboard_graphics = true
}
local loaded = { }

function require(name)
  if loaded[name] or skipped[name] then
    return
  end
  loaded[name] = true
  dofile(here .. "/../" .. name .. ".lua")
end

dofile(here .. "/../draw_main.lua")

-- Modifiers in the runtime's combo order: ctrl, alt, shift.

local function press(mods, key)
  local combo = table.concat(mods, "+")
  if combo ~= "" then
    combo = combo .. "+"
  end
  local ctrl = combo:find("ctrl+", 1, true) ~= nil
  local sc = compy.input.shortcuts.keypressed[combo .. key]
  if sc and sc(key) then
    return
  end
  local hook = compy.input.hooks.keypressed
  if hook and hook(key) then
    return
  end
  if widget.shown and key == "escape" and not ctrl
      and widget.flags.clear_on_cancel then
    widget.text = ""
  end
end

local function in_game_with_draft()
  GS.screen = "game"
  widget.shown = true
  widget.text = "EE"
end

print("== Draw Escape ==")

T.it("bare Escape empties the field and stays in the game", function()
  in_game_with_draft()
  press({ }, "escape")
  T.eq(widget.text, "")
  T.eq(GS.screen, "game")
end)

-- This fails if the Shift+Esc shortcut goes: the press then
-- falls through to the shown widget as an Escape and empties
-- the field in the game.

T.it("Shift+Esc goes to the menu and keeps the draft", function()
  in_game_with_draft()
  press({ "shift" }, "escape")
  T.eq(widget.text, "EE")
  T.eq(GS.screen, "menu")
end)

local keeps = {
  { "alt" },
  { "alt", "shift" },
  { "ctrl" },
  { "ctrl", "shift" },
  { "ctrl", "alt" },
  { "ctrl", "alt", "shift" }
}

for _, mods in ipairs(keeps) do
  local name = table.concat(mods, "+") .. "+escape"
  T.it(name .. " keeps the draft", function()
    in_game_with_draft()
    press(mods, "escape")
    T.eq(widget.text, "EE", name)
    T.eq(GS.screen, "game", name)
  end)
end

T.run()
