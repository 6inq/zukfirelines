local Inspector = require("src/core/inspector")

local Panel = {}

local EVENT_ID = "zuk-fire-lines:content"
local LISTENER = "panel"
local parent, view

local function build(app)
  view:AddTitle("ZukFireLines")
  view:AddText("by 6ing")
  view:AddText({ text = app.status, height = 48 })
  if not app.store:get("inspector") then
    view:AddText({ text = "Turn on the Arena inspector in the settings to list what is around you during the fight.", height = 48 })
    return
  end
  view:AddTitle("Arena inspector")
  view:AddText({ text = "Moving things are listed first. Fire lines should move every tick. Enter their ids in the settings.", height = 48 })
  local rows = app.inspector:rows()
  if #rows == 0 then view:AddText("Nothing seen yet.") end
  for _, row in ipairs(rows) do view:AddText({ text = Inspector.describe(row), height = 24 }) end
  view:AddSimpleButton("Clear inspector", function() app:resetInspector() end)
end

local function render(app)
  if not parent then return end
  if view then pcall(function() return view:Destroy() end) end
  view = prettyui.SimpleView.new(parent, { width = parent.width, height = parent.height })
  local ok, err = pcall(build, app)
  if not ok and log then log("[zuk-fire-lines] panel failed: " .. tostring(err)) end
end

function Panel.start(app)
  Event.ContentLayerReady.Subscribe(EVENT_ID, function(event)
    parent = event.component
    app:onChange(LISTENER, function() render(app) end)
  end)
end

function Panel.stop(app)
  pcall(function() return Event.ContentLayerReady.Unsubscribe(EVENT_ID) end)
  if app then app:onChange(LISTENER, nil) end
  if view then pcall(function() return view:Destroy() end) end
  view, parent = nil, nil
end

return Panel
