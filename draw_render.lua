-- draw_render.lua

-- Draw's free canvas plus the picture-task target panel,
-- optional field hint and completion message.

function draw_canvas_grid()
  local left, top = GRID.offset_x, GRID.offset_y
  local right = left + GRID.cols * GRID.cell
  local bottom = top + GRID.rows * GRID.cell
  gfx.setColor(GRID_LINE.color)
  gfx.setLineWidth(GRID_LINE.width)
  for col = 0, GRID.cols do
    local x = left + col * GRID.cell
    gfx.line(x, top, x, bottom)
  end
  for row = 0, GRID.rows do
    local y = top + row * GRID.cell
    gfx.line(left, y, right, y)
  end
end

function draw_canvas_bg()
  local w, h = gfx.getDimensions()
  gfx.setColor(CANVAS_BG)
  gfx.rectangle("fill", 0, 0, w, h)
end

function setHintColor()
  local color = Color[Color.cyan]
  gfx.setColor(color[1], color[2], color[3], HINT_ALPHA)
end

function drawHintEdge(edge)
  local x1, y1 = cell_center(edge.c1, edge.r1)
  local x2, y2 = cell_center(edge.c2, edge.r2)
  local radius = GRID.trace_r * HINT_WIDTH_FRAC
  gfx.line(x1, y1, x2, y2)
  gfx.circle("fill", x1, y1, radius)
  gfx.circle("fill", x2, y2, radius)
end

function drawFieldHint()
  local level = currentDrawLevel()
  if not level or not GS.hint then
    return
  end
  setHintColor()
  gfx.setLineWidth(GRID.trace_r * 2 * HINT_WIDTH_FRAC)
  for _, edge in ipairs(level.edge_list) do
    drawHintEdge(edge)
  end
end

function legendBlockTop()
  return legend_top(gfx.getFont())
end

function previewGeometry()
  local font_h = gfx.getFont():getHeight()
  local panel_w = picturePanelWidth()
  local panel_left = gfx.getWidth() - panel_w
  local zone_top = font_h * 3
  local zone_h = legendBlockTop() - font_h - zone_top
  local avail_w = panel_w - 2 * font_h
  local cell = math.min(
    avail_w / CANVAS.cols,
    zone_h / CANVAS.rows
  )
  local left = panel_left
      + (panel_w - CANVAS.cols * cell) / 2
  local top = zone_top
      + (zone_h - CANVAS.rows * cell) / 2
  return { left = left, top = top, cell = cell }
end

function previewPoint(point, geo)
  local x = geo.left + (point.col - 0.5) * geo.cell
  local y = geo.top + (point.row - 0.5) * geo.cell
  return x, y
end

function drawPreviewGrid(geo)
  local right = geo.left + CANVAS.cols * geo.cell
  local bottom = geo.top + CANVAS.rows * geo.cell
  gfx.setColor(GRID_LINE.color)
  gfx.setLineWidth(GRID_LINE.width)
  for col = 0, CANVAS.cols do
    local x = geo.left + col * geo.cell
    gfx.line(x, geo.top, x, bottom)
  end
  for row = 0, CANVAS.rows do
    local y = geo.top + row * geo.cell
    gfx.line(geo.left, y, right, y)
  end
end

function drawPreviewEdge(edge, geo)
  local p1 = { col = edge.c1, row = edge.r1 }
  local p2 = { col = edge.c2, row = edge.r2 }
  local x1, y1 = previewPoint(p1, geo)
  local x2, y2 = previewPoint(p2, geo)
  gfx.line(x1, y1, x2, y2)
end

function drawPreviewRoute(level, geo)
  gfx.setColor(Color[Color.cyan])
  local width = math.max(2, geo.cell * PREVIEW_LINE_FRAC)
  gfx.setLineWidth(width)
  for _, edge in ipairs(level.edge_list) do
    drawPreviewEdge(edge, geo)
  end
end

function drawPreviewStart(level, geo)
  local point = { col = level.col, row = level.row }
  local x, y = previewPoint(point, geo)
  gfx.setColor(Color[Color.green + Color.bright])
  gfx.circle("fill", x, y, math.max(3, geo.cell * 0.16))
end

function drawTargetTitle(level)
  local font = gfx.getFont()
  local panel_w = picturePanelWidth()
  local x = gfx.getWidth() - panel_w
  local number = GS.level_index .. "/" .. #DRAW_LEVELS
  local label = "Picture " .. number
  gfx.setColor(Color[Color.black])
  local y = font:getHeight() * 0.4
  gfx.printf(label, x, y, panel_w, "center")
  gfx.printf(level.name, x, font:getHeight() * 1.4,
    panel_w, "center")
end

function drawTargetPanel()
  local level = currentDrawLevel()
  if not level then
    return
  end
  local geo = previewGeometry()
  drawTargetTitle(level)
  drawPreviewGrid(geo)
  drawPreviewRoute(level, geo)
  drawPreviewStart(level, geo)
end

function drawTaskComplete()
  if not GS.won then
    return
  end
  local w, h = gfx.getDimensions()
  local font = gfx.getFont()
  local y = (h - font:getHeight()) / 2
  local color = Color[Color.black]
  gfx.setColor(color[1], color[2], color[3], 0.55)
  gfx.rectangle("fill", 0, y - font:getHeight(),
    w, font:getHeight() * 3)
  gfx.setColor(Color[Color.white + Color.bright])
  local suffix = DRAW_COMPLETE_NEXT_SUFFIX
  if GS.level_index == #DRAW_LEVELS then
    suffix = DRAW_COMPLETE_FINAL_SUFFIX
  end
  draw_keycap_banner(DRAW_COMPLETE_PREFIX, "tab", suffix)
end

function draw_scene()
  draw_canvas_bg()
  draw_canvas_grid()
  drawFieldHint()
  draw_traces()
  draw_player(GRID.scale)
  draw_echo()
  drawTargetPanel()
  draw_legend()
  drawTaskComplete()
end
