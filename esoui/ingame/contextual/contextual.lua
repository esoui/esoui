local FADE_OUT_DELAY = 3000
local FADE_IN_TIME = 250
local FADE_OUT_TIME = 750

local g_hasValidTarget = false
local g_isMousedOver = false
local g_showActionBarSetting = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_ACTION_BAR))
local g_actionBarReferences = 0
local g_actionBarHasAnAction = false
local g_holdingForFadeOut = false

local INSTANT = true
local ANIMATED = false

local function ShouldActionBarShow()
    if g_showActionBarSetting == ACTION_BAR_SETTING_CHOICE_ON then
        return true
    elseif g_showActionBarSetting == ACTION_BAR_SETTING_CHOICE_OFF then
        return false
    else
        local actionBarIsRelevant = (g_hasValidTarget or g_isMousedOver or g_actionBarReferences > 0)
        if g_actionBarHasAnAction and actionBarIsRelevant then
            return true
        else
            return false
        end
    end
end

local function GetAnimationTimes(speed)
    local fadeInTime = speed == ANIMATED and FADE_IN_TIME or 0
    local fadeOutTime = speed == ANIMATED and FADE_OUT_TIME or 0
    return fadeInTime, fadeOutTime
end

local function SetShouldntShow(speed)
    local fadeInTime, fadeOutTime = GetAnimationTimes(speed)
    g_holdingForFadeOut = false
    ACTION_BAR_FRAGMENT:SetHiddenForReason("ShouldntShow", true, fadeInTime, fadeOutTime)
    EVENT_MANAGER:UnregisterForUpdate("ZO_Contextual")
end

local function SetShouldntShowAnimated()
    SetShouldntShow(ANIMATED)
end

local function UpdateFadeState(speed)
    local fadeInTime, fadeOutTime = GetAnimationTimes(speed)
    if ShouldActionBarShow() then
        ACTION_BAR_FRAGMENT:SetHiddenForReason("ShouldntShow", false, fadeInTime, fadeOutTime)
        if(g_holdingForFadeOut) then
            g_holdingForFadeOut = false
            EVENT_MANAGER:UnregisterForUpdate("ZO_Contextual")
        end
    else
        --only wait to set the hidden reason if we're animating and the bar is actually showing
        if(speed == ANIMATED and not ACTION_BAR_FRAGMENT:IsHidden()) then
            if(not g_holdingForFadeOut) then
                g_holdingForFadeOut = true
                EVENT_MANAGER:RegisterForUpdate("ZO_Contextual", FADE_OUT_DELAY, SetShouldntShowAnimated)
            end
        else
            SetShouldntShow(INSTANT)
        end
    end
end

local function OnPlayerCombatState(eventCode, inCombat)
    if inCombat then
        ZO_ContextualActionBar_AddReference()
    else
        ZO_ContextualActionBar_RemoveReference()
    end
end

local function OnInterfaceSettingChanged(eventCode, settingType, settingId)
    if settingType == SETTING_TYPE_UI then
        if settingId == UI_SETTING_SHOW_ACTION_BAR then
            g_showActionBarSetting = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_ACTION_BAR))
            UpdateFadeState(INSTANT)
        end
    end
end

local function RefreshActionBarHasAnAction()
    local hadAnAction = g_actionBarHasAnAction
    g_actionBarHasAnAction = ZO_ActionBar_HasAnyActionSlotted()

    return hadAnAction ~= g_actionBarHasAnAction
end

local function RefreshHasValidTarget()
    local hadValidTarget = g_hasValidTarget
    g_hasValidTarget = false
    
    if(DoesUnitExist("reticleover")) then
        local reaction = GetUnitReaction("reticleover")
        if(IsUnitAttackable("reticleover") and reaction ~= UNIT_REACTION_NEUTRAL) then
            g_hasValidTarget = true
        else            
            if(reaction == UNIT_REACTION_FRIENDLY or reaction == UNIT_REACTION_PLAYER_ALLY or IsUnitFriendlyFollower("reticleover")) then
                local currentHealth, maxHealth = GetUnitPower("reticleover", POWERTYPE_HEALTH)
                if(currentHealth < maxHealth) then
                    g_hasValidTarget = true
                end
            end
        end
    end

    return (hadValidTarget ~= g_hasValidTarget)
end

local function OnReticleTargetChanged()
    if(RefreshHasValidTarget()) then
        UpdateFadeState(ANIMATED)
    end
end

local function OnPowerUpdate(eventCode, unitTag, powerIndex, powerType)
    if(RefreshHasValidTarget()) then
        UpdateFadeState(ANIMATED)
    end
end

local function OnSlotsUpdated()
    if(RefreshActionBarHasAnAction()) then
        UpdateFadeState(ANIMATED)
    end
end

function ZO_ContextualActionBar_OnMouseEnter()
    g_isMousedOver = true
    UpdateFadeState(ANIMATED)
end

function ZO_ContextualActionBar_OnUpdate(control)
    if g_isMousedOver and not MouseIsOver(control) then
        g_isMousedOver = false
        UpdateFadeState(ANIMATED)
    end
end

function ZO_ContextualActionBar_AddReference()
    g_actionBarReferences = g_actionBarReferences + 1
    UpdateFadeState(ANIMATED)
end

function ZO_ContextualActionBar_RemoveReference()
    g_actionBarReferences = g_actionBarReferences - 1
    UpdateFadeState(ANIMATED)
end

function ZO_ContextualActionBar_OnInitialized(self)
    CONTEXTUAL_ACTION_BAR_AREA_FRAGMENT = ZO_HUDFadeSceneFragment:New(self)
    ACTION_BAR_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_HIDING and g_holdingForFadeOut) then        
            SetShouldntShow(INSTANT)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("ZO_Contextual", EVENT_ACTION_SLOT_UPDATED, OnSlotsUpdated)
    EVENT_MANAGER:RegisterForEvent("ZO_Contextual", EVENT_ACTION_SLOTS_FULL_UPDATE, OnSlotsUpdated)
    EVENT_MANAGER:RegisterForEvent("ZO_Contextual", EVENT_PLAYER_ACTIVATED, OnSlotsUpdated)
    EVENT_MANAGER:RegisterForEvent("ZO_Contextual", EVENT_POWER_UPDATE, OnPowerUpdate)
    EVENT_MANAGER:AddFilterForEvent("ZO_Contextual", EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, POWERTYPE_HEALTH, REGISTER_FILTER_UNIT_TAG, "reticleover")
    EVENT_MANAGER:RegisterForEvent("ZO_Contextual", EVENT_RETICLE_TARGET_CHANGED, OnReticleTargetChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_Contextual", EVENT_PLAYER_COMBAT_STATE, OnPlayerCombatState)
    EVENT_MANAGER:RegisterForEvent("ZO_Contextual", EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)

    local function Initialize()
        RefreshHasValidTarget()
        ACTION_BAR_FRAGMENT:SetHiddenForReason("ShouldntShow", true)
        UpdateFadeState(INSTANT)
    end

    CALLBACK_MANAGER:RegisterCallback("UnitFramesCreated", Initialize)
end