ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_GAMEPAD_DIMENSIONS_X = 190
ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_GAMEPAD_DIMENSIONS_Y = 64
ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_GAMEPAD_ICON_DIMENSIONS = 64

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStory_ActivityCompletionTile_Gamepad = ZO_Object.MultiSubclass(ZO_Tile_Gamepad, ZO_ZoneStory_ActivityCompletionTile)

function ZO_ZoneStory_ActivityCompletionTile_Gamepad:New(...)
    return ZO_ZoneStory_ActivityCompletionTile.New(self, ...)
end

function ZO_ZoneStory_ActivityCompletionTile_Gamepad_OnInitialized(control)
    ZO_ZoneStory_ActivityCompletionTile_Gamepad:New(control)
end