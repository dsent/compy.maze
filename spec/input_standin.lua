-- spec/input_standin.lua

-- A stand-in for the Compy runtime's input routing, for the
-- Escape specs. It follows the runtime's documented contract
-- (doc/input_api.md): a key press goes to its exact combo
-- shortcut, then the hook, then the shown widget, stopping at
-- the first that takes it. The widget treats a bare Esc as a
-- cancel, its repeats included, as the IDE's field does
-- (fieldKeys.lua binds the cancel to the chord "escape" alone,
-- and the field looks a key up by its exact chord); a cancel
-- empties the field only under clear_on_cancel and hides it
-- only under hide_on_cancel. A hidden widget's get_text
-- answers nil. Key answers for the modifiers of the press in
-- hand. stop() counts its calls in `stops`.

local here = ...

widget = { shown = false, text = "", flags = { } }

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

local function ignore_repeat(f)
  return function(k, sc, isrepeat)
    if not isrepeat then
      return f(k, sc, isrepeat)
    end
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
      ignore_repeat = ignore_repeat
    },
    configure = function(flags)
      for k, v in pairs(flags) do
        widget.flags[k] = v
      end
    end,
    show = function(config)
      for k, v in pairs(config) do
        widget.flags[k] = v
      end
      widget.shown = true
    end,
    hide = function()
      widget.shown = false
    end,
    is_shown = function()
      return widget.shown
    end,
    get_text = function()
      if widget.shown then
        return widget.text
      end
    end,
    clear = function()
      widget.text = ""
    end
  }
}

-- stop() ends the program in the runtime; here it counts.

stops = 0

function stop()
  stops = stops + 1
end

-- The modifiers of the press in hand, as Key reports them.

local held = { }

Key = {
  shift = function()
    return held.shift == true
  end,
  ctrl = function()
    return held.ctrl == true
  end,
  alt = function()
    return held.alt == true
  end,
  is_shift = function(k)
    return k == "lshift" or k == "rshift"
  end
}

function string.lines(text)
  return { text }
end

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
  maze_render = true,
  maze_decorations = true,
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

-- A key press through the routing. mods in the runtime's
-- combo order: ctrl, alt, shift.

local function route(mods, key, isrepeat)
  local combo = table.concat(mods, "+")
  if combo ~= "" then
    combo = combo .. "+"
  end
  combo = combo .. key
  local sc = compy.input.shortcuts.keypressed[combo]
  if sc and sc(key, "", isrepeat) then
    return
  end
  local hook = compy.input.hooks.keypressed
  if hook and hook(key, "", isrepeat) then
    return
  end
  local cancel = widget.shown and combo == "escape"
  if not cancel then
    return
  end
  if widget.flags.clear_on_cancel then
    widget.text = ""
  end
  if widget.flags.hide_on_cancel then
    widget.shown = false
  end
end

function press(mods, key, isrepeat)
  held = { }
  for _, m in ipairs(mods) do
    held[m] = true
  end
  route(mods, key, isrepeat)
  held = { }
end

-- Every chord of Escape with Ctrl, Alt or Shift held.

ESC_CHORDS = {
  { "shift" },
  { "alt" },
  { "alt", "shift" },
  { "ctrl" },
  { "ctrl", "shift" },
  { "ctrl", "alt" },
  { "ctrl", "alt", "shift" }
}
