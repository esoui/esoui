local function OnGlobalMouseUp(eventCode, button, ctrl, alt, shift, command)
    if(button == MOUSE_BUTTON_INDEX_RIGHT) then
        ClearCursor()
    end
end

local function ShowLogoutDialog(dialogName, deferralTimeMS)
    if(ZO_Dialogs_IsShowing(dialogName)) then
        -- Update the dialog with the new deferral time
        ZO_Dialogs_UpdateDialogMainText(ZO_Dialogs_FindDialog(dialogName), nil, {deferralTimeMS})
    else
        -- Show the initial dialog
        if(deferralTimeMS) then
            ZO_Dialogs_ShowPlatformDialog(dialogName, { endTime = deferralTimeMS + GetFrameTimeMilliseconds() }, {mainTextParams = {deferralTimeMS}})
        else
            ZO_Dialogs_ShowPlatformDialog(dialogName)
        end
    end
end

local function OnLogoutDeferred(eventCode, deferralTimeMS, wasQuitRequest)
    if(wasQuitRequest) then
        ShowLogoutDialog("QUIT_DEFERRED", deferralTimeMS)
    else
        ShowLogoutDialog("LOGOUT_DEFERRED", deferralTimeMS)
    end
end

local function OnLogoutDisallowed(eventCode, wasQuitRequest)
    if(wasQuitRequest) then
        ShowLogoutDialog("QUIT_PREVENTED")
    end
end

local function OnCombatStateChanged(eventCode, inCombat)
    if(inCombat) then
        ZO_Dialogs_ReleaseDialog("QUIT_PREVENTED")
        ZO_Dialogs_ReleaseDialog("QUIT_DEFERRED")
        ZO_Dialogs_ReleaseDialog("LOGOUT_DEFERRED")
    end
end

local function OnZoneCollectibleRequirementFailed(eventId, collectibleId)
    local collectibleName = GetCollectibleName(collectibleId)
    local storeTextId
    local platform = GetUIPlatform()
    if platform == UI_PLATFORM_PC then
        storeTextId = SI_COLLECTIBLE_ZONE_JUMP_FAILURE_DIALOG_STORE_PC
    elseif platform == UI_PLATFORM_PS4 then
        storeTextId = SI_COLLECTIBLE_ZONE_JUMP_FAILURE_DIALOG_STORE_PS4
    else
        storeTextId = SI_COLLECTIBLE_ZONE_JUMP_FAILURE_DIALOG_STORE_XBOX
    end
    ZO_Dialogs_ShowPlatformDialog("ZONE_COLLECTIBLE_REQUIREMENT_FAILED", nil, {mainTextParams = {collectibleName, GetString(storeTextId) }})
end

EVENT_MANAGER:RegisterForEvent("Globals", EVENT_GLOBAL_MOUSE_UP, OnGlobalMouseUp)
EVENT_MANAGER:RegisterForEvent("Globals", EVENT_LOGOUT_DEFERRED, OnLogoutDeferred)
EVENT_MANAGER:RegisterForEvent("Globals", EVENT_LOGOUT_DISALLOWED, OnLogoutDisallowed)
EVENT_MANAGER:RegisterForEvent("Globals", EVENT_PLAYER_COMBAT_STATE, OnCombatStateChanged)
EVENT_MANAGER:RegisterForEvent("Globals", EVENT_ZONE_COLLECTIBLE_REQUIREMENT_FAILED, OnZoneCollectibleRequirementFailed)


-- Item sounds for slotting actions should mirror the equip sounds according to the audio department.
-- This is globally overridden here...
ITEM_SOUND_ACTION_SLOT = ITEM_SOUND_ACTION_EQUIP

--
-- Gamepad action/binding script handlers
--

CHECK_MOVEMENT_BEFORE_INTERACT_OR_ACTION = false

local JumpOrInteractDown, JumpOrInteractUp
do
    local JUMP_OR_INTERACT_DID_NOTHING = 0
    local JUMP_OR_INTERACT_DID_JUMP = 1
    local JUMP_OR_INTERACT_DID_INTERACT = 2

    local jumpPerformedByJumpOrInteract = JUMP_OR_INTERACT_DID_NOTHING

    local function TryingToMove()
        -- treat the player like they're never trying to move if we're not doing the check
        return CHECK_MOVEMENT_BEFORE_INTERACT_OR_ACTION and IsPlayerTryingToMove()
    end

    JumpOrInteractDown = function()
        jumpPerformedByJumpOrInteract = JUMP_OR_INTERACT_DID_NOTHING

        local interactPromptVisible = RETICLE:GetInteractPromptVisible()
        if not IsBlockActive() then  --don't allow Interactions or Jumps while blocking on Gamepad as it will trigger a roll anyway.
            if(TryingToMove() or not (interactPromptVisible)) then
                jumpPerformedByJumpOrInteract = JUMP_OR_INTERACT_DID_JUMP
                JumpAscendStart()
            else
                jumpPerformedByJumpOrInteract = JUMP_OR_INTERACT_DID_INTERACT
                if not FISHING_MANAGER:StartInteraction() then GameCameraInteractStart() end
            end
        end
    end
    
    JumpOrInteractUp = function()
        if(JUMP_OR_INTERACT_DID_INTERACT == jumpPerformedByJumpOrInteract) then
            FISHING_MANAGER:StopInteraction()
        elseif(JUMP_OR_INTERACT_DID_JUMP == jumpPerformedByJumpOrInteract) then
            AscendStop()
        end
    end
end

function ZO_ActionHandler_JumpOrInteractDown()
    JumpOrInteractDown()
end

function ZO_ActionHandler_JumpOrInteractUp()
    JumpOrInteractUp()
end