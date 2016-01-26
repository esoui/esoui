--Layout consts, defining the widths of the list's columns as provided by design--
ZO_GAMEPAD_FRIENDS_LIST_USER_FACING_NAME_WIDTH = 350 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_FRIENDS_LIST_ZONE_WIDTH = 396 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X

-----------------
-- Friend List
-----------------

local FriendsList_Gamepad = ZO_GamepadSocialListPanel:Subclass()

function FriendsList_Gamepad:New(...)
    return ZO_GamepadSocialListPanel.New(self, ...)
end

function FriendsList_Gamepad:Initialize(control)
    ZO_GamepadSocialListPanel.Initialize(self, control, FRIENDS_LIST_MANAGER, "ZO_GamepadFriendsListRow")
    self:SetTitle(GetString(SI_GAMEPAD_CONTACTS_FRIENDS_LIST_TITLE))
    self:SetEmptyText(GetString(SI_GAMEPAD_CONTACTS_FRIENDS_LIST_NO_FRIENDS_MESSAGE));
        self:SetupSort(FRIENDS_LIST_ENTRY_SORT_KEYS, "status", ZO_SORT_ORDER_DOWN)

    GAMEPAD_FRIENDS_LIST_SCENE = ZO_Scene:New("gamepad_friends", SCENE_MANAGER)
    GAMEPAD_FRIENDS_LIST_SCENE:AddFragment(self:GetListFragment())
end

function FriendsList_Gamepad:GetAddKeybind()
    local keybind  =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        name = GetString(SI_GAMEPAD_CONTACTS_ADD_FRIEND_BUTTON_LABEL),
        
        keybind = "UI_SHORTCUT_SECONDARY",

        callback = function()
            local platform = GetUIPlatform()
            if platform == UI_PLATFORM_PC or platform == UI_PLATFORM_XBOX then
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SOCIAL_ADD_FRIEND_DIALOG")
            else
                ZO_ShowConsoleAddFriendDialogFromUserListSelector()
            end
        end,
    }
    return keybind
end

function FriendsList_Gamepad:LayoutTooltip(tooltipManager, tooltip, data)
    tooltipManager:LayoutFriend(tooltip, ZO_FormatUserFacingDisplayName(data.displayName), data.characterName, data.class, data.gender, data.level, data.veteranRank, data.formattedAllianceName, data.formattedZone, not data.online)
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

function FriendsList_Gamepad:BuildOptionsList()
    local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildSendMailOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption, ZO_SocialOptionsDialogGamepad.ShouldAddWhisperOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildInviteToGroupOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsLoggedIn)

    local function BuildTravelToFriendPlayerOption()
        return self:BuildTravelToPlayerOption(JumpToFriend)
    end
    self:AddOptionTemplate(groupId, BuildTravelToFriendPlayerOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsLoggedIn)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildInviteToGameOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildIgnoreOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildRemoveFriendOption, function() return not IsConsoleUI() end)
end

function ZO_FriendsList_Gamepad_OnInitialized(self)
    ZO_FRIENDS_LIST_GAMEPAD = FriendsList_Gamepad:New(self)
end