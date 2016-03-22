ZO_QuickslotRadialManager = ZO_InteractiveRadialMenuController:Subclass()

function ZO_QuickslotRadialManager:New(...)
    return ZO_InteractiveRadialMenuController.New(self, ...)
end

-- functions overridden from base

function ZO_QuickslotRadialManager:PrepareForInteraction()
    if SCENE_MANAGER:IsShowing("treasureMapQuickSlot") then
        SYSTEMS:HideScene("treasureMapQuickSlot")
        return false
    elseif not SCENE_MANAGER:IsShowing("hud") then
        return false
    end
    return true
end

function ZO_QuickslotRadialManager:InteractionCanceled()
    ActionButtonUp(ACTION_BAR_FIRST_UTILITY_BAR_SLOT + 1)
end

function ZO_QuickslotRadialManager:SetupEntryControl(entryControl, slotNum)
    local selected = (slotNum == self.selectedSlotNum)
    local itemCount = GetSlotItemCount(slotNum)
    local slotType = GetSlotType(slotNum)
    ZO_SetupSelectableItemRadialMenuEntryTemplate(entryControl, selected, slotType ~= ACTION_TYPE_NOTHING and itemCount or nil)
end

local EMPTY_QUICKSLOT_TEXTURE = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds"
local EMPTY_QUICKSLOT_STRING = GetString(SI_QUICKSLOTS_EMPTY)

function ZO_QuickslotRadialManager:PopulateMenu()
    self.selectedSlotNum = GetCurrentQuickslot()

    for i = ACTION_BAR_FIRST_UTILITY_BAR_SLOT + 1, ACTION_BAR_FIRST_UTILITY_BAR_SLOT + ACTION_BAR_UTILITY_BAR_SIZE do
        if not self:ValidateOrClearQuickslot(i) then
            self.menu:AddEntry(EMPTY_QUICKSLOT_STRING, EMPTY_QUICKSLOT_TEXTURE, EMPTY_QUICKSLOT_TEXTURE, function() SetCurrentQuickslot(i) end, i)
        else
            local slotType = GetSlotType(i)
            local slotIcon = GetSlotTexture(i)
            local slotName = GetSlotName(i)
            slotName = zo_strformat(SI_TOOLTIP_ITEM_NAME, slotName)
            local slotItemQuality = GetSlotItemQuality(i)

            local slotNameData
            if slotItemQuality
            then
                local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, slotItemQuality)
                local colorTable = { r = r, g = g, b = b }
                slotNameData = {slotName, colorTable}
            else
                slotNameData = slotName
            end
            self.menu:AddEntry(slotNameData, slotIcon, slotIcon, function() SetCurrentQuickslot(i) end, i)
        end
    end
end

function ZO_QuickslotRadialManager:ValidateOrClearQuickslot(slot)
    local isValid = false
    local slotType = GetSlotType(slot)
    if slotType ~= ACTION_TYPE_NOTHING then
        local slotIcon = GetSlotTexture(slot)
        if not slotIcon or slotIcon == '' then
            ClearSlot(slot)
        else
            isValid = true
        end
    end
    return isValid
end

--Quickslot Radial Manager

local QuickslotSlotRadialManager = ZO_Object:Subclass()

function QuickslotSlotRadialManager:New()
    return ZO_Object.New(self)
end

function QuickslotSlotRadialManager:StartInteraction()
    self.gamepad = IsInGamepadPreferredMode()
    if self.gamepad then
        return QUICKSLOT_RADIAL_GAMEPAD:StartInteraction()
    else
        return QUICKSLOT_RADIAL_KEYBOARD:StartInteraction()
    end
end

function QuickslotSlotRadialManager:StopInteraction()
    if self.gamepad then
        return QUICKSLOT_RADIAL_GAMEPAD:StopInteraction()
    else
        return QUICKSLOT_RADIAL_KEYBOARD:StopInteraction()
    end
end

QUICKSLOT_RADIAL_MANAGER = QuickslotSlotRadialManager:New()