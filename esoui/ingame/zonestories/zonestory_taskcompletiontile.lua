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

function ZO_ZoneStory_ActivityCompletionTile:Layout(data)
    ZO_Tile.Layout(self, data)

    self.zoneData = data.zoneData
    self.completionType = data.completionType

    self.iconControl:SetTexture(ZO_ZoneStories_Manager.GetCompletionTypeIcon(data.completionType))
    local text = ZO_ZoneStories_Manager.GetActivityCompletionProgressText(data.zoneData.id, data.completionType)
    self.valueControl:SetText(text)
end