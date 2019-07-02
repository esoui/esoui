------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_BLACKLIST_KEYBOARD_NAME_COLUMN_SIZE = 550

ZO_GUILD_RECRUITMENT_BLACKLIST_KEYBOARD_ENTRY_HEIGHT = 32

ZO_GuildRecruitment_Blacklist_Keyboard = ZO_Object.MultiSubclass(ZO_GuildRecruitment_Blacklist_Shared, ZO_GuildFinder_Panel_Shared, ZO_SortFilterList)

function ZO_GuildRecruitment_Blacklist_Keyboard:New(...)
    return ZO_GuildRecruitment_Blacklist_Shared.New(self, ...)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:Initialize(control)
    local function SetupRow(control, data)
        self:SetupRow(control, data)
    end

    ZO_GuildRecruitment_Blacklist_Shared.Initialize(self, control)
    ZO_GuildFinder_Panel_Shared.Initialize(self, control)
    ZO_SortFilterList.Initialize(self, control)

    ZO_ScrollList_AddDataType(self.list, ZO_GUILD_RECRUITMENT_BLACKLIST_ENTRY_TYPE, "ZO_GuildRecruitment_Blacklist_Row_Keyboard", ZO_GUILD_RECRUITMENT_BLACKLIST_KEYBOARD_ENTRY_HEIGHT, SetupRow)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

    self:SetEmptyText(GetString(SI_GUILD_RECRUITMENT_BLACKLIST_EMPTY_LIST_TEXT))

    self.sortFunction = function(listEntry1, listEntry2) return self:CompareGuildBlacklistedPlayers(listEntry1, listEntry2) end
    self.sortHeaderGroup:SelectHeaderByKey("name")

    self:InitializeKeybindDescriptors()
end

function ZO_GuildRecruitment_Blacklist_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Add Player
        {
            name = GetString(SI_GUILD_RECRUITMENT_BLACKLIST_PLAYER_ACTION_TEXT),
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                if GetNumGuildBlacklistEntries(self.guildId) >= MAX_GUILD_BLACKLISTED_PLAYERS then
                    return false, GetString("SI_GUILDBLACKLISTRESPONSE", GUILD_BLACKLIST_RESPONSE_BLACKLIST_FULL)
                end
                return true
            end,
            callback = function()
                local data =
                {
                    guildId = self.guildId,
                }
                ZO_Dialogs_ShowPlatformDialog("GUILD_ADD_PLAYER_TO_BLACKLIST", data)
            end,
        },
    }
end

function ZO_GuildRecruitment_Blacklist_Keyboard:FilterScrollList()
    ZO_GuildRecruitment_Blacklist_Shared.FilterScrollList(self)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:CompareGuildBlacklistedPlayers(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, ZO_GUILD_RECRUITMENT_BLACKLIST_ENTRY_SORT_KEYS, self.currentSortOrder)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:SortScrollList()
    if self.currentSortKey ~= nil and self.currentSortOrder ~= nil then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, self.sortFunction)
    end
end

function ZO_GuildRecruitment_Blacklist_Keyboard:SetupRow(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)
    ZO_GuildRecruitment_Blacklist_Shared.SetupRow(self, control, data)

    local noteControl = control:GetNamedChild("Note")
    noteControl:SetHidden(data.note == "")
end

function ZO_GuildRecruitment_Blacklist_Keyboard:Row_OnMouseEnter(control)
    ZO_SortFilterList.Row_OnMouseEnter(self, control)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:Row_OnMouseExit(control)
    ZO_SortFilterList.Row_OnMouseExit(self, control)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:Row_OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        ClearMenu()

        local data = ZO_ScrollList_GetData(control)
        if data then
            if DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_MANAGE_BLACKLIST) then
                local dialogData = 
                {
                    displayName = data.name,
                    index = data.index,
                    note = data.note,
                    changedCallback = function(displayName, note)
                        local blacklistResult = SetGuildBlacklistNote(self.guildId, data.index, note)
                        if not ZO_GuildRecruitment_Manager.IsBlacklistResultSuccessful(blacklistResult) then
                            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
                        end
                    end
                }
                AddMenuItem(GetString(SI_SOCIAL_MENU_EDIT_NOTE), function() ZO_Dialogs_ShowDialog("EDIT_NOTE", dialogData) end)
                self:ShowMenu(control)
            end
        end
    end
end

function ZO_GuildRecruitment_Blacklist_Keyboard:Row_Remove_OnMouseEnter(control)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:Row_Remove_OnMouseExit(control)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:Row_Remove_OnClicked(control)
    local data = ZO_ScrollList_GetData(control)
    if data then
        local blacklistResult = RemoveFromGuildBlacklist(data.guildId, data.index)
        if not ZO_GuildRecruitment_Manager.IsBlacklistResultSuccessful(blacklistResult) then
            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
        end
    end
end

function ZO_GuildRecruitment_Blacklist_Keyboard:Row_Note_OnMouseEnter(control)
    local parentControl = control:GetParent()

    local data = ZO_ScrollList_GetData(parentControl)
    self.currentData = data
    if data then
        InitializeTooltip(InformationTooltip, control, RIGHT, -2, 0)
        SetTooltipText(InformationTooltip, data.note)
    end
end

function ZO_GuildRecruitment_Blacklist_Keyboard:Row_Note_OnMouseExit(control)
    ClearTooltip(InformationTooltip)

    self.currentData = nil

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:Row_Note_OnClicked(control)
    local parentControl = control:GetParent()
    local data = ZO_ScrollList_GetData(parentControl)
    if data then
        local dialogData = 
        {
            displayName = data.name,
            index = data.index,
            note = data.note,
            changedCallback = function(displayName, note)
                local blacklistResult = SetGuildBlacklistNote(self.guildId, data.index, note)
                if not ZO_GuildRecruitment_Manager.IsBlacklistResultSuccessful(blacklistResult) then
                    ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
                end
            end
        }
        ZO_Dialogs_ShowDialog("EDIT_NOTE", dialogData)
    end
end

function ZO_GuildRecruitment_Blacklist_Keyboard:OnShowing()
    ZO_GuildRecruitment_Blacklist_Shared.OnShowing(self)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:OnHidden()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:ShowCategory()
    ZO_GuildFinder_Panel_Shared.ShowCategory(self)

    if self:GetFragment():IsShowing() then
        ZO_GuildRecruitment_Blacklist_Shared.OnShowing(self)
    end

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_Blacklist_Keyboard:HideCategory()
    ZO_GuildFinder_Panel_Shared.HideCategory(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

-- XML Functions
-----------------

function ZO_GuildRecruitment_Blacklist_Keyboard_Row_OnMouseEnter(control)
    GUILD_RECRUITMENT_BLACKLIST_KEYBOARD:Row_OnMouseEnter(control)
end

function ZO_GuildRecruitment_Blacklist_Keyboard_Row_OnMouseExit(control)
    GUILD_RECRUITMENT_BLACKLIST_KEYBOARD:Row_OnMouseExit(control)
end

function ZO_GuildRecruitment_Blacklist_Keyboard_Row_OnMouseUp(control, button, upInside)
    GUILD_RECRUITMENT_BLACKLIST_KEYBOARD:Row_OnMouseUp(control, button, upInside)
end

function ZO_GuildRecruitment_Blacklist_Keyboard_Row_Remove_OnMouseEnter(control)
    GUILD_RECRUITMENT_BLACKLIST_KEYBOARD:Row_Remove_OnMouseEnter(control)
end

function ZO_GuildRecruitment_Blacklist_Keyboard_Row_Remove_OnMouseExit(control)
    GUILD_RECRUITMENT_BLACKLIST_KEYBOARD:Row_Remove_OnMouseExit(control)
end

function ZO_GuildRecruitment_Blacklist_Keyboard_Remove_OnClicked(control)
    GUILD_RECRUITMENT_BLACKLIST_KEYBOARD:Row_Remove_OnClicked(control)
end

function ZO_GuildRecruitment_Blacklist_Keyboard_Row_Note_OnMouseEnter(control)
    GUILD_RECRUITMENT_BLACKLIST_KEYBOARD:Row_Note_OnMouseEnter(control)
end

function ZO_GuildRecruitment_Blacklist_Keyboard_Row_Note_OnMouseExit(control)
    GUILD_RECRUITMENT_BLACKLIST_KEYBOARD:Row_Note_OnMouseExit(control)
end

function ZO_GuildRecruitment_Blacklist_Keyboard_Row_Note_OnClicked(control)
    GUILD_RECRUITMENT_BLACKLIST_KEYBOARD:Row_Note_OnClicked(control)
end

function ZO_GuildRecruitment_Blacklist_Keyboard_OnInitialized(control)
    GUILD_RECRUITMENT_BLACKLIST_KEYBOARD = ZO_GuildRecruitment_Blacklist_Keyboard:New(control)
end

function ZO_GuildRecruitment_AddToBlacklistDialog_Keyboard_OnInitialized(self)
    local function UpdateAddRestrictions(nameEditControl)
        local blacklistDisplayName = nameEditControl:GetText()
        local confirmButton = self:GetNamedChild("Confirm")
        local confirmButtonState = BSTATE_NORMAL
        local confirmButtonStateLocked = false
        local result = IsGuildBlacklistAccountNameValid(self.data.guildId, blacklistDisplayName)
        local errorText

        if not ZO_GuildRecruitment_Manager.IsBlacklistResultSuccessful(result) then
            confirmButtonState = BSTATE_DISABLED
            confirmButtonStateLocked = true
            if result ~= GUILD_BLACKLIST_RESPONSE_DISPLAY_NAME_EMPTY then
                errorText = zo_strformat(GetString("SI_GUILDBLACKLISTRESPONSE", result), blacklistDisplayName)
            end
        end
        confirmButton:SetState(confirmButtonState, confirmButtonLocked)

        if errorText then
            InitializeTooltip(InformationTooltip, nameEditControl, RIGHT, -35, 0)
            SetTooltipText(InformationTooltip, errorText, ZO_ERROR_COLOR:UnpackRGB())
        else
            ClearTooltip(InformationTooltip)
        end
    end

    local nameEdit = self:GetNamedChild("NameEdit")
    ZO_PreHookHandler(nameEdit, "OnTextChanged", function(editControl)
        UpdateAddRestrictions(editControl)
    end)

    ZO_Dialogs_RegisterCustomDialog("GUILD_ADD_PLAYER_TO_BLACKLIST",
    {
        title =
        {
            text = SI_GUILD_RECRUITMENT_BLACKLIST_ADD_PLAYER_DIALOG_TITLE,
        },
        mainText =
        {
            text = SI_GUILD_RECRUITMENT_BLACKLIST_ADD_PLAYER_DIALOG_DESCRIPTION,
        },
        canQueue = true,
        customControl = self,
        setup = function(dialog)
            local nameEditControl = dialog:GetNamedChild("NameEdit")
            nameEditControl:SetText("")
            dialog:GetNamedChild("NoteEdit"):SetText("")
            UpdateAddRestrictions(nameEditControl)
        end,
        buttons =
        {
            -- Yes Button
            {
                control = self:GetNamedChild("Confirm"),
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_YES),
                callback = function(dialog)
                    local nameControl = dialog:GetNamedChild("NameEdit")
                    local name = nameControl:GetText()
                    local noteControl = dialog:GetNamedChild("NoteEdit")
                    local note = noteControl:GetText()

                    local blacklistResult = AddToGuildBlacklistByDisplayName(dialog.data.guildId, name, note)
                    if not ZO_GuildRecruitment_Manager.IsAddedToBlacklistSuccessful(blacklistResult) then
                        ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
                    end
                end,
            },
            -- No Button
            {
                control = self:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_NO),
            },
        },
        finishedCallback = function()
            ClearTooltipImmediately(InformationTooltip)
        end,
    })
end