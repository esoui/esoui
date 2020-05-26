----
-- ZO_CharacterSelect_EventTile_Shared
----

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_CharacterSelect_EventTile_Shared = ZO_Tile:Subclass()

function ZO_CharacterSelect_EventTile_Shared:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_CharacterSelect_EventTile_Shared:Initialize(...)
    ZO_Tile.Initialize(self, ...)

    self.container = self.control:GetNamedChild("Container")
    self.timeRemainingLabel = self.container:GetNamedChild("TimeRemaining")
    self.titleLabel = self.container:GetNamedChild("Title")
    self.descriptionLabel = self.container:GetNamedChild("Description")
    self.eventImageTexture = self.container:GetNamedChild("EventImage")

    self.control:SetHandler("OnUpdate", function()
        local remainingTime = CHARACTER_SELECT_MANAGER:GetEventAnnouncementRemainingTimeByIndex(self.data.index)
        self:SetTimeRemaining(remainingTime)
    end)
end

function ZO_CharacterSelect_EventTile_Shared:SetTimeRemaining(remainingTime)
    local countDownText = ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
    local remainingTimeText = zo_strformat(SI_EVENT_ANNOUNCEMENT_TIME, ZO_SELECTED_TEXT:Colorize(countDownText))
    self.timeRemainingLabel:SetText(remainingTimeText)
end

function ZO_CharacterSelect_EventTile_Shared:SetTitle(titleText)
    self.titleLabel:SetText(titleText)
end

function ZO_CharacterSelect_EventTile_Shared:SetDescription(descriptionText)
    self.descriptionLabel:SetText(descriptionText)
end

function ZO_CharacterSelect_EventTile_Shared:SetEventImage(eventImageFile)
    self.eventImageTexture:SetTexture(eventImageFile)
    self.eventImageTexture:SetHidden(eventImageFile == ZO_NO_TEXTURE_FILE)
end

function ZO_CharacterSelect_EventTile_Shared:Layout(data)
    ZO_Tile.Layout(self, data)

    self.data = data
    self:SetTitle(data.name)
    self:SetDescription(data.description)
    self:SetEventImage(data.image)
end