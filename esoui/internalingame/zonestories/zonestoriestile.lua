----
-- ZO_ZoneStoriesTile
----
local ZONE_STORIES_TILE_SOURCE_WIDTH = 1024
local ZONE_STORIES_TILE_TEXTURE_WIDTH = 620
ZO_ZONE_STORIES_TILE_TEXTURE_COORDS_RIGHT = ZONE_STORIES_TILE_TEXTURE_WIDTH / ZONE_STORIES_TILE_SOURCE_WIDTH

local ZONE_STORIES_TILE_SOURCE_HEIGHT = 512
local ZONE_STORIES_TILE_TEXTURE_HEIGHT = ZONE_STORIES_TILE_TEXTURE_WIDTH / ZO_MARKET_ANNOUNCEMENT_TILE_DIMENSIONS_ASPECT_RATIO
local ZONE_STORIES_TILE_CENTERED_HEIGHT_OFFSET = (ZONE_STORIES_TILE_SOURCE_HEIGHT - ZONE_STORIES_TILE_TEXTURE_HEIGHT) / 2
ZO_ZONE_STORIES_TILE_TEXTURE_COORDS_TOP = ZONE_STORIES_TILE_CENTERED_HEIGHT_OFFSET / ZONE_STORIES_TILE_SOURCE_HEIGHT
ZO_ZONE_STORIES_TILE_TEXTURE_COORDS_BOTTOM = (ZONE_STORIES_TILE_SOURCE_HEIGHT - ZONE_STORIES_TILE_CENTERED_HEIGHT_OFFSET) / ZONE_STORIES_TILE_SOURCE_HEIGHT

ZO_ZoneStoriesTile = ZO_ActionTile:Subclass()

function ZO_ZoneStoriesTile:New(...)
    return ZO_ActionTile.New(self, ...)
end

function ZO_ZoneStoriesTile:Layout(data)
    ZO_Tile.Layout(self, data)

    self:SetTitle(ZO_CachedStrFormat(SI_ZONE_NAME, GetZoneNameById(data.zoneId)))

    -- The tile on all platforms is of a landscape dimension rather than portrait as in gamepad, 
    -- so we want to use the keyboard background on tiles regardless of platform.
    local backgroundFile = GetZoneStoryKeyboardBackground(data.zoneId)
    self:SetBackground(backgroundFile)

    self:SetActionCallback(function()
        ShowZoneStoriesScene(data.zoneId)
    end)
end