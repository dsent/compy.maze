-- Draw command-language invariants that differ by mini-game.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
dofile(here .. "/support.lua")
dofile(here .. "/../core_constants.lua")
dofile(here .. "/../draw_constants.lua")
dofile(here .. "/../script.lua")

print("== Draw mini-game command scopes ==")

T.it("Free draw rejects picture-navigation commands", function()
  setPictureNavigationEnabled(false)
  local next_bad = validate_program({ ".E" })
  local previous_bad = validate_program({ "," })
  T.eq(next_bad.msg, "Invalid input")
  T.eq(next_bad.col_from, 1)
  T.eq(previous_bad.msg, "Invalid input")
  T.eq(previous_bad.col_from, 1)
end)

T.it("picture mode accepts silent next and previous commands", function()
  setPictureNavigationEnabled(true)
  T.eq(validate_program({ "3.;2," }), nil)
  T.eq(SILENT_CMDS["."], true)
  T.eq(SILENT_CMDS[","], true)
end)

-- Esc is the way back to the menu: a typed "<" is an
-- unknown token in both mini-games.

T.it("both mini-games refuse a typed <", function()
  setPictureNavigationEnabled(false)
  T.eq(validate_program({ "<" }).msg, "Invalid input")
  setPictureNavigationEnabled(true)
  T.eq(validate_program({ "<" }).msg, "Invalid input")
  T.eq(PRIMITIVES["<"], nil)
end)

T.run()
