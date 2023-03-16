------------------
-- Guild Finder --
------------------
ZO_GUILD_RECRUITMENT_APPLICATIONS_GAMEPAD_NAME_COLUMN_SIZE = 405
ZO_GUILD_RECRUITMENT_APPLICATIONS_GAMEPAD_CHAMPION_POINTS_COLUMN_SIZE = 150
ZO_GUILD_RECRUITMENT_APPLICATIONS_GAMEPAD_EXPIRATION_COLUMN_SIZE = 150

ZO_GUILD_RECRUITMENT_APPLICATIONS_GAMEPAD_ENTRY_HEIGHT = 64

ZO_GUILD_RECRUITMENT_GAMEPAD_CONFIRM_ACCEPT_DIALOG_NAME = "GAMEPAD_CONFIRM_ACCEPT_APPLICATION_PROMPT"
ZO_GUILD_RECRUITMENT_GAMEPAD_CONFIRM_DECLINE_DIALOG_NAME = "GAMEPAD_CONFIRM_DECLINE_APPLICATION_PROMPT"
ZO_GUILD_RECRUITMENT_GAMEPAD_OPTIONS_DIALOG_NAME = "GAMEPAD_APPLICATION_OPTIONS_PROMPT"

ZO_GuildRecruitment_Applications_Gamepad = ZO_Object.MultiSubclass(ZO_GuildRecruitment_ApplicationsList_Shared, ZO_GuildRecruitment_Panel_Shared, ZO_GuildFinder_ListPanel_GamepadBehavior)

function ZO_GuildRecruitment_Applications_Gamepad:New(...)
    return ZO_GuildFinder_ListPanel_GamepadBehavior.New(self, ...)
end

function ZO_GuildRecruitment_Applications_Gamepad:Initialize(control)
    ZO_GuildRecruitment_ApplicationsList_Shared.Initialize(self, control)
    ZO_GuildRecruitment_Panel_Shared.Initialize(self, control)
    ZO_GuildFinder_ListPanel_GamepadBehavior.Initialize(self, control)

    self:SetAutomaticallyColorRows(false)

    local function SetupRow(control, data)
        data.iconSize = 40
        self:SetupRow(control, data)
    end

    ZO_ScrollList_AddDataType(self.list, ZO_GUILD_FINDER_APPLICATION_ENTRY_TYPE, "ZO_GuildRecruitment_Applications_Row_Gamepad", ZO_GUILD_RECRUITMENT_APPLICATIONS_GAMEPAD_ENTRY_HEIGHT, SetupRow)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

    self:SetEmptyText(GetString(SI_GUILD_RECRUITMENT_APPLICATIONS_EMPTY_LIST_TEXT));
    self:SetupSort(ZO_GUILD_RECRUITMENT_APPLICATIONS_ENTRY_SORT_KEYS, "durationS", ZO_SORT_ORDER_DOWN)

    self.onGuildPermissionChangedCallback = nil
    self:InitializeConfirmAcceptDialog()
    self:InitializeConfirmDeclineDialog()
    self:InitializeOptionsDialog()
end

function ZO_GuildRecruitment_Applications_Gamepad:SetupRow(control, data)
    ZO_GuildRecruitment_ApplicationsList_Shared.SetupRow(self, control, data)

    local nameLabel = control:GetNamedChild("Name")
    nameLabel:SetText(ZO_FormatUserFacingDisplayName(data.name))
end

function ZO_GuildRecruitment_Applications_Gamepad:OnSelectionChanged(previousData, selectedData)
    ZO_GuildFinder_ListPanel_GamepadBehavior.OnSelectionChanged(self, previousData, selectedData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

    if selectedData then
        GAMEPAD_TOOLTIPS:LayoutGuildApplicationDetails(GAMEPAD_RIGHT_TOOLTIP, selectedData)
    end
end

function ZO_GuildRecruitment_Applications_Gamepad:InitializeKeybinds()
    ZO_GuildFinder_ListPanel_GamepadBehavior.InitializeKeybinds(self)
    table.insert(self.keybindStripDescriptor,
        -- Accept Application
        {
            name = GetString(SI_GUILD_RECRUITMENT_APPLICATION_ACCEPT),
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    local numMembers, _, _, numInvitees = GetGuildInfo(selectedData.guildId)
                    local totalPlayers = numMembers + numInvitees
                    if totalPlayers >= MAX_GUILD_MEMBERS then
                        return false, GetString("SI_SOCIALACTIONRESULT", SOCIAL_RESULT_GUILD_IS_FULL)
                    end
                end
                return true
            end,
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    ZO_Dialogs_ShowPlatformDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_CONFIRM_ACCEPT_DIALOG_NAME, selectedData, {mainTextParams = { ZO_FormatUserFacingDisplayName(selectedData.name) }})
                end
            end,
        }
    )
    table.insert(self.keybindStripDescriptor,
        -- Decline Application
        {
            name = GetString(SI_GUILD_RECRUITMENT_APPLICATION_DECLINE),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    ZO_Dialogs_ShowPlatformDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_CONFIRM_DECLINE_DIALOG_NAME, selectedData, {mainTextParams = { ZO_FormatUserFacingDisplayName(selectedData.name) }})
                end
            end,
        }
    )
    table.insert(self.keybindStripDescriptor,
        -- Options
        {
            name = GetString(SI_GAMEPAD_OPTIONS_MENU),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    ZO_Dialogs_ShowPlatformDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_OPTIONS_DIALOG_NAME, selectedData)
                end
            end,
        }
    )
end

function ZO_GuildRecruitment_Applications_Gamepad:OnCommitComplete()
    GUILD_RECRUITMENT_GAMEPAD:RefreshKeybinds()
end

function ZO_GuildRecruitment_Applications_Gamepad:OnShowing()
    ZO_GuildRecruitment_ApplicationsList_Shared.OnShowing(self)
end

function ZO_GuildRecruitment_Applications_Gamepad:GetSelectedNarrationText()
    local narrations = {}
    local selectedData = self:GetSelectedData()
    if selectedData then
        --Get the narration for the user id column
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_GetPlatformAccountLabel()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.name))

        --Get the narration for the level column
        local levelString = ZO_GetLevelOrChampionPointsNarrationString(selectedData.level, selectedData.championPoints)
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_RECRUITMENT_APPLICATIONS_SORT_HEADER_LEVEL)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(levelString))

        --Get the narration for the expiration column
        local timeRemainingS = GetGuildFinderGuildApplicationDuration(self.guildId, selectedData.index)
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_FINDER_APPLICATIONS_SORT_HEADER_EXPIRATION)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_FormatCountdownTimer(timeRemainingS)))
    end
    return narrations
end

--Overridden from base
function ZO_GuildRecruitment_Applications_Gamepad:GetHeaderNarration()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_RECRUITMENT_CATEGORY_APPLICATIONS))
end

-------------
-- Dialogs --
-------------

function ZO_GuildRecruitment_Applications_Gamepad:InitializeConfirmAcceptDialog()
    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GUILD_RECRUITMENT_GAMEPAD_CONFIRM_ACCEPT_DIALOG_NAME)
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_CONFIRM_ACCEPT_DIALOG_NAME,
    {
        blockDialogReleaseOnPress = true,

        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
            allowRightStickPassThrough = true,
        },

        setup = function(dialog)
            self.acceptConfirmText = nil
            self:RegisterPermissionRemovedDialogCallback(GUILD_PERMISSION_MANAGE_APPLICATIONS, ReleaseDialog)
            dialog:setupFunc()
        end,

        finishedCallback = function(dialog)
            self:UnregisterPermissionRemovedDialogCallback(GUILD_PERMISSION_MANAGE_APPLICATIONS)
        end,

        title =
        {
            text = SI_GUILD_RECRUITMENT_APPLICATION_ACCEPT_TITLE,
        },

        mainText = 
        {
            text = SI_GUILD_RECRUITMENT_APPLICATION_ACCEPT_DESCRIPTION,
        },

        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    local acceptApplicationResult = AcceptGuildApplication(dialog.data.guildId, dialog.data.index)
                    if ZO_GuildFinder_Manager.IsFailedApplicationResult(acceptApplicationResult) then
                        ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_PROCESS_APPLICATION_FAILED", nil, { mainTextParams = { acceptApplicationResult } })
                    end
                    ReleaseDialog()
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function()
                    ReleaseDialog()
                end,
            },
        }
    })
end

function ZO_GuildRecruitment_Applications_Gamepad:InitializeConfirmDeclineDialog()
    local function ReleaseDialog()
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
        ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GUILD_RECRUITMENT_GAMEPAD_CONFIRM_DECLINE_DIALOG_NAME)
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_CONFIRM_DECLINE_DIALOG_NAME,
    {
        blockDialogReleaseOnPress = true,

        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },

        setup = function(dialog)
            self.declineMessage = GUILD_RECRUITMENT_MANAGER:GetSavedApplicationsDefaultMessage(self.guildId)
            self.addToBlacklist = false
            self.blacklistNote = nil
            self:RegisterPermissionRemovedDialogCallback(GUILD_PERMISSION_MANAGE_APPLICATIONS, ReleaseDialog)

            dialog:setupFunc()
        end,

        finishedCallback = function(dialog)
            self:UnregisterPermissionRemovedDialogCallback(GUILD_PERMISSION_MANAGE_APPLICATIONS)
        end,

        title =
        {
            text = SI_GUILD_RECRUITMENT_APPLICATION_DECLINE_TITLE,
        },

        mainText = 
        {
            text = SI_GUILD_RECRUITMENT_APPLICATION_DECLINE_DESCRIPTION,
        },
        parametricList =
        {
            -- Text reply to applicant
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem_Multiline",
                templateData = {
                    textChangedCallback = function(control)
                        local declineMessage = control:GetText()
                        self.declineMessage = declineMessage
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_APPLICATION_DECLINE_MESSAGE_LENGTH)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        data.control = control

                        control.editBoxControl:SetDefaultText(GetString(SI_GUILD_RECRUITMENT_APPLICATION_DECLINE_DEFAULT_RESPONSE))
                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_APPLICATION_DECLINE_MESSAGE_LENGTH)
                        if self.declineMessage then
                            control.editBoxControl:SetText(self.declineMessage)
                        end
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.editBoxControl:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                },
            },
            -- Blacklist checkbox
            {
                template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
                templateData = {
                    text = GetString(SI_GUILD_RECRUITMENT_ADD_TO_BLACKLIST_ACTION),
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local hasPermission = DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_MANAGE_BLACKLIST)
                        local blacklistFull = GetNumGuildBlacklistEntries(self.guildId) >= MAX_GUILD_BLACKLISTED_PLAYERS
                        enabled = hasPermission and not blacklistFull
                        data.enabled = enabled
                        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

                        local checkboxControl = control.checkBox

                        if self.addToBlacklist then
                            ZO_CheckButton_SetChecked(checkboxControl)
                        else
                            ZO_CheckButton_SetUnchecked(checkboxControl)
                        end

                        if enabled then
                            ZO_CheckButton_Enable(checkboxControl)
                        else
                            ZO_CheckButton_Disable(checkboxControl)

                            if selected then
                                local NO_TOOLTIP_TITLE = nil
                                local tooltipText = ""
                                if not hasPermission then
                                    tooltipText = GetString(SI_GUILD_RECRUITMENT_NO_BLACKLIST_PERMISSION)
                                elseif blacklistFull then
                                    tooltipText = GetString("SI_GUILDBLACKLISTRESPONSE", GUILD_BLACKLIST_RESPONSE_BLACKLIST_FULL)
                                end
                                GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, NO_TOOLTIP_TITLE, tooltipText)
                            else
                                GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
                            end
                        end
                    end,
                    callback = function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        local targetControl = dialog.entryList:GetTargetControl()
                        ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                        self.addToBlacklist = ZO_GamepadCheckBoxTemplate_IsChecked(targetControl)

                        local RESELECT_ENTRY = true
                        ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog, nil, RESELECT_ENTRY)
                        SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    end,
                    narrationText = ZO_GetDefaultParametricListToggleNarrationText,
                },
            },
            -- Blacklist Note
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem_Multiline",
                templateData = {
                    textChangedCallback = function(control)
                        local blacklistNote = control:GetText()
                        self.blacklistNote = blacklistNote
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        data.control = control

                        control.editBoxControl:SetDefaultText(GetString(SI_GUILD_RECRUITMENT_BLACKLIST_NOTE_DEFAULT_TEXT))
                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_BLACKLIST_MESSAGE_LENGTH)
                        if self.blacklistNote then
                            control.editBoxControl:SetText(self.blacklistNote)
                        end
                    end,
                    visible = function()
                        return self.addToBlacklist
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.editBoxControl:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                },
            },
            -- Decline applicant
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = {
                    text = GetString(SI_GUILD_RECRUITMENT_APPLICATION_DECLINE),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local declineApplicationResult, blacklistResult = DeclineGuildApplication(dialog.data.guildId, dialog.data.index, self.declineMessage, self.addToBlacklist, self.blacklistNote)
                        ReleaseDialog()
                        if ZO_GuildFinder_Manager.IsFailedApplicationResult(declineApplicationResult) then
                            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_APPLICATION_DECLINED_FAILED", nil, { mainTextParams = { GetString("SI_GUILDPROCESSAPPLICATIONRESPONSE", declineApplicationResult) } })
                        elseif self.addToBlacklist and not ZO_GuildRecruitment_Manager.IsAddedToBlacklistSuccessful(blacklistResult) then
                            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
                        end
                    end,
                },
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

function ZO_GuildRecruitment_Applications_Gamepad:InitializeOptionsDialog()
    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GUILD_RECRUITMENT_GAMEPAD_OPTIONS_DIALOG_NAME)
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_OPTIONS_DIALOG_NAME,
    {
        blockDialogReleaseOnPress = true,

        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },

        setup = function(dialog)
            self:RegisterPermissionRemovedDialogCallback(GUILD_PERMISSION_MANAGE_APPLICATIONS, ReleaseDialog)
            dialog:setupFunc()
        end,

        finishedCallback = function(dialog)
            self:UnregisterPermissionRemovedDialogCallback(GUILD_PERMISSION_MANAGE_APPLICATIONS)
        end,

        title =
        {
            text = SI_GAMEPAD_OPTIONS_MENU,
        },
        parametricList =
        {
            -- Send Mail
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData =
                {
                    text = GetString(SI_SOCIAL_MENU_SEND_MAIL),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        MAIL_MANAGER_GAMEPAD:GetSend():ComposeMailTo(ZO_FormatUserFacingCharacterOrDisplayName(dialog.data.name))
                        ReleaseDialog()
                    end,
                },
            },
            -- Report
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData =
                {
                    text = GetString(SI_GUILD_FINDER_REPORT_ACTION),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local selectedData = self:GetSelectedData()
                        if selectedData then
                            local function ReportCallback()
                                -- If the player was reported then decline their application
                                local NO_MESSAGE = ""
                                local BLACKLIST = true
                                local declineApplicationResult, blacklistResult = DeclineGuildApplication(selectedData.guildId, selectedData.index, NO_MESSAGE, BLACKLIST, NO_MESSAGE)
                                if ZO_GuildFinder_Manager.IsFailedApplicationResult(declineApplicationResult) then
                                    ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_APPLICATION_DECLINED_FAILED", nil, { mainTextParams = { GetString("SI_GUILDPROCESSAPPLICATIONRESPONSE", declineApplicationResult) } })
                                elseif not ZO_GuildRecruitment_Manager.IsAddedToBlacklistSuccessful(blacklistResult) then
                                    ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
                                end
                            end
                            ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(dialog.data.name, ReportCallback)
                        end
                        ReleaseDialog()
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
                    callback = function()
                        local selectedData = self:GetSelectedData()
                        if selectedData then
                            ZO_ShowGamerCardFromDisplayNameOrFallback(selectedData.name, ZO_ID_REQUEST_TYPE_GUILD_APPLICATION_INFO, selectedData.guildId, selectedData.index)
                        end
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
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function()
                    ReleaseDialog()
                end,
            },
        }
    })
end

-- XML Functions
-----------------

function ZO_GuildRecruitment_Applications_Gamepad_OnInitialized(control)
    GUILD_RECRUITMENT_APPLICATIONS_GAMEPAD = ZO_GuildRecruitment_Applications_Gamepad:New(control)
end
