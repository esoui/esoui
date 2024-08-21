--Layout consts, defining the widths of the list's columns as provided by design--
ZO_GAMEPAD_GROUP_LIST_USER_FACING_NAME_WIDTH = 350 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GROUP_LIST_CHARACTER_NAME_WIDTH = 240 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GROUP_LIST_ZONE_WIDTH = 270 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GROUP_LIST_ROLES_WIDTH = 125 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X

local SORT_KEYS =
{
    ["displayName"] = { },
    ["characterName"] = { },
    ["formattedZone"] = { tiebreaker = "displayName" },
    ["class"] = { tiebreaker = "displayName" },
    ["championPoints"] = { tiebreaker = "displayName", isNumeric = true },
    ["level"] = { tiebreaker = "championPoints", isNumeric = true },
    ["status"] = { tiebreaker = "displayName", isNumeric = true},
}
----------------------------------
--Group List Gamepad
----------------------------------

local GroupList_Gamepad = ZO_GamepadSocialListPanel:Subclass()

function GroupList_Gamepad:New(...)
    return ZO_GamepadSocialListPanel.New(self, ...)
end

function GroupList_Gamepad:Initialize(control)
    ZO_GamepadSocialListPanel.Initialize(self, control, GROUP_LIST_MANAGER, "ZO_GroupListRow_Gamepad")
    self:SetEmptyText(GetString(SI_GROUP_LIST_PANEL_NO_GROUP_MESSAGE));
    self:SetupSort(SORT_KEYS, "displayName", ZO_SORT_ORDER_UP)

    --If we removed our created group listing while in this list, we need to refresh the keybinds
    local function OnGroupListingRemoved(_, result)
        if self:IsActivated() then
            self:UpdateKeybinds()
        end
    end
    EVENT_MANAGER:RegisterForEvent("GroupList_Gamepad", EVENT_GROUP_FINDER_REMOVE_GROUP_LISTING_RESULT, OnGroupListingRemoved)
end

function GroupList_Gamepad:InitializeKeybinds()
    ZO_GamepadSocialListPanel.InitializeKeybinds(self)

    -- My Listing
    local myGroupListingKeybind =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GROUP_FINDER_MY_GROUP_LISTING),
        keybind = "UI_SHORTCUT_QUATERNARY",
        visible = function()
            return HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING)
        end,
        callback = function()
            GROUP_FINDER_GAMEPAD:SetMode(ZO_GROUP_FINDER_MODES.MANAGE)
            ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(GROUP_FINDER_GAMEPAD:GetCategoryData())
        end,
    }
    self:AddUniversalKeybind(myGroupListingKeybind)
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
    local characterNameControl = control:GetNamedChild("CharacterName")
    if data.leader then
        displayNameControl:SetText(zo_iconTextFormat("EsoUI/Art/UnitFrames/Gamepad/gp_Group_Leader.dds", 32, 32, ZO_FormatUserFacingDisplayName(data.displayName)))
        characterNameControl:SetText(ZO_FormatUserFacingCharacterName(data.characterName))
    end

    displayNameControl:SetColor(fontColor:UnpackRGB())
    
    local rolesControl = control:GetNamedChild("Roles")
    local dpsIcon = rolesControl:GetNamedChild("DPS")
    local healIcon = rolesControl:GetNamedChild("Heal")
    local tankIcon = rolesControl:GetNamedChild("Tank")
    dpsIcon:SetTexture(ZO_GetGamepadRoleIcon(LFG_ROLE_DPS))
    healIcon:SetTexture(ZO_GetGamepadRoleIcon(LFG_ROLE_HEAL))
    tankIcon:SetTexture(ZO_GetGamepadRoleIcon(LFG_ROLE_TANK))
    
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
        ZO_GamepadSocialListPanel.RefreshData(self)
    end

    GAMEPAD_GROUP_ROLES_BAR:UpdateEnabledState()
end

function GroupList_Gamepad:RefreshTooltip()
    --Do nothing, because group list doesn't use a tooltip like other social lists
end

function GroupList_Gamepad:GetSelectedNarrationText()
    local ROW_ENTRY_PAUSE_TIME_MS = 100
    local narration = {}
    local entryData = self:GetSelectedData()
    if entryData then
        --Indicate that this entry is the group leader
        if entryData.leader then
            table.insert(narration, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GROUP_MENU_NARRATION_GROUP_LEADER)))
        end

        if entryData.displayName then
            local narrationStrings = { ZO_GetPlatformAccountLabel(), ZO_FormatUserFacingDisplayName(entryData.displayName) }
            table.insert(narration, SCREEN_NARRATION_MANAGER:CreateNarratableObject(narrationStrings, ROW_ENTRY_PAUSE_TIME_MS))
        end

        local hideCharacterFields = not entryData.hasCharacter or (zo_strlen(entryData.characterName) <= 0)
        if not hideCharacterFields then
            local characterNarration = self:GetCharacterFieldsNarration(entryData)
            ZO_CombineNumericallyIndexedTables(narration, characterNarration)

            --Narrate the selected role icon
            if entryData.selectedRole and entryData.selectedRole ~= LFG_ROLE_INVALID then
                local narrationStrings = { GetString(SI_GROUP_LIST_PANEL_ROLES_HEADER), GetString("SI_LFGROLE", entryData.selectedRole) }
                table.insert(narration, SCREEN_NARRATION_MANAGER:CreateNarratableObject(narrationStrings, ROW_ENTRY_PAUSE_TIME_MS))
            end
        end
    end

    return narration
end

----------------------------------
-- ZO_SocialOptionsDialogGamepad--
----------------------------------

function GroupList_Gamepad:BuildOptionsList()
    local groupingId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)

    local function BuildTravelToGroupPlayerOption()
        return self:BuildTravelToPlayerOption(JumpToGroupMember)
    end
    self:AddOptionTemplate(groupingId, BuildTravelToGroupPlayerOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsLoggedIn)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption, ZO_SocialOptionsDialogGamepad.ShouldAddWhisperOption)
    
    local function CanKickMember()
        return IsGroupModificationAvailable() and not DoesGroupModificationRequireVote() and IsUnitGroupLeader("player") and not self:SelectedDataIsPlayer()
    end

    local function CanVoteForKickMember()
        return IsGroupModificationAvailable() and DoesGroupModificationRequireVote() and not self:SelectedDataIsPlayer()
    end

    local function ShouldAddPromoteOption()
        return IsUnitGroupLeader("player") and self.socialData.online and not self:SelectedDataIsPlayer()
    end

    local function CanJumpToPlayerHouse()
       return not self:SelectedDataIsPlayer()
    end

    self:AddOptionTemplate(groupingId, GroupList_Gamepad.BuildPromoteToLeaderOption, ShouldAddPromoteOption)
    self:AddOptionTemplate(groupingId, GroupList_Gamepad.BuildKickMemberOption, CanKickMember)
    self:AddOptionTemplate(groupingId, GroupList_Gamepad.BuildVoteKickMemberOption, CanVoteForKickMember)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildAddFriendOption, ZO_SocialOptionsDialogGamepad.ShouldAddFriendOption)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildVisitPlayerHouseOption, CanJumpToPlayerHouse)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildInviteToTributeOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsLoggedIn)

    self:AddInviteToGuildOptionTemplates()
end

function GroupList_Gamepad:BuildPromoteToLeaderOption()
    local callback = function()
        ZO_Dialogs_ShowPlatformDialog("GROUP_PROMOTE_LEADER", self.socialData, { mainTextParams = { self.socialData.characterName, self.socialData.displayName, }, } )
    end
    return self:BuildOptionEntry(nil, SI_GROUP_LIST_MENU_PROMOTE_TO_LEADER, callback)
end

function GroupList_Gamepad:BuildKickMemberOption()
    local callback = function()
        GroupKick(self.socialData.unitTag)
    end
    return self:BuildOptionEntry(nil, SI_GROUP_LIST_MENU_KICK_FROM_GROUP, callback)
end

function GroupList_Gamepad:BuildVoteKickMemberOption()
    local callback = function()
        BeginGroupElection(GROUP_ELECTION_TYPE_KICK_MEMBER, ZO_GROUP_ELECTION_DESCRIPTORS.NONE, self.socialData.unitTag)
    end
    return self:BuildOptionEntry(nil, SI_GROUP_LIST_MENU_VOTE_KICK_FROM_GROUP, callback)
end

-------------
--XML calls--
-------------

function ZO_GroupList_Gamepad_OnInitialized(control)
    GROUP_LIST_GAMEPAD = GroupList_Gamepad:New(control)
end