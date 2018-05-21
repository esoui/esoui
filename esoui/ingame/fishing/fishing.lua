ZO_Fishing = ZO_InteractiveRadialMenuController:Subclass()

function ZO_Fishing:New(...)
    return ZO_InteractiveRadialMenuController.New(self, ...)
end

-- Overridden from base

function ZO_Fishing:PrepareForInteraction()
    if not SCENE_MANAGER:IsInUIMode() then
        local additionalInfo = select(5, GetGameCameraInteractableActionInfo())
        if additionalInfo == ADDITIONAL_INTERACT_INFO_FISHING_NODE then
            if GetFishingLure() == 0 then
                self:ShowMenu()
            end
            return true
        end
    end
    return false
end

function ZO_Fishing:SetupEntryControl(entryControl, lureIndex)
    local selected = lureIndex == GetFishingLure()
    local _, _, stackCount = GetFishingLureInfo(lureIndex)
    ZO_SetupSelectableItemRadialMenuEntryTemplate(entryControl, selected, stackCount > 0 and stackCount or nil)
end

function ZO_Fishing:PopulateMenu()
    for i=1, GetNumFishingLures() do
        local name, icon, stack = GetFishingLureInfo(i)
        if stack > 0 then
            self.menu:AddEntry(zo_strformat(SI_TOOLTIP_ITEM_NAME, name), icon, icon, function() SetFishingLure(i) end, i)
        else
            self.menu:AddEntry(GetString(SI_NO_BAIT_IN_SLOT), "EsoUI/Art/Fishing/bait_emptySlot.dds", "EsoUI/Art/Fishing/bait_emptySlot.dds", nil, i)
        end
    end
end

--Fishing Manager

local FishingManager = ZO_Object:Subclass()

function FishingManager:New()
    return ZO_Object.New(self)
end

function FishingManager:StartInteraction()
    self.gamepad = IsInGamepadPreferredMode()
    if self.gamepad then
        return FISHING_GAMEPAD:StartInteraction()
    else
        return FISHING_KEYBOARD:StartInteraction()
    end
end

function FishingManager:StopInteraction()
    if self.gamepad then
        return FISHING_GAMEPAD:StopInteraction()
    else
        return FISHING_KEYBOARD:StopInteraction()
    end
end

FISHING_MANAGER = FishingManager:New()