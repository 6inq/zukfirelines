-- Settings panel: on/off, row width (3 or 5), tile colour, fire-line ids, inspector.
local Settings = {}

local EVENT_ID = "zuk-fire-lines:settings"
local view

local function mount(parent, store, app)
  Settings.destroy()
  view = prettyui.SimpleView.new(parent, { width = parent.width, height = parent.height })
  view:AddTitle("ZukFireLines")
  view:AddCheckboxButton({
    { text = "Highlight fire lines", value = "enabled", selected = store:get("enabled") },
  }, { onChange = function(_, _, changed, selected) store:set(changed, selected); app:settingsChanged() end })

  view:AddText("Tiles across each line")
  view:AddComboBox({
    entries = { { label = "3 tiles", id = 3 }, { label = "5 tiles", id = 5 } },
    selectedID = store:get("width"),
    onChange = function(_, entryID, _, eventType)
      if eventType ~= nil and eventType ~= ui.SelectionChangeEvent.SELECTED then return end
      if store:set("width", entryID) then app:settingsChanged() end
    end,
  })

  view:AddText("Tile colour")
  view:AddColourPicker({
    value = store:get("colour"), alphaSlider = true,
    onChange = function(_, colour) store:set("colour", colour); app:settingsChanged() end,
  })

  view:AddTitle("Fire-line ids")
  view:AddText({ text = "Config ids of the fire-line entities, separated by commas. Find them with the Arena inspector.", height = 48 })
  view:AddTextField({
    placeholder = "e.g. 28520, 28521", text = store:get("fireIDs"),
    onChange = function(_, _, text) if store:set("fireIDs", text or "") then app:settingsChanged() end end,
  })

  view:AddTitle("Arena inspector")
  view:AddCheckboxButton({
    { text = "List nearby NPCs and scenery in the panel", value = "inspector", selected = store:get("inspector") },
  }, { onChange = function(_, _, changed, selected) store:set(changed, selected); app:settingsChanged() end })
end

function Settings.start(store, app)
  Event.SettingsLayerReady.Subscribe(EVENT_ID, function(event)
    local ok, err = pcall(mount, event.component, store, app)
    if not ok and log then log("[zuk-fire-lines] settings failed: " .. tostring(err)) end
  end)
end

function Settings.destroy()
  if view then pcall(function() return view:Destroy() end) end
  view = nil
end

function Settings.stop()
  pcall(function() return Event.SettingsLayerReady.Unsubscribe(EVENT_ID) end)
  Settings.destroy()
end

return Settings
