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
    self.progressBar = self.container:GetNamedChild("ProgressBar")
    self.timerText = self.container:GetNamedChild("TimerText")
    self.timerLabel = self.container:GetNamedChild("TimerLabel")
    ZO_StatusBar_SetGradientColor(self.progressBar, ZO_XP_BAR_GRADIENT_COLORS)

    ZO_HUDTracker_Base.DeferredInitialize(self, ...)
end

function ZO_DynamicEventsTracker:InitializeStyles()
    self.styles =
    {
        keyboard =
        {
            FONT_TIMER_TEXT = "ZoFontWinT1",
            COLOR_TIMER_TEXT = INTERFACE_TEXT_COLOR_SELECTED,
            FONT_TIMER_LABEL = "ZoFontWinT1",
            COLOR_TIMER_LABEL = INTERFACE_TEXT_COLOR_NORMAL,

            TIMER_TEXT_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.progressBar, BOTTOMRIGHT, 0, 2),
            TIMER_LABEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.timerText, BOTTOMRIGHT, 0, 2),
        },
        gamepad =
        {
            FONT_TIMER_TEXT = "ZoFontGamepadBold27",
            COLOR_TIMER_TEXT = INTERFACE_TEXT_COLOR_SELECTED,
            FONT_TIMER_LABEL = "ZoFontGamepadBold27",
            COLOR_TIMER_LABEL = INTERFACE_TEXT_COLOR_SELECTED,

            TIMER_TEXT_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.progressBar, BOTTOMRIGHT, 0, 10),
            TIMER_LABEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.timerText, BOTTOMRIGHT, 0, 10),
        },
    }

    ZO_HUDTracker_Base.InitializeStyles(self)
end

do
    local DISPLAY_NAME = GetString(SI_HUD_EDITOR_DYNAMIC_EVENT_TRACKER)

    function ZO_DynamicEventsTracker:GetHUDElementInfo()
        return DISPLAY_NAME
    end

    function ZO_DynamicEventsTracker:GetHUDElementOptionKeys()
        local KEY = "Dynamic"
        return KEY, DISPLAY_NAME
    end
end

function ZO_DynamicEventsTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    local function OnUpdate()
        self:Update()
    end

    self.control:RegisterForEvent(EVENT_WORLD_EVENT_PARTICIPATION_BEGIN, OnUpdate)
    self.control:RegisterForEvent(EVENT_WORLD_EVENT_PARTICIPATION_END, OnUpdate)

    local function OnStepChanged(_, worldEventInstanceId, stepDefId)
        if worldEventInstanceId == self.worldEventInstanceId then
            self:Update()
        end
    end

    self.control:RegisterForEvent(EVENT_WORLD_EVENT_STEP_CHANGED, OnStepChanged)

    local function OnProgressChanged(_, worldEventInstanceId, stepDefId, newCurrentProgress, newMaxProgress)
        if worldEventInstanceId == self.worldEventInstanceId and stepDefId == self.stepDefId then
            self:RefreshProgress(newCurrentProgress, newMaxProgress)
        end
    end

    self.control:RegisterForEvent(EVENT_WORLD_EVENT_STEP_PROGRESS_CHANGED, OnProgressChanged)
end

function ZO_DynamicEventsTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    self.timerText:SetFont(style.FONT_TIMER_TEXT)
    self.timerText:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, style.COLOR_TIMER_TEXT))
    self.timerLabel:SetFont(style.FONT_TIMER_LABEL)
    self.timerLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, style.COLOR_TIMER_LABEL))
    ZO_ApplyPlatformTemplateToControl(self.progressBar, "ZO_HUDTracker_Base_ProgressBar")
end

function ZO_DynamicEventsTracker:OnShown()
    ZO_HUDTracker_Base.OnShown(self)

    self:RefreshTimer()
    self:RefreshAnchors()
end

function ZO_DynamicEventsTracker:Update()
    local worldEventInstanceId, stepDefId = GetParticipatingWorldEventStep()
    self.worldEventInstanceId = worldEventInstanceId
    self.stepDefId = stepDefId

    local isInDynamicEvent = worldEventInstanceId ~= 0
    if isInDynamicEvent then
        self:SetHeaderText(GetWorldEventStepName(worldEventInstanceId, stepDefId))
        self:SetSubLabelText(GetWorldEventStepDescription(stepDefId))

        self.expireTimeS = GetWorldEventCurrentStepExpireTimeS(worldEventInstanceId)
        self.timerLabel:SetHidden(self.expireTimeS == 0)

        local timerText = GetWorldEventStepTimerTextOverride()
        if timerText == "" then
            timerText = GetString(SI_DYNAMIC_EVENTS_TIMER_LABEL)
        end
        self.timerText:SetText(timerText)
        self.timerText:SetHidden(self.expireTimeS == 0)

        self:RefreshProgress()
    end
    self:GetFragment():SetHiddenForReason("NotInDynamicEvent", not isInDynamicEvent, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)

    ZO_HUDTracker_Base.Update(self)
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

    local progressBar = self.progressBar
    if maxProgress > 1 then
        ZO_StatusBar_SmoothTransition(progressBar, currentProgress, maxProgress)
        progressBar.progressBarLabel:SetText(string.format("%.0f%%", currentProgress / maxProgress * 100))
        progressBar:SetHidden(false)
    else
        progressBar:SetHidden(true)
    end
end

function ZO_DynamicEventsTracker:RefreshAnchors()
    ZO_HUDTracker_Base.RefreshAnchors(self)

    local style = self.currentStyle
    self:RefreshAnchorSetOnControl(self.timerText, style.TIMER_TEXT_PRIMARY_ANCHOR, style.TIMER_TEXT_SECONDARY_ANCHOR)
    self:RefreshAnchorSetOnControl(self.timerLabel, style.TIMER_LABEL_PRIMARY_ANCHOR, style.TIMER_LABEL_SECONDARY_ANCHOR)
end

function ZO_DynamicEventsTracker:GetPriority()
    return ZO_HUD_TRACKER_PRIORITY.DYNAMIC_EVENTS
end

function ZO_DynamicEventsTracker.OnInitialized(control)
    DYNAMIC_EVENTS_TRACKER = ZO_DynamicEventsTracker:New(control)
end

HUD_TRACKER_MANAGER:RegisterTracker("ZO_DynamicEventsTracker_Template", "ZO_DynamicEventsTracker_TL")