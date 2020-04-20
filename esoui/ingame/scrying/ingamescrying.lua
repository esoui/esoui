--------------------
-- Scrying Ingame --
--------------------

local ANTIQUITY_SCRYING_INTERACTION =
{
    type = "Antiquity Scrying",
    interactTypes = { INTERACTION_ANTIQUITY_SCRYING },
}

ZO_SceneManager_Leader.AddBypassHideSceneConfirmationReason("SCRYING_INTERRUPTED")

-- This object holds the interaction logic between the scrying remote scene and the rest of the ingame UI.
ZO_IngameScrying = ZO_Object:Subclass()

function ZO_IngameScrying:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_IngameScrying:Initialize()
    SCRYING_SCENE = ZO_RemoteInteractScene:New("Scrying", SCENE_MANAGER, ANTIQUITY_SCRYING_INTERACTION)

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

    local function OnScryingExitResponse(_, accept)
        if accept then
            SCRYING_SCENE:AcceptHideScene()
        else
            SCRYING_SCENE:RejectHideScene()
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_IngameScrying", EVENT_SCRYING_EXIT_RESPONSE, OnScryingExitResponse)

    local function OnInterruptScrying()
        if SCRYING_SCENE:IsShowing() then
            SCENE_MANAGER:RequestShowLeaderBaseScene(ZO_BHSCR_SCRYING_INTERRUPTED)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_IngameScrying", EVENT_INTERRUPT_SCRYING, OnInterruptScrying)
end

function ZO_IngameScrying:RefreshInputModeFragments()
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:AddFragment(GAMEPAD_UI_MODE_FRAGMENT)
        SCENE_MANAGER:AddFragment(HIDE_MOUSE_FRAGMENT)
    else
        SCENE_MANAGER:RemoveFragment(GAMEPAD_UI_MODE_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(HIDE_MOUSE_FRAGMENT)
    end
end

INGAME_SCRYING = ZO_IngameScrying:New()