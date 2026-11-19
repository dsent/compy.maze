-- Esc in maze: a bare Esc empties a command field that holds
-- text and a plan that holds keys, from an empty one or a
-- level with neither steps back to the track menu, and at the
-- menu leaves the program. Esc with Ctrl, Alt or Shift held
-- does none of this, and a held Esc acts once. maze_main.lua
-- runs here against the stand-in in input_standin.lua.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
dofile(here .. "/support.lua")
assert(loadfile(here .. "/input_standin.lua"))(here)
dofile(here .. "/../maze_main.lua")

-- A level with the command field, holding `text`; or, with
-- no text, a direct-control level, which shows no field and
-- runs the real direct controls (controls.lua, keys).

local function in_game(text)
  reset_state()
  GS.mode = "game"
  GS.running = nil
  ctrl_pressed = nil
  macro_state.recording = false
  widget.shown = text ~= nil
  widget.text = text or ""
  if text == nil then
    keys()
  end
end

print("== Maze Escape ==")

-- Esc is the program's alone: the field's own cancel stays
-- inert, so neither flag is set, at load or when the field
-- opens.

T.it("the field is given no cancel flag", function()
  open_editor("")
  T.eq(widget.flags.clear_on_cancel, nil)
  T.eq(widget.flags.hide_on_cancel, nil)
end)

-- A click is no command: no mouse hook takes it, so the
-- runtime hands it to the field. The runtime makes a
-- love.mousepressed a hook too, so neither may be set.

T.it("no mouse hook takes a click from the field", function()
  T.eq(compy.input.hooks.mousepressed, nil)
  T.eq(love.mousepressed, nil)
end)

-- A refused program's error goes with its text: the prompt
-- says "Commands:" again and the echo is empty, as at a
-- level's fresh start.

T.it("Esc after a refused program clears its error", function()
  in_game("")
  open_editor("")
  submit("q")
  T.eq(widget.text, "q")
  T.eq(widget.flags.prompt, "Unknown command: Q")
  press({ }, "escape")
  T.eq(widget.text, "")
  T.eq(widget.flags.prompt, "Commands:")
  T.eq(GS.invalid, nil)
  T.eq(echo_lines, { })
  T.eq(GS.mode, "game")
  press({ }, "escape")
  T.eq(GS.mode, "menu")
end)

T.it("Esc on a field emptied by hand still goes back", function()
  in_game("")
  open_editor("")
  submit("q")
  widget.text = ""
  press({ }, "escape")
  T.eq(GS.mode, "menu")
end)

T.it("Esc empties the field and stays in the level", function()
  in_game("FF")
  press({ }, "escape")
  T.eq(widget.text, "")
  T.eq(GS.mode, "game")
end)

T.it("Esc on an empty field goes to the menu", function()
  in_game("")
  press({ }, "escape")
  T.eq(GS.mode, "menu")
  T.eq(widget.shown, false)
end)

T.it("Esc in a level with no field goes to the menu", function()
  in_game(nil)
  press({ }, "escape")
  T.eq(GS.mode, "menu")
end)

local function at_menu()
  GS.mode = "menu"
  widget.shown = false
  stops = 0
end

T.it("Esc at the menu leaves the program", function()
  at_menu()
  press({ }, "escape")
  T.eq(stops, 1)
end)

T.it("a held Esc that reaches the menu stays there", function()
  in_game("")
  stops = 0
  press({ }, "escape")
  press({ }, "escape", true)
  press({ }, "escape", true)
  T.eq(GS.mode, "menu")
  T.eq(stops, 0)
end)

for _, mods in ipairs(ESC_CHORDS) do
  local name = table.concat(mods, "+") .. "+escape"
  T.it(name .. " at the menu does nothing", function()
    at_menu()
    press(mods, "escape")
    T.eq(stops, 0, name)
    T.eq(GS.mode, "menu", name)
  end)
end

T.it("a held Esc empties the field and stays in the level",
  function()
    in_game("FF")
    press({ }, "escape")
    press({ }, "escape", true)
    press({ }, "escape", true)
    T.eq(widget.text, "")
    T.eq(GS.mode, "game")
  end)

T.it("a held Esc left from a chord does not leave", function()
  in_game(nil)
  press({ "alt" }, "escape")
  press({ }, "escape", true)
  T.eq(GS.mode, "game")
end)

-- Plan a path: the plan buffer counts as a field. `keys` is
-- what it holds; `running` puts a run in flight.

local function in_plan(keys, running)
  in_game(nil)
  ctrl_pressed = plan_key
  GS.plan = { buf = keys, done = 0 }
  GS.running = running
end

T.it("Esc empties a plan that holds keys and stays", function()
  in_plan({ "N", "E" })
  press({ }, "escape")
  T.eq(#GS.plan.buf, 0)
  T.eq(GS.mode, "game")
end)

T.it("Esc on an empty plan goes to the menu", function()
  in_plan({ })
  press({ }, "escape")
  T.eq(GS.mode, "menu")
end)

T.it("a held Esc empties the plan and stays", function()
  in_plan({ "N", "E" })
  press({ }, "escape")
  press({ }, "escape", true)
  press({ }, "escape", true)
  T.eq(#GS.plan.buf, 0)
  T.eq(GS.mode, "game")
end)

T.it("shift+escape keeps the plan and the level", function()
  in_plan({ "N", "E" })
  press({ "shift" }, "escape")
  T.eq(GS.plan.buf, { "N", "E" })
  T.eq(GS.mode, "game")
end)

T.it("Esc during a run goes to the menu", function()
  in_plan({ "N", "E" }, true)
  press({ }, "escape")
  T.eq(GS.mode, "menu")
  GS.running = false
end)

for _, mods in ipairs(ESC_CHORDS) do
  local name = table.concat(mods, "+") .. "+escape"
  T.it(name .. " keeps the draft and the level", function()
    in_game("FF")
    press(mods, "escape")
    T.eq(widget.text, "FF", name)
    T.eq(widget.shown, true, name)
    T.eq(GS.mode, "game", name)
  end)
  T.it(name .. " stays in a level with no field", function()
    in_game(nil)
    press(mods, "escape")
    T.eq(GS.mode, "game", name)
    T.eq(macro_state.recording, false, name)
    T.eq(#player.queue, 0, name)
  end)
end

T.run()
