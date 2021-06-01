
-----------------------------
-- Companion Progress Bar
-----------------------------

ZO_CompanionProgressBar_Keyboard = ZO_InitializingObject:Subclass()

function ZO_CompanionProgressBar_Keyboard:Initialize(control)
    self.control = control
    self.companionIcon = control:GetNamedChild("Icon")
    self.levelLabel = control:GetNamedChild("Level")
    
    local function OnBarLevelChanged(_, level)
        self.levelLabel:SetText(level)
    end

    local xpBarControl = control:GetNamedChild("Bar")
    ZO_StatusBar_SetGradientColor(xpBarControl, ZO_XP_BAR_GRADIENT_COLORS)
    self.xpBar = ZO_WrappingStatusBar:New(xpBarControl, OnBarLevelChanged)

    xpBarControl.progressBar = self

    control:RegisterForEvent(EVENT_COMPANION_EXPERIENCE_GAIN, function(eventId, ...) self:RefreshCompanionLevel() end)
end

function ZO_CompanionProgressBar_Keyboard:OnShowing()
    if HasActiveCompanion() then
        self.companionIcon:SetTexture(ZO_COMPANION_MANAGER:GetActiveCompanionIcon())
        local FORCE_REFRESH = true
        self:RefreshCompanionLevel(FORCE_REFRESH)
    end
end

function ZO_CompanionProgressBar_Keyboard:RefreshCompanionLevel(forceRefresh)
    if HasActiveCompanion() and (forceRefresh or not self.control:IsHidden()) then
        local level, currentXpInLevel, totalXpInLevel, isMaxLevel = ZO_COMPANION_MANAGER:GetLevelInfo()
        local shouldNotWrap = forceRefresh
        if isMaxLevel then
            self.xpBar:SetValue(level, 1, 1, shouldNotWrap, forceRefresh)
        else
            self.xpBar:SetValue(level, currentXpInLevel, totalXpInLevel, shouldNotWrap, forceRefresh)
        end
    end
end

function ZO_CompanionProgressBar_Keyboard:OnMouseEnter(bar)
    if not HasActiveCompanion() then
        return
    end

    local level, currentXpInLevel, totalXpInLevel, isMaxLevel = ZO_COMPANION_MANAGER:GetLevelInfo()
    InitializeTooltip(InformationTooltip, bar, TOP, 0, 10)
    SetTooltipText(InformationTooltip, zo_strformat(SI_LEVEL_DISPLAY, GetString(SI_EXPERIENCE_LEVEL_LABEL), level))

    if isMaxLevel then
        InformationTooltip:AddLine(GetString(SI_EXPERIENCE_LIMIT_REACHED))
    else
        local percentageXp = zo_floor(currentXpInLevel / totalXpInLevel * 100) 
        InformationTooltip:AddLine(zo_strformat(SI_EXPERIENCE_CURRENT_MAX_PERCENT, ZO_CommaDelimitNumber(currentXpInLevel), ZO_CommaDelimitNumber(totalXpInLevel), percentageXp))
    end
end

function ZO_CompanionProgressBar_Keyboard:OnMouseExit(self)
    ClearTooltip(InformationTooltip)
end


-----------------------------
-- Companion Progress Bar Fragment
-----------------------------

ZO_CompanionProgress_Keyboard = ZO_InitializingObject:Subclass()

function ZO_CompanionProgress_Keyboard:Initialize(control)
    self.control = control
    self.progressBarContainer = control:GetNamedChild("ProgressBar")
    self.progressBar = ZO_CompanionProgressBar_Keyboard:New(self.progressBarContainer)

    -- fragment
    COMPANION_PROGRESS_BAR_FRAGMENT = ZO_FadeSceneFragment:New(control)
    COMPANION_PROGRESS_BAR_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.progressBar:OnShowing()
        end
    end)
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionProgress_Keyboard_OnInitialize(control)
    COMPANION_PROGRESS_KEYBOARD = ZO_CompanionProgress_Keyboard:New(control)
end
