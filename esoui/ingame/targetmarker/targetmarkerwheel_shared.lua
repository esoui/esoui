ZO_TargetMarkerWheel_Shared = ZO_InteractiveRadialMenuController:Subclass()

function ZO_TargetMarkerWheel_Shared:Initialize(...)
    ZO_InteractiveRadialMenuController.Initialize(self, ...)
    self.menu:SetShowKeybinds(function() return ZO_AreTogglableWheelsEnabled() end)
    self.menu:SetKeybindActionLayer(GetString(SI_KEYBINDINGS_LAYER_ACCESSIBLE_QUICKWHEEL))
end

function ZO_TargetMarkerWheel_Shared:SetupEntryControl(entryControl, data)
    local NOT_SELECTED = false
    ZO_SetupSelectableItemRadialMenuEntryTemplate(entryControl, NOT_SELECTED)
end

function ZO_TargetMarkerWheel_Shared:PrepareForInteraction()
    if not SCENE_MANAGER:IsShowing("hud") then
        return false
    end
    return true
end

function ZO_TargetMarkerWheel_Shared:PopulateMenu()
    for iconIndex, iconPath in ipairs(ZO_GetPlatformTargetMarkerIconTable()) do
        self.menu:AddEntry("", iconPath, iconPath, function() AssignTargetMarkerToReticleTarget(iconIndex) end, iconIndex)
    end
end

-----------------------------
-- Global Functions
-----------------------------

function ZO_TargetMarkerWheelMenuEntryTemplate_OnInitialized(control)
    ZO_SelectableItemRadialMenuEntryTemplate_OnInitialized(control)
end