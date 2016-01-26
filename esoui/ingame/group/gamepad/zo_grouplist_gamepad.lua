--Layout consts, defining the widths of the list's columns as provided by design--
ZO_GAMEPAD_GROUP_LIST_USER_FACING_NAME_WIDTH = 404 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GROUP_LIST_ZONE_WIDTH = 392 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GROUP_LIST_ROLES_WIDTH = 212 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X

local SORT_KEYS =
{
    ["displayName"] = { },
    ["formattedZone"] = { tiebreaker = "displayName" },
    ["class"] = { tiebreaker = "displayName" },
    ["veteranRank"] = { tiebreaker = "displayName", isNumeric = true },
    ["level"] = { tiebreaker = "veteranRank", isNumeric = true },
    ["status"] = { tiebreaker = "displayName", isNumeric = true},
}
----------------------------------
--Group List Gamepad
----------------------------------

local GroupList_Gamepad = ZO_Object.MultiSubclass(ZO_GroupList_Base, ZO_GamepadSocialListPanel)

function GroupList_Gamepad:New(...)
    return ZO_GamepadSocialListPanel.New(self, ...)
end

function GroupList_Gamepad:Initialize(control)
    ZO_GamepadSocialListPanel.Initialize(self, control, GROUP_LIST_MANAGER, "ZO_GroupListRow_Gamepad")
    ZO_GroupList_Base.Initialize(self, control)
    self:SetEmptyText(GetString(SI_GAMEPAD_GROUP_LIST_PANEL_NO_GROUP_MESSAGE));
    self:SetupSort(SORT_KEYS, "displayName", ZO_SORT_ORDER_DOWN)

    self:InitializeEvents()
end

function GroupList_Gamepad:InitializeEvents()
    local function OnGroupMemberJoined()
        PlaySound(SOUNDS.GROUP_JOIN)
    end
    self.control:RegisterForEvent(EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
end

function GroupList_Gamepad:GetBackKeybindCallback()
    return function()
        GAMEPAD_GROUP_MENU:SelectMenuList()
    end
end

function GroupList_Gamepad:SetupRow(control, data, selected)
    ZO_SocialList_SharedSocialSetup(control, data, selected)

    local fontColor = data.online and ZO_NORMAL_TEXT or ZO_DISABLED_TEXT

    local displayNameControl = control:GetNamedChild("DisplayName")
    if data.leader then
        displayNameControl:SetText(zo_iconTextFormat("EsoUI/Art/LFG/LFG_leader_icon.dds", 32, 32, ZO_FormatUserFacingDisplayName(data.displayName)))
    end

    displayNameControl:SetColor(fontColor:UnpackRGB())
    
    local rolesControl = control:GetNamedChild("Roles")
    local dpsIcon = rolesControl:GetNamedChild("DPS")
    local healIcon = rolesControl:GetNamedChild("Heal")
    local tankIcon = rolesControl:GetNamedChild("Tank")
    dpsIcon:SetTexture(ZO_GAMEPAD_LFG_OPTION_INFO[LFG_ROLE_DPS].icon)
    healIcon:SetTexture(ZO_GAMEPAD_LFG_OPTION_INFO[LFG_ROLE_HEAL].icon)
    tankIcon:SetTexture(ZO_GAMEPAD_LFG_OPTION_INFO[LFG_ROLE_TANK].icon)
    
    dpsIcon:SetAlpha(data.isDps and ZO_GAMEPAD_ICON_SELECTED_ALPHA or ZO_GAMEPAD_ICON_UNSELECTED_ALPHA)
    healIcon:SetAlpha(data.isHeal and ZO_GAMEPAD_ICON_SELECTED_ALPHA or ZO_GAMEPAD_ICON_UNSELECTED_ALPHA)
    tankIcon:SetAlpha(data.isTank and ZO_GAMEPAD_ICON_SELECTED_ALPHA or ZO_GAMEPAD_ICON_UNSELECTED_ALPHA)
end

function GroupList_Gamepad:OnShown()
    ZO_GamepadSocialListPanel.OnShowing(self)
    self:RefreshData()
end

function GroupList_Gamepad:RefreshData()
    if not self.control:IsHidden() then
        ZO_SortFilterList.RefreshData(self)
    end
end

function GroupList_Gamepad:RefreshTooltip()
    --Do nothing, because group list doesn't use a tooltip like other social lists
end

----------------------------------
-- ZO_SocialOptionsDialogGamepad--
----------------------------------

function GroupList_Gamepad:BuildOptionsList()
    local groupingId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)

    local function BuildTravelToGroupPlayerOption()
        local IGNORE_ALLIANCE = true
        return self:BuildTravelToPlayerOption(JumpToGroupMember, IGNORE_ALLIANCE)
    end
    self:AddOptionTemplate(groupingId, BuildTravelToGroupPlayerOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsLoggedIn)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption, ZO_SocialOptionsDialogGamepad.ShouldAddWhisperOption)
    
    local function CanManipulateRank()
        return IsUnitGroupLeader("player") and not self:SelectedDataIsPlayer()
    end

    local function ShouldAddPromoteOption()
        return CanManipulateRank() and self.socialData.online
    end
    self:AddOptionTemplate(groupingId, GroupList_Gamepad.BuildPromoteToLeaderOption, ShouldAddPromoteOption)
    self:AddOptionTemplate(groupingId, GroupList_Gamepad.BuildKickMemberOption, CanManipulateRank)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildAddFriendOption, ZO_SocialOptionsDialogGamepad.ShouldAddFriendOption)
end

function GroupList_Gamepad:BuildPromoteToLeaderOption()
    local callback = function()
        GroupPromote(self.socialData.unitTag)
    end
    return self:BuildOptionEntry(nil, SI_GROUP_LIST_MENU_PROMOTE_TO_LEADER, callback)
end

function GroupList_Gamepad:BuildKickMemberOption()
    local callback = function()
        GroupKick(self.socialData.unitTag)
    end
    return self:BuildOptionEntry(nil, SI_GROUP_LIST_MENU_KICK_FROM_GROUP, callback)
end

-------------
--XML calls--
-------------

function ZO_GroupList_Gamepad_OnInitialized(control)
    GROUP_LIST_GAMEPAD = GroupList_Gamepad:New(control)
end