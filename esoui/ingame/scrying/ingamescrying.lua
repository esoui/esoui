--------------------
-- Scrying Ingame --
--------------------

local ANTIQUITY_SCRYING_INTERACTION =
{
    type = "Antiquity Scrying",
    interactTypes = { INTERACTION_ANTIQUITY_SCRYING },
}

local function ToggleHelp()
    HELP_MANAGER:ToggleHelp()
end

local KEYBOARD_STYLE =
{
    helpTutorialsDescriptor = 
    {
        keybind = "TOGGLE_HELP",
        callback = ToggleHelp
    }
}
local GAMEPAD_STYLE =
{
    helpTutorialsDescriptor = 
    {
        keybind = "GAMEPAD_SPECIAL_TOGGLE_HELP",
        callback = ToggleHelp
    }
}

-- This object holds the interaction logic between the scrying remote scene and the rest of the ingame UI.
ZO_IngameScrying = ZO_Object:Subclass()

function ZO_IngameScrying:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_IngameScrying:Initialize(control)
    self.control = control
    SCRYING_SCENE = ZO_RemoteInteractScene:New("Scrying", SCENE_MANAGER, ANTIQUITY_SCRYING_INTERACTION)
    SCRYING_FRAGMENT = ZO_SimpleSceneFragment:New(control) -- intro/outro animation handled by C++
    SCRYING_SCENE:AddFragment(SCRYING_FRAGMENT)

    SCRYING_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RefreshInputModeFragments()
        end
    end)

    SCRYING_SCENE:SetHideSceneConfirmationCallback(function(scene, nextSceneName, bypassHideSceneConfirmationReason)
        if bypassHideSceneConfirmationReason == nil and IsScryingInProgress() then
            RequestScryingExit()
        else
            SCRYING_SCENE:AcceptHideScene()
        end
    end)

    SCRYING_SCENE:SetHandleGamepadPreferredModeChangedCallback(function()
        -- Input mode switching is also partially handled in internalingame
        self:RefreshInputModeFragments()
        local HANDLED = true
        return HANDLED
    end)

    local overlaySceneInfo =
    {
        systemFilters = { UI_SYSTEM_ANTIQUITY_SCRYING },
        showOverlayConditionalFunction = IsScryingInProgress,
    }
    HELP_MANAGER:AddOverlayScene("Scrying", overlaySceneInfo)

    SCRYING_ACTIONS_FRAGMENT = ZO_ActionLayerFragment:New("ScryingActions")

    local function OnScryingExitResponse(_, accept)
        if accept then
            SCRYING_SCENE:AcceptHideScene()
        else
            SCRYING_SCENE:RejectHideScene()
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_IngameScrying", EVENT_SCRYING_EXIT_RESPONSE, OnScryingExitResponse)

    self.helpTutorialsButton = control:GetNamedChild("HelpTutorialsKeybindButton")
    self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
end

function ZO_IngameScrying:ApplyPlatformStyle(style)
    self.helpTutorialsButton:SetKeybindButtonDescriptor(style.helpTutorialsDescriptor)
    ApplyTemplateToControl(self.helpTutorialsButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    --Reset the text here to handle the force uppercase on gamepad
    self.helpTutorialsButton:SetText(GetString(SI_HELP_TUTORIALS))
end

function ZO_IngameScrying:RefreshInputModeFragments()
    if SCRYING_ACTIONS_FRAGMENT:IsShowing() then
        --Remove the scrying actions fragment so it can be on top of the gamepad UI mode fragment
        SCENE_MANAGER:RemoveFragment(SCRYING_ACTIONS_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(SPECIAL_TOGGLE_HELP_ACTION_LAYER_FRAGMENT)
    end

    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:AddFragment(GAMEPAD_UI_MODE_FRAGMENT)
        SCENE_MANAGER:AddFragment(HIDE_MOUSE_FRAGMENT)
    else
        SCENE_MANAGER:RemoveFragment(GAMEPAD_UI_MODE_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(HIDE_MOUSE_FRAGMENT)
    end

    -- Re-add the scrying actions fragment so it can be on top of the gamepad UI mode fragment
    SCENE_MANAGER:AddFragment(SCRYING_ACTIONS_FRAGMENT)
    SCENE_MANAGER:AddFragment(SPECIAL_TOGGLE_HELP_ACTION_LAYER_FRAGMENT)
end

function ZO_IngameScrying_OnInitialized(control)
    INGAME_SCRYING = ZO_IngameScrying:New(control)
end