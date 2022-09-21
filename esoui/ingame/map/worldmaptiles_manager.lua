--[[
    Map Tile Pool Object.  Creates the base tiles for the world map...controls must be able to be indexed by tile
--]]

ZO_WorldMapTiles_Manager = ZO_ControlPool:Subclass()

function ZO_WorldMapTiles_Manager:Initialize(parent)
    ZO_ControlPool.Initialize(self, "ZO_MapTile", parent, "")
end

function ZO_WorldMapTiles_Manager:UpdateMapData()
    local numHorizontalTiles, numVerticalTiles = GetMapNumTiles()

    self.horizontalTiles = numHorizontalTiles
    self.verticalTiles = numVerticalTiles
    self.totalTiles = numHorizontalTiles * numVerticalTiles
end

function ZO_WorldMapTiles_Manager:LayoutTiles()
    if self.horizontalTiles == nil then
        self:UpdateMapData()
    end

    local tileWidth = ZO_MAP_CONSTANTS.MAP_WIDTH / self.horizontalTiles
    local tileHeight = ZO_MAP_CONSTANTS.MAP_HEIGHT / self.verticalTiles

    self:ReleaseAllObjects()
    
    for i = 1, self.totalTiles do
        local tileControl = self:AcquireObject(i)
        tileControl:SetDimensions(tileWidth, tileHeight)
        local xOffset = zo_mod(i - 1, self.horizontalTiles) * tileWidth
        local yOffset = zo_floor((i - 1) / self.horizontalTiles) * tileHeight
        tileControl:SetAnchor(TOPLEFT, self.parent, TOPLEFT, xOffset, yOffset)
    end
end

function ZO_WorldMapTiles_Manager:UpdateTextures()
    self:UpdateMapData()
    self:LayoutTiles()

    for i = 1, self.totalTiles do
        local tileControl = self:GetActiveObject(i)
        tileControl:SetTexture(GetMapTileTexture(i))
    end
end