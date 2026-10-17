local A = require("assert")
local Store = require("src/core/store")

local T = {}

local function memoryDb()
  local db = { data = {} }
  function db:GetStructuredData(key) return self.data[key] end
  function db:SetStructuredData(key, value) self.data[key] = value end
  return db
end

function T.defaults()
  local s = Store.new(memoryDb())
  A.eq(s:get("enabled"), true); A.eq(s:get("width"), 3); A.eq(s:get("colour"), Store.DEFAULT_COLOUR)
  A.eq(s:get("fireIDs"), ""); A.eq(s:get("inspector"), false)
end

function T.only_three_or_five_wide()
  local s = Store.new(memoryDb())
  A.eq(s:set("width", 5), true); A.eq(s:set("width", 4), false); A.eq(s:set("width", 1), false); A.eq(s:get("width"), 5)
end

function T.everything_persists_including_off()
  local db = memoryDb()
  local s = Store.new(db)
  s:set("enabled", false); s:set("width", 5); s:set("colour", 0x123456AB); s:set("fireIDs", "1, 2"); s:set("inspector", true)
  local r = Store.new(db)
  A.eq(r:get("enabled"), false); A.eq(r:get("width"), 5); A.eq(r:get("colour"), 0x123456AB)
  A.eq(r:get("fireIDs"), "1, 2"); A.eq(r:get("inspector"), true)
end

function T.invalid_stored_values_fall_back()
  local db = memoryDb()
  db.data[Store.KEY] = { enabled = "yes", width = 7, colour = -1, fireIDs = 5, inspector = "no" }
  local s = Store.new(db)
  A.eq(s:get("enabled"), true); A.eq(s:get("width"), 3); A.eq(s:get("colour"), Store.DEFAULT_COLOUR)
  A.eq(s:get("fireIDs"), ""); A.eq(s:get("inspector"), false)
end

function T.throwing_db_tolerated()
  local db = {}
  function db:GetStructuredData() error("boom") end
  function db:SetStructuredData() error("boom") end
  A.eq(Store.new(db):set("width", 5), true)
end

return T
