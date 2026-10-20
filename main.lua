local Store = require("src/core/store")
local App = require("src/app")
local Panel = require("src/ui/panel")
local Settings = require("src/ui/settings")

local store = Store.new()
local app = App.new(store, require("src/data/fire_ids"))
local stopped = false

function PluginShutdown()
  if stopped then return end
  stopped = true
  Panel.stop(app)
  Settings.stop()
  app:stop()
end

app:start()
Panel.start(app)
Settings.start(store, app)

log("[zuk-fire-lines] loaded")
