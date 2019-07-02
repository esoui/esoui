--Uses ZO_SlotUtil.lua behavior

ABILITY_SLOT_TYPE_ACTIONBAR = 1
ABILITY_SLOT_TYPE_QUICKSLOT = 2

local USE_BASE_ABILITY = true

function ZO_ActionSlot_SetupSlot(iconControl, buttonControl, icon, normalFrame, downFrame, cooldownIconControl)
    iconControl:SetHidden(false)
    iconControl:SetTexture(icon)

    if cooldownIconControl then
        cooldownIconControl:SetTexture(icon)
    end

    buttonControl:SetNormalTexture(normalFrame)
    buttonControl:SetPressedTexture(downFrame)
end

function ZO_ActionSlot_ClearSlot(iconControl, buttonControl, normalFrame, downFrame, cooldownIconControl)
    iconControl:SetHidden(true)
    if cooldownIconControl then
        cooldownIconControl:SetHidden(true)
    end
    buttonControl:SetNormalTexture(normalFrame)
    buttonControl:SetPressedTexture(downFrame)
end

function ZO_ActionSlot_SetUnusable(iconControl, unusable, useDesaturation)
    if unusable then
        if useDesaturation
        then
            iconControl:SetDesaturation(1)
            iconControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            iconControl:SetDesaturation(0)
            iconControl:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
        end
    else
        iconControl:SetDesaturation(0)
        iconControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    end
end

local function TryPlaceAction(abilitySlot)
    if(GetCursorContentType() ~= MOUSE_CONTENT_EMPTY)
    then
        local button = ZO_ActionBar_GetButton(abilitySlot.slotNum)
        if button then
            local slotNum = button:GetSlot()
            ZO_ActionBar_AttemptPlacement(slotNum)
            return true
        end
    end
end

local function TryPlaceQuickslotAction(abilitySlot)
    if(GetCursorContentType() ~= MOUSE_CONTENT_EMPTY)
    then
        ZO_ActionBar_AttemptPlacement(abilitySlot.slotNum)
        return true
    end
end

local function TryPickupAction(abilitySlot)
    local lockedReason = GetActionBarLockedReason()
    if lockedReason == ACTION_BAR_LOCKED_REASON_COMBAT then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_RESPECRESULT", RESPEC_RESULT_IS_IN_COMBAT))
        return false
    elseif lockedReason == ACTION_BAR_LOCKED_REASON_NOT_RESPECCABLE then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_RESPECRESULT", RESPEC_RESULT_ACTIVE_HOTBAR_NOT_RESPECCABLE))
        return false
    end

    local button = ZO_ActionBar_GetButton(abilitySlot.slotNum)
    if button then
        local slotNum = button:GetSlot()
        ZO_ActionBar_AttemptPickup(slotNum)
        return true
    end
end

local function TryPickupQuickslotAction(abilitySlot)
    ZO_ActionBar_AttemptPickup(abilitySlot.slotNum)
    return true
end

local function ClearAbilitySlot(slotNum)
    local slotType = GetSlotType(slotNum)
    if(slotType == ACTION_TYPE_ITEM) then
        local soundCategory = GetSlotItemSound(slotNum) 
        if(soundCategory ~= ITEM_SOUND_CATEGORY_NONE) then
            PlayItemSound(soundCategory, ITEM_SOUND_ACTION_UNEQUIP)
        end
    end
    ClearSlot(slotNum) 
end

local function TryShowActionMenu(abilitySlot)
    local button = ZO_ActionBar_GetButton(abilitySlot.slotNum)
    if button then
        local slotNum = button:GetSlot()
        if IsSlotUsed(slotNum) and not IsSlotLocked(slotNum)
        then
            ClearMenu()
            AddMenuItem(GetString(SI_ABILITY_ACTION_CLEAR_SLOT), function() ClearAbilitySlot(slotNum) end)
            ShowMenu(abilitySlot)
            return true
        end
    end
end

local function TryShowQuickslotActionMenu(abilitySlot)
    if IsSlotUsed(abilitySlot.slotNum) and not IsSlotLocked(abilitySlot.slotNum)
    then
        ClearMenu()
        AddMenuItem(GetString(SI_ABILITY_ACTION_CLEAR_SLOT), function() ClearAbilitySlot(abilitySlot.slotNum) end)
        ShowMenu(abilitySlot)
        return true
    end
end

local AbilityClicked =
{
    [ABILITY_SLOT_TYPE_ACTIONBAR] =
    {
        [MOUSE_BUTTON_INDEX_LEFT] =
        {
            function(abilitySlot) 
                return TryPlaceAction(abilitySlot)
            end,
        },

        [MOUSE_BUTTON_INDEX_RIGHT] =
        {
            function(abilitySlot)
                return TryShowActionMenu(abilitySlot)
            end,
        },
    },
    [ABILITY_SLOT_TYPE_QUICKSLOT] =
    {
        [MOUSE_BUTTON_INDEX_LEFT] =
        {
            function(abilitySlot)
                return TryPlaceQuickslotAction(abilitySlot)
            end,
        },

        [MOUSE_BUTTON_INDEX_RIGHT] =
        {
            function(abilitySlot)
                return TryShowQuickslotActionMenu(abilitySlot)
            end,
        },
    }
}

function ZO_AbilitySlot_OnSlotClicked(abilitySlot, buttonId)
    return RunClickHandlers(AbilityClicked, abilitySlot, buttonId)
end

local function TryClearQuickslot(abilitySlot)
    if IsSlotUsed(abilitySlot.slotNum) and not IsSlotLocked(abilitySlot.slotNum) then
        ClearSlot(abilitySlot.slotNum)
        return true
    end
end

local AbilityDoubleClicked =
{
    [ABILITY_SLOT_TYPE_QUICKSLOT] =
    {
        [MOUSE_BUTTON_INDEX_LEFT] =
        {
            function(abilitySlot)
                return TryClearQuickslot(abilitySlot)
            end,
        },
    }
}

function ZO_AbilitySlot_OnSlotDoubleClicked(abilitySlot, buttonId)
    return RunClickHandlers(AbilityDoubleClicked, abilitySlot, buttonId)
end

local AbilityMouseUp =
{
}

function ZO_AbilitySlot_OnSlotMouseUp(abilitySlot, upInside, buttonId)
    return RunClickHandlers(AbilityMouseUp, abilitySlot, buttonId, upInside)
end

local AbilityMouseDown =
{
}

function ZO_AbilitySlot_OnSlotMouseDown(abilitySlot, buttonId)
    return RunClickHandlers(AbilityMouseDown, abilitySlot, buttonId)
end

local AbilityDragStart =
{
    [ABILITY_SLOT_TYPE_ACTIONBAR] =
    {
        function(abilitySlot)
            return TryPickupAction(abilitySlot)
        end,
    },
    [ABILITY_SLOT_TYPE_QUICKSLOT] =
    {
        function(abilitySlot)
            return TryPickupQuickslotAction(abilitySlot)
        end,
    },
}

function ZO_AbilitySlot_OnDragStart(abilitySlot, button)
    local t = GetCursorContentType()
    if(t ~= MOUSE_CONTENT_EMPTY) then
        return false
    end

    return RunHandlers(AbilityDragStart, abilitySlot, button)
end

local AbilityReceiveDrag =
{
    [ABILITY_SLOT_TYPE_ACTIONBAR] =
    {
        function(abilitySlot)
            return TryPlaceAction(abilitySlot)
        end,
    },
    [ABILITY_SLOT_TYPE_QUICKSLOT] =
    {
        function(abilitySlot)
            return TryPlaceQuickslotAction(abilitySlot)
        end,
    },
}

function ZO_AbilitySlot_OnReceiveDrag(abilitySlot, button)
    local t = GetCursorContentType()
    if(t == MOUSE_CONTENT_EMPTY) then
        return
    end

    return RunHandlers(AbilityReceiveDrag, abilitySlot, button)
end

local function AbilitySlotTooltipBaseInitialize(abilitySlot, tooltip, owner)
    abilitySlot.activeTooltip = tooltip
    InitializeTooltip(tooltip, owner, BOTTOM, 0, -5, TOP)
end

local function SetTooltipToActionBarSlot(tooltip, slot)
    local slotType = GetSlotType(slot)

    if slotType ~= ACTION_TYPE_NOTHING then
        tooltip:SetAction(slot)
        return true
    end
    return false
end

local function TryShowActionBarTooltip(abilitySlot)
    local button = ZO_ActionBar_GetButton(abilitySlot.slotNum)
    if button then
        local actionSlotIndex = button:GetSlot()
        local slotData = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():GetSlotData(actionSlotIndex)
        if slotData then
            -- This is an ability, use the slotData tooltip
            if abilitySlot.activeTooltip then
                ClearTooltip(abilitySlot.activeTooltip)
                abilitySlot.activeTooltip = nil
            end

            local tooltip = slotData:GetKeyboardTooltipControl()
            if tooltip then
                AbilitySlotTooltipBaseInitialize(abilitySlot, tooltip, abilitySlot)
                slotData:SetKeyboardTooltip(tooltip)
            end
        else
            -- this is a quickslot, use the quickslot path
            if GetSlotType(actionSlotIndex) ~= ACTION_TYPE_NOTHING then
                AbilitySlotTooltipBaseInitialize(abilitySlot, ItemTooltip, abilitySlot)
                return SetTooltipToActionBarSlot(ItemTooltip, actionSlotIndex)
            else
                ClearTooltip(ItemTooltip)
            end
        end
    end
end

local function TryShowQuickslotTooltip(abilitySlot, tooltip, owner)
    if GetSlotType(abilitySlot.slotNum) ~= ACTION_TYPE_NOTHING then
        AbilitySlotTooltipBaseInitialize(abilitySlot, tooltip, owner)
        return SetTooltipToActionBarSlot(tooltip, abilitySlot.slotNum)
    else
        ClearTooltip(tooltip)
    end
end

local AbilityEnter =
{
    [ABILITY_SLOT_TYPE_ACTIONBAR] =
    {
        function(abilitySlot)
            return TryShowActionBarTooltip(abilitySlot)
        end,
    },
    [ABILITY_SLOT_TYPE_QUICKSLOT] =
    {
        function(abilitySlot)
            ZO_QuickslotControl_OnMouseEnter(abilitySlot)
            return TryShowQuickslotTooltip(abilitySlot, ItemTooltip, abilitySlot)
        end,
    },
}

function ZO_AbilitySlot_OnMouseEnter(abilitySlot)
    RunHandlers(AbilityEnter, abilitySlot)
end

local AbilityExit =
{
    [ABILITY_SLOT_TYPE_QUICKSLOT] =
    {
        function(abilitySlot)
            ZO_QuickslotControl_OnMouseExit(abilitySlot)
        end,
    },
}

function ZO_AbilitySlot_OnMouseExit(abilitySlot)
    if(abilitySlot.activeTooltip) then
        ClearTooltip(abilitySlot.activeTooltip)
    end

    abilitySlot.activeTooltip = nil

    RunHandlers(AbilityExit, abilitySlot)
end