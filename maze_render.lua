-- maze_render.lua

-- Maze-only rendering: walls, cells, grid, goals,
-- boxes, legend, macro list, win/fail modals, scene.

-- The in-game HUD inherits the Compy runtime font: a
-- monospace Nerd font carrying icon + CJK fallbacks,
-- sized to the screen. The legend's compass and rotation
-- glyphs live in those fallbacks, so the HUD must NOT
-- install its own font. Only the start menu picks a
-- proportional UI font, cached by size below.

FONT_UI = "assets/fonts/SarasaGothicJ-Bold.ttf"

FONT_CACHE = { }

function getFont(path, px)
  local key = px .. ":" .. path
  local f = FONT_CACHE[key]
  if not f then
    f = gfx.newFont(path, px)
    FONT_CACHE[key] = f
  end
  return f
end

function draw_walls()
  if cur_background then
    cur_background()
    return
  end
  local w, h = gfx.getDimensions()
  gfx.setColor(Color[Color.blue + Color.bright])
  gfx.rectangle("fill", 0, 0, w, h)
end

function draw_cells()
  gfx.setColor(Color[Color.white])
  for r, row in ipairs(GS.grid) do
    for c = 1, #row do
      if row:sub(c, c) ~= "#" then
        local x, y = cell_top_left(c, r)
        gfx.rectangle("fill", x, y, GRID.cell, GRID.cell)
      end
    end
  end
end

-- Grid crosses in center of passable squares

function draw_cross(cx, cy, s)
  gfx.line(cx - s, cy, cx + s, cy)
  gfx.line(cx, cy - s, cx, cy + s)
end

function draw_grid()
  if not cur_grid then
    return
  end
  gfx.setColor(Color[Color.white + Color.bright])
  gfx.setLineWidth(1)
  for r, row in ipairs(GS.grid) do
    for c = 1, #row do
      if row:sub(c, c) ~= "#" then
        local cx, cy = cell_center(c, r)
        draw_cross(cx, cy, GRID.cell / 4)
      end
    end
  end
end

-- Destination targets

function draw_goals()
  for _, g in pairs(GS.goal_map) do
    local x, y = cell_center(g.col, g.row)
    local fill = TARGET.cell_fill * g.radius
    local w, h = TARGET.sprite_w, TARGET.sprite_h
    local s = sprite_scale(w, h, fill)
    gfx.push("all")
    gfx.translate(x, y)
    gfx.scale(s, s)
    gfx.translate(-w / 2, -h / 2)
    target_sprite()
    gfx.pop()
  end
end

-- Position near the wall edge.

function bump_pos(p)
  local a = player.anim
  local dir = player.dir
  if a.move_cmd == "B" then
    dir = OPPOSITE_DIR[dir]
  end
  local d = DIR_DELTA[dir]
  local cx, cy = cell_center(player.col, player.row)
  return cx + d.x * GRID.bump_dist * p, cy + d.y * GRID.
      bump_dist * p
end

function ANIM_DRAW_POS.bump()
  return bump_pos(anim_progress())
end

function ANIM_DRAW_POS.fail()
  return bump_pos(1)
end

function push_offset(p)
  local peak = GRID.push_path - GRID.bump_dist
  local dist = GRID.push_path * p
  if dist < peak then
    return dist
  end
  return peak - (dist - peak)
end

function push_player_pos()
  local a = player.anim
  local dir = push_dir(a.move_cmd)
  local d = DIR_DELTA[dir]
  local cx, cy = cell_center(a.from_col, a.from_row)
  local f = push_offset(anim_progress())
  return cx + (d.x * f), cy + (d.y * f)
end

function push_box_offset(p)
  local dist = GRID.push_path * p - GRID.bump_dist
  if dist < 0 then
    return 0
  end
  if GRID.cell < dist then
    return GRID.cell
  end
  return dist
end

ANIM_DRAW_POS.push = push_player_pos

-- Letters of currently defined non-empty macros,
-- shown above the legend in up to 3 lines of 8.

function macro_letters()
  local letters = { }
  for k, v in pairs(macros) do
    if 0 < #v then
      table.insert(letters, k)
    end
  end
  table.sort(letters)
  return letters
end

function macro_lines(letters)
  local n = MACRO_LINE_LEN
  local lines = { }
  for i = 1, #letters, n do
    local j = math.min(i + n - 1, #letters)
    table.insert(lines, table.concat(letters, "", i, j))
  end
  return lines
end

function draw_macros_list()
  local letters = macro_letters()
  local lines = macro_lines(letters)
  local font = gfx.getFont()
  local fh = font:getHeight()
  local row = text_row(font)
  local w = gfx.getWidth()
  local x = (w - fh) - font:getWidth(
    string.rep("X", MACRO_LINE_LEN)
  )
  local y = legend_top(font) - row * #lines
  gfx.setColor(Color[Color.black])
  for _, line in ipairs(lines) do
    gfx.print(line, x, y)
    y = y + row
  end
end

-- Dim overlay for macro recording

function draw_dim()
  local w, h = gfx.getDimensions()
  gfx.setColor(0, 0, 0, 0.5)
  gfx.rectangle("fill", 0, 0, w, h)
end

function draw_macro_name(x, y)
  local name = macro_state.name:lower()
  key_bg[name] = Color[Color.blue]
  draw_key(x, y, name)
end

function draw_macro_body(x, y)
  key_bg = { }
  local w = gfx.getDimensions()
  local start_x = x
  for _, k in ipairs(macro_state.body) do
    local lk = k:lower()
    if w < x + width[lk] then
      x = start_x
      y = y + height[lk] + SCALE
    end
    draw_key(x, y, lk)
    x = x + width[lk] + SCALE
  end
end

function draw_macro_ui()
  if Key.shift() then
    draw_dim()
  end
  if not macro_state.recording then
    return
  end
  local _, h = gfx.getDimensions()
  local name = macro_state.name:lower()
  local m = STD_H * SCALE
  local y = (h - height[name]) / 2
  draw_macro_name(m, y)
  draw_macro_body(m, y + height[name] + SCALE)
end

-- Box drawing

function box_draw_pos(b)
  local a = player.anim
  if not a or a.kind ~= "push"
       or a.box ~= b
  then
    return cell_top_left(b.col, b.row)
  end
  local dir = push_dir(a.move_cmd)
  local d = DIR_DELTA[dir]
  local x, y = cell_top_left(b.col, b.row)
  local f = push_box_offset(anim_progress())
  return x + (d.x * f), y + (d.y * f)
end

function draw_box_goals()
  gfx.setColor(Color[Color.cyan])
  for _, g in pairs(GS.box_goal_map) do
    local x, y = cell_top_left(g.col, g.row)
    gfx.rectangle("fill", x, y, GRID.cell, GRID.cell)
  end
end

function draw_boxes()
  for _, b in pairs(GS.box_map) do
    local x, y = box_draw_pos(b)
    local w, h = BOX.sprite_w, BOX.sprite_h
    local s = sprite_scale(w, h, BOX.cell_fill)
    gfx.push("all")
    gfx.translate(x, y)
    gfx.scale(s, s)
    box_sprite()
    gfx.pop()
  end
end

-- Plan-a-path strip: the typed plan as key tiles above a
-- faint backdrop, below the boxed-in field. Tiles use
-- the keyboard game's draw_key so they match the real
-- Compy keycaps, ten per row across two rows anchored at
-- the bottom edge.

function plan_strip_x()
  local w = gfx.getWidth()
  local row = PLAN_ROW_LEN * plan_tile_w()
  local gaps = (PLAN_ROW_LEN - 1) * plan_gap()
  return (w - (row + gaps)) / 2
end

function plan_zone_top()
  return gfx.getHeight() - plan_zone_h()
end

function plan_tile_pos(i)
  local col = (i - 1) % PLAN_ROW_LEN
  local row = math.floor((i - 1) / PLAN_ROW_LEN)
  local g = plan_gap()
  local x = plan_strip_x()
      + col * (plan_tile_w() + g)
  local y = plan_zone_top() + g
      + row * (plan_tile_h() + g)
  return x, y
end

-- Tile background by state: executed green, executing
-- bright green, crash bright red, pending a plain keycap.
-- Slightly translucent so the field shows through the
-- overlay; the crash tile stays near-opaque for salience.

function plan_crash_bg(i, at)
  if i < at then
    return Color.with_alpha(Color[Color.green], 0.85)
  elseif i == at then
    return Color.with_alpha(
      Color[Color.red + Color.bright], 0.95
    )
  end
end

function plan_tile_bg(i)
  local p = GS.plan
  if p.crash_at then
    return plan_crash_bg(i, p.crash_at)
  end
  if plan_won() or p.ran or i <= p.done then
    return Color.with_alpha(Color[Color.green], 0.85)
  end
  local exec = GS.running and i == p.exec
  if exec then
    return Color.with_alpha(
      Color[Color.green + Color.bright], 0.9
    )
  end
  return Color.with_alpha(Color[Color.black], 0.85)
end

-- Tiles after the crash never ran; dim them.

function plan_tile_dim(i)
  local at = GS.plan.crash_at
  return at and at < i
end

function draw_plan_tile(i)
  local x, y = plan_tile_pos(i)
  local name = GS.plan.buf[i]:lower()
  key_bg[name] = plan_tile_bg(i)
  draw_key(x, y, name)
  key_bg[name] = nil
  if plan_tile_dim(i) then
    gfx.setColor(0, 0, 0, 0.6)
    local tw, th = plan_tile_w(), plan_tile_h()
    gfx.rectangle("fill", x, y, tw, th)
  end
end

function draw_plan_backdrop()
  local w, h = gfx.getDimensions()
  local top = plan_zone_top()
  gfx.setColor(0, 0, 0, 0.22)
  gfx.rectangle("fill", 0, top, w, h - top)
end

-- The prompt sits in the compass column above the corner
-- HUD, wrapped to the column and centered, so a long
-- translation stacks into extra lines instead of leaking
-- over the field. It shows whenever input is open; it
-- hides during a run and the win pause.

function prompt_column()
  local font = gfx.getFont()
  local x = legend_left(font)
  local lim = gfx.getWidth() - x - font:getHeight()
  return x, lim
end

function tab_hint_showing()
  if not GS.win_macros then
    return false
  end
  local modal = GS.celebrating or GS.won or GS.failed
  return not modal
end

function hud_top()
  local top = hud_corner_top()
  if tab_hint_showing() then
    return tab_hint_top(top)
  end
  return top
end

function prompt_top(font, lim)
  local _, lines = font:getWrap(PLAN_PROMPT, lim)
  local th = #lines * font:getHeight()
  return (hud_top() - th) - font:getHeight() / 2
end

function draw_plan_prompt()
  if plan_locked() then
    return
  end
  local font = gfx.getFont()
  local x, lim = prompt_column()
  local y = prompt_top(font, lim)
  gfx.setColor(0, 0, 0, 0.6)
  gfx.printf(PLAN_PROMPT, x + 1, y + 1, lim, "center")
  gfx.setColor(1, 1, 1, 0.8)
  gfx.printf(PLAN_PROMPT, x, y, lim, "center")
end

-- draw_key leaves the keycap font active; restore the
-- HUD font once the tiles are done.

function draw_plan_strip()
  if cur_controls ~= plan then
    return
  end
  local font = gfx.getFont()
  draw_plan_backdrop()
  draw_plan_prompt()
  for i = 1, #(GS.plan.buf) do
    draw_plan_tile(i)
  end
  gfx.setFont(font)
end

-- On plan levels the bottom-corner HUD (legend and macro
-- list) lifts above the strip zone.

function hud_lift()
  if cur_controls == plan then
    return plan_zone_h() + 2 * SCALE
  end
  return 0
end

-- Top of the lifted corner HUD block (macros + legend),
-- as drawn by draw_hud_corner.

function hud_corner_top()
  local font = gfx.getFont()
  local macro_h = text_row(font) * #macro_lines(macro_letters())
  return legend_top(font) - macro_h - hud_lift()
end

function draw_tab_hint_corner()
  if not tab_hint_showing() then
    return
  end
  local label = tab_hint_label(level_index == #levels)
  draw_tab_hint(hud_corner_top(), label)
end

function draw_hud_corner()
  gfx.push()
  gfx.translate(0, -hud_lift())
  draw_legend()
  draw_macros_list()
  gfx.pop()
  draw_tab_hint_corner()
end

-- Win modal.

function draw_celebrate()
  if not (GS.celebrating or GS.won) then
    return
  end
  gfx.setColor(Color[Color.white + Color.bright])
  draw_keycap_banner(CELEBRATE_PREFIX, "tab",
    CELEBRATE_SUFFIX)
end

-- Failed-run modal (miss / crash): a calm "not yet",
-- never punitive. Hidden during a win so they never stack.

function draw_failed()
  if not GS.failed or GS.celebrating or GS.won then
    return
  end
  local prefix = FAILED_MISS_PREFIX
  if GS.failed == "crash" then
    prefix = FAILED_CRASH_PREFIX
  end
  gfx.setColor(Color[Color.white + Color.bright])
  draw_keycap_banner(prefix, "tab", FAILED_SUFFIX)
end

-- Level indicator: muted "Maze N" in a top corner.
-- Top-right keeps clear of the upper-left echo and the
-- bottom-right legend.

function draw_level_indicator()
  local font = gfx.getFont()
  local label = "Maze " .. level_index
  local m = font:getHeight() / 2
  local x = (gfx.getWidth() - font:getWidth(label)) - m
  gfx.setColor(1, 1, 1, 0.5)
  gfx.print(label, x, m)
end

-- Win and failed-run modals; the win one hides the other.

function draw_modals()
  draw_celebrate()
  draw_failed()
end

-- Draw everything on screen

function draw_scene()
  draw_walls()
  draw_cells()
  draw_grid()
  draw_box_goals()
  draw_goals()
  draw_traces()
  draw_boxes()
  draw_player(GRID.scale)
  draw_echo()
  draw_hud_corner()
  draw_level_indicator()
  draw_macro_ui()
  draw_plan_strip()
  draw_modals()
end
