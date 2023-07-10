local function OnGlobalMouseUp(eventCode, button, ctrl, alt, shift, command)
    if(button == MOUSE_BUTTON_INDEX_RIGHT) then
        ClearCursor()
    end
end

local function ShowLogoutDialog(dialogName, deferralTimeMS)
    if ZO_Dialogs_IsShowing(dialogName) then
        -- Update the dialog with the new deferral time
        ZO_Dialogs_UpdateDialogMainText(ZO_Dialogs_FindDialog(dialogName), nil, {deferralTimeMS})
    else
        -- Show the initial dialog
        if deferralTimeMS then
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
    if inCombat then
        ZO_Dialogs_ReleaseDialog("QUIT_PREVENTED")
        ZO_Dialogs_ReleaseDialog("QUIT_DEFERRED")
        ZO_Dialogs_ReleaseDialog("LOGOUT_DEFERRED")
        local NUM_FLASHES_BEFORE_SOLID = 7
        FlashTaskbarWindow("IN_COMBAT", NUM_FLASHES_BEFORE_SOLID)
    end
end

local function OnZoneCollectibleRequirementFailed(eventId, collectibleId, message)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    local collectibleName = collectibleData:GetName()
    local categoryName = collectibleData:GetCategoryData():GetName()
    local marketOperation = MARKET_OPEN_OPERATION_DLC_FAILURE_TELEPORT_TO_ZONE
    ZO_Dialogs_ShowPlatformDialog("COLLECTIBLE_REQUIREMENT_FAILED", { collectibleData = collectibleData, marketOpenOperation = marketOperation }, { mainTextParams = { message, collectibleName, categoryName } })
end

local function OnLinkNotHandled(link, button, ...)
    ClearMenu()
    if button == MOUSE_BUTTON_INDEX_LEFT then
        if ZO_ChatSystem_ShouldUseKeyboardChatSystem() then
            ZO_PopupTooltip_SetLink(link)
        else
            SCENE_MANAGER:Push("gamepadChatMenu")
            CHAT_MENU_GAMEPAD:SelectMessageEntryByLink(link)
        end
    elseif button == MOUSE_BUTTON_INDEX_RIGHT and link ~= "" then
        local function AddLink()
            ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
        end

        AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
        ShowMenu(control)
    end
end

EVENT_MANAGER:RegisterForEvent("Globals", EVENT_GLOBAL_MOUSE_UP, OnGlobalMouseUp)
EVENT_MANAGER:RegisterForEvent("Globals", EVENT_LOGOUT_DEFERRED, OnLogoutDeferred)
EVENT_MANAGER:RegisterForEvent("Globals", EVENT_LOGOUT_DISALLOWED, OnLogoutDisallowed)
EVENT_MANAGER:RegisterForEvent("Globals", EVENT_PLAYER_COMBAT_STATE, OnCombatStateChanged)
EVENT_MANAGER:RegisterForEvent("Globals", EVENT_ZONE_COLLECTIBLE_REQUIREMENT_FAILED, OnZoneCollectibleRequirementFailed)

LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_NOT_HANDLED_EVENT, OnLinkNotHandled)

-- Item sounds for slotting actions should mirror the equip sounds according to the audio department.
-- This is globally overridden here...
ITEM_SOUND_ACTION_SLOT = ITEM_SOUND_ACTION_EQUIP

--
-- Gamepad action/binding script handlers
--

ZO_JUMP_OR_INTERACT_DID_NOTHING = 0
ZO_JUMP_OR_INTERACT_DID_JUMP = 1
ZO_JUMP_OR_INTERACT_DID_INTERACT = 2

local g_actionPerformedByJumpOrInteract = ZO_JUMP_OR_INTERACT_DID_NOTHING

function ZO_SetJumpOrInteractDownAction(action)
    g_actionPerformedByJumpOrInteract = action
end

function ZO_GetJumpOrInteractDownAction()
    return g_actionPerformedByJumpOrInteract
end

function ZO_FormatResourceBarCurrentAndMax(current, maximum, overrideSetting)
    local returnValue = ""

    local percent = 0
    if maximum ~= 0 then
        percent = (current/maximum) * 100
        if percent < 10 then
            percent = ZO_CommaDelimitDecimalNumber(zo_roundToNearest(percent, .1))
            percent = ZO_FastFormatDecimalNumber(percent)
        else
            percent = zo_round(percent)
        end
    end

    local USE_LOWERCASE_NUMBER_SUFFIXES = false
    local setting = overrideSetting or tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_RESOURCE_NUMBERS))
    if setting == RESOURCE_NUMBERS_SETTING_NUMBER_ONLY then
        returnValue = ZO_AbbreviateAndLocalizeNumber(current, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
    elseif setting == RESOURCE_NUMBERS_SETTING_PERCENT_ONLY then
        returnValue = percent
    elseif setting == RESOURCE_NUMBERS_SETTING_NUMBER_AND_PERCENT then
        returnValue = zo_strformat(SI_ATTRIBUTE_NUMBERS_WITH_PERCENT, ZO_AbbreviateAndLocalizeNumber(current, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES), percent)
    end

    return returnValue
end

-- Determines whether any item or collectible furnishing can be placed in the current house.
function ZO_CanPlaceFurnitureInCurrentHouse()
    return GetCurrentZoneHouseId() ~= 0 and IsOwnerOfCurrentHouse()
end