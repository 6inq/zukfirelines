-- Each server tick: scan nearby entities, feed the inspector, find the fire lines and draw them.
local Lines = require("src/core/lines")
local Inspector = require("src/core/inspector")
local Scanner = require("src/game/scanner")
local TileRenderer = require("src/game/tile_renderer")

local App = {}
App.__index = App

local EVENT_ID = "zuk-fire-lines:tick"
App.RANGE = 40 -- tiles around the player; covers the arena
App.STATUS = {
  NO_IDS = "No fire-line ids set yet. Turn on the Arena inspector during the fight to find them.",
  NO_WORLD = "This client cannot draw on the ground yet.",
  OFF = "Tile highlighting is off.",
}

---@param defaultIDs integer[] bundled fire-line config ids
function App.new(store, defaultIDs)
  local self = setmetatable({ store = store, defaultIDs = defaultIDs or {}, listeners = {}, status = "" }, App)
  self.lines, self.inspector = Lines.new(), Inspector.new()
  self.scanner, self.renderer = Scanner.new(), TileRenderer.new()
  self.tiles = {}
  return self
end

function App:onChange(key, fn)
  self.listeners[key] = fn
  if fn then pcall(fn, self) end
end

function App:_notify()
  for _, fn in pairs(self.listeners) do pcall(fn, self) end
end

function App:fireIDs()
  local ids = Lines.parseIDs(self.store:get("fireIDs"))
  for _, id in ipairs(self.defaultIDs) do ids[id] = true end
  return ids
end

local function playerTile()
  local ok, grid = pcall(function()
    if not Player.IsAvailable() then return nil end
    return Player.GetEntity().coordGrid
  end)
  if ok and grid then return { x = grid.x, z = grid.z, level = grid.level } end
  return nil
end

function App:_statusFor(ids, fireCount)
  if not self.store:get("enabled") then return App.STATUS.OFF end
  if next(ids) == nil then return App.STATUS.NO_IDS end
  if not TileRenderer.available() then return App.STATUS.NO_WORLD end
  if fireCount == 0 then return "Watching for fire lines." end
  return fireCount == 1 and "Highlighting 1 fire line." or ("Highlighting " .. fireCount .. " fire lines.")
end

-- Find the fire among `entities`, update the rows and draw them.
function App:_process(entities)
  local ids = self:fireIDs()
  local fire = Scanner.filterIDs(entities, ids)
  self.tiles = self.lines:update(fire, self.store:get("width"))
  if self.store:get("enabled") and TileRenderer.available() then
    local ok, err = pcall(self.renderer.render, self.renderer, self.tiles, self.store:get("colour"))
    if not ok and log then log("[zuk-fire-lines] draw failed: " .. tostring(err)) end
  else
    self.renderer:clear()
  end
  return self:_statusFor(ids, #fire)
end

function App:tick()
  local origin = playerTile()
  local entities = origin and self.scanner:near(origin, App.RANGE) or {}
  self.lastEntities = entities
  local inspecting = self.store:get("inspector")
  if inspecting then self.inspector:observe(entities) end
  local status = self:_process(entities)
  self.ticks = (self.ticks or 0) + 1
  -- The inspector list refreshes every 5 ticks (3s) rather than rebuilding the panel every tick.
  if status ~= self.status or (inspecting and self.ticks % 5 == 0) then
    self.status = status
    self:_notify()
  end
end

-- Settings changed: redraw from the last tick's entities straight away. (NPCs are only
-- collected as the client draws them, so rescanning here would briefly find nothing.)
function App:settingsChanged()
  self.renderer.signature = nil
  self.status = self:_process(self.lastEntities or {})
  self:_notify()
end

function App:resetInspector()
  self.inspector:reset()
  self:_notify()
end

function App:start()
  self.scanner:start()
  Event.ServerLogic.Subscribe(EVENT_ID, function() self:tick() end)
end

function App:stop()
  pcall(Event.ServerLogic.Unsubscribe, EVENT_ID)
  self.scanner:stop()
  self.renderer:clear()
  self.listeners = {}
end

return App
