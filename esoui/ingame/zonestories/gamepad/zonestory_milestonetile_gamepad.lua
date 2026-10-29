ZO_ZONE_STORIES_MILESTONE_TILE_GAMEPAD_DIMENSIONS_X = 390
ZO_ZONE_STORIES_MILESTONE_TILE_GAMEPAD_DIMENSIONS_Y = 104
ZO_ZONE_STORIES_MILESTONE_TILE_GAMEPAD_ICON_DIMENSIONS = 64

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStory_MilestoneTile_Gamepad = ZO_Object.MultiSubclass(ZO_Tile_Gamepad, ZO_ZoneStory_MilestoneTile)

function ZO_ZoneStory_MilestoneTile_Gamepad:New(...)
    return ZO_ZoneStory_MilestoneTile.New(self, ...)
end

function ZO_ZoneStory_MilestoneTile_Gamepad_OnInitialized(control)
    ZO_ZoneStory_MilestoneTile_Gamepad:New(control)
end