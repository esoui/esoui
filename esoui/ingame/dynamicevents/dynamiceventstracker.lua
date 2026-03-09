ZO_DynamicEventsTracker = ZO_HUDTracker_Base:Subclass()

function ZO_DynamicEventsTracker:Initialize(...)
    ZO_HUDTracker_Base.Initialize(self, ...)

    local fragment = self:GetFragment()
    DYNAMIC_EVENTS_TRACKER_FRAGMENT = fragment
    local INSTANT = 0
    fragment:SetHiddenForReason("NotInDynamicEvent", true, INSTANT, INSTANT)

    self.expireTimeS = 0
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, ZO_GetEventForwardingFunction(self, self.Update))
    self.control:SetHandler("OnUpdate", function(_, timeS)
        self:RefreshTimer()
    end)
end

function ZO_DynamicEventsTracker:DeferredInitialize(...)
    self.timerLabel = self.container:GetNamedChild("TimerLabel")
    self.progressBar = self.container:GetNamedChild("ProgressBar")
    ZO_StatusBar_SetGradientColor(self.progressBar, ZO_XP_BAR_GRADIENT_COLORS)

    ZO_HUDTracker_Base.DeferredInitialize(self, ...)
end

function ZO_DynamicEventsTracker:InitializeStyles()
    self.styles =
    {
        keyboard =
        {
            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT),
            CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),
            FONT_HEADER = "ZoFontGameShadow",
            FONT_SUBLABEL = "ZoFontGameShadow",
            FONT_TIMER_LABEL = "ZoFontWinT1",
            COLOR_TIMER_LABEL = INTERFACE_TEXT_COLOR_NORMAL,
            RESIZE_TO_FIT_PADDING_HEIGHT = 10,
            TEXT_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_LEFT,
            TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, ZO_AdvZoneHUDTracker, BOTTOMLEFT),
            TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X),

            TIMER_LABEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, self.subLabel, BOTTOMLEFT, 0, 2),
            TIMER_LABEL_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.subLabel, BOTTOMRIGHT, 0, 2),
        },
        gamepad =
        {
            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT),
            CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, nil, nil, -15, 0),
            FONT_HEADER = "ZoFontGamepadBold27",
            FONT_SUBLABEL = "ZoFontGamepad34",
            FONT_TIMER_LABEL = "ZoFontGamepadBold27",
            COLOR_TIMER_LABEL = INTERFACE_TEXT_COLOR_SELECTED,
            RESIZE_TO_FIT_PADDING_HEIGHT = 20,
            TEXT_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_RIGHT,
            TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, ZO_AdvZoneHUDTracker, BOTTOMLEFT),
            TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X),

            TIMER_LABEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.subLabel, BOTTOMRIGHT, 0, 10),
        },
    }

    ZO_HUDTracker_Base.InitializeStyles(self)
end

function ZO_DynamicEventsTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    local function OnUpdate()
        self:Update()
    end

    self.control:RegisterForEvent(EVENT_WORLD_EVENT_PARTICIPATION_BEGIN, OnUpdate)
    self.control:RegisterForEvent(EVENT_WORLD_EVENT_PARTICIPATION_END, OnUpdate)

    local function OnStepChanged(_, worldEventInstanceId, stepIndex)
        if worldEventInstanceId == self.worldEventInstanceId then
            self:Update()
        end
    end

    self.control:RegisterForEvent(EVENT_WORLD_EVENT_STEP_CHANGED, OnStepChanged)

    local function OnProgressChanged(_, worldEventInstanceId, stepIndex, newCurrentProgress, newMaxProgress)
        if worldEventInstanceId == self.worldEventInstanceId and stepIndex == self.stepIndex then
            self:RefreshProgress(newCurrentProgress, newMaxProgress)
        end
    end

    self.control:RegisterForEvent(EVENT_WORLD_EVENT_STEP_PROGRESS_CHANGED, OnProgressChanged)
end

function ZO_DynamicEventsTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    self.timerLabel:SetFont(style.FONT_TIMER_LABEL)
    self.timerLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, style.COLOR_TIMER_LABEL))
    ZO_ApplyPlatformTemplateToControl(self.progressBar, "ZO_DynamicEventsTracker_ProgressBar")
end

function ZO_DynamicEventsTracker:GetPrimaryAnchor()
    return self.currentStyle.TOP_LEVEL_PRIMARY_ANCHOR
end

function ZO_DynamicEventsTracker:GetSecondaryAnchor()
    return self.currentStyle.TOP_LEVEL_SECONDARY_ANCHOR
end

function ZO_DynamicEventsTracker:OnShown()
    self:RefreshTimer()
    self:RefreshAnchors()
end

function ZO_DynamicEventsTracker:Update()
    local worldEventInstanceId, stepIndex = GetParticipatingWorldEventStep()
    self.worldEventInstanceId = worldEventInstanceId
    self.stepIndex = stepIndex

    local isInDynamicEvent = worldEventInstanceId ~= 0
    if isInDynamicEvent then
        self:SetHeaderText(GetWorldEventStepName(worldEventInstanceId, stepIndex))
        self:SetSubLabelText(GetWorldEventStepDescription(worldEventInstanceId, stepIndex))

        self.expireTimeS = GetWorldEventCurrentStepExpireTimeS(worldEventInstanceId)
        self.timerLabel:SetHidden(self.expireTimeS == 0)

        self:RefreshProgress()
    end
    self:GetFragment():SetHiddenForReason("NotInDynamicEvent", not isInDynamicEvent, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
    return true
end

function ZO_DynamicEventsTracker:RefreshTimer()
    if self.expireTimeS ~= 0 then
        local secondsRemaining = zo_max(self.expireTimeS - GetTimeStamp(), 0)
        self.timerLabel:SetText(ZO_FormatTimeLargestTwo(secondsRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL))
    end
end

function ZO_DynamicEventsTracker:RefreshProgress(currentProgress, maxProgress)
    if not currentProgress then
        currentProgress, maxProgress = GetWorldEventCurrentStepProgress(self.worldEventInstanceId)
    end

    if maxProgress > 1 then
        self.progressBar:SetMinMax(0, maxProgress)
        self.progressBar:SetValue(currentProgress)
        self.progressBar.progressBarLabel:SetText(string.format("%.0f%%", currentProgress / maxProgress * 100))
        self.progressBar:SetHidden(false)
    else
        self.progressBar:SetHidden(true)
    end
end

function ZO_DynamicEventsTracker:RefreshAnchors()
    ZO_HUDTracker_Base.RefreshAnchors(self)

    local style = self.currentStyle
    self:RefreshAnchorSetOnControl(self.timerLabel, style.TIMER_LABEL_PRIMARY_ANCHOR, style.TIMER_LABEL_SECONDARY_ANCHOR)
end

function ZO_DynamicEventsTracker.OnInitialized(control)
    DYNAMIC_EVENTS_TRACKER = ZO_DynamicEventsTracker:New(control)
end