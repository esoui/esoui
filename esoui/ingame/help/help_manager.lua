local ZO_Help_Manager = ZO_CallbackObject:Subclass()

function ZO_Help_Manager:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_Help_Manager:Initialize(...)
    self.overlayScenes = {}

    EVENT_MANAGER:RegisterForEvent(eventKey, EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function(...) self:OnGamepadPreferredModeChanged(...) end)
end

function ZO_Help_Manager:OnGamepadPreferredModeChanged()
    if self:IsShowingOverlayScene() then
        SCENE_MANAGER:RemoveFragmentGroup(HELP_TUTORIALS_OVERLAY_KEYBOARD_FRAGMENT_GROUP)
        ZO_Dialogs_ReleaseDialog("HELP_TUTORIALS_OVERLAY_DIALOG")
    end
end

function ZO_Help_Manager:AddOverlayScene(sceneName)
    -- TODO: Augment functionality to specifcy system filters
    self.overlayScenes[sceneName] = true
end

function ZO_Help_Manager:IsShowingOverlayScene()
    for sceneName in pairs(self.overlayScenes) do
        if SCENE_MANAGER:IsShowing(sceneName) then
            return true
        end
    end
    return false
end

function ZO_Help_Manager:ToggleHelp()
    if TUTORIAL_SYSTEM:ShowHelp() then
        return
    end

    if self:IsShowingOverlayScene() then
        self:ToggleHelpOverlay()
        return
    end

    SYSTEMS:GetObject("mainMenu"):ToggleCategory(MENU_CATEGORY_HELP)
end

function ZO_Help_Manager:ToggleHelpOverlay()
    if IsInGamepadPreferredMode() then
        if ZO_Dialogs_IsShowing("HELP_TUTORIALS_OVERLAY_DIALOG") then
            ZO_Dialogs_ReleaseDialog("HELP_TUTORIALS_OVERLAY_DIALOG")
        else
            ZO_Dialogs_ShowGamepadDialog("HELP_TUTORIALS_OVERLAY_DIALOG")
        end
    else
        if HELP_TUTORIALS_FRAGMENT:IsShowing() then
            SCENE_MANAGER:RemoveFragmentGroup(HELP_TUTORIALS_OVERLAY_KEYBOARD_FRAGMENT_GROUP)
        else
            SCENE_MANAGER:AddFragmentGroup(HELP_TUTORIALS_OVERLAY_KEYBOARD_FRAGMENT_GROUP)
        end
    end
end

HELP_MANAGER = ZO_Help_Manager:New()