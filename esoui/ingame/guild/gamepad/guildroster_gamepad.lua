--Layout consts, defining the widths of the list's columns as provided by design--
ZO_GAMEPAD_GUILD_ROSTER_RANK_WIDTH = 90 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GUILD_ROSTER_USER_FACING_NAME_WIDTH = 310 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GUILD_ROSTER_CHARACTER_NAME_WIDTH = 165 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GUILD_ROSTER_ZONE_WIDTH = 210 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X

-----------------
-- Guild Roster
-----------------

ZO_GamepadGuildRosterManager = ZO_GamepadSocialListPanel:Subclass()

function ZO_GamepadGuildRosterManager:New(...)
    return ZO_GamepadSocialListPanel.New(self, ...)
end

function ZO_GamepadGuildRosterManager:Initialize(control)
    ZO_GamepadSocialListPanel.Initialize(self, control, GUILD_ROSTER_MANAGER, "ZO_GamepadGuildRosterRow")

	--Need to call SetEmptyText so the empty text label is created and have the text be properly set by InteractiveSortFilterList the filters returns no result
	--GuildRoster will never be empty unless it was filtered out
	self:SetEmptyText(GetString(""))

    self:SetupSort(GUILD_ROSTER_ENTRY_SORT_KEYS, "status", ZO_SORT_ORDER_DOWN)
end

function ZO_GamepadGuildRosterManager:InitializeHeader()
    local contentHeaderData = 
    {
        titleText = GetString(SI_GAMEPAD_GUILD_ROSTER_HEADER),
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_HUB_GUILD_NAME_HEADER),
        data2HeaderText = GetString(SI_GAMEPAD_GUILD_HEADER_GUILD_MASTER_LABEL),
    }
    ZO_GamepadInteractiveSortFilterList.InitializeHeader(self, contentHeaderData)
end

function ZO_GamepadGuildRosterManager:PerformDeferredInitialization()
    if self.initialized then return end
    self.initialized = true

    if GetUIPlatform() == UI_PLATFORM_XBOX then
        local keybind  =
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            name = GetString(SI_GAMEPAD_GUILD_ADD_FRIEND),

            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function() ZO_ShowConsoleInviteToGuildFromUserListSelector(GUILD_ROSTER_MANAGER:GetGuildId()) end,

            visible = function()
                return GetNumberConsoleFriends() > 0 and DoesPlayerHaveGuildPermission(GUILD_ROSTER_MANAGER:GetGuildId(), GUILD_PERMISSION_INVITE)
            end
        }

        self:AddUniversalKeybind(keybind)
    end
end

function ZO_GamepadGuildRosterManager:GetAddKeybind()
    local keybind  =  {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        name = GetString(SI_GUILD_INVITE_ACTION),

        keybind = "UI_SHORTCUT_SECONDARY",

        callback = function()
            local guildId = GUILD_ROSTER_MANAGER:GetGuildId()
            local platform = GetUIPlatform()
            if platform == UI_PLATFORM_PS4 then
                ZO_ShowConsoleInviteToGuildFromUserListSelector(guildId)
            else
                local name = GetGuildName(guildId)
                local dialogData = {guildId = guildId} 
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_GUILD_INVITE_DIALOG", dialogData, {mainTextParams = {name}})
            end
        end,

        visible = function()
            return DoesPlayerHaveGuildPermission(GUILD_ROSTER_MANAGER:GetGuildId(), GUILD_PERMISSION_INVITE)
        end
    }
    return keybind
end

function ZO_GamepadGuildRosterManager:GetBackKeybindCallback()
    return function()
        GAMEPAD_GUILD_HUB:SetEnterInSingleGuildList(true)
        SCENE_MANAGER:HideCurrentScene()
    end
end

function ZO_GamepadGuildRosterManager:LayoutTooltip(tooltipManager, tooltip, data)
    local guildId = GUILD_ROSTER_MANAGER:GetGuildId()
    tooltipManager:LayoutGuildMember(tooltip, ZO_FormatUserFacingDisplayName(data.displayName), data.characterName, data.class, data.gender, guildId, data.rankIndex, data.note, data.level, data.championPoints, data.formattedAllianceName, data.formattedZone, not data.online, data.secsSinceLogoff, data.timeStamp)
end

function ZO_GamepadGuildRosterManager:ColorRow(control, data, selected)
    local textColor, iconColor, textColor2 = self:GetRowColors(data, selected)
    GUILD_ROSTER_MANAGER:ColorRow(control, data, textColor, iconColor, textColor2)
end

function ZO_GamepadGuildRosterManager:OnShowing()
    GAMEPAD_GUILD_HOME:SetHeaderHidden(true)
    GAMEPAD_GUILD_HOME:SetContentHeaderHidden(true)
    self:PerformDeferredInitialization()
    self:Activate()
    ZO_GamepadSocialListPanel.OnShowing(self)
end

function ZO_GamepadGuildRosterManager:OnHidden()
    GAMEPAD_GUILD_HOME:SetHeaderHidden(false)
    GAMEPAD_GUILD_HOME:SetContentHeaderHidden(false)
    ZO_GamepadSocialListPanel.OnHidden(self)
end

-----------------
-- Options
-----------------

function ZO_GamepadGuildRosterManager:SetupOptions(socialData)
    ZO_SocialOptionsDialogGamepad.SetupOptions(self, socialData)
    self.playerData = GUILD_ROSTER_MANAGER:GetPlayerData()
    self.guildId = GUILD_ROSTER_MANAGER:GetGuildId()
    self.guildName = GUILD_ROSTER_MANAGER:GetGuildName()
    self.guildAlliance = GUILD_ROSTER_MANAGER:GetGuildAlliance()
    self.noteChangedCallback = GUILD_ROSTER_MANAGER:GetNoteEditedFunction()
end

function ZO_GamepadGuildRosterManager:BuildOptionsList()
    local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)

    local function CanPromote()
        return DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PROMOTE) and self.socialData.rankIndex > 1
    end

    local function ShouldAddPromoteOption()
        return CanPromote() and self.playerData.rankIndex < (self.socialData.rankIndex - 1)
    end

    local function ShouldAddPromoteToGuildMasterOption()
        return CanPromote() and not ShouldAddPromoteOption() and IsGuildRankGuildMaster(self.guildId, self.playerData.rankIndex)
    end
    self:AddOptionTemplate(groupId, ZO_GamepadGuildRosterManager.BuildPromoteOption, ShouldAddPromoteOption)
    self:AddOptionTemplate(groupId, ZO_GamepadGuildRosterManager.BuildPromoteToGuildMasterOption, ShouldAddPromoteToGuildMasterOption)

    local function ShouldAddDemoteOption()
        local guildId = self.guildId
        local rankIndex = self.socialData.rankIndex
        return DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_DEMOTE) and 
                rankIndex < GetNumGuildRanks(guildId) and
                self.playerData.rankIndex < rankIndex
    end
    self:AddOptionTemplate(groupId, ZO_GamepadGuildRosterManager.BuildDemoteOption, ShouldAddDemoteOption)

    local function ShouldAddRemoveOption()
        local socialData = self.socialData
        local playerData = self.playerData
        return DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_REMOVE) and 
                playerData.rankIndex < socialData.rankIndex and 
                playerData.index ~= socialData.index
    end
    self:AddOptionTemplate(groupId, ZO_GamepadGuildRosterManager.BuildRemoveOption, ShouldAddRemoveOption)

    local function ShouldAddEditNoteOption()
        return DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_NOTE_EDIT)
    end
    self:AddOptionTemplate(groupId, ZO_GamepadGuildRosterManager.BuildEditNoteOption, ShouldAddEditNoteOption)

    local function SelectedIndexIsPlayerIndex()
        return self.socialData.index == self.playerData.index
    end
    self:AddOptionTemplate(groupId, ZO_GamepadGuildRosterManager.BuildLeaveGuildOption, SelectedIndexIsPlayerIndex)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption, ZO_SocialOptionsDialogGamepad.ShouldAddWhisperOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildInviteToGroupOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsLoggedIn)

    local function BuildTravelToGuildPlayerOption()
        return self:BuildTravelToPlayerOption(JumpToGuildMember)
    end

    local function CanJumpToPlayerHouse()
       return not self:SelectedDataIsPlayer()
    end

    self:AddOptionTemplate(groupId, BuildTravelToGuildPlayerOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsLoggedIn)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildVisitPlayerHouseOption, CanJumpToPlayerHouse)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildSendMailOption, function() return not SelectedIndexIsPlayerIndex() end)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildAddFriendOption, ZO_SocialOptionsDialogGamepad.ShouldAddFriendOption)
    self:AddOptionTemplate(groupId, ZO_GamepadGuildRosterManager.BuildShowGamerCardOption, IsConsoleUI)
end

function ZO_GamepadGuildRosterManager:BuildPromoteOption()
    local callback = function() 
        GuildPromote(self.guildId, self.socialData.displayName); 
        PlaySound(SOUNDS.GUILD_ROSTER_PROMOTE)
        local newRank = self.socialData.rankIndex - 1
        if newRank > 0 then
            local rankText = GetFinalGuildRankName(self.guildId, newRank)
            local rankIcon = zo_iconFormat(GetFinalGuildRankTextureSmall(self.guildId, newRank), 24, 24)
            local alertText = zo_strformat(SI_GAMEPAD_GUILD_NOTIFY_PROMOTED, rankIcon, rankText)
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, alertText)
        end
    end
    return self:BuildOptionEntry(nil, SI_GUILD_PROMOTE, callback)
end

function ZO_GamepadGuildRosterManager:BuildPromoteToGuildMasterOption()
    local callback = function()
        local guildInfo = ZO_PrefixIconNameFormatter(ZO_GetAllianceIconUserAreaDataName(self.guildAlliance), self.guildName)
        local rankName = GetFinalGuildRankName(self.guildId, 2)
        ZO_Dialogs_ShowGamepadDialog("PROMOTE_TO_GUILDMASTER", {guildId = self.guildId, displayName = self.socialData.displayName}, { mainTextParams = { ZO_FormatUserFacingDisplayName(self.socialData.displayName), "", guildInfo, rankName}})  
    end
    return self:BuildOptionEntry(nil, SI_GUILD_PROMOTE, callback)
end

function ZO_GamepadGuildRosterManager:BuildDemoteOption()
    local callback = function()
        GuildDemote(self.guildId, self.socialData.displayName)
        PlaySound(SOUNDS.GUILD_ROSTER_DEMOTE)
        local newRank = self.socialData.rankIndex + 1
        if newRank <= GetNumGuildRanks(self.guildId) then
            local rankText = GetFinalGuildRankName(self.guildId, newRank)
            local rankIcon = zo_iconFormat(GetFinalGuildRankTextureSmall(self.guildId, newRank), 24, 24)
            local alertText = zo_strformat(SI_GAMEPAD_GUILD_NOTIFY_DEMOTED, rankIcon, rankText)
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, alertText)
        end
    end
    return self:BuildOptionEntry(nil, SI_GUILD_DEMOTE, callback)
end

function ZO_GamepadGuildRosterManager:BuildRemoveOption()
    local callback = function()
        local guildInfo = ZO_PrefixIconNameFormatter(ZO_GetAllianceIconUserAreaDataName(self.guildAlliance), self.guildName)
        ZO_Dialogs_ShowGamepadDialog("GUILD_REMOVE_MEMBER", {guildId = self.guildId,  displayName = self.socialData.displayName}, { mainTextParams = { ZO_FormatUserFacingDisplayName(self.socialData.displayName), "", guildInfo }})                                                                
    end
    return self:BuildOptionEntry(nil, SI_GUILD_REMOVE, callback)
end

function ZO_GamepadGuildRosterManager:BuildLeaveGuildOption()
    local callback = function()
        local data = {
            hideSceneOnLeave = true
        }   
        local IS_GAMEPAD = true
        ZO_ShowLeaveGuildDialog(self.guildId, data, IS_GAMEPAD)
    end
    return self:BuildOptionEntry(nil, SI_GUILD_LEAVE, callback)
end

function ZO_GamepadGuildRosterManager:BuildAddFriendOption()
    local callback = function()      
        if IsConsoleUI() then
             ZO_ShowConsoleAddFriendDialogFromDisplayNameOrFallback(self.socialData.displayName, ZO_ID_REQUEST_TYPE_GUILD_INFO, self.guildId, self.socialData.index)
        else
            local data = { displayName = self.socialData.displayName, }
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SOCIAL_ADD_FRIEND_DIALOG", data)
        end
    end
    return self:BuildOptionEntry(nil, SI_SOCIAL_MENU_ADD_FRIEND, callback)
end

function ZO_GamepadGuildRosterManager:BuildShowGamerCardOption()
    if(IsConsoleUI()) then
        local callback = function()
            ZO_ShowGamerCardFromDisplayNameOrFallback(self.socialData.displayName, ZO_ID_REQUEST_TYPE_GUILD_INFO, self.guildId, self.socialData.index)
        end
        return self:BuildOptionEntry(nil, GetGamerCardStringId(), callback)
    end
end

function ZO_GamepadGuildRoster_Initialize(control)
    GUILD_ROSTER_GAMEPAD = ZO_GamepadGuildRosterManager:New(control)
end