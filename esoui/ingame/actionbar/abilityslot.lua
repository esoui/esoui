--Uses ZO_SlotUtil.lua behavior

ABILITY_SLOT_TYPE_ACTIONBAR = 1
ABILITY_SLOT_TYPE_UTILITY = 2

local USE_BASE_ABILITY = true

function ZO_ActionSlot_SetupSlot(iconControl, buttonControl, icon, normalFrame, downFrame, cooldownIconControl, mouseOverTexture)
    iconControl:SetHidden(false)
    iconControl:SetTexture(icon)

    if cooldownIconControl then
        cooldownIconControl:SetTexture(icon)
    end

    if mouseOverTexture then
        buttonControl:SetMouseOverTexture(mouseOverTexture)
    end

    buttonControl:SetNormalTexture(normalFrame)
    buttonControl:SetPressedTexture(downFrame)
end

function ZO_ActionSlot_ClearSlot(iconControl, buttonControl, normalFrame, downFrame, cooldownIconControl, mouseOverTexture)
    iconControl:SetHidden(true)
    if cooldownIconControl then
        cooldownIconControl:SetHidden(true)
    end

    if mouseOverTexture then
        buttonControl:SetMouseOverTexture(mouseOverTexture)
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

local function TryPlaceUtilitySlotAction(utilitySlot)
    if GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
        ZO_ActionBar_AttemptPlacement(utilitySlot.slotNum, utilitySlot.object:GetHotbarCategory())
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

    if abilitySlot.hotbarCategory ~= HOTBAR_CATEGORY_COMPANION then
        local button = ZO_ActionBar_GetButton(abilitySlot.slotNum, abilitySlot.hotbarCategory)
        if button then
            local slotNum = button:GetSlot()
            ZO_ActionBar_AttemptPickup(slotNum, abilitySlot.hotbarCategory)
            return true
        end
    end
end

local function TryPickupUtilitySlotAction(utilitySlot)
    ZO_ActionBar_AttemptPickup(utilitySlot.slotNum, utilitySlot.object:GetHotbarCategory())
    return true
end

local function ClearAbilitySlot(slotNum, hotbarCategory)
    local slotType = GetSlotType(slotNum, hotbarCategory)
    if slotType == ACTION_TYPE_ITEM then
        local soundCategory = GetSlotItemSound(slotNum, hotbarCategory)
        if soundCategory ~= ITEM_SOUND_CATEGORY_NONE then
            PlayItemSound(soundCategory, ITEM_SOUND_ACTION_UNEQUIP)
        end
    end
    ClearSlot(slotNum, hotbarCategory)
end

local function TryShowActionMenu(abilitySlot)
    if abilitySlot.hotbarCategory ~= HOTBAR_CATEGORY_COMPANION then
        local button = ZO_ActionBar_GetButton(abilitySlot.slotNum, abilitySlot.hotbarCategory)
        if button then
            local slotNum = button:GetSlot()
            if IsSlotUsed(slotNum, abilitySlot.hotbarCategory) and not IsActionSlotRestricted(slotNum, abilitySlot.hotbarCategory) then
                ClearMenu()
                AddMenuItem(GetString(SI_ABILITY_ACTION_CLEAR_SLOT), function() ClearAbilitySlot(slotNum, abilitySlot.hotbarCategory) end)
                ShowMenu(abilitySlot)
                return true
            end
        end
    end
end

local function TryShowUtilitySlotActionMenu(utilitySlot)
    local hotbarCategory = utilitySlot.object:GetHotbarCategory()
    if IsSlotUsed(utilitySlot.slotNum, hotbarCategory) and not IsActionSlotRestricted(utilitySlot.slotNum, hotbarCategory) then
        ClearMenu()
        AddMenuItem(GetString(SI_ABILITY_ACTION_CLEAR_SLOT), function() ClearAbilitySlot(utilitySlot.slotNum, hotbarCategory) end)
        ShowMenu(utilitySlot)
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
    [ABILITY_SLOT_TYPE_UTILITY] =
    {
        [MOUSE_BUTTON_INDEX_LEFT] =
        {
            function(utilitySlot)
                return TryPlaceUtilitySlotAction(utilitySlot)
            end,
        },

        [MOUSE_BUTTON_INDEX_RIGHT] =
        {
            function(utilitySlot)
                return TryShowUtilitySlotActionMenu(utilitySlot)
            end,
        },
    }
}

function ZO_AbilitySlot_OnSlotClicked(abilitySlot, buttonId)
    return RunClickHandlers(AbilityClicked, abilitySlot, buttonId)
end

local function TryClearUtilitySlot(utilitySlot)
    local hotbarCategory = utilitySlot.object:GetHotbarCategory()
    if IsSlotUsed(utilitySlot.slotNum, hotbarCategory) and not IsActionSlotRestricted(utilitySlot.slotNum, hotbarCategory) then
        ClearSlot(utilitySlot.slotNum, hotbarCategory)
        return true
    end
end

local AbilityDoubleClicked =
{
    [ABILITY_SLOT_TYPE_UTILITY] =
    {
        [MOUSE_BUTTON_INDEX_LEFT] =
        {
            function(utilitySlot)
                return TryClearUtilitySlot(utilitySlot)
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
    [ABILITY_SLOT_TYPE_UTILITY] =
    {
        function(utilitySlot)
            return TryPickupUtilitySlotAction(utilitySlot)
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
    [ABILITY_SLOT_TYPE_UTILITY] =
    {
        function(utilitySlot)
            return TryPlaceUtilitySlotAction(utilitySlot)
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

local function SetTooltipToActionBarSlot(tooltip, slotIndex, hotbarCategory)
    local slotType = GetSlotType(slotIndex, hotbarCategory)

    if slotType ~= ACTION_TYPE_NOTHING then
        tooltip:SetAction(slotIndex, hotbarCategory)
        return true
    end
    return false
end

local function TryShowActionBarTooltip(abilitySlot)
    local button = ZO_ActionBar_GetButton(abilitySlot.slotNum, abilitySlot.hotbarCategory)
    if button then
        local actionSlotIndex = button:GetSlot()
        if abilitySlot.hotbarCategory == HOTBAR_CATEGORY_QUICKSLOT_WHEEL then
            --this is a quickslot, use the quickslot path
            if GetSlotType(actionSlotIndex, abilitySlot.hotbarCategory) ~= ACTION_TYPE_NOTHING then
                AbilitySlotTooltipBaseInitialize(abilitySlot, ItemTooltip, abilitySlot)
                return SetTooltipToActionBarSlot(ItemTooltip, actionSlotIndex, abilitySlot.hotbarCategory)
            else
                ClearTooltip(ItemTooltip)
            end
        else
            local hotbar = abilitySlot.hotbarCategory and ACTION_BAR_ASSIGNMENT_MANAGER:GetHotbar(abilitySlot.hotbarCategory) or ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
            local slotData = hotbar:GetSlotData(actionSlotIndex)
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
            end
        end
    end
end

local function TryShowUtilitySlotTooltip(utilitySlot, tooltip, owner)
    local hotbarCategory = utilitySlot.object:GetHotbarCategory()
    if GetSlotType(utilitySlot.slotNum, hotbarCategory) ~= ACTION_TYPE_NOTHING then
        AbilitySlotTooltipBaseInitialize(utilitySlot, tooltip, owner)
        return SetTooltipToActionBarSlot(tooltip, utilitySlot.slotNum, hotbarCategory)
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
    [ABILITY_SLOT_TYPE_UTILITY] =
    {
        function(utilitySlot)
            utilitySlot.object:OnMouseOverUtilitySlot(utilitySlot)
            return TryShowUtilitySlotTooltip(utilitySlot, ItemTooltip, utilitySlot)
        end,
    },
}

function ZO_AbilitySlot_OnMouseEnter(abilitySlot)
    RunHandlers(AbilityEnter, abilitySlot)
end

local AbilityExit =
{
    [ABILITY_SLOT_TYPE_UTILITY] =
    {
        function(utilitySlot)
            utilitySlot.object:OnMouseExitUtilitySlot(utilitySlot)
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