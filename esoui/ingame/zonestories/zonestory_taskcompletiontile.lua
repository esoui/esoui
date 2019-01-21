-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStory_ActivityCompletionTile = ZO_Tile:Subclass()

function ZO_ZoneStory_ActivityCompletionTile:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_ZoneStory_ActivityCompletionTile:Initialize(...)
    ZO_Tile.Initialize(self, ...)

    local control = self.control
    self.iconControl = control:GetNamedChild("Icon")
    self.valueControl = control:GetNamedChild("Value")
end

function ZO_ZoneStory_ActivityCompletionTile:Layout(zoneData, completionType)
    ZO_Tile.Layout(self, zoneData, completionType)

    self.zoneData = zoneData
    self.completionType = completionType

    self.iconControl:SetTexture(ZO_ZoneStories_Manager.GetCompletionTypeIcon(completionType))
    local text = ZO_ZoneStories_Manager.GetActivityCompletionProgressText(zoneData.id, completionType)
    self.valueControl:SetText(text)
end