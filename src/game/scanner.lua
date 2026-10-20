local Scanner = {}
Scanner.__index = Scanner

local EVENT_ID = "zuk-fire-lines:entities"

function Scanner.new()
  return setmetatable({ npcs = {}, frameNPCs = {} }, Scanner)
end

function Scanner:_onEntity(event)
  pcall(function()
    if event.entityType ~= EntityType.NPC then return end
    local npc = event.npcEntity
    if not npc or not npc.isValid then return end
    local grid = npc.coordGrid
    self.frameNPCs[npc.uid] = {
      uid = "npc:" .. tostring(npc.uid), kind = "NPC", id = npc.config and npc.config.id,
      name = npc.displayName, x = grid.x, z = grid.z, level = grid.level,
    }
  end)
  return true
end

function Scanner:start()
  Event.EntityDraw.Subscribe(EVENT_ID, function(event) return self:_onEntity(event) end)
end

function Scanner:stop()
  pcall(function() return Event.EntityDraw.Unsubscribe(EVENT_ID) end)
end

function Scanner:collectNPCs()
  self.npcs, self.frameNPCs = self.frameNPCs, {}
  local list = {}
  for _, npc in pairs(self.npcs) do list[#list + 1] = npc end
  return list
end

local function near(a, b, range)
  return math.max(math.abs(a.x - b.x), math.abs(a.z - b.z)) <= range
end

function Scanner.locsNear(origin, range)
  local ok, locs = pcall(function() return LocList.Filter({ func = function(loc)
    local grid = loc.coordGrid
    return grid ~= nil and not loc.isHidden and near(grid, origin, range)
  end }) end)
  local list = {}
  if not ok or type(locs) ~= "table" then return list end
  for _, loc in ipairs(locs) do
    local grid = loc.coordGrid
    list[#list + 1] = {
      uid = "loc:" .. tostring(loc.configID) .. "@" .. grid.x .. "," .. grid.z, kind = "Scenery",
      id = loc.configID, name = loc.displayName or (loc.config and loc.config.name), x = grid.x, z = grid.z, level = grid.level,
    }
  end
  return list
end

function Scanner:near(origin, range)
  local list = {}
  for _, npc in ipairs(self:collectNPCs()) do
    if near(npc, origin, range) then list[#list + 1] = npc end
  end
  for _, loc in ipairs(Scanner.locsNear(origin, range)) do list[#list + 1] = loc end
  return list
end

function Scanner.filterIDs(entities, ids)
  local list = {}
  for _, entity in ipairs(entities) do
    if entity.id and ids[entity.id] then list[#list + 1] = entity end
  end
  return list
end

return Scanner
