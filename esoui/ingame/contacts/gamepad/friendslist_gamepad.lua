--Layout consts, defining the widths of the list's columns as provided by design--
ZO_GAMEPAD_FRIENDS_LIST_USER_FACING_NAME_WIDTH = 310 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_FRIENDS_LIST_CHARACTER_NAME_WIDTH = 205 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_FRIENDS_LIST_ZONE_WIDTH = 260 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X

ZO_GAMEPAD_FRIENDS_LIST_HERON_USER_INFO_WIDTH = 100 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
-- Remove 100px from existing columns to make room for the heron user info column. These should add up to 100 so the overall layout is the same width whether or not the heron column is visible
ZO_GAMEPAD_FRIENDS_LIST_HERON_USER_FACING_NAME_WIDTH = ZO_GAMEPAD_FRIENDS_LIST_USER_FACING_NAME_WIDTH - 20
ZO_GAMEPAD_FRIENDS_LIST_HERON_CHARACTER_NAME_WIDTH = ZO_GAMEPAD_FRIENDS_LIST_CHARACTER_NAME_WIDTH - 20
ZO_GAMEPAD_FRIENDS_LIST_HERON_ZONE_WIDTH = ZO_GAMEPAD_FRIENDS_LIST_ZONE_WIDTH - 60

-----------------
-- Friend List
-----------------

local FriendsList_Gamepad = ZO_GamepadSocialListPanel:Subclass()

function FriendsList_Gamepad:New(...)
    return ZO_GamepadSocialListPanel.New(self, ...)
end

function FriendsList_Gamepad:Initialize(control, rowTemplate)
    ZO_GamepadSocialListPanel.Initialize(self, control, FRIENDS_LIST_MANAGER, rowTemplate)
    self:SetTitle(GetString(SI_GAMEPAD_CONTACTS_FRIENDS_LIST_TITLE))
    self:SetEmptyText(GetString(SI_GAMEPAD_CONTACTS_FRIENDS_LIST_NO_FRIENDS_MESSAGE));
    self:SetupSort(FRIENDS_LIST_ENTRY_SORT_KEYS, "status", ZO_SORT_ORDER_UP)

    GAMEPAD_FRIENDS_LIST_SCENE = ZO_Scene:New("gamepad_friends", SCENE_MANAGER)
    GAMEPAD_FRIENDS_LIST_SCENE:AddFragment(self:GetListFragment())

    if ZO_IsPlaystationPlatform() then
        EVENT_MANAGER:RegisterForEvent("FriendsList_Gamepad", EVENT_FRIEND_CHARACTER_INFO_RECEIVED, function(eventId, ...) self:OnFriendCharacterInfoReceived(...) end)
    end
end

function FriendsList_Gamepad:OnFriendCharacterInfoReceived(displayName, hasCharacter, characterName, zoneName, class, alliance, level, championPoints)
    if not hasCharacter or not ZO_Dialogs_IsShowing("GAMEPAD_SOCIAL_OPTIONS_DIALOG") then
        return
    end

    local entryData = self:GetSelectedData()
    if not entryData then
        return
    end

    if entryData.displayName == displayName then
        local gender = GetGenderFromNameDescriptor(characterName)
        local formattedZonename = ZO_CachedStrFormat(SI_ZONE_NAME, zoneName)
        local formattedAllianceName = ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(alliance))

        local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
        ZO_GenericGamepadDialog_ShowTooltip(parametricDialog)
        GAMEPAD_TOOLTIPS:LayoutFriend(GAMEPAD_LEFT_DIALOG_TOOLTIP, ZO_FormatUserFacingDisplayName(entryData.displayName), characterName, class, gender, level, championPoints, formattedAllianceName, formattedZonename, not entryData.online, entryData.secsSinceLogoff, entryData.timeStamp)
    end
end

function FriendsList_Gamepad:GetAddKeybind()
    local platform = GetUIPlatform()
    if platform ~= UI_PLATFORM_XBOX then
        local keybind =
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            name = GetString(SI_GAMEPAD_CONTACTS_ADD_FRIEND_BUTTON_LABEL),

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                if ZO_IsPCOrHeronUI() then
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SOCIAL_ADD_FRIEND_DIALOG")
                else
                    ZO_ShowConsoleAddFriendDialogFromUserListSelector()
                end
            end,
        }
        return keybind
    end
end

function FriendsList_Gamepad:LayoutTooltip(tooltipManager, tooltip, data)
    -- PlayStation will not show a tooltip here, we will show the tooltip if the player opens the social options dialog
    if not ZO_IsPlaystationPlatform() then
        tooltipManager:LayoutFriend(tooltip, ZO_FormatUserFacingDisplayName(data.displayName), data.characterName, data.class, data.gender, data.level, data.championPoints, data.formattedAllianceName, data.formattedZone, not data.online, data.secsSinceLogoff, data.timeStamp, data.heronName)
    end
end

function FriendsList_Gamepad:OnNumOnlineChanged()
    if GAMEPAD_CONTACTS then
        GAMEPAD_CONTACTS:UpdateOnline()
    end
end

function FriendsList_Gamepad:OnNumTotalFriendsChanged()
    if GAMEPAD_CONTACTS then
        GAMEPAD_CONTACTS:UpdateOnline()
    end
end

function FriendsList_Gamepad:OnShowing()
    if IsConsoleUI() and RequestSocialListForActiveProfile then
        EVENT_MANAGER:RegisterForUpdate("FriendsListConsoleRefresh", 60000, function() RequestSocialListForActiveProfile() end)
        RequestSocialListForActiveProfile()
    end
    FRIENDS_LIST_MANAGER:RefreshData()
    self:Activate()
    ZO_GamepadSocialListPanel.OnShowing(self)
end

function FriendsList_Gamepad:OnHidden()
    if IsConsoleUI() then
        EVENT_MANAGER:UnregisterForUpdate("FriendsListConsoleRefresh")
    end
end

function FriendsList_Gamepad:CommitScrollList()
    ZO_GamepadSocialListPanel.CommitScrollList(self)

    --This just sets the empty text, the visibility of the empty text is controlled by SortFilterList when the filtered list is empty
    --The text is reset by GamepadInteractiveSortFilterList.CommitScrollList where it sets the text to No Friends or Filter Returned None as appropriate and this overrides it if the players are offline
    if #self.masterList > 0 then
        if self:GetCurrentSearch() == "" and GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SOCIAL_LIST_HIDE_OFFLINE) then
            self.emptyRowMessage:SetText(GetString(SI_FRIENDS_LIST_ALL_FRIENDS_OFFLINE))
        end
    end
end

-- Overriding version from ZO_GamepadSocialListPanel
function FriendsList_Gamepad:ColorRow(control, data, selected)
    if not ZO_IsPlaystationPlatform() then
        ZO_GamepadSocialListPanel.ColorRow(self, control, data, selected)
    else
        local textColor = self:GetRowColors(data, selected)

        local displayNameControl = control:GetNamedChild("DisplayName")
        displayNameControl:SetColor(textColor:UnpackRGBA())
    end
end

function FriendsList_Gamepad:BuildOptionsList()
    local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption, ZO_SocialOptionsDialogGamepad.ShouldAddWhisperOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildInviteToGroupOption, ZO_SocialOptionsDialogGamepad.ShouldAddInviteToGroupOptionAndCanSelectedDataBeInvited)

    local function BuildTravelToFriendPlayerOption()
        return self:BuildTravelToPlayerOption(JumpToFriend)
    end

    self:AddOptionTemplate(groupId, BuildTravelToFriendPlayerOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsLoggedIn)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildVisitPlayerHouseOption)

    local function ShouldShowInviteToTribute()
        -- As part of SelectedDataIsLoggedIn we check if we have character information for the player in question
        -- On PlayStation we don't have character info when we run this check, so remove the hasCharacter check
        -- All other platforms will have character information as appropriate
        if ZO_IsPlaystationPlatform() then
            return self.socialData.online and not self:SelectedDataIsPlayer()
        else
            return self:SelectedDataIsLoggedIn()
        end
    end
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildInviteToTributeOption, ShouldShowInviteToTribute)

    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildSendMailOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildIgnoreOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildRemoveFriendOption, ZO_SocialOptionsDialogGamepad.ShouldAddRemoveFriendOption)

    self:AddInviteToGuildOptionTemplates()
end

function FriendsList_Gamepad:GetSelectedNarrationText()
    local ROW_ENTRY_PAUSE_TIME_MS = 100
    local narrations = {}
    local entryData = self:GetSelectedData()
    if entryData then
        if entryData.status then
            local narrationStrings = { GetString(SI_GAMEPAD_CONTACTS_LIST_HEADER_STATUS), GetString("SI_PLAYERSTATUS", entryData.status) }
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(narrationStrings, ROW_ENTRY_PAUSE_TIME_MS))
        end

        --Stadia has an extra column
        if IsHeronUI() and entryData.isHeronUser then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_CONTACTS_LIST_HEADER_HERON_USER_INFO)))
        end

        if entryData.displayName then
            local narrationStrings = { ZO_GetPlatformAccountLabel(), ZO_FormatUserFacingDisplayName(entryData.displayName) }
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(narrationStrings, ROW_ENTRY_PAUSE_TIME_MS))
        end

        --Playstation does not show any of the character fields
        local hideCharacterFields = ZO_IsPlaystationPlatform() or not entryData.hasCharacter or (zo_strlen(entryData.characterName) <= 0)
        if not hideCharacterFields then
            ZO_AppendNarration(narrations, self:GetCharacterFieldsNarration(entryData))
        end
    end

    return narrations
end

function FriendsList_Gamepad:GetFooterNarration()
    if GAMEPAD_CONTACTS_FRAGMENT:IsShowing() then
        return GAMEPAD_CONTACTS:GetNarrationText()
    end
end

-- Overriding from ZO_SocialOptionsDialogGamepad
function FriendsList_Gamepad:GetDialogData()
    local data = ZO_SocialOptionsDialogGamepad.GetDialogData(self)
    if ZO_IsPlaystationPlatform() then
        data.setupFunction = function(dialog)
            local entryData = self:GetSelectedData()
            if entryData.online then
                RequestCharacterDataForFriend(entryData.displayName)
            end
        end
    end
    return data
end

---
-- Global XML Function
---

function ZO_FriendsList_Gamepad_OnInitialized(control)
    -- Set up columns before initializing panel
    local rowTemplate
    local headersTemplate
    if IsHeronUI() then
        rowTemplate = "ZO_GamepadFriendsListRow_Heron"
        headersTemplate = "ZO_GamepadFriendsListHeaders_Heron"
    elseif ZO_IsPlaystationPlatform() then
        rowTemplate = "ZO_GamepadFriendsListRow_Playstation"
        headersTemplate = "ZO_GamepadFriendsListHeaders_Playstation"
    else
        rowTemplate = "ZO_GamepadFriendsListRow"
        headersTemplate = "ZO_GamepadFriendsListHeaders"
    end
    ApplyTemplateToControl(control:GetNamedChild("ContainerHeaders"), headersTemplate)

    ZO_FRIENDS_LIST_GAMEPAD = FriendsList_Gamepad:New(control, rowTemplate)
end