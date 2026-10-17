-- Persistent settings. The db is injectable for tests.
local Store = {}
Store.__index = Store

Store.KEY = "zuk-fire-lines:settings"
Store.DEFAULT_COLOUR = 0xFF5A1E99 -- fiery orange, semi-transparent

local function isBool(v) return type(v) == "boolean" end
local function isColour(v) return type(v) == "number" and v == math.floor(v) and v >= 0 and v <= 0xFFFFFFFF end
local function isWidth(v) return v == 3 or v == 5 end
local function isText(v) return type(v) == "string" and #v <= 500 end

local SETTINGS = {
  enabled = { default = true, valid = isBool },
  width = { default = 3, valid = isWidth },
  colour = { default = Store.DEFAULT_COLOUR, valid = isColour },
  fireIDs = { default = "", valid = isText },
  inspector = { default = false, valid = isBool },
}

function Store.new(db)
  local self = setmetatable({ settings = {} }, Store)
  self.db = db or rawget(_G, "PersistentDB")
  local raw
  if self.db then
    local ok, value = pcall(self.db.GetStructuredData, self.db, Store.KEY)
    if ok then raw = value end
  end
  raw = type(raw) == "table" and raw or {}
  for name, spec in pairs(SETTINGS) do
    -- Not `valid and value or default`: that idiom turns a saved `false` back into the default.
    if spec.valid(raw[name]) then self.settings[name] = raw[name] else self.settings[name] = spec.default end
  end
  self.settings.colour = math.floor(self.settings.colour)
  return self
end

function Store:get(name)
  return self.settings[name]
end

function Store:set(name, value)
  local spec = SETTINGS[name]
  if not spec or not spec.valid(value) then return false end
  self.settings[name] = value
  if self.db then
    local ok, err = pcall(self.db.SetStructuredData, self.db, Store.KEY, self.settings)
    if not ok and log then log("[zuk-fire-lines] save failed: " .. tostring(err)) end
  end
  return true
end

return Store
