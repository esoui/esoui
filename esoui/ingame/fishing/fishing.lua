ZO_Fishing = ZO_InteractiveRadialMenuController:Subclass()

-- Overridden from base

function ZO_Fishing:Initialize(...)
    ZO_InteractiveRadialMenuController.Initialize(self, ...)
    self.menu:SetShowKeybinds(function() return ZO_AreTogglableWheelsEnabled() end)
    self.menu:SetKeybindActionLayer(GetString(SI_KEYBINDINGS_LAYER_ACCESSIBLE_QUICKWHEEL))
end

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