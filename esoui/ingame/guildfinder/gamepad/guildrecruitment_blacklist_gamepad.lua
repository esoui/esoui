------------------
-- Guild Finder --
------------------
ZO_GUILD_RECRUITMENT_BLACKLIST_GAMEPAD_NAME_COLUMN_SIZE = 730

ZO_GUILD_RECRUITMENT_BLACKLIST_GAMEPAD_ENTRY_HEIGHT = 64

ZO_GUILD_RECRUITMENT_GAMEPAD_BLACKLIST_PLAYER_DIALOG_NAME = "GAMEPAD_ADD_PLAYER_TO_BLACKLIST_PROMPT"
ZO_GUILD_RECRUITMENT_GAMEPAD_SELECT_BLACKLIST_ENTRY_DIALOG_NAME = "GAMEPAD_SELECT_BLACKLIST_ENTRY_PROMPT"

ZO_GuildRecruitment_Blacklist_Gamepad = ZO_Object.MultiSubclass(ZO_GuildRecruitment_Blacklist_Shared, ZO_GuildRecruitment_Panel_Shared, ZO_GuildFinder_ListPanel_GamepadBehavior)

function ZO_GuildRecruitment_Blacklist_Gamepad:New(...)
    return ZO_GuildFinder_ListPanel_GamepadBehavior.New(self, ...)
end

function ZO_GuildRecruitment_Blacklist_Gamepad:Initialize(control)
    ZO_GuildRecruitment_Blacklist_Shared.Initialize(self, control)
    ZO_GuildRecruitment_Panel_Shared.Initialize(self, control)
    ZO_GuildFinder_ListPanel_GamepadBehavior.Initialize(self, control)

    self:SetAutomaticallyColorRows(false)

    local function SetupRow(control, data)
        self:SetupRow(control, data)
    end

    ZO_ScrollList_AddDataType(self.list, ZO_GUILD_RECRUITMENT_BLACKLIST_ENTRY_TYPE, "ZO_GuildRecruitment_Blacklist_Row_Gamepad", ZO_GUILD_RECRUITMENT_BLACKLIST_GAMEPAD_ENTRY_HEIGHT, SetupRow)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

    self:SetEmptyText(GetString(SI_GUILD_RECRUITMENT_BLACKLIST_EMPTY_LIST_TEXT));
    self:SetupSort(ZO_GUILD_RECRUITMENT_BLACKLIST_ENTRY_SORT_KEYS, "name", ZO_SORT_ORDER_UP)

    self:InitializeBlacklistPlayerDialog()
    self:InitializeSelectBlacklistEntryDialog()
end

function ZO_GuildRecruitment_Blacklist_Gamepad:SetupRow(control, data)
    ZO_GuildRecruitment_Blacklist_Shared.SetupRow(self, control, data)

    local nameLabel = control:GetNamedChild("Name")
    nameLabel:SetText(ZO_FormatUserFacingDisplayName(data.name))
end

function ZO_GuildRecruitment_Blacklist_Gamepad:OnSelectionChanged(previousData, selectedData)
    ZO_GuildFinder_ListPanel_GamepadBehavior.OnSelectionChanged(self, previousData, selectedData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

    if selectedData then
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_RIGHT_TOOLTIP, ZO_FormatUserFacingDisplayName(selectedData.name), selectedData.note)
    end
end

function ZO_GuildRecruitment_Blacklist_Gamepad:InitializeKeybinds()
    ZO_GuildFinder_ListPanel_GamepadBehavior.InitializeKeybinds(self)
    table.insert(self.keybindStripDescriptor,
        -- edit player
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    ZO_Dialogs_ShowPlatformDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_SELECT_BLACKLIST_ENTRY_DIALOG_NAME, selectedData, { mainTextParams = { ZO_FormatUserFacingDisplayName(selectedData.name) } })
                end
            end,
        }
    )

    table.insert(self.keybindStripDescriptor,
        -- add player
        {
            name = GetString(SI_GUILD_RECRUITMENT_BLACKLIST_PLAYER_ACTION_TEXT),
            keybind = "UI_SHORTCUT_SECONDARY",
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
                ZO_Dialogs_ShowPlatformDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_BLACKLIST_PLAYER_DIALOG_NAME, data)
            end,
        }
    )
end

function ZO_GuildRecruitment_Blacklist_Gamepad:OnCommitComplete()
    GUILD_RECRUITMENT_GAMEPAD:RefreshKeybinds()
end

function ZO_GuildRecruitment_Blacklist_Gamepad:OnShowing()
    ZO_GuildRecruitment_Blacklist_Shared.OnShowing(self)
end

function ZO_GuildRecruitment_Blacklist_Gamepad:GetSelectedNarrationText()
    local narrations = {}
    local selectedData = self:GetSelectedData()
    if selectedData then
        --The name will be narrated in the tooltip, so only narrate the column header here
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_GetPlatformAccountLabel()))
    end
    return narrations
end

--Overridden from base
function ZO_GuildRecruitment_Blacklist_Gamepad:GetHeaderNarration()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_RECRUITMENT_CATEGORY_BLACKLIST))
end

-------------
-- Dialogs --
-------------

function ZO_GuildRecruitment_Blacklist_Gamepad:InitializeBlacklistPlayerDialog()
    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GUILD_RECRUITMENT_GAMEPAD_BLACKLIST_PLAYER_DIALOG_NAME)
    end

    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    ZO_Dialogs_RegisterCustomDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_BLACKLIST_PLAYER_DIALOG_NAME,
    {
        blockDialogReleaseOnPress = true,

        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            self:RegisterPermissionRemovedDialogCallback(GUILD_PERMISSION_MANAGE_BLACKLIST, ReleaseDialog)
            dialog:setupFunc()
        end,

        finishedCallback = function(dialog)
            self:UnregisterPermissionRemovedDialogCallback(GUILD_PERMISSION_MANAGE_BLACKLIST)
        end,

        title =
        {
            text = SI_GUILD_RECRUITMENT_BLACKLIST_PLAYER_ACTION_TEXT,
        },

        parametricList =
        {
            -- user name
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData = {
                    nameField = true,
                    textChangedCallback = function(control)
                        parametricDialog.data.name = control:GetText()
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        local platform = ZO_GetPlatformAccountLabel()
                        control.editBoxControl:SetDefaultText(zo_strformat(SI_REQUEST_DISPLAY_NAME_INSTRUCTIONS, platform))
                        if parametricDialog.data.name then
                            control.editBoxControl:SetText(parametricDialog.data.name)
                        end
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.editBoxControl:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                },
            },

            -- note
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData = {
                    nameField = true,
                    textChangedCallback = function(control)
                        parametricDialog.data.note = control:GetText()
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_BLACKLIST_MESSAGE_LENGTH)
                        control.editBoxControl:SetDefaultText(GetString(SI_GUILD_RECRUITMENT_BLACKLIST_DEFAULT_NOTE_TEXT))
                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        if parametricDialog.data.note then
                            control.editBoxControl:SetText(parametricDialog.data.note)
                        end
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.editBoxControl:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                },
            },

            -- Add to Blacklist
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = {
                    confirmEntry = true,
                    text = GetString(SI_GUILD_RECRUITMENT_ADD_TO_BLACKLIST_ACTION),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local blacklistResult = AddToGuildBlacklistByDisplayName(dialog.data.guildId, dialog.data.name, dialog.data.note)
                        if not ZO_GuildRecruitment_Manager.IsAddedToBlacklistSuccessful(blacklistResult) then
                            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
                        end
                        ReleaseDialog()
                    end,
                },
            },
        },

        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                enabled = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData.messageEntry then
                        if ZO_IsConsolePlatform() then
                            if IsConsoleCommunicationRestricted() then
                                return false, GetString(SI_CONSOLE_COMMUNICATION_PERMISSION_ERROR_GLOBALLY_RESTRICTED)
                            end
                        end
                    elseif targetData.confirmEntry then
                        local blacklistDisplayName = dialog.data.name or ""
                        local result = IsGuildBlacklistAccountNameValid(dialog.data.guildId, blacklistDisplayName)
                        if ZO_GuildRecruitment_Manager.IsBlacklistResultSuccessful(result) then
                            return true
                        else
                            local errorText = zo_strformat(GetString("SI_GUILDBLACKLISTRESPONSE", result), blacklistDisplayName)
                            return false, errorText
                        end
                    end
                end,
                callback = function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    data.callback(dialog)
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
                callback = function()
                    ReleaseDialog()
                end,
            },
        }
    })
end

function ZO_GuildRecruitment_Blacklist_Gamepad:InitializeSelectBlacklistEntryDialog()
    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GUILD_RECRUITMENT_GAMEPAD_SELECT_BLACKLIST_ENTRY_DIALOG_NAME)
    end

    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    ZO_Dialogs_RegisterCustomDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_SELECT_BLACKLIST_ENTRY_DIALOG_NAME,
    {
        blockDialogReleaseOnPress = true,

        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },

        setup = function(dialog)
            self:RegisterPermissionRemovedDialogCallback(GUILD_PERMISSION_MANAGE_BLACKLIST, ReleaseDialog)
            dialog:setupFunc()
        end,

        finishedCallback = function(dialog)
            self:UnregisterPermissionRemovedDialogCallback(GUILD_PERMISSION_MANAGE_BLACKLIST)
        end,

        title =
        {
            text = SI_GAMEPAD_OPTIONS_MENU,
        },

        parametricList =
        {
            -- Remove from Blacklist
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = {
                    text = GetString(SI_GUILD_RECRUITMENT_BLACKLIST_REMOVE),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local blacklistResult = RemoveFromGuildBlacklist(dialog.data.guildId, dialog.data.index)
                        if not ZO_GuildRecruitment_Manager.IsBlacklistResultSuccessful(blacklistResult) then
                            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
                        end
                        ReleaseDialog()
                    end,
                },
            },

            -- Edit Note
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = {
                    text = GetString(SI_SOCIAL_MENU_EDIT_NOTE),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local function NoteChangedCallback(displayName, note)
                            local blacklistResult = SetGuildBlacklistNote(self.guildId, dialog.data.index, note)
                            if not ZO_GuildRecruitment_Manager.IsBlacklistResultSuccessful(blacklistResult) then
                                ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
                            end
                        end

                        ReleaseDialog()
                        local data =
                        {
                            displayName = dialog.data.name,
                            index = dialog.data.index,
                            note = dialog.data.note,
                            noteChangedCallback = NoteChangedCallback,
                        }
                        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SOCIAL_EDIT_NOTE_DIALOG", data)
                    end,
                },
            },

            -- View Gamercard
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData =
                {
                    text = GetString(GetGamerCardStringId()),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    visible = IsConsoleUI,
                    callback = function(dialog)
                        ZO_ShowGamerCardFromDisplayNameOrFallback(dialog.data.name, ZO_ID_REQUEST_TYPE_GUILD_BLACKLIST_INFO, self.guildId, dialog.data.index)
                        ReleaseDialog()
                    end,
                }
            },
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    data.callback(dialog)
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    ReleaseDialog()
                end,
            },
        }
    })
end

-- XML Functions
-----------------

function ZO_GuildRecruitment_Blacklist_Gamepad_OnInitialized(control)
    GUILD_RECRUITMENT_BLACKLIST_GAMEPAD = ZO_GuildRecruitment_Blacklist_Gamepad:New(control)
end
