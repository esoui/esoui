
ZO_CompanionFooter_Gamepad = ZO_InitializingObject:Subclass()

function ZO_CompanionFooter_Gamepad:Initialize(control)
    self.control = control
    local levelBarContainer = control:GetNamedChild("LevelBarContainer")
    self.companionIcon = levelBarContainer:GetNamedChild("Icon")
    self.levelLabel = levelBarContainer:GetNamedChild("Level")
    self.companionNameLabel = control:GetNamedChild("CompanionNameValue")

    local function OnBarLevelChanged(_, level)
        self.levelLabel:SetText(level)
    end

    local xpBarControl = levelBarContainer:GetNamedChild("Bar")
    ZO_StatusBar_SetGradientColor(xpBarControl, ZO_XP_BAR_GRADIENT_COLORS)
    self.xpBar = ZO_WrappingStatusBar:New(xpBarControl, OnBarLevelChanged)

    EVENT_MANAGER:RegisterForEvent("ZO_CompanionFooter_Gamepad", EVENT_COMPANION_EXPERIENCE_GAIN, function(eventId, ...) self:RefreshCompanionLevel() end)

    COMPANION_FOOTER_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    COMPANION_FOOTER_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            if HasActiveCompanion() then
                self.companionIcon:SetTexture(ZO_COMPANION_MANAGER:GetActiveCompanionIcon())
                local FORCE_REFRESH = true
                self:RefreshCompanionLevel(FORCE_REFRESH)
                local companionName = GetCompanionName(GetActiveCompanionDefId())
                self.companionNameLabel:SetText(zo_strformat(SI_COMPANION_NAME_FORMATTER, companionName))
            end
        end
    end)
end

function ZO_CompanionFooter_Gamepad:RefreshCompanionLevel(forceRefresh)
    if HasActiveCompanion() and (forceRefresh or COMPANION_FOOTER_GAMEPAD_FRAGMENT:IsShowing()) then
        local level, currentXpInLevel, totalXpInLevel, isMaxLevel = ZO_COMPANION_MANAGER:GetLevelInfo()
        local shouldNotWrap = forceRefresh
        if isMaxLevel then
            self.xpBar:SetValue(level, 1, 1, shouldNotWrap, forceRefresh)
        else
            self.xpBar:SetValue(level, currentXpInLevel, totalXpInLevel, shouldNotWrap, forceRefresh)
        end
    end
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionFooter_Gamepad_OnInitialized(control)
    COMPANION_FOOTER_GAMEPAD = ZO_CompanionFooter_Gamepad:New(control)
end