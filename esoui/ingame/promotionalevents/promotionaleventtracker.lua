ZO_PromotionalEventTracker = ZO_HUDTracker_Base:Subclass()

function ZO_PromotionalEventTracker:Initialize(control)
    ZO_HUDTracker_Base.Initialize(self, control)

    self.progressLabel = self.container:GetNamedChild("ProgressLabel")
    self.headerIcon = self.headerLabel:GetNamedChild("Icon")

    PROMOTIONAL_EVENT_TRACKER_FRAGMENT = self:GetFragment()
    -- ESO-894612: This may not be necessary or the fix for the bug, but some players reported the tutorial firing when it shouldn't have
    -- (see ZO_PromotionalEventTracker:OnShowing). Best guess is that it's not yet marked hidden via an Update call by the time the
    -- fragment gets shown via the scene. Not sure how though, and we don't have a reliable repro.
    local INSTANT = 0
    PROMOTIONAL_EVENT_TRACKER_FRAGMENT:SetHiddenForReason("NoTrackedPromotionalEvent", true, INSTANT, INSTANT)
end

function ZO_PromotionalEventTracker:InitializeStyles()
    self.styles =
    {
        keyboard =
        {
            FONT_HEADER = "ZoFontGameShadow",
            FONT_SUBLABEL = "ZoFontGameShadow",
            FONT_PROGRESS_LABEL = "ZoFontGameShadow",
            TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_NONE,
            RESIZE_TO_FIT_PADDING_HEIGHT = 10,

            TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, ZO_ZoneStoryTracker, BOTTOMLEFT),
            TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X),

            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT),
            CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),

            PROGRESS_LABEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, self.subLabel, BOTTOMLEFT, 0, 2),
            PROGRESS_LABEL_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.subLabel, BOTTOMRIGHT, 0, 2),

            SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y = 2,

            HEADER_ICON_SIZE = 25,
            HEADER_ICON_OFFSET = -2,
        },
        gamepad =
        {
            FONT_HEADER = "ZoFontGamepadBold27",
            FONT_SUBLABEL = "ZoFontGamepad34",
            FONT_PROGRESS_LABEL = "ZoFontGamepad34",
            TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_UPPERCASE,
            RESIZE_TO_FIT_PADDING_HEIGHT = 20,

            TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, ZO_ZoneStoryTracker, BOTTOMLEFT),
            TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, -15, 0, ANCHOR_CONSTRAINS_X),

            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),

            PROGRESS_LABEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.subLabel, BOTTOMRIGHT, 0, 10),

            SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y = 10,
            
            HEADER_ICON_SIZE = 48,
            HEADER_ICON_OFFSET = -10,
        }
    }
    ZO_HUDTracker_Base.InitializeStyles(self)
end

function ZO_PromotionalEventTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    local function Update()
        self:Update()
    end

    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", Update)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("RewardsClaimed", Update)
    self.control:RegisterForEvent(EVENT_PROMOTIONAL_EVENTS_ACTIVITY_PROGRESS_UPDATED, Update)
    self.control:RegisterForEvent(EVENT_PROMOTIONAL_EVENTS_ACTIVITY_TRACKING_UPDATED, Update)
end

function ZO_PromotionalEventTracker:Update()
    local hidden = true
    if not IsPromotionalEventSystemLocked() then
        local campaignKey, activityIndex = GetTrackedPromotionalEventActivityInfo()
        local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByKey(campaignKey)
        if campaignData then
            local activityData = campaignData:GetActivityData(activityIndex)
            if activityData then
                self:SetSubLabelText(activityData:GetDisplayName())
                
                local progress = activityData:GetProgress()
                local completionThreshold = activityData:GetCompletionThreshold()
                local progressText = zo_strformat(SI_PROMOTIONAL_EVENT_TRACKER_PROGRESS_FORMATTER, ZO_CommaDelimitNumber(progress), ZO_CommaDelimitNumber(completionThreshold))
                self.progressLabel:SetText(progressText)
                hidden = false
            end
        end
    end
    self:GetFragment():SetHiddenForReason("NoTrackedPromotionalEvent", hidden, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
end

function ZO_PromotionalEventTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    self.progressLabel:SetFont(style.FONT_PROGRESS_LABEL)
    self.headerIcon:SetDimensions(style.HEADER_ICON_SIZE, style.HEADER_ICON_SIZE)
    self.headerIcon:SetAnchor(RIGHT, nil, LEFT, style.HEADER_ICON_OFFSET)
end

function ZO_PromotionalEventTracker:GetPrimaryAnchor()
    return self.currentStyle.TOP_LEVEL_PRIMARY_ANCHOR
end

function ZO_PromotionalEventTracker:GetSecondaryAnchor()
    return self.currentStyle.TOP_LEVEL_SECONDARY_ANCHOR
end

function ZO_PromotionalEventTracker:RefreshAnchors()
    -- ZO_HUDTracker_Base override.
    ZO_HUDTracker_Base.RefreshAnchors(self)

    local style = self.currentStyle
    self:RefreshAnchorSetOnControl(self.progressLabel, style.PROGRESS_LABEL_PRIMARY_ANCHOR, style.PROGRESS_LABEL_SECONDARY_ANCHOR)
end

function ZO_PromotionalEventTracker:OnShowing()
    TriggerTutorial(TUTORIAL_TRIGGER_PROMOTIONAL_EVENTS_HUD_TRACKER_SHOWN)
end

function ZO_PromotionalEventTracker:SetHidden(isHidden)
    ZO_HUDTracker_Base.SetHidden(self, isHidden)

    self.progressLabel:SetHidden(isHidden)
end

function ZO_PromotionalEventTracker.OnControlInitialized(control)
    PROMOTIONAL_EVENT_TRACKER = ZO_PromotionalEventTracker:New(control)
end