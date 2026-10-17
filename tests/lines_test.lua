local A = require("assert")
local Lines = require("src/core/lines")
local Inspector = require("src/core/inspector")

local T = {}

local function keys(tiles)
  local list = {}
  for index, t in ipairs(tiles) do list[index] = t.x .. "," .. t.z end
  return table.concat(list, " ")
end

local function fire(uid, x, z) return { uid = uid, x = x, z = z, level = 0 } end

function T.first_sighting_is_a_single_tile()
  local lines = Lines.new()
  A.eq(keys(lines:update({ fire("a", 10, 20) }, 3)), "10,20", "no direction yet, no guessing")
end

function T.moving_east_gives_a_north_south_row()
  local lines = Lines.new()
  lines:update({ fire("a", 10, 20) }, 3)
  A.eq(keys(lines:update({ fire("a", 11, 20) }, 3)), "11,19 11,20 11,21")
end

function T.moving_north_gives_an_east_west_row()
  local lines = Lines.new()
  lines:update({ fire("a", 10, 20) }, 3)
  A.eq(keys(lines:update({ fire("a", 10, 21) }, 3)), "9,21 10,21 11,21")
end

function T.width_five()
  local lines = Lines.new()
  lines:update({ fire("a", 10, 20) }, 5)
  A.eq(keys(lines:update({ fire("a", 9, 20) }, 5)), "9,18 9,19 9,20 9,21 9,22", "moving west")
end

function T.row_follows_the_fire_each_tick()
  local lines = Lines.new()
  lines:update({ fire("a", 0, 0) }, 3)
  for x = 1, 5 do
    A.eq(keys(lines:update({ fire("a", x, 0) }, 3)), x .. ",-1 " .. x .. ",0 " .. x .. ",1")
  end
end

function T.keeps_direction_while_paused_for_a_tick()
  local lines = Lines.new()
  lines:update({ fire("a", 0, 0) }, 3)
  lines:update({ fire("a", 1, 0) }, 3)
  A.eq(keys(lines:update({ fire("a", 1, 0) }, 3)), "1,-1 1,0 1,1")
end

function T.tiles_vanish_when_the_fire_leaves()
  local lines = Lines.new()
  lines:update({ fire("a", 0, 0) }, 3)
  lines:update({ fire("a", 1, 0) }, 3)
  A.eq(#lines:update({}, 3), 0)
  A.eq(keys(lines:update({ fire("a", 2, 0) }, 3)), "2,0", "a returning uid starts fresh")
end

function T.several_lines_are_merged_without_duplicates()
  local lines = Lines.new()
  lines:update({ fire("a", 0, 0), fire("b", 0, 2) }, 3)
  local tiles = lines:update({ fire("a", 1, 0), fire("b", 1, 2) }, 3)
  A.eq(keys(tiles), "1,-1 1,0 1,1 1,2 1,3", "rows overlap at 1,1 once")
end

function T.diagonal_movement_snaps_to_dominant_axis()
  local lines = Lines.new()
  lines:update({ fire("a", 0, 0) }, 3)
  A.eq(keys(lines:update({ fire("a", 2, 1) }, 3)), "2,0 2,1 2,2")
end

function T.parse_ids()
  local ids = Lines.parseIDs("28520, 28521 abc 7;8")
  A.eq(ids[28520], true); A.eq(ids[28521], true); A.eq(ids[7], true); A.eq(ids[8], true)
  A.eq(next(Lines.parseIDs("")), nil); A.eq(next(Lines.parseIDs(nil)), nil)
end

function T.inspector_lists_moving_things_first()
  local inspector = Inspector.new()
  inspector:observe({ { uid = "w", kind = "Scenery", id = 1, name = "Wall", x = 0, z = 0 },
    { uid = "f", kind = "NPC", id = 900, name = "Fire", x = 5, z = 5 } })
  inspector:observe({ { uid = "w", kind = "Scenery", id = 1, name = "Wall", x = 0, z = 0 },
    { uid = "f", kind = "NPC", id = 900, name = "Fire", x = 6, z = 5 } })
  local rows = inspector:rows()
  A.eq(rows[1].id, 900); A.eq(rows[1].moves, 1); A.eq(rows[2].id, 1)
  A.eq(Inspector.describe(rows[1]), "NPC 900  Fire  (moved 1, seen 2)")
  inspector:reset()
  A.eq(#inspector:rows(), 0)
end

function T.inspector_caps_rows()
  local inspector = Inspector.new()
  local list = {}
  for id = 1, 40 do list[id] = { uid = tostring(id), kind = "NPC", id = id, x = 0, z = 0 } end
  inspector:observe(list)
  A.eq(#inspector:rows(), Inspector.MAX_ROWS)
end

return T
