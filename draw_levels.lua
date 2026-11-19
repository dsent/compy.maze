-- draw_levels.lua

-- Ordered picture tasks, sorted by the fewest commands that
-- draw each picture (ties by characters), with Square before
-- T because going back over a line is harder. Each route is
-- that shortest plain program, starting at the declared cell
-- and using drawing moves only, so every picture is one
-- continuous trail with the pen down. Repeated edges are
-- part of the route where a branched picture has to come
-- back over itself.

DRAW_LEVELS = {
  {
    name = "Line",
    col = 2,
    row = 5,
    route = "5E",
    hint = true
  },
  {
    name = "Corner",
    col = 2,
    row = 2,
    route = "4S4E",
    hint = true
  },
  {
    name = "Bowl",
    col = 2,
    row = 3,
    route = "3S5E3N",
    hint = true
  },
  {
    name = "Square",
    col = 2,
    row = 2,
    route = "4E4S4W4N",
    hint = false
  },
  {
    name = "T",
    col = 6,
    row = 2,
    route = "4W2E5S",
    hint = true
  },
  {
    name = "Flag",
    col = 2,
    row = 8,
    route = "6N3E2S3W",
    hint = false
  },
  {
    name = "Plus",
    col = 4,
    row = 6,
    route = "4N2S2E4W",
    hint = false
  },
  {
    name = "Boot",
    col = 3,
    row = 2,
    route = "2E4S2E2S4W6N",
    hint = false
  },
  {
    name = "Steps",
    col = 2,
    row = 7,
    route = "NENENENE",
    hint = true
  },
  {
    name = "Mug",
    col = 2,
    row = 3,
    route = "3E3SE2NW3S3W4N",
    hint = false
  },
  {
    name = "Key",
    col = 3,
    row = 4,
    route = "N2W2S2EN3ESN2E2S",
    hint = false
  },
  {
    name = "Car",
    col = 6,
    row = 7,
    route = "SEN6W2N2E2N3E2S2E2S5WSWN",
    hint = false
  },
  {
    name = "Mountain",
    col = 1,
    row = 6,
    route = "NENENENESESESES7W",
    hint = true
  },
  {
    name = "Arrow",
    col = 1,
    row = 4,
    route = "S4E2SENENENWNWNW2S4W",
    hint = true
  },
  {
    name = "House",
    col = 4,
    row = 8,
    route = "2NE2S2E4NWNWNWSWSW4S3E",
    hint = true
  },
  {
    name = "Dog",
    col = 1,
    row = 4,
    route = "S4E2N2ESESW3SWN3WSW3N4E2N",
    hint = true
  },
  {
    name = "Boat",
    col = 3,
    row = 5,
    route = "4ENWNWNWNW5S5ESWS5WNWN2E",
    hint = false
  },
  {
    name = "Castle",
    col = 4,
    row = 8,
    route = "2NE2S3E6NWSWNWSWNWSWNW6S4E",
    hint = false
  },
  {
    name = "Heart",
    col = 4,
    row = 3,
    route = "EN2ESE2SWSWSWSWNWNWNW2NEN2ES",
    hint = true
  },
  {
    name = "Cat",
    col = 1,
    row = 4,
    route = "E2SES3ENENEWNEW2NWSWSWNWNW3SW",
    hint = true
  }
}

TARGET_DELTA = {
  N = { col = 0, row = -1 },
  S = { col = 0, row = 1 },
  E = { col = 1, row = 0 },
  W = { col = -1, row = 0 }
}

function targetEdgeKey(c1, r1, c2, r2)
  local a = c1 .. ":" .. r1
  local b = c2 .. ":" .. r2
  if b < a then
    a, b = b, a
  end
  return a .. "-" .. b
end

function addTargetStep(level, col, row, dir)
  local d = TARGET_DELTA[dir]
  local nc = col + d.col
  local nr = row + d.row
  local key = targetEdgeKey(col, row, nc, nr)
  if not level.edges[key] then
    table.insert(level.edge_list, {
      c1 = col,
      r1 = row,
      c2 = nc,
      r2 = nr
    })
  end
  level.edges[key] = true
  table.insert(level.points, { col = nc, row = nr })
  return nc, nr
end

function expandTargetRoute(level)
  local col, row = level.col, level.row
  local parsed = ""
  level.points = { { col = col, row = row } }
  level.edges = { }
  level.edge_list = { }
  for count, dir in level.route:gmatch("(%d*)([NSEW])") do
    local steps = tonumber(count) or 1
    parsed = parsed .. count .. dir
    for _ = 1, steps do
      col, row = addTargetStep(level, col, row, dir)
    end
  end
  level.dir = level.route:match("[NSEW]") or "N"
  level.route_valid = parsed == level.route
end

function measureTargetBounds(level)
  local first = level.points[1]
  level.min_col = first.col
  level.max_col = first.col
  level.min_row = first.row
  level.max_row = first.row
  for _, point in ipairs(level.points) do
    level.min_col = math.min(level.min_col, point.col)
    level.max_col = math.max(level.max_col, point.col)
    level.min_row = math.min(level.min_row, point.row)
    level.max_row = math.max(level.max_row, point.row)
  end
end

function prepareDrawLevels()
  for _, level in ipairs(DRAW_LEVELS) do
    expandTargetRoute(level)
    measureTargetBounds(level)
  end
end

function targetPointInBounds(point)
  local col_ok = 1 <= point.col and point.col <= 8
  local row_ok = 1 <= point.row and point.row <= 8
  return col_ok and row_ok
end

function drawLevelIsValid(level)
  if not level.route_valid or type(level.hint) ~= "boolean" then
    return false
  end
  if #level.edge_list == 0 then
    return false
  end
  for _, point in ipairs(level.points) do
    if not targetPointInBounds(point) then
      return false
    end
  end
  return true
end

function traceEdgeSet(traces)
  local edges = { }
  for _, trace in ipairs(traces) do
    local key = targetEdgeKey(
      trace.c1, trace.r1, trace.c2, trace.r2
    )
    edges[key] = true
  end
  return edges
end

function edgeSetsEqual(a, b)
  for key in pairs(a) do
    if not b[key] then
      return false
    end
  end
  for key in pairs(b) do
    if not a[key] then
      return false
    end
  end
  return true
end

function tracesMatchTarget(traces, level)
  return edgeSetsEqual(traceEdgeSet(traces), level.edges)
end

function clampDrawLevelIndex(index)
  return math.max(1, math.min(#DRAW_LEVELS, index))
end
