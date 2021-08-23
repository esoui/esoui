----
-- ZO_EventAnnouncementTile
----

ZO_EventAnnouncementTile = ZO_ActionTile:Subclass()

function ZO_EventAnnouncementTile:New(...)
    return ZO_ActionTile.New(self, ...)
end

function ZO_EventAnnouncementTile:Initialize(control)
    ZO_ActionTile.Initialize(self, control)

    self.control:SetHandler("OnUpdate", function()
        local remainingTime = ZO_MARKET_ANNOUNCEMENT_MANAGER:GetEventAnnouncementRemainingTimeByIndex(self.data.index)
        self:SetHeaderText(self:GetTimeRemainingText(remainingTime))
    end)
end

function ZO_EventAnnouncementTile:GetTimeRemainingText(remainingTime)
    local countDownText = ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR_NO_SECONDS)
    return zo_strformat(SI_EVENT_ANNOUNCEMENT_TIME, countDownText)
end

function ZO_EventAnnouncementTile:Layout(data)
    ZO_Tile.Layout(self, data)

    self.data = ZO_MARKET_ANNOUNCEMENT_MANAGER:GetEventAnnouncementDataByIndex(data.eventAnnouncementIndex)
    self:SetTitle(self.data.name)

    self:SetActionAvailable(self.data.marketProductId ~= 0)

    -- The tile on all platforms is of a landscape dimension rather than portrait as in gamepad, 
    -- so we want to use the keyboard background on tiles regardless of platform.
    self:SetBackground(self.data.tileImage)
end