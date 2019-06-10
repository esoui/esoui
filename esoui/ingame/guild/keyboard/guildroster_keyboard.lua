-----------------
--Guild Roster
-----------------

local ZO_KeyboardGuildRosterManager = ZO_SocialListKeyboard:Subclass()

function ZO_KeyboardGuildRosterManager:New(...)
    return ZO_SocialListKeyboard.New(self, ...)
end

function ZO_KeyboardGuildRosterManager:Initialize(control)
    ZO_SocialListKeyboard.Initialize(self, control)
    control:SetHandler("OnEffectivelyHidden", function() self:OnEffectivelyHidden() end)

    self:SetEmptyText(GetString(SI_SORT_FILTER_LIST_NO_RESULTS))
    
    ZO_ScrollList_AddDataType(self.list, GUILD_MEMBER_DATA, "ZO_KeyboardGuildRosterRow", 30, function(rowControl, data) self:SetupRow(rowControl, data) end)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

    self.searchBox = GetControl(control, "SearchBox")
    self.searchBox:SetHandler("OnTextChanged", function() self:OnSearchTextChanged() end)

    self.sortFunction = function(listEntry1, listEntry2) return self:CompareGuildMembers(listEntry1, listEntry2) end
    self.sortHeaderGroup:SelectHeaderByKey("status")

    self.hideOfflineCheckBox = GetControl(control, "HideOffline")

    GUILD_ROSTER_SCENE = ZO_Scene:New("guildRoster", SCENE_MANAGER)
    GUILD_ROSTER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self:UpdateHideOfflineCheckBox(self.hideOfflineCheckBox)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)

    GUILD_ROSTER_FRAGMENT = ZO_FadeSceneFragment:New(control)
    self:InitializeDirtyLogic(GUILD_ROSTER_FRAGMENT)

    GUILD_ROSTER_MANAGER:AddList(self)
end

function ZO_KeyboardGuildRosterManager:PerformDeferredInitialization()
    if self.keybindStripDescriptor then return end

    self:RefreshData()
    self:InitializeKeybindDescriptor()
end

function ZO_KeyboardGuildRosterManager:InitializeKeybindDescriptor()
    self.keybindStripDescriptor =
    {
        -- Invite
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_GUILD_INVITE_ACTION),
            keybind = "UI_SHORTCUT_PRIMARY",
        
            callback = function()
                local guildId = GUILD_ROSTER_MANAGER:GetGuildId()
                local name = GetGuildName(guildId)
                ZO_Dialogs_ShowDialog("GUILD_INVITE", guildId, {mainTextParams = {name}})
            end,

            enabled = function()
                local numMembers, _, _, numInvitees = GetGuildInfo(GUILD_ROSTER_MANAGER:GetGuildId())
                local totalPlayers = numMembers + numInvitees
                if totalPlayers >= MAX_GUILD_MEMBERS then
                    return false, GetString("SI_SOCIALACTIONRESULT", SOCIAL_RESULT_GUILD_IS_FULL)
                end
                return true
            end,

            visible = function()
                return DoesPlayerHaveGuildPermission(GUILD_ROSTER_MANAGER:GetGuildId(), GUILD_PERMISSION_INVITE)
            end
        },
        
        -- Whisper
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_SOCIAL_LIST_PANEL_WHISPER),
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                StartChatInput("", CHAT_CHANNEL_WHISPER, data.displayName)
            end,

            visible = function()
                if(self.mouseOverRow and IsChatSystemAvailableForCurrentPlatform()) then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    return data.hasCharacter and data.online and not data.isLocalPlayer
                end
                return false
            end
        },

        -- Invite to Group
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_FRIENDS_LIST_PANEL_INVITE),
            keybind = "UI_SHORTCUT_TERTIARY",
        
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                local NOT_SENT_FROM_CHAT = false
                local DISPLAY_INVITED_MESSAGE = true
                TryGroupInviteByName(data.characterName, NOT_SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE)
            end,

            visible = function()
                if IsGroupModificationAvailable() and self.mouseOverRow then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    if data.hasCharacter and data.online and not data.isLocalPlayer and data.rankId ~= DEFAULT_INVITED_RANK then
                        return true
                    end
                end
                return false
            end
        },
    }
end

function ZO_KeyboardGuildRosterManager:OnGuildIdChanged(guildId)
    self.searchBox:SetText("")
    self.searchBox:LoseFocus()
    self:UpdateKeybinds()
end

function ZO_KeyboardGuildRosterManager:BuildMasterList()
     -- The master list lives in the GUILD_ROSTER_MANAGER and is built there
end

function ZO_KeyboardGuildRosterManager:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local searchTerm = self.searchBox:GetText()
    local hideOffline = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SOCIAL_LIST_HIDE_OFFLINE)

    local masterList = GUILD_ROSTER_MANAGER:GetMasterList()
    for i = 1, #masterList do
        local data = masterList[i]
        if searchTerm == "" or GUILD_ROSTER_MANAGER:IsMatch(searchTerm, data) then
            if not hideOffline or data.online or data.rankId == DEFAULT_INVITED_RANK then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(GUILD_MEMBER_DATA, data))
            end
        end
    end
end

function ZO_KeyboardGuildRosterManager:CompareGuildMembers(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, GUILD_ROSTER_ENTRY_SORT_KEYS, self.currentSortOrder)
end

function ZO_KeyboardGuildRosterManager:SortScrollList()
    if(self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, self.sortFunction)
    end
end

function ZO_KeyboardGuildRosterManager:ColorRow(control, data, selected)
    local textColor, iconColor = self:GetRowColors(data, selected)
    GUILD_ROSTER_MANAGER:ColorRow(control, data, textColor, iconColor, textColor)
end

function ZO_KeyboardGuildRosterManager:SetupRow(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)
    GUILD_ROSTER_MANAGER:SetupEntry(control, data) 
end

function ZO_KeyboardGuildRosterManager:UnlockSelection()
    ZO_SortFilterList.UnlockSelection(self)
    self:RefreshVisible()
end


--Events
---------

function ZO_KeyboardGuildRosterManager:OnEffectivelyHidden()
    ClearMenu()
end

function ZO_KeyboardGuildRosterManager:OnSearchTextChanged()
    ZO_EditDefaultText_OnTextChanged(self.searchBox)
    self:RefreshFilters()
end

function ZO_KeyboardGuildRosterManager:GuildRosterRow_OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        ClearMenu()

        local data = ZO_ScrollList_GetData(control)
        if data then
            local guildId = GUILD_ROSTER_MANAGER:GetGuildId()
            local guildName = GUILD_ROSTER_MANAGER:GetGuildName()
            local guildAlliance = GUILD_ROSTER_MANAGER:GetGuildAlliance()

            local dataIndex = data.index
            local playerIndex = GetPlayerGuildMemberIndex(guildId)
            local masterList = GUILD_ROSTER_MANAGER:GetMasterList()
            local playerData = masterList[playerIndex]
            local playerHasHigherRank = playerData.rankIndex < data.rankIndex
            local playerIsGuildmaster = IsGuildRankGuildMaster(guildId, playerData.rankIndex)
            local playerIsPendingInvite = data.rankId == DEFAULT_INVITED_RANK
            local ALLIANCE_ICON_SIZE = 17

            if DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_PROMOTE) and not playerIsPendingInvite then
                if data.rankIndex > 1 then
                    local newRankIndex = data.rankIndex - 1
                    if playerData.rankIndex < newRankIndex then
                        AddMenuItem(GetString(SI_GUILD_PROMOTE),
                                    function()
                                        GuildPromote(guildId, data.displayName)
                                        PlaySound(SOUNDS.GUILD_ROSTER_PROMOTE)
                                    end)
                    elseif playerIsGuildmaster then
                        AddMenuItem(GetString(SI_GUILD_PROMOTE),
                                    function()
                                        local allianceIcon = zo_iconFormat(GetAllianceSymbolIcon(guildAlliance), ALLIANCE_ICON_SIZE, ALLIANCE_ICON_SIZE)
                                        local rankName = GetFinalGuildRankName(guildId, 2)
                                        ZO_Dialogs_ShowDialog("PROMOTE_TO_GUILDMASTER", { guildId = guildId, displayName = data.displayName}, { mainTextParams = { data.displayName, allianceIcon, guildName, rankName }})
                                    end)
                    end
                end
            end

            if DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_DEMOTE) and not playerIsPendingInvite then
                if data.rankIndex < GetNumGuildRanks(guildId) then
                    if playerHasHigherRank then
                        AddMenuItem(GetString(SI_GUILD_DEMOTE),
                                    function()
                                        GuildDemote(guildId, data.displayName)
                                        PlaySound(SOUNDS.GUILD_ROSTER_DEMOTE)
                                    end)
                    end
                end
            end

            if DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_REMOVE) then
                if playerIsPendingInvite then
                    local allianceIcon = zo_iconFormat(GetAllianceSymbolIcon(guildAlliance), ALLIANCE_ICON_SIZE, ALLIANCE_ICON_SIZE)
                        AddMenuItem(GetString(SI_GUILD_UNINVITE), function()
                                                                    ZO_Dialogs_ShowDialog("UNINVITE_GUILD_PLAYER", { guildId = guildId,  displayName = data.displayName }, { mainTextParams = { data.displayName, allianceIcon, guildName } })
                                                                end)
                else
                    if playerHasHigherRank and playerIndex ~= dataIndex then
                        local allianceIcon = zo_iconFormat(GetAllianceSymbolIcon(guildAlliance), ALLIANCE_ICON_SIZE, ALLIANCE_ICON_SIZE)
                        AddMenuItem(GetString(SI_GUILD_REMOVE), function()
                                                                    ZO_Dialogs_ShowDialog("GUILD_REMOVE_MEMBER_KEYBOARD", { guildId = guildId,  displayName = data.displayName }, { mainTextParams = { data.displayName } })
                                                                end)
                    end
                end
            end

            if DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_NOTE_EDIT) and not playerIsPendingInvite then
                AddMenuItem(GetString(SI_SOCIAL_MENU_EDIT_NOTE),    function()
                                                                        ZO_Dialogs_ShowDialog("EDIT_NOTE", {displayName = data.displayName, note = data.note, changedCallback = GUILD_ROSTER_MANAGER:GetNoteEditedFunction()})
                                                                    end)
            end

            if dataIndex == playerIndex then
                ZO_AddLeaveGuildMenuItem(guildId)
            elseif not playerIsPendingInvite then
                if data.hasCharacter and data.online then
                    if IsChatSystemAvailableForCurrentPlatform() then
                        AddMenuItem(GetString(SI_SOCIAL_LIST_SEND_MESSAGE), function() StartChatInput("", CHAT_CHANNEL_WHISPER, data.displayName) end)
                    end
                    if IsGroupModificationAvailable() then
                        AddMenuItem(GetString(SI_SOCIAL_MENU_INVITE), function() 
                            local NOT_SENT_FROM_CHAT = false
                            local DISPLAY_INVITED_MESSAGE = true
                            TryGroupInviteByName(data.characterName, NOT_SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE) 
                        end)
                    end
                    AddMenuItem(GetString(SI_SOCIAL_MENU_JUMP_TO_PLAYER), function() JumpToGuildMember(data.displayName) end)
                end
                AddMenuItem(GetString(SI_SOCIAL_MENU_VISIT_HOUSE), function() JumpToHouse(data.displayName) end)
                AddMenuItem(GetString(SI_SOCIAL_MENU_SEND_MAIL), function() MAIL_SEND:ComposeMailTo(data.displayName) end)

                if not IsFriend(data.displayName) then
                    AddMenuItem(GetString(SI_SOCIAL_MENU_ADD_FRIEND), function() ZO_Dialogs_ShowDialog("REQUEST_FRIEND", {name = data.displayName}) end)
                end
            end

            self:ShowMenu(control)
        end
    end
end

function ZO_KeyboardGuildRosterManager:GuildRosterRowRank_OnMouseEnter(control)
    local row = control:GetParent()
    local data = ZO_ScrollList_GetData(row)

    if(data.rankIndex) then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
        SetTooltipText(InformationTooltip, GetFinalGuildRankName(GUILD_ROSTER_MANAGER:GetGuildId(), data.rankIndex))
    end

    self:EnterRow(row)
end

function ZO_KeyboardGuildRosterManager:GuildRosterRowRank_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
end

--Global XML
---------------

function ZO_KeyboardGuildRosterRow_OnMouseEnter(control)
    GUILD_ROSTER_KEYBOARD:Row_OnMouseEnter(control)
end

function ZO_KeyboardGuildRosterRow_OnMouseExit(control)
    GUILD_ROSTER_KEYBOARD:Row_OnMouseExit(control)
end

function ZO_KeyboardGuildRosterRow_OnMouseUp(control, button, upInside)
    GUILD_ROSTER_KEYBOARD:GuildRosterRow_OnMouseUp(control, button, upInside)
end

function ZO_KeyboardGuildRosterRowNote_OnMouseEnter(control)
    GUILD_ROSTER_KEYBOARD:Note_OnMouseEnter(control)
end

function ZO_KeyboardGuildRosterRowNote_OnMouseExit(control)
    GUILD_ROSTER_KEYBOARD:Note_OnMouseExit(control)
end

function ZO_KeyboardGuildRosterRowNote_OnClicked(control)
    GUILD_ROSTER_KEYBOARD:Note_OnClicked(control, GUILD_ROSTER_MANAGER:GetNoteEditedFunction())
end

function ZO_KeyboardGuildRosterRowDisplayName_OnMouseEnter(control)
    GUILD_ROSTER_KEYBOARD:DisplayName_OnMouseEnter(control)
end

function ZO_KeyboardGuildRosterRowDisplayName_OnMouseExit(control)
    GUILD_ROSTER_KEYBOARD:DisplayName_OnMouseExit(control)
end

function ZO_KeyboardGuildRosterRowAlliance_OnMouseEnter(control)
    GUILD_ROSTER_KEYBOARD:Alliance_OnMouseEnter(control)
end

function ZO_KeyboardGuildRosterRowAlliance_OnMouseExit(control)
    GUILD_ROSTER_KEYBOARD:Alliance_OnMouseExit(control)
end

function ZO_KeyboardGuildRosterRowStatus_OnMouseEnter(control)
    GUILD_ROSTER_KEYBOARD:Status_OnMouseEnter(control)
end

function ZO_KeyboardGuildRosterRowStatus_OnMouseExit(control)
    GUILD_ROSTER_KEYBOARD:Status_OnMouseExit(control)
end

function ZO_KeyboardGuildRosterRowClass_OnMouseEnter(control)
    GUILD_ROSTER_KEYBOARD:Class_OnMouseEnter(control)
end

function ZO_KeyboardGuildRosterRowClass_OnMouseExit(control)
    GUILD_ROSTER_KEYBOARD:Class_OnMouseExit(control)
end

function ZO_KeyboardGuildRosterRowChampion_OnMouseEnter(control)
    GUILD_ROSTER_KEYBOARD:Champion_OnMouseEnter(control)
end

function ZO_KeyboardGuildRosterRowChampion_OnMouseExit(control)
    GUILD_ROSTER_KEYBOARD:Champion_OnMouseExit(control)
end

function ZO_KeyboardGuildRosterRowRank_OnMouseEnter(control)
    GUILD_ROSTER_KEYBOARD:GuildRosterRowRank_OnMouseEnter(control)
end

function ZO_KeyboardGuildRosterRowRank_OnMouseExit(control)
    GUILD_ROSTER_KEYBOARD:GuildRosterRowRank_OnMouseExit(control)
end

function ZO_KeyboardGuildRoster_OnInitialized(control)
    GUILD_ROSTER_KEYBOARD = ZO_KeyboardGuildRosterManager:New(control)
end

function ZO_KeyboardGuildRoster_ToggleHideOffline(self)
    GUILD_ROSTER_KEYBOARD:HideOffline_OnClicked()
end

function ZO_ConfirmRemoveGuildMemberDialog_Keyboard_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("GUILD_REMOVE_MEMBER_KEYBOARD",
    {
        title =
        {
            text = SI_PROMPT_TITLE_GUILD_REMOVE_MEMBER,
        },
        mainText =
        {
            text = SI_GUILD_REMOVE_MEMBER_WARNING,
        },
        canQueue = true,
        customControl = self,
        setup = function(dialog)
            local checkboxControl = dialog:GetNamedChild("Check")
            local blacklistMessageControl = dialog:GetNamedChild("BlacklistMessage")
            local blacklistMessageEdit = blacklistMessageControl:GetNamedChild("Edit")

            -- Setup checkbox
            ZO_CheckButton_SetUnchecked(checkboxControl)
            ZO_CheckButton_SetLabelText(checkboxControl, GetString(SI_GUILD_RECRUITMENT_ADD_TO_BLACKLIST_ACTION))
            ZO_CheckButton_SetToggleFunction(checkboxControl, function() blacklistMessageControl:SetHidden(not ZO_CheckButton_IsChecked(checkboxControl)) end)

            if DoesPlayerHaveGuildPermission(dialog.data.guildId, GUILD_PERMISSION_MANAGE_BLACKLIST) then
                ZO_CheckButton_Enable(checkboxControl)
                ZO_CheckButton_SetTooltipEnabledState(checkboxControl, false)
            else
                ZO_CheckButton_SetTooltipEnabledState(checkboxControl, true)
                ZO_CheckButton_SetTooltipAnchor(checkboxControl, RIGHT, checkboxControl.label)
                ZO_CheckButton_SetTooltipText(checkboxControl, GetString(SI_GUILD_RECRUITMENT_NO_BLACKLIST_PERMISSION))

                ZO_CheckButton_Disable(checkboxControl)
            end

            -- Set to default values each time dialog is opened
            blacklistMessageControl:SetHidden(true)
            blacklistMessageEdit:SetText("")
        end,
        buttons =
        {
            -- Yes Button
            {
                control = self:GetNamedChild("Confirm"),
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_DIALOG_REMOVE),
                callback = function(dialog)

                    local isChecked = ZO_CheckButton_IsChecked(dialog:GetNamedChild("Check"))
                    if isChecked then
                        local blacklistMessageControl = dialog:GetNamedChild("BlacklistMessageEdit")
                        local blacklistMessage = blacklistMessageControl:GetText()
                        local blacklistResult = AddToGuildBlacklistByDisplayName(dialog.data.guildId, dialog.data.displayName, blacklistMessage)
                        if not ZO_GuildRecruitment_Manager.IsAddedToBlacklistSuccessful(blacklistResult) then
                            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
                        end
                    else
                        GuildRemove(dialog.data.guildId, dialog.data.displayName)
                    end
                end,
            },
            -- No Button
            {
                control = self:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
            },
        },
    })
end