-- Arena inspector: summarises what is near the player so the fire-line ids can be found
-- in game. Entities that move between ticks are the likely fire lines. Pure.
local Inspector = {}
Inspector.__index = Inspector

Inspector.MAX_ROWS = 15

function Inspector.new()
  return setmetatable({ types = {}, positions = {} }, Inspector)
end

function Inspector:reset()
  self.types, self.positions = {}, {}
end

---@param entities table[] { uid, kind, id, name, x, z }
function Inspector:observe(entities)
  for _, e in ipairs(entities) do
    local key = e.kind .. ":" .. tostring(e.id)
    local row = self.types[key]
    if not row then
      row = { kind = e.kind, id = e.id, name = e.name or "?", seen = 0, moves = 0 }
      self.types[key] = row
    end
    row.seen = row.seen + 1
    local last = self.positions[e.uid]
    if last and (last.x ~= e.x or last.z ~= e.z) then row.moves = row.moves + 1 end
    self.positions[e.uid] = { x = e.x, z = e.z }
  end
end

-- Moving types first (most moves first), then by how often they were seen.
function Inspector:rows()
  local list = {}
  for _, row in pairs(self.types) do list[#list + 1] = row end
  table.sort(list, function(a, b)
    if a.moves ~= b.moves then return a.moves > b.moves end
    if a.seen ~= b.seen then return a.seen > b.seen end
    return tostring(a.id) < tostring(b.id)
  end)
  for index = #list, Inspector.MAX_ROWS + 1, -1 do list[index] = nil end
  return list
end

function Inspector.describe(row)
  return string.format("%s %s  %s  (moved %d, seen %d)", row.kind, tostring(row.id), row.name, row.moves, row.seen)
end

return Inspector
