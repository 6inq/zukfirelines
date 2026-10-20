local Lines = {}
Lines.__index = Lines

Lines.WIDTHS = { 3, 5 }

local function axisStep(dx, dz)
  if dx == 0 and dz == 0 then return nil end
  if math.abs(dx) >= math.abs(dz) then return { dx = dx > 0 and 1 or -1, dz = 0 } end
  return { dx = 0, dz = dz > 0 and 1 or -1 }
end

function Lines.row(centre, direction, width)
  if not direction then return { { x = centre.x, z = centre.z } } end
  local px, pz = direction.dz, direction.dx
  local half = (width - 1) // 2
  local tiles = {}
  for offset = -half, half do
    tiles[#tiles + 1] = { x = centre.x + px * offset, z = centre.z + pz * offset }
  end
  return tiles
end

function Lines.new()
  return setmetatable({ previous = {}, directions = {} }, Lines)
end

function Lines:update(entities, width)
  local seen, tiles, unique = {}, {}, {}
  for _, entity in ipairs(entities or {}) do
    local last = self.previous[entity.uid]
    local moved = last and axisStep(entity.x - last.x, entity.z - last.z)
    if moved then self.directions[entity.uid] = moved end
    seen[entity.uid] = { x = entity.x, z = entity.z }
    for _, tile in ipairs(Lines.row(entity, self.directions[entity.uid], width)) do
      local key = tile.x .. ":" .. tile.z
      if not unique[key] then
        unique[key] = true
        tiles[#tiles + 1] = { x = tile.x, z = tile.z, level = entity.level or 0 }
      end
    end
  end
  for uid in pairs(self.directions) do
    if not seen[uid] then self.directions[uid] = nil end
  end
  self.previous = seen
  table.sort(tiles, function(a, b) return a.x == b.x and a.z < b.z or a.x < b.x end)
  return tiles
end

function Lines.parseIDs(text)
  local ids = {}
  for number in tostring(text or ""):gmatch("%d+") do ids[tonumber(number)] = true end
  return ids
end

return Lines
