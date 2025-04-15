----
-- ZO_PromotionalEventTile
----
local PROMOTIONAL_EVENT_TILE_SOURCE_WIDTH = 512
local PROMOTIONAL_EVENT_TILE_TEXTURE_WIDTH = 300
ZO_PROMOTIONAL_EVENT_TILE_TEXTURE_COORDS_RIGHT = PROMOTIONAL_EVENT_TILE_TEXTURE_WIDTH / PROMOTIONAL_EVENT_TILE_SOURCE_WIDTH

local PROMOTIONAL_EVENT_TILE_SOURCE_HEIGHT = 256
local PROMOTIONAL_EVENT_TILE_TEXTURE_HEIGHT = 200
ZO_PROMOTIONAL_EVENT_TILE_TEXTURE_COORDS_BOTTOM = PROMOTIONAL_EVENT_TILE_TEXTURE_HEIGHT / PROMOTIONAL_EVENT_TILE_SOURCE_HEIGHT

ZO_PromotionalEventTile = ZO_ActionTile:Subclass()

function ZO_PromotionalEventTile:New(...)
    return ZO_ActionTile.New(self, ...)
end

function ZO_PromotionalEventTile:Initialize(control)
    ZO_ActionTile.Initialize(self, control)

    self.bannerTextLabel = self.container:GetNamedChild("TextCallout")
    self.glowUnderlay = self.container:GetNamedChild("GlowUnderlay")
    self.glowOverlay = self.container:GetNamedChild("GlowOverlay")
end

function ZO_PromotionalEventTile:Layout(data)
    ZO_Tile.Layout(self, data)

    local campaignData
    for _, iterCampaignData in PROMOTIONAL_EVENT_MANAGER:CampaignIterator({ ZO_PromotionalEventCampaignData.HasAnyUnclaimedRewards }) do
        -- The first campaign that has rewards left
        campaignData = iterCampaignData
        break
    end

    if not campaignData then
        -- If all rewards are claimed, just go back to the first campaign
        campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByIndex(1)
    end

    local secondsRemaining = campaignData:GetSecondsRemaining()
    if secondsRemaining > 0 then
        local timeRemainingText = ZO_FormatTime(secondsRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
        self:SetHeaderText(zo_strformat(SI_EVENT_ANNOUNCEMENT_TIME, timeRemainingText))
    end

    self:SetTitle(campaignData:GetDisplayName())

    -- The tile on all platforms is of a landscape dimension rather than portrait as in gamepad,
    -- so we want to use the keyboard background on tiles regardless of platform.
    local backgroundFile = campaignData:GetAnnouncementBackgroundFileIndex()
    if backgroundFile ~= ZO_NO_TEXTURE_FILE then
        self:SetBackground(backgroundFile)
    else
        self:SetBackground("EsoUI/Art/PromotionalEvent/promotionalEvents_announcement_bg.dds")
    end

    local bannerText
    if PROMOTIONAL_EVENT_MANAGER:HasAnyUnclaimedRewards() then
        bannerText = campaignData:GetAnnouncementBannerText()
        self.glowUnderlay:SetHidden(false)
        self.glowOverlay:SetHidden(false)
    else
        bannerText = zo_iconTextFormatNoSpace(ZO_CHECK_ICON, "100%", "100%", GetString(SI_MARKET_ANNOUNCEMENT_PROMOTIONAL_EVENT_COMPLETE))
        self.glowUnderlay:SetHidden(true)
        self.glowOverlay:SetHidden(true)
    end

    if bannerText == "" then
        self.bannerTextLabel:SetHidden(true)
    else
        self.bannerTextLabel:SetText(bannerText)
        self.bannerTextLabel:SetHidden(false)
    end

    self:SetActionCallback(function()
        PROMOTIONAL_EVENT_MANAGER:ShowPromotionalEventScene(campaignData)
    end)
end