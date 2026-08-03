ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_GAMEPAD_DIMENSIONS_X = 190
ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_GAMEPAD_DIMENSIONS_Y = 78
ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_GAMEPAD_ICON_DIMENSIONS = 64

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStory_ActivityCompletionTile_Gamepad = ZO_Object.MultiSubclass(ZO_Tile_Gamepad, ZO_Tile)

function ZO_ZoneStory_ActivityCompletionTile_Gamepad:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_ZoneStory_ActivityCompletionTile_Gamepad:Initialize(...)
    ZO_Tile.Initialize(self, ...)

    local control = self.control
    self.iconControl = control:GetNamedChild("Icon")
    self.valueControl = control:GetNamedChild("Title")
    self.selectionFrameControl = control:GetNamedChild("SelectionFrame")
end

function ZO_ZoneStory_ActivityCompletionTile_Gamepad:Layout(data)
    ZO_Tile.Layout(self, data)

    local zoneId = data.zoneData.id
    local completionType = data.completionType
    local completionIndex = data.completionIndex
    self.zoneData = data.zoneData
    self.zoneId = zoneId
    self.completionType = completionType
    self.completionIndex = completionIndex

    self.iconControl:SetTexture(ZO_ZoneStories_Manager.GetCompletionTypeIcon(completionType, completionIndex))
    local text = ZO_ZoneStories_Manager.GetActivityCompletionProgressText(zoneId, completionType, completionIndex)
    self.valueControl:SetText(text)

    local color = ZO_ZoneStories_Manager.IsZoneCompletionTypeComplete(zoneId, completionType) and ZO_NORMAL_TEXT or ZO_SELECTED_TEXT
    self.valueControl:SetColor(color:UnpackRGB())

    self.selectionFrameControl:SetHidden(not self:IsTracking())
end

function ZO_ZoneStory_ActivityCompletionTile_Gamepad:IsTracking()
    local trackedZoneId, trackedZoneCompletionType = GetTrackedZoneStoryActivityInfo()
    return trackedZoneId == self.zoneId and trackedZoneCompletionType == self.completionType
end

function ZO_ZoneStory_ActivityCompletionTile_Gamepad.OnControlInitialized(control)
    ZO_ZoneStory_ActivityCompletionTile_Gamepad:New(control)
end