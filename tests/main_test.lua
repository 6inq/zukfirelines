-- Boots main.lua with a stubbed client: fire NPCs sweep across, tiles follow and vanish.
local A = require("assert")
local Store = require("src/core/store")
local App = require("src/app")

local T = {}

local function memoryDb()
  local db = { data = {} }
  function db:GetStructuredData(key) return self.data[key] end
  function db:SetStructuredData(key, value) self.data[key] = value end
  return db
end

local function boot(opts)
  opts = opts or {}
  local env = { events = {}, shapes = {}, settings = {}, panels = {}, npcs = {}, locs = opts.locs or {} }
  local function bus(name)
    return { Subscribe = function(k, f) env.events[name .. ":" .. k] = f end,
      Unsubscribe = function(k) env.events[name .. ":" .. k] = nil end }
  end
  _G.Event = { ServerLogic = bus("Tick"), EntityDraw = bus("Draw"), ContentLayerReady = bus("Content"), SettingsLayerReady = bus("Settings") }
  _G.EntityType = { NPC = 1, PLAYER = 2 }
  _G.ui = { SelectionChangeEvent = { SELECTED = 1 } }
  _G.log = function() end
  _G.Player = { IsAvailable = function() return true end,
    GetEntity = function() return { coordGrid = { x = 100, z = 100, level = 0 } } end }
  _G.LocList = { Filter = function(filter)
    local out = {}
    for _, loc in ipairs(env.locs) do if filter.func(loc) then out[#out + 1] = loc end end
    return out
  end }
  _G.ShapeList, _G.ShapeData, _G.World, _G.Vector3, _G.CoordGrid = nil, nil, nil, nil, nil
  if opts.world ~= false then
    _G.Vector3 = { new = function(x, y, z) return { x = x, y = y, z = z } end }
    _G.ShapeData = { new = function() return {} end }
    _G.World = { GetGroundHeight = function() return 0, true end }
    _G.CoordGrid = { new = function(level, mx, mz, lx, lz)
      local x, z = mx * 64 + lx, mz * 64 + lz
      return { ToCoordFine = function() return { position = { x = x * 512 + 256, z = z * 512 + 256 } } end }
    end }
    _G.ShapeList = { CreateInstance = function(name)
      local shape = { name = name, destroyed = false }
      function shape:SetShapeData(data) self.data = data; return true end
      function shape:Destroy() self.destroyed = true end
      env.shapes[#env.shapes + 1] = shape
      return shape
    end }
  end
  _G.PersistentDB = memoryDb()
  if opts.settings then PersistentDB:SetStructuredData(Store.KEY, opts.settings) end
  _G.prettyui = { SimpleView = { new = function(parent)
    local list = parent.kind == "settings" and env.settings or env.panels
    local calls = {}; list[#list + 1] = calls
    return setmetatable({}, { __index = function(_, method)
      if method == "Destroy" then return function() end end
      return function(_, ...)
        local call = { method = method, args = { ... } }
        if method == "AddText" or method == "AddTitle" then call.content = type(call.args[1]) == "table" and call.args[1].text or call.args[1] end
        calls[#calls + 1] = call
        return call
      end
    end })
  end } }
  for key in pairs(package.loaded) do if key:match("^src/") then package.loaded[key] = nil end end
  dofile("main.lua")
  return env
end

-- Draw every NPC in env.npcs (as the client does each frame), then run a server tick.
local function tick(env)
  for _, npc in ipairs(env.npcs) do
    env.events["Draw:zuk-fire-lines:entities"]({ entityType = EntityType.NPC, npcEntity = {
      isValid = true, uid = npc.uid, displayName = npc.name, config = { id = npc.id },
      coordGrid = { x = npc.x, z = npc.z, level = 0 } } })
  end
  env.events["Tick:zuk-fire-lines:tick"]()
end

local function live(env) for _, s in ipairs(env.shapes) do if not s.destroyed then return s end end end
local function tileCount(shape) return #shape.data.positions / 8 end

local function texts(calls)
  local out = {}
  for _, c in ipairs(calls or {}) do if c.content then out[#out + 1] = c.content end end
  return table.concat(out, "\n")
end

function T.without_ids_it_explains_how_to_find_them()
  local env = boot()
  env.events["Content:zuk-fire-lines:content"]({ component = { kind = "content" } })
  tick(env)
  A.truthy(texts(env.panels[#env.panels]):find("Arena inspector", 1, true))
  A.eq(live(env), nil)
  PluginShutdown()
end

function T.fire_line_sweeping_east_is_highlighted_and_follows()
  local env = boot({ settings = { fireIDs = "900" } })
  env.npcs = { { uid = 1, id = 900, name = "Fire", x = 90, z = 100 }, { uid = 2, id = 5, name = "TzKal-Zuk", x = 100, z = 110 } }
  tick(env)
  A.eq(tileCount(live(env)), 1, "first sighting: just the fire's tile")
  for step = 1, 4 do
    env.npcs[1].x = 90 + step
    tick(env)
    local shape = live(env)
    A.eq(tileCount(shape), 3, "3-wide row")
    A.eq(shape.translation.x, (90 + step) * 512 + 256, "row moves with the fire")
  end
  local shape = live(env)
  A.eq(shape.data.rgba[1], Store.DEFAULT_COLOUR, "fill colour"); A.eq(#shape.data.tris, 18); A.eq(#shape.data.lines, 24)
  env.npcs = { env.npcs[2] }
  tick(env)
  A.eq(live(env), nil, "tiles gone when the fire leaves")
  PluginShutdown()
end

function T.five_wide_and_custom_colour_from_settings()
  local env = boot({ settings = { fireIDs = "900" } })
  env.npcs = { { uid = 1, id = 900, x = 90, z = 100 } }
  tick(env); env.npcs[1].z = 101; tick(env)
  env.events["Settings:zuk-fire-lines:settings"]({ component = { kind = "settings" } })
  local calls = env.settings[1]
  for _, c in ipairs(calls) do
    if c.method == "AddComboBox" then c.args[1].onChange(nil, 5, "5 tiles", 1) end
    if c.method == "AddColourPicker" then c.args[1].onChange(nil, 0x00FF0080) end
  end
  local shape = live(env)
  A.eq(tileCount(shape), 5); A.eq(shape.data.rgba[1], 0x00FF0080)
  A.eq(shape.data.rgba[5], 0x00FF00FF, "outline is the same hue, opaque")
  A.eq(Store.new(PersistentDB):get("width"), 5)
  PluginShutdown()
end

function T.ids_entered_in_settings_take_effect()
  local env = boot()
  env.npcs = { { uid = 1, id = 900, x = 90, z = 100 } }
  tick(env)
  A.eq(live(env), nil)
  env.events["Settings:zuk-fire-lines:settings"]({ component = { kind = "settings" } })
  for _, c in ipairs(env.settings[1]) do
    if c.method == "AddTextField" then c.args[1].onChange(nil, nil, "900") end
  end
  A.truthy(live(env), "highlighted after typing the id")
  PluginShutdown()
end

function T.scenery_fire_also_works()
  local env = boot({ settings = { fireIDs = "4321" }, locs = { { configID = 4321, coordGrid = { x = 95, z = 100, level = 0 } } } })
  tick(env)
  A.truthy(live(env), "fire made of scenery objects is found too")
  PluginShutdown()
end

function T.inspector_lists_moving_npcs_first()
  local env = boot({ settings = { inspector = true }, locs = { { configID = 77, displayName = "Lava", coordGrid = { x = 101, z = 101, level = 0 } } } })
  env.events["Content:zuk-fire-lines:content"]({ component = { kind = "content" } })
  env.npcs = { { uid = 1, id = 900, name = "Wall of flame", x = 90, z = 100 } }
  for step = 1, 5 do env.npcs[1].x = 90 + step; tick(env) end
  local all = texts(env.panels[#env.panels])
  local fire, lava = all:find("NPC 900  Wall of flame", 1, true), all:find("Scenery 77  Lava", 1, true)
  A.truthy(fire and lava and fire < lava, "moving fire listed above static scenery")
  PluginShutdown()
end

function T.far_away_entities_ignored()
  local env = boot({ settings = { fireIDs = "900" } })
  env.npcs = { { uid = 1, id = 900, x = 100 + App.RANGE + 5, z = 100 } }
  tick(env)
  A.eq(live(env), nil)
  PluginShutdown()
end

function T.turned_off_draws_nothing()
  local env = boot({ settings = { fireIDs = "900", enabled = false } })
  env.npcs = { { uid = 1, id = 900, x = 90, z = 100 } }
  tick(env)
  A.eq(live(env), nil)
  A.eq(Store.new(PersistentDB):get("enabled"), false, "off stays off")
  PluginShutdown()
end

function T.no_world_drawing_is_reported()
  local env = boot({ world = false, settings = { fireIDs = "900" } })
  env.events["Content:zuk-fire-lines:content"]({ component = { kind = "content" } })
  tick(env)
  A.truthy(texts(env.panels[#env.panels]):find("cannot draw", 1, true))
  PluginShutdown()
end

function T.entity_draw_always_lets_npcs_draw()
  local env = boot()
  local result = env.events["Draw:zuk-fire-lines:entities"]({ entityType = EntityType.NPC, npcEntity = { isValid = false } })
  A.eq(result, true)
  A.eq(env.events["Draw:zuk-fire-lines:entities"]({ entityType = EntityType.PLAYER }), true)
  PluginShutdown()
end

function T.shutdown_cleans_up()
  local env = boot({ settings = { fireIDs = "900" } })
  env.npcs = { { uid = 1, id = 900, x = 90, z = 100 } }
  tick(env)
  local shape = live(env)
  PluginShutdown(); PluginShutdown()
  A.eq(next(env.events), nil); A.eq(shape.destroyed, true)
end

return T
