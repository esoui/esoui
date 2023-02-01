------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD_NAME_COLUMN_SIZE = 225
ZO_GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD_CHAMPION_POINTS_COLUMN_SIZE = 70
ZO_GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD_EXPIRATION_COLUMN_SIZE = 70

ZO_GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD_LEVEL_COLUMN_OFFSET_X = 175
ZO_GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD_EXPIRATION_COLUMN_OFFSET_X = 70

ZO_GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD_ENTRY_HEIGHT = 32

ZO_GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD_ICON_SIZE = 22

ZO_GuildRecruitment_ApplicationsList_Keyboard = ZO_Object.MultiSubclass(ZO_GuildRecruitment_ApplicationsList_Shared, ZO_GuildFinder_ApplicationsList_Keyboard)

function ZO_GuildRecruitment_ApplicationsList_Keyboard:New(...)
    return ZO_GuildRecruitment_ApplicationsList_Shared.New(self, ...)
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:Initialize(control)
    self.entryTemplate = "ZO_GuildRecruitment_Application_Row_Keyboard"

    ZO_GuildFinder_ApplicationsList_Keyboard.Initialize(self, control)
    ZO_GuildRecruitment_ApplicationsList_Shared.Initialize(self, control)

    self:SetEmptyText(GetString(SI_GUILD_RECRUITMENT_APPLICATIONS_EMPTY_LIST_TEXT))

    self.sortFunction = function(listEntry1, listEntry2) return self:CompareGuildApplications(listEntry1, listEntry2) end
    self.sortHeaderGroup:SelectHeaderByKey("durationS")

    self:InitializeKeybindDescriptors()
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Report
        {
            name = GetString(SI_GUILD_FINDER_REPORT_ACTION),
            keybind = "UI_SHORTCUT_REPORT_PLAYER",
            visible = function()
                return self.currentData ~= nil
            end,
            callback = function()
                ZO_GuildRecruitment_ApplicationsList_Keyboard.ReportPlayer(self.currentData)
            end,
        },
        -- Decline Application
        {
            name = GetString(SI_GUILD_RECRUITMENT_APPLICATION_DECLINE),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible = function()
                return self.currentData ~= nil
            end,
            callback = function()
                ZO_Dialogs_ShowPlatformDialog("GUILD_DECLINE_APPLICATION_KEYBOARD", self.currentData, { mainTextParams = { self.currentData.name } })
            end,
        },
        -- Accept Application
        {
            name = GetString(SI_GUILD_RECRUITMENT_APPLICATION_ACCEPT),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                return self.currentData ~= nil
            end,
            enabled = function()
                local numMembers, _, _, numInvitees = GetGuildInfo(GUILD_ROSTER_MANAGER:GetGuildId())
                local totalPlayers = numMembers + numInvitees
                if totalPlayers >= MAX_GUILD_MEMBERS then
                    return false, GetString("SI_SOCIALACTIONRESULT", SOCIAL_RESULT_GUILD_IS_FULL)
                end
                return true
            end,
            callback = function()
                ZO_Dialogs_ShowPlatformDialog("GUILD_ACCEPT_APPLICATION", self.currentData, {mainTextParams = { self.currentData.name }})
            end,
        },
    }
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard.ReportPlayer(data)
    local function ReportCallback()
        -- If the player was reported then decline their application 
        local NO_MESSAGE = ""
        local BLACKLIST = true
        local declineApplicationResult, blacklistResult = DeclineGuildApplication(data.guildId, data.index, NO_MESSAGE, BLACKLIST)
        if ZO_GuildFinder_Manager.IsFailedApplicationResult(declineApplicationResult) then
            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_APPLICATION_DECLINED_FAILED", nil, { mainTextParams = { GetString("SI_GUILDPROCESSAPPLICATIONRESPONSE", declineApplicationResult) } })
        elseif not ZO_GuildRecruitment_Manager.IsAddedToBlacklistSuccessful(blacklistResult) then
            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
        end
    end
    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(data.name, ReportCallback)
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:FilterScrollList()
    ZO_GuildRecruitment_ApplicationsList_Shared.FilterScrollList(self)
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:CompareGuildApplications(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, ZO_GUILD_RECRUITMENT_APPLICATIONS_ENTRY_SORT_KEYS, self.currentSortOrder)
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:SetupRow(control, data)
    ZO_GuildFinder_ApplicationsList_Keyboard.SetupRow(self, control, data)
    ZO_GuildRecruitment_ApplicationsList_Shared.SetupRow(self, control, data)
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:Row_OnMouseEnter(control)
    ZO_GuildFinder_ApplicationsList_Keyboard.Row_OnMouseEnter(self, control)

    local data = ZO_ScrollList_GetData(control)
    self.currentData = data
    if data then
        GUILD_FINDER_MANAGER:ShowApplicationTooltipOnMouseEnter(data, control)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:Row_OnMouseExit(control)
    ZO_GuildFinder_ApplicationsList_Keyboard.Row_OnMouseExit(self, control)

    GUILD_FINDER_MANAGER:HideApplicationTooltipOnMouseExit()

    self.currentData = nil

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:Row_OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        ClearMenu()

        local data = ZO_ScrollList_GetData(control)
        if data then
            if DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_MANAGE_APPLICATIONS) then
                AddMenuItem(GetString(SI_GUILD_RECRUITMENT_APPLICATION_ACCEPT), function() ZO_Dialogs_ShowPlatformDialog("GUILD_ACCEPT_APPLICATION", data, {mainTextParams = { data.name }}) end)
                AddMenuItem(GetString(SI_GUILD_RECRUITMENT_APPLICATION_DECLINE), function() ZO_Dialogs_ShowPlatformDialog("GUILD_DECLINE_APPLICATION_KEYBOARD", data, {mainTextParams = { data.name }}) end)
                AddMenuItem(GetString(SI_GUILD_FINDER_REPORT_ACTION), function() ZO_GuildRecruitment_ApplicationsList_Keyboard.ReportPlayer(data) end)
            end
            AddMenuItem(GetString(SI_SOCIAL_MENU_SEND_MAIL), function() MAIL_SEND:ComposeMailTo(data.name) end)
        end

        self:ShowMenu(control)
    end
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:OnShowing()
    ZO_GuildRecruitment_ApplicationsList_Shared.OnShowing(self)
    ZO_GuildFinder_ApplicationsList_Keyboard.OnShowing(self)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:OnHidden()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:ShowCategory()
    ZO_GuildFinder_ApplicationsList_Keyboard.ShowCategory(self)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard:HideCategory()
    ZO_GuildFinder_ApplicationsList_Keyboard.HideCategory(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

-- XML Functions
-----------------

function ZO_GuildRecruitment_ApplicationsList_Row_OnMouseEnter(control)
    GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD:GetSubcategoryManager(ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_RECEIVED):Row_OnMouseEnter(control)
end

function ZO_GuildRecruitment_ApplicationsList_Row_OnMouseExit(control)
    GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD:GetSubcategoryManager(ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_RECEIVED):Row_OnMouseExit(control)
end

function ZO_GuildRecruitment_ApplicationsList_Row_OnMouseUp(control, button, upInside)
    GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD:GetSubcategoryManager(ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_RECEIVED):Row_OnMouseUp(control, button, upInside)
end

function ZO_GuildRecruitment_ApplicationsList_Keyboard_OnInitialized(control)
    GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD:SetSubcategoryManager(ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_RECEIVED, ZO_GuildRecruitment_ApplicationsList_Keyboard:New(control))
end

function ZO_ConfirmDeclineApplicationDialog_Keyboard_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("GUILD_DECLINE_APPLICATION_KEYBOARD",
    {
        title =
        {
            text = SI_GUILD_RECRUITMENT_APPLICATION_DECLINE_TITLE,
        },
        mainText =
        {
            text = SI_GUILD_RECRUITMENT_APPLICATION_DECLINE_DESCRIPTION,
        },
        canQueue = true,
        customControl = self,
        setup = function(dialog)
            local declineMessageEdit = dialog:GetNamedChild("DeclineMessageEdit")
            declineMessageEdit:SetMaxInputChars(MAX_GUILD_APPLICATION_DECLINE_MESSAGE_LENGTH)
            local checkboxControl = dialog:GetNamedChild("Check")
            local blacklistMessageControl = dialog:GetNamedChild("BlacklistMessage")
            local blacklistMessageEdit = blacklistMessageControl:GetNamedChild("Edit")

            -- Setup checkbox
            ZO_CheckButton_SetUnchecked(checkboxControl)
            ZO_CheckButton_SetLabelText(checkboxControl, GetString(SI_GUILD_RECRUITMENT_ADD_TO_BLACKLIST_ACTION))
            ZO_CheckButton_SetToggleFunction(checkboxControl, function() blacklistMessageControl:SetHidden(not ZO_CheckButton_IsChecked(checkboxControl)) end)

            local function DisableBlacklistCheckbox(tooltipString)
                ZO_CheckButton_SetUnchecked(checkboxControl)
                ZO_CheckButton_SetTooltipEnabledState(checkboxControl, true)
                ZO_CheckButton_SetTooltipAnchor(checkboxControl, RIGHT, checkboxControl.label)
                ZO_CheckButton_SetTooltipText(checkboxControl, tooltipString)

                ZO_CheckButton_Disable(checkboxControl)
            end

            if DoesPlayerHaveGuildPermission(dialog.data.guildId, GUILD_PERMISSION_MANAGE_BLACKLIST) then
                if GetNumGuildBlacklistEntries(dialog.data.guildId) >= MAX_GUILD_BLACKLISTED_PLAYERS then
                    DisableBlacklistCheckbox(GetString("SI_GUILDBLACKLISTRESPONSE", GUILD_BLACKLIST_RESPONSE_BLACKLIST_FULL))
                else
                    ZO_CheckButton_Enable(checkboxControl)
                    ZO_CheckButton_SetTooltipEnabledState(checkboxControl, false)
                end
            else
                DisableBlacklistCheckbox(GetString(SI_GUILD_RECRUITMENT_NO_BLACKLIST_PERMISSION))
            end

            -- Set to default values each time dialog is opened
            declineMessageEdit:SetText(GUILD_RECRUITMENT_MANAGER:GetSavedApplicationsDefaultMessage(dialog.data.guildId) or "")
            blacklistMessageControl:SetHidden(true)
            blacklistMessageEdit:SetText("")
        end,
        buttons =
        {
            -- Confirm Button
            {
                control = self:GetNamedChild("Confirm"),
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    local declineMessageControl = dialog:GetNamedChild("DeclineMessageEdit")
                    local declineMessage = declineMessageControl:GetText()
                    local isChecked = ZO_CheckButton_IsChecked(dialog:GetNamedChild("Check"))
                    local blacklistMessageControl = dialog:GetNamedChild("BlacklistMessageEdit")
                    local blacklistMessage = blacklistMessageControl:GetText()
                    local declineApplicationResult, blacklistResult = DeclineGuildApplication(dialog.data.guildId, dialog.data.index, declineMessage, isChecked, blacklistMessage)
                    if ZO_GuildFinder_Manager.IsFailedApplicationResult(declineApplicationResult) then
                        ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_APPLICATION_DECLINED_FAILED", nil, { mainTextParams = { GetString("SI_GUILDPROCESSAPPLICATIONRESPONSE", declineApplicationResult) } })
                     elseif isChecked and not ZO_GuildRecruitment_Manager.IsAddedToBlacklistSuccessful(blacklistResult) then
                        ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { blacklistResult } })
                    end
                end,
            },
            -- Cancel Button
            {
                control = self:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end