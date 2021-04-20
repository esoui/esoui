local g_actionBarButtons = {}
local g_backBarSlots = {}
local g_companionUltimateButton
local g_quickslotButton
local g_showHiddenButtonsRefCount = 1
local g_actionBarActiveWeaponPair
local g_activeWeaponSwapInProgress = false
local g_activeHotbar = HOTBAR_CATEGORY_PRIMARY
local g_backHotbar = HOTBAR_CATEGORY_BACKUP
local MINIMUM_ACTION_BAR_TIMER_DISPLAYED_TIME_MS = 1000

local function GetRemappedActionSlotNum(slotNum)
    if slotNum > ACTION_BAR_FIRST_UTILITY_BAR_SLOT and slotNum <= ACTION_BAR_FIRST_UTILITY_BAR_SLOT + ACTION_BAR_UTILITY_BAR_SIZE then
        return ACTION_BAR_FIRST_UTILITY_BAR_SLOT + 1
    else
        return slotNum
    end
end

function ZO_ActionBar_HasAnyActionSlotted()
    for physicalSlot in pairs(g_actionBarButtons) do
        if GetSlotType(physicalSlot) ~= ACTION_TYPE_NOTHING then
            return true
        end
    end
    return false
end

function ZO_ActionBar_GetButton(slotNum, hotbarCategory)
    local remappedSlotNum = GetRemappedActionSlotNum(slotNum)
    if hotbarCategory == HOTBAR_CATEGORY_COMPANION and slotNum == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
        return g_companionUltimateButton
    elseif hotbarCategory == g_backHotbar then
        return g_backBarSlots[remappedSlotNum]
    else
        return g_actionBarButtons[remappedSlotNum]
    end
end

function ZO_ActionBar_CanUseActionSlots()
    return (not (IsGameCameraActive() or IsInteractionCameraActive() or IsProgrammableCameraActive()) or SCENE_MANAGER:IsShowing("hud")) and not IsUnitDead("player")
end

function ZO_ActionBar_OnActionButtonDown(slotNum)
    local button = ZO_ActionBar_GetButton(slotNum)
    if button then
        button:OnPress()
    end
end

function ZO_ActionBar_OnActionButtonUp(slotNum)
    local button = ZO_ActionBar_GetButton(slotNum)
    if button then
        button:OnRelease()
    end
end

function AreActionBarsLocked()
    return GetSetting_Bool(SETTING_TYPE_ACTION_BARS, ACTION_BAR_SETTING_LOCK_ACTION_BARS)
end

function ZO_ActionBar_AreHiddenButtonsShowing()
    return (g_showHiddenButtonsRefCount > 0)
end

function ZO_ActionBar_AttemptPlacement(slotNum)
    PlaceInActionBar(slotNum)   -- Fails and shows an error if the button is locked
end

function ZO_ActionBar_AttemptPickup(slotNum)
    if AreActionBarsLocked() then
        return
    end

    PickupAction(slotNum)   -- Fails and shows an error if the button is locked
    ClearTooltip(AbilityTooltip)
end

local function OnPowerUpdate(evt, unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
    g_actionBarButtons[ACTION_BAR_ULTIMATE_SLOT_INDEX + 1]:SetUltimateMeter(powerPool)
end

local function OnCompanionPowerUpdate(evt, unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
    g_companionUltimateButton:SetUltimateMeter(powerPool)
end

local function OnItemSlotChanged(eventCode, itemSoundCategory)
    PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_SLOT)
end

local function HandleSlotChanged(slotNum, hotbarCategory)
    local btn = ZO_ActionBar_GetButton(slotNum, hotbarCategory)
    if btn and not btn.noUpdates then
        if hotbarCategory == HOTBAR_CATEGORY_COMPANION then
            if not DoesUnitExist("companion") or not HasActiveCompanion() then
                btn:SetEnabled(false)
                return
            else
                btn:SetEnabled(true)
            end
        end

        btn:HandleSlotChanged(hotbarCategory)
        local isBackBarSlot = hotbarCategory == g_backHotbar
        local buttonTemplate
        if slotNum == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
            buttonTemplate = isBackBarSlot and ZO_GetPlatformTemplate("ZO_ActionBarTimer_BackBarSlot_Ultimate") or ZO_GetPlatformTemplate("ZO_UltimateActionButton")
            if not isBackBarSlot then
                btn:UpdateUltimateMeter()
            end
        else
            buttonTemplate = isBackBarSlot and ZO_GetPlatformTemplate("ZO_ActionBarTimer_BackBarSlot") or ZO_GetPlatformTemplate("ZO_ActionButton")
        end
        btn:ApplyStyle(buttonTemplate)
    end
end

local function HandleHotbarStateChanged(_, slotNum, hotbarCategory)
    if hotbarCategory ~= g_backHotbar then
        local btn = ZO_ActionBar_GetButton(slotNum, hotbarCategory)
        if btn and not btn.noUpdates then
            btn:UpdateState()
        end
    end
end

local function HandleAbilityUsed(slotNum)
    local btn = ZO_ActionBar_GetButton(slotNum)
    if btn and IsInGamepadPreferredMode() then
        btn:PlayAbilityUsedBounce()
    end
end

local function UpdateCooldowns()
    for i, button in pairs(g_actionBarButtons) do
        button:UpdateCooldown()
    end
    g_companionUltimateButton:UpdateCooldown()
end

local function MakeActionButton(slotNum, buttonStyle, buttonClass)
    local button
    if buttonStyle.isBackBar then
        button = buttonClass:New(slotNum, buttonStyle.parentBar, buttonStyle.template, g_backHotbar)
        g_backBarSlots[slotNum] = button
    elseif buttonStyle.isCompanion then
        button = buttonClass:New(slotNum, buttonStyle.type, buttonStyle.parentBar, buttonStyle.template, HOTBAR_CATEGORY_COMPANION)
        button:SetShowBindingText(buttonStyle.showBinds)
        g_companionUltimateButton = button
    else
        button = buttonClass:New(slotNum, buttonStyle.type, buttonStyle.parentBar, buttonStyle.template)
        button:SetShowBindingText(buttonStyle.showBinds)
        g_actionBarButtons[slotNum] = button
    end

    return button
end

local function HandleInventoryChanged(eventCode, bag, slot)
    for _, physicalSlot in pairs(g_actionBarButtons) do
        if physicalSlot then
            local slotType = GetSlotType(physicalSlot:GetSlot())
            if slotType == ACTION_TYPE_ITEM then
                physicalSlot:SetupCount()
                physicalSlot:UpdateState()
            elseif slotType == ACTION_TYPE_ABILITY then
                physicalSlot:UpdateState()
            end
        end
    end
end

local function ShowHiddenButtons()
    g_showHiddenButtonsRefCount = g_showHiddenButtonsRefCount + 1
    if g_showHiddenButtonsRefCount == 1 then
        for _, control in pairs(g_actionBarButtons) do
            if control:GetButtonType() == ACTION_BUTTON_TYPE_HIDDEN then
                control.slot:SetHidden(false)
            end
        end
    end
end

local function HideHiddenButtons()
    g_showHiddenButtonsRefCount = g_showHiddenButtonsRefCount - 1
    if g_showHiddenButtonsRefCount == 0 then
        for _, control in pairs(g_actionBarButtons) do
            if control:GetButtonType() == ACTION_BUTTON_TYPE_HIDDEN then
                if not control:HasAction() then
                    control.slot:SetHidden(true)
                end
            end
        end
    end
end

local function HideAllAbilityActionButtonDropCallouts()
    for i = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 do
        local callout = ZO_ActionBar_GetButton(i).slot:GetNamedChild("DropCallout")
        callout:SetHidden(true)
    end
end

local function ShowAppropriateAbilityActionButtonDropCallouts(abilityIndex)
    HideAllAbilityActionButtonDropCallouts()

    for i = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 do
        local isValid = IsValidAbilityForSlot(abilityIndex, i)
        local callout = ZO_ActionBar_GetButton(i).slot:GetNamedChild("DropCallout")

        if not isValid then
            callout:SetColor(1, 0, 0, 1)
        else
            callout:SetColor(1, 1, 1, 1)
        end

        callout:SetHidden(false)
    end
end

local function HandleCursorPickup(eventCode, cursorType, param1, param2, param3)
    if cursorType == MOUSE_CONTENT_ACTION or cursorType == MOUSE_CONTENT_INVENTORY_ITEM or cursorType == MOUSE_CONTENT_QUEST_ITEM or cursorType == MOUSE_CONTENT_QUEST_TOOL then
        ShowHiddenButtons()
    end

    if cursorType == MOUSE_CONTENT_ACTION and param1 == ACTION_TYPE_ABILITY then
        ShowAppropriateAbilityActionButtonDropCallouts(param3)
    end
end

local function HandleCursorDropped(eventCode, cursorType)
    if cursorType == MOUSE_CONTENT_ACTION or cursorType == MOUSE_CONTENT_INVENTORY_ITEM or cursorType == MOUSE_CONTENT_QUEST_ITEM or cursorType == MOUSE_CONTENT_QUEST_TOOL then
        HideHiddenButtons()
    end

    if cursorType == MOUSE_CONTENT_ACTION then
        HideAllAbilityActionButtonDropCallouts()
    end
end

local function OnActiveQuickslotChanged(eventCode, actionSlotIndex)
    HandleSlotChanged(ACTION_BAR_FIRST_UTILITY_BAR_SLOT + 1)
end

local function OnCollectionUpdated()
    local quickslot = ACTION_BAR_FIRST_UTILITY_BAR_SLOT + 1
    local button = ZO_ActionBar_GetButton(quickslot)
    if button then
        local slotId = button:GetSlot()
        if ZO_QuickslotRadialManager:ValidateOrClearQuickslot(slotId) then
            HandleSlotChanged(quickslot)
        end
    end
end

local function OnActionSlotEffectsCleared(event)
    for _, physicalSlot in pairs(g_backBarSlots) do
        physicalSlot:SetFillBar(0, 0)
    end
    for _, physicalSlot in pairs(g_actionBarButtons) do
        physicalSlot:SetTimer(0)
    end
end

local function OnActionSlotEffectUpdated(_, hotbarCategory, slotId)
    local isBackBarSlot = hotbarCategory == g_backHotbar
    local physicalSlot = ZO_ActionBar_GetButton(slotId, hotbarCategory)
    if physicalSlot then
        if isBackBarSlot then
            local timeRemainingMS = GetActionSlotEffectTimeRemaining(physicalSlot:GetSlot(), g_backHotbar)
            if timeRemainingMS > MINIMUM_ACTION_BAR_TIMER_DISPLAYED_TIME_MS then
                local durationMS = GetActionSlotEffectDuration(physicalSlot:GetSlot(), g_backHotbar)
                physicalSlot:SetFillBar(timeRemainingMS, durationMS)
            end
        else
            local timeRemainingMS = GetActionSlotEffectTimeRemaining(physicalSlot:GetSlot(), hotbarCategory)
            if timeRemainingMS > MINIMUM_ACTION_BAR_TIMER_DISPLAYED_TIME_MS then
                physicalSlot:SetTimer(timeRemainingMS)
            end
        end
    end
end

local function UpdateAllSlots(eventCode)
    for physicalSlotNum in pairs(g_actionBarButtons) do
        HandleSlotChanged(physicalSlotNum)
        OnActionSlotEffectUpdated(nil, g_activeHotbar, physicalSlotNum)
    end
    
    for physicalSlotNum in pairs(g_backBarSlots) do
        HandleSlotChanged(physicalSlotNum, g_backHotbar)
        OnActionSlotEffectUpdated(nil, g_backHotbar, physicalSlotNum)
    end

    HandleSlotChanged(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, HOTBAR_CATEGORY_COMPANION)
    OnActionSlotEffectUpdated(nil, HOTBAR_CATEGORY_COMPANION, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1)
end

local function OnPlayerActivated(eventCode)
    UpdateAllSlots()
    HideAllAbilityActionButtonDropCallouts()
end

local function OnActiveWeaponPairChanged(eventCode, activeWeaponPair)
    if activeWeaponPair ~= g_actionBarActiveWeaponPair then
        g_activeWeaponSwapInProgress = true
        g_actionBarButtons[ACTION_BAR_ULTIMATE_SLOT_INDEX + 1]:UpdateUltimateMeter()
        g_actionBarActiveWeaponPair = activeWeaponPair
    end
end

local function OnCurrentHotbarUpdated(currentHotbarCategory)
    g_activeHotbar = currentHotbarCategory
    if g_activeHotbar == HOTBAR_CATEGORY_PRIMARY or g_activeHotbar == HOTBAR_CATEGORY_BACKUP then
        if g_activeHotbar == HOTBAR_CATEGORY_PRIMARY then
            g_backHotbar = HOTBAR_CATEGORY_BACKUP
        else
            g_backHotbar = HOTBAR_CATEGORY_PRIMARY
        end
        for _, physicalSlot in pairs(g_backBarSlots) do
            physicalSlot:SetActive(true)
        end
    else
        for _, physicalSlot in pairs(g_backBarSlots) do
            physicalSlot:SetActive(false)
        end
    end
end

local GAMEPAD_CONSTANTS =
{
    abilitySlotOffsetX = 10,
    ultimateSlotOffsetX = 65,
    companionUltimateSlotOffsetX = 45,
    backRowSlotOffsetY = -20,
    backRowUltimateSlotOffsetY = -30,
    anchor = ZO_Anchor:New(BOTTOM, GuiRoot, BOTTOM, 0, -25),
    width = 606,
    showNormalBindingTextOnUltimate = false,
    showKeybindBG = false,
    showWeaponSwapButton = false,
    weaponSwapOffsetY = 4,

}

local KEYBOARD_CONSTANTS =
{
    abilitySlotOffsetX = 2,
    ultimateSlotOffsetX = 62,
    companionUltimateSlotOffsetX = 12,
    backRowSlotOffsetY = -20,
    backRowUltimateSlotOffsetY = -20,
    anchor = ZO_Anchor:New(BOTTOM, GuiRoot, BOTTOM, 0, 0),
    width = 483,
    showNormalBindingTextOnUltimate = true,
    showKeybindBG = true,
    showWeaponSwapButton = true,
    weaponSwapOffsetY = -4,
}

local function GetPlatformConstants()
    return IsInGamepadPreferredMode() and GAMEPAD_CONSTANTS or KEYBOARD_CONSTANTS
end

function ZO_ActionBar_GetAnchor()
    local constants = GetPlatformConstants()
    return constants.anchor
end

local function SetCompanionAnchors()
    g_quickslotButton.slot:SetAnchor(RIGHT, ZO_ActionBar1WeaponSwap, LEFT, -5, 0)
    if not DoesUnitExist("companion") or not HasActiveCompanion() then
        g_companionUltimateButton:SetEnabled(false)
    else
        g_companionUltimateButton:SetEnabled(true)
        if IsInGamepadPreferredMode() then
            g_quickslotButton.slot:SetAnchor(RIGHT, ZO_ActionBar_GetButton(ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1).slot, LEFT, -25, 0)
        end
    end
end

local function HandleCompanionStateChanged()
    HandleSlotChanged(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, HOTBAR_CATEGORY_COMPANION)
    SetCompanionAnchors()
end

local function ApplyStyle(style)
    ZO_ActionBar1:ClearAnchors()
    style.anchor:Set(ZO_ActionBar1)
    ZO_ActionBar1:SetWidth(style.width)

    local lastButton
    local buttonTemplate = ZO_GetPlatformTemplate("ZO_ActionButton")
    local backBarButtonTemplate = ZO_GetPlatformTemplate("ZO_ActionBarTimer_BackBarSlot")
    for physicalSlot, button in pairs(g_actionBarButtons) do
        if button then
            button:ApplyStyle(buttonTemplate)
            if physicalSlot > ACTION_BAR_FIRST_NORMAL_SLOT_INDEX and physicalSlot < ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + ACTION_BAR_SLOTS_PER_PAGE then
                local anchorTarget = lastButton and lastButton.slot
                if not lastButton then
                    local yOffset = GetPlatformConstants().weaponSwapOffsetY
                    ZO_ActionBar1WeaponSwap:SetAnchor(TOPLEFT, nil, TOPLEFT, 55, yOffset)
                    anchorTarget = ZO_ActionBar1WeaponSwap
                end
                button:ApplyAnchor(anchorTarget, style.abilitySlotOffsetX)

                local backBarButton = g_backBarSlots[physicalSlot]
                if backBarButton then
                    backBarButton:ApplyStyle(backBarButtonTemplate)
                    backBarButton:ApplyAnchor(button.slot, style.backRowSlotOffsetY)
                end
                lastButton = button
            elseif physicalSlot == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
                button:ApplyStyle(ZO_GetPlatformTemplate("ZO_UltimateActionButton"))
                button:SetShowBindingText(style.showNormalBindingTextOnUltimate)
                button:ApplyAnchor(g_actionBarButtons[ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + ACTION_BAR_SLOTS_PER_PAGE - 1].slot, style.ultimateSlotOffsetX)
                button:UpdateUltimateMeter()

                local backBarButton = g_backBarSlots[physicalSlot]
                if backBarButton then
                    backBarButton:ApplyStyle(ZO_GetPlatformTemplate("ZO_ActionBarTimer_BackBarSlot_Ultimate"))
                    backBarButton:ApplyAnchor(button.slot, style.backRowUltimateSlotOffsetY)
                end

                g_companionUltimateButton:ApplyStyle(ZO_GetPlatformTemplate("ZO_UltimateActionButton"))
                g_companionUltimateButton:SetShowBindingText(style.showNormalBindingTextOnUltimate)
                local IS_ANCHORED_LEFT = true
                g_companionUltimateButton:ApplyAnchor(g_quickslotButton.slot, style.companionUltimateSlotOffsetX, IS_ANCHORED_LEFT)
                g_companionUltimateButton:UpdateUltimateMeter()
                SetCompanionAnchors()
            end
        end
    end

    ZO_ActionBar1:GetNamedChild("KeybindBG"):SetHidden(not style.showKeybindBG)
    ZO_WeaponSwap_SetPermanentlyHidden(ZO_ActionBar1:GetNamedChild("WeaponSwap"), not style.showWeaponSwapButton)
end

function ZO_ActionBar_OnInitialized(control)
    local weaponSwap = control:GetNamedChild("WeaponSwap")
    local yOffset = GetPlatformConstants().weaponSwapOffsetY
    weaponSwap:SetAnchor(TOPLEFT, nil, TOPLEFT, 55, yOffset)

    local MAIN_BAR_STYLE =
    {
        type = ACTION_BUTTON_TYPE_VISIBLE,
        template = "ZO_ActionButton",
        showBinds = true,
        parentBar = control,
    }

    --Quick Bar Slot
    g_quickslotButton = MakeActionButton(ACTION_BAR_FIRST_UTILITY_BAR_SLOT + 1, MAIN_BAR_STYLE, QuickslotActionButton)
    g_quickslotButton:SetupBounceAnimation()

    local function OnSwapAnimationHalfDone(animation, button, isBackBarSlot)
        --Main hotbar buttons' HandleSlotChanged does not take a parameter, therefore we can always pass g_backHotbar for back row's use
        button:HandleSlotChanged(g_backHotbar)

        if not isBackBarSlot then
            if button:GetSlot() == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
                button:UpdateUltimateMeter()
            end
            local timeRemainingMS = GetActionSlotEffectTimeRemaining(button:GetSlot(), g_activeHotbar)
            button:SetTimer(timeRemainingMS)
        else
            local timeRemainingMS = GetActionSlotEffectTimeRemaining(button:GetSlot(), g_backHotbar)
            local durationMS = GetActionSlotEffectDuration(button:GetSlot(), g_backHotbar)
            button:SetFillBar(timeRemainingMS, durationMS)
        end
    end

    local function OnSwapAnimationDone(animation, button)
        button.noUpdates = false
        if button:GetSlot() == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
            g_activeWeaponSwapInProgress = false
        end
    end

    local function SetupSwapAnimation(button)
        button:SetupSwapAnimation(OnSwapAnimationHalfDone, OnSwapAnimationDone)
    end

    --Main Bar
    for i = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + ACTION_BAR_SLOTS_PER_PAGE - 1 do
        local barButton = MakeActionButton(i, MAIN_BAR_STYLE, ActionButton)
        SetupSwapAnimation(barButton)
        barButton:SetupBounceAnimation()
        barButton:SetupTimerSwapAnimation()
    end

    local ULTIMATE_BUTTON_STYLE =
    {
        type = ACTION_BUTTON_TYPE_VISIBLE,
        template = "ZO_UltimateActionButton",
        showBinds = true,
        parentBar = control,
    }

    --Ultimate Button
    local ultimateButton = MakeActionButton(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, ULTIMATE_BUTTON_STYLE, ActionButton)
    SetupSwapAnimation(ultimateButton)
    ultimateButton:SetupBounceAnimation()
    ultimateButton:SetupKeySlideAnimation()
    ultimateButton:SetupTimerSwapAnimation()

    ultimateButton:UpdateUltimateMeter()

    local COMPANION_ULTIMATE_BUTTON_STYLE =
    {
        type = ACTION_BUTTON_TYPE_VISIBLE,
        template = "ZO_UltimateActionButton",
        showBinds = true,
        parentBar = control,
        isCompanion = true,
    }

    --Companion Ultimate Button
    local companionUltimateButton = MakeActionButton(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, COMPANION_ULTIMATE_BUTTON_STYLE, ActionButton)
    companionUltimateButton:SetupBounceAnimation()
    companionUltimateButton:SetupKeySlideAnimation()
    companionUltimateButton:SetupTimerSwapAnimation()

    companionUltimateButton:UpdateUltimateMeter()
    SetCompanionAnchors()

    local BACK_BAR_STYLE =
    {
        template = "ZO_ActionBarTimer_BackBarSlot",
        parentBar = control,
        isBackBar = true,
    }

    --Back Bar
    for i = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + ACTION_BAR_SLOTS_PER_PAGE - 1 do
        local backBarButton = MakeActionButton(i, BACK_BAR_STYLE, ZO_ActionBarTimer)
        SetupSwapAnimation(backBarButton)
    end

    local BACK_BAR_ULTIMATE_STYLE =
    {
        template = "ZO_ActionBarTimer_BackBarSlot_Ultimate",
        parentBar = control,
        isBackBar = true,
    }

    --Back Bar Ultimate
    local ultimateBackBarButton = MakeActionButton(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, BACK_BAR_ULTIMATE_STYLE, ZO_ActionBarTimer)
    SetupSwapAnimation(ultimateBackBarButton)

    local function PlayBackBarSwapAnimation(physicalSlot)
        local style = GetPlatformConstants()
        local offsetY
        if physicalSlot:GetSlot() == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
            offsetY = style.backRowUltimateSlotOffsetY
        else
            offsetY = style.backRowSlotOffsetY
        end

        physicalSlot:ApplySwapAnimationStyle(offsetY)

        physicalSlot.backBarSwapAnimation:PlayFromStart()
    end

    local function OnActiveHotbarUpdated(event, didActiveHotbarChange)
        if didActiveHotbarChange then
            for _, physicalSlot in pairs(g_actionBarButtons) do
                if physicalSlot.hotbarSwapAnimation then
                    physicalSlot.noUpdates = true
                    physicalSlot.hotbarSwapAnimation:PlayFromStart()
                    physicalSlot.timerSwapAnimation:PlayFromStart()
                end
            end
            for _, physicalSlot in pairs(g_backBarSlots) do
                if physicalSlot.backBarSwapAnimation then
                    physicalSlot.noUpdates = true
                    PlayBackBarSwapAnimation(physicalSlot)
                end
            end
        else
            g_activeWeaponSwapInProgress = false
            UpdateAllSlots()
        end
    end

    local function OnAllHotbarsUpdated(event)
        g_activeWeaponSwapInProgress = false
        UpdateAllSlots()
    end

    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_HOTBAR_SLOT_UPDATED, function(...) HandleSlotChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_HOTBAR_SLOT_STATE_UPDATED, function (...) HandleHotbarStateChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_ACTIVE_COMPANION_STATE_CHANGED, function() HandleCompanionStateChanged() end)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, OnActiveHotbarUpdated)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, OnAllHotbarsUpdated)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_ACTION_SLOT_ABILITY_USED, function (_, slotnum) HandleAbilityUsed(slotnum) end)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_ACTION_UPDATE_COOLDOWNS, UpdateCooldowns)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_INVENTORY_FULL_UPDATE, HandleInventoryChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleInventoryChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_OPEN_BANK, HandleInventoryChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_CLOSE_BANK, HandleInventoryChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_CURSOR_PICKUP, HandleCursorPickup)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_CURSOR_DROPPED, HandleCursorDropped)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_POWER_UPDATE, OnPowerUpdate)
    EVENT_MANAGER:AddFilterForEvent("ZO_ActionBar", EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, POWERTYPE_ULTIMATE, REGISTER_FILTER_UNIT_TAG, "player")
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBarCompanion", EVENT_POWER_UPDATE, OnCompanionPowerUpdate)
    EVENT_MANAGER:AddFilterForEvent("ZO_ActionBarCompanion", EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, POWERTYPE_ULTIMATE, REGISTER_FILTER_UNIT_TAG, "companion")
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_ITEM_SLOT_CHANGED, OnItemSlotChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_ACTIVE_QUICKSLOT_CHANGED, OnActiveQuickslotChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnActiveWeaponPairChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_ACTION_SLOT_EFFECT_UPDATE, OnActionSlotEffectUpdated)
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBar", EVENT_ACTION_SLOT_EFFECTS_CLEARED, OnActionSlotEffectsCleared)
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", OnCurrentHotbarUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)

    ZO_PlatformStyle:New(ApplyStyle, KEYBOARD_CONSTANTS, GAMEPAD_CONSTANTS)

    HideHiddenButtons()

    ACTION_BAR_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)
end