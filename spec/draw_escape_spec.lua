-- Esc in draw: a bare Esc empties a command field that holds
-- text, from an empty field steps back to the draw menu, and
-- at the menu leaves the program. Esc with Ctrl, Alt or Shift
-- held does none of this, and a held Esc acts once. The
-- widget lives in the Compy runtime, so draw_main.lua runs
-- here against the stand-in in input_standin.lua.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
dofile(here .. "/support.lua")
assert(loadfile(here .. "/input_standin.lua"))(here)
dofile(here .. "/../draw_main.lua")

local function in_game(text)
  GS.screen = "game"
  widget.shown = true
  widget.text = text
end

print("== Draw Escape ==")

-- Esc is the program's alone: the field's own cancel stays
-- inert, so neither flag is set, at load or when the field
-- opens.

T.it("the field is given no cancel flag", function()
  open_editor("")
  T.eq(widget.flags.clear_on_cancel, nil)
  T.eq(widget.flags.hide_on_cancel, nil)
end)

-- A click is no command: no mouse hook takes it, so the
-- runtime hands it to the field.

T.it("no mouse hook takes a click from the field", function()
  T.eq(compy.input.hooks.mousepressed, nil)
end)

T.it("Esc empties the field and stays in the game", function()
  in_game("EE")
  press({ }, "escape")
  T.eq(widget.text, "")
  T.eq(GS.screen, "game")
end)

T.it("Esc on an empty field goes to the menu", function()
  in_game("")
  press({ }, "escape")
  T.eq(GS.screen, "menu")
  T.eq(widget.shown, false)
end)

local function at_menu()
  GS.screen = "menu"
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
  T.eq(GS.screen, "menu")
  T.eq(stops, 0)
end)

for _, mods in ipairs(ESC_CHORDS) do
  local name = table.concat(mods, "+") .. "+escape"
  T.it(name .. " at the menu does nothing", function()
    at_menu()
    press(mods, "escape")
    T.eq(stops, 0, name)
    T.eq(GS.screen, "menu", name)
  end)
end

T.it("a held Esc empties the field and stays in the game",
  function()
    in_game("EE")
    press({ }, "escape")
    press({ }, "escape", true)
    press({ }, "escape", true)
    T.eq(widget.text, "")
    T.eq(GS.screen, "game")
  end)

T.it("a held Esc left from a chord does not leave", function()
  in_game("")
  press({ "alt" }, "escape")
  press({ }, "escape", true)
  T.eq(GS.screen, "game")
end)

for _, mods in ipairs(ESC_CHORDS) do
  local name = table.concat(mods, "+") .. "+escape"
  T.it(name .. " keeps the draft and the game", function()
    in_game("EE")
    press(mods, "escape")
    T.eq(widget.text, "EE", name)
    T.eq(widget.shown, true, name)
    T.eq(GS.screen, "game", name)
  end)
  T.it(name .. " on an empty field stays in the game", function()
    in_game("")
    press(mods, "escape")
    T.eq(widget.shown, true, name)
    T.eq(GS.screen, "game", name)
  end)
end

T.run()
