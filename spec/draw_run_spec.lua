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
draw_layout = function()
  return { }
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

T.it("a jump carries the jumping program's shortcuts, as in maze",
  function()
    startDrawMode("picture")
    run("x=e;.")
    T.eq(GS.level_index, 2)
    T.eq(widget.text, "")
    run("x")
    T.eq(GS.invalid, nil)
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

T.run()
