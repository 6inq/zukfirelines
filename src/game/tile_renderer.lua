-- Draws highlighted tiles on the ground as one 3D shape (ShapeList, as Tilemarkers does).
-- Rebuilt only when the set of tiles or the colour changes; cleared when no fire is present.
local TileRenderer = {}
TileRenderer.__index = TileRenderer

TileRenderer.TILE = 512
local HEIGHT_OFFSET = 30
local INSET = 16          -- small gap so neighbouring tiles read as separate squares
local LINE_WIDTH = 2.0

function TileRenderer.new()
  return setmetatable({ shape = nil, signature = nil }, TileRenderer)
end

function TileRenderer.available()
  return rawget(_G, "ShapeList") ~= nil and rawget(_G, "ShapeData") ~= nil
    and rawget(_G, "World") ~= nil and rawget(_G, "Vector3") ~= nil
end

local function height(level, x, z)
  local ok, h, available = pcall(function() return World.GetGroundHeight(level, math.floor(x), math.floor(z)) end)
  if ok and available ~= false and type(h) == "number" then return h end
  return nil
end

-- World-space centre of a tile. Uses the client's own conversion (as Tilemarkers does via
-- ToCoordFine), falling back to 512 units per tile.
function TileRenderer.centre(level, x, z)
  local ok, position = pcall(function()
    return CoordGrid.new(level, x // 64, z // 64, x % 64, z % 64):ToCoordFine(true).position
  end)
  if ok and position then return position.x, position.z end
  return x * TileRenderer.TILE + TileRenderer.TILE / 2, z * TileRenderer.TILE + TileRenderer.TILE / 2
end

-- Opaque outline in the same hue as the fill.
local function outlineOf(rgba)
  return (rgba & 0xFFFFFF00) | 0xFF
end

-- Four corners per tile (fine units, tile x * 512 .. +512), relative to the anchor.
local function build(tiles, anchor, rgba)
  local data = ShapeData.new()
  local positions, colours, tris, lines = {}, {}, {}, {}
  local T = TileRenderer.TILE
  local half = T / 2 - INSET
  for _, tile in ipairs(tiles) do
    local cx, cz = TileRenderer.centre(tile.level, tile.x, tile.z)
    local minX, minZ, maxX, maxZ = cx - half, cz - half, cx + half, cz + half
    local corners = { { minX, minZ }, { maxX, minZ }, { maxX, maxZ }, { minX, maxZ } }
    local base = #positions
    for index, c in ipairs(corners) do
      local h = height(tile.level, c[1], c[2]) or anchor.y
      local p = Vector3.new(c[1] - anchor.x, h - anchor.y + HEIGHT_OFFSET, c[2] - anchor.z)
      positions[base + index] = p
      colours[base + index] = rgba
      positions[base + 4 + index] = p
      colours[base + 4 + index] = outlineOf(rgba)
    end
    for _, i in ipairs({ 0, 1, 2, 0, 2, 3 }) do tris[#tris + 1] = base + i end
    for _, i in ipairs({ 0, 1, 1, 2, 2, 3, 3, 0 }) do lines[#lines + 1] = base + 4 + i end
  end
  data.positions, data.rgba, data.tris, data.lines = positions, colours, tris, lines
  return data
end

local function signatureOf(tiles, rgba)
  local parts = { tostring(rgba) }
  for _, tile in ipairs(tiles) do parts[#parts + 1] = tile.level .. ":" .. tile.x .. ":" .. tile.z end
  return table.concat(parts, "|")
end

---@param tiles table[] { x, z, level } tile coordinates
---@param rgba integer 0xRRGGBBAA
function TileRenderer:render(tiles, rgba)
  if #tiles == 0 then
    self:clear()
    return false
  end
  local signature = signatureOf(tiles, rgba)
  if signature == self.signature and self.shape then return true end
  local first = tiles[1]
  local ax, az = TileRenderer.centre(first.level, first.x, first.z)
  local ay = height(first.level, ax, az)
  if not ay then return false end
  local anchor = Vector3.new(ax, ay, az)
  if not self.shape then
    self.shape = ShapeList.CreateInstance("zuk-fire-lines:tiles")
    if not self.shape then return false end
  end
  if not self.shape:SetShapeData(build(tiles, anchor, rgba)) then
    self:clear()
    return false
  end
  self.shape.translation = anchor
  self.shape.lineWidth = LINE_WIDTH
  self.shape.colour = 0xFFFFFFFF
  self.shape.ignoreDepth = false
  self.signature = signature
  return true
end

function TileRenderer:clear()
  if self.shape then pcall(function() return self.shape:Destroy() end) end
  self.shape, self.signature = nil, nil
end

return TileRenderer
