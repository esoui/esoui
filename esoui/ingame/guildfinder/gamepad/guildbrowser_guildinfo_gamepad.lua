------------------
-- Guild Finder --
------------------

ZO_GUILD_BROWSER_GUILD_INFO_ATTRIBUTE_OFFSET_Y = 20
ZO_GUILD_BROWSER_GUILD_INFO_ATTRIBUTE_OFFSET_X = 20

ZO_GuildBrowser_GuildInfo_Gamepad = ZO_Object.MultiSubclass(ZO_GuildBrowser_GuildInfo_Shared, ZO_Gamepad_ParametricList_Screen)

function ZO_GuildBrowser_GuildInfo_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_GuildBrowser_GuildInfo_Gamepad:Initialize(control)
    local sceneName = "guildBrowserGuildInfoGamepad"
    GAMEPAD_GUILD_BROWSER_GUILD_INFO_SCENE = ZO_Scene:New(sceneName, SCENE_MANAGER)

    self.links = {}
    self.currentLinkIndex = 1

    local ACTIVATE_LIST_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_LIST_ON_SHOW, GAMEPAD_GUILD_BROWSER_GUILD_INFO_SCENE)

    self:GetMainList():AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    -- Initialize shared elements in info display area
    local rightPane = control:GetNamedChild("RightPane")
    self.rightPane = rightPane
    local rightPaneFragment = ZO_FadeSceneFragment:New(rightPane)
    GAMEPAD_GUILD_BROWSER_GUILD_INFO_SCENE:AddFragment(rightPaneFragment)

    self.refreshMessageLabel = control:GetNamedChild("RefreshMessage")

    ZO_GuildBrowser_GuildInfo_Shared.Initialize(self, rightPane)

    self.infoPanel = rightPane:GetNamedChild("InfoPanel")
    self.topSection = self.infoPanel:GetNamedChild("TopSection")
    self.scrollContainer = self.infoPanel:GetNamedChild("ScrollContainer")
    self.scrollChild = self.scrollContainer:GetNamedChild("ScrollChild")

    self.heraldry = self.topSection:GetNamedChild("Heraldry")
    self.allianceIcon = self.topSection:GetNamedChild("AllianceIcon")
    self.guildNameLabel = self.topSection:GetNamedChild("GuildName")

    self.guildTraderLabelPair = self.topSection:GetNamedChild("GuildTrader")
    self.guildTraderLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_KIOSK))
    self.playtimeLabelPair = self.topSection:GetNamedChild("Playtime")
    self.playtimeLabelPair.header:SetText(GetString(SI_GUILD_FINDER_GUILD_INFO_PLAYTIME_HEADER))
    self.foundedLabelPair = self.topSection:GetNamedChild("Founded")
    self.foundedLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_FOUNDED_DATE))

    self.sizeLabelPair = self.topSection:GetNamedChild("Size")
    self.sizeLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_SIZE))
    self.personalitiesLabelPair = self.topSection:GetNamedChild("Personalities")
    self.personalitiesLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_PERSONALITIES))
    self.languagesLabelPair = self.topSection:GetNamedChild("Languages")
    self.languagesLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_LANGUAGES))

    self.activitiesLabel = self.scrollChild:GetNamedChild("Activities")
    self.headerMessageLabel = self.scrollChild:GetNamedChild("HeaderMessage")
    self.recruitmentMessageLabel = self.scrollChild:GetNamedChild("RecruitmentMessage")
    local activitiesHeader = self.scrollChild:GetNamedChild("ActivitiesHeader")
    activitiesHeader:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ACTIVITIES))

    self.rolesLabelPair = self.topSection:GetNamedChild("Roles")
    self.rolesLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ROLES))
    self.minCPLabelPair = self.topSection:GetNamedChild("MinCP")
    self.minCPLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP))

    GAMEPAD_GUILD_BROWSER_GUILD_INFO_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    GAMEPAD_GUILD_BROWSER_GUILD_INFO_FRAGMENT:SetHideOnSceneHidden(true)

    self:InitializeSubmitDialog()

    self:BuildActionList()
end

function ZO_GuildBrowser_GuildInfo_Gamepad:IsShown()
    GAMEPAD_GUILD_BROWSER_GUILD_INFO_FRAGMENT:IsShowing()
end

function ZO_GuildBrowser_GuildInfo_Gamepad:GetInfoPanelNarrationText()
    if not self.refreshMessageLabel:IsHidden() then
        --If the refresh message is showing, narrate that instead
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.refreshMessageText)
    elseif not self.infoPanel:IsHidden() then
        local guildData = GUILD_BROWSER_MANAGER:GetGuildData(self.currentGuildId)
        if guildData then
            local narrations = {}
            --Generate the narration for the alliance
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(guildData.alliance))))

            --Generate the narration for the guild name
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(guildData.guildName))

            --Generate the narration for the active members
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_SIZE)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(guildData.size))

            --Generate the narration for the founded date
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_FOUNDED_DATE)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(guildData.foundedDateText))

            --Generate the narration for the play style
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_PERSONALITIES)))
            local personalityString = zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString("SI_GUILDPERSONALITYATTRIBUTEVALUE", guildData.personality))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(personalityString))

            --Generate the narration for the language
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_LANGUAGES)))
            local languageString = zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString("SI_GUILDLANGUAGEATTRIBUTEVALUE", guildData.language))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(languageString))

            --Generate the narration for the playtime
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_FINDER_GUILD_INFO_PLAYTIME_HEADER)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_GuildFinder_Manager.CreatePlaytimeRangeText(guildData)))

            --Generate the narration for the roles
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ROLES)))
            for _, role in ipairs(guildData.roles) do
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_LFGROLE", role)))
            end

            --Generate the narration for the min champion points
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(guildData.minimumCP))

            --Generate the narration for the guild trader
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_KIOSK)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, guildData.guildTraderText)))

            --Generate the narration for the guild header Message
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(guildData.headerMessage))

            --Generate the activities narration
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ACTIVITIES)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(guildData.activitiesText))

            --Generate the narration for the recruitment message
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(guildData.recruitmentMessage))
            return narrations
        end
    end
end

function ZO_GuildBrowser_GuildInfo_Gamepad:BuildActionList()
    local list = self:GetMainList()
    list:Clear()

    local function GetEntryNarrationText(entryData, entryControl)
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.text))
        ZO_AppendNarration(narrations, self:GetInfoPanelNarrationText())
        return narrations
    end

    if GetGuildRecruitmentStatusAttribute(self.currentGuildId) == GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_LISTED then
        local applyEntry = ZO_GamepadEntryData:New(GetString(SI_GUILD_BROWSER_GUILD_INFO_APPLY_TO_GUILD))
        applyEntry.onSelectFunction = function()
            local guildData = GUILD_BROWSER_MANAGER:GetGuildData(self.currentGuildId)
            if guildData then
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SUBMIT_GUILD_FINDER_APPLICATION")
            else
                local data =
                {
                    guildId = self.currentGuildId,
                    onCloseFunction = function() SCENE_MANAGER:HideCurrentScene() end,
                }
                ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_APPLICATION_STALE", data, { mainTextParams = { GetString("SI_GUILDAPPLICATIONRESPONSE", GUILD_APP_RESPONSE_GUILD_DATA_OUT_OF_DATE) } })
            end
        end
        applyEntry.narrationText = GetEntryNarrationText
        list:AddEntry("ZO_GamepadItemSubEntryTemplate", applyEntry)
    else
        local exitEntry = ZO_GamepadEntryData:New(GetString(SI_GUILD_BROWSER_GUILD_INFO_EXIT))
        exitEntry.onSelectFunction = function() SCENE_MANAGER:HideCurrentScene() end
        exitEntry.narrationText = GetEntryNarrationText
        list:AddEntry("ZO_GamepadItemSubEntryTemplate", exitEntry)
    end

    list:Commit()
end

function ZO_GuildBrowser_GuildInfo_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                if #GUILD_BROWSER_MANAGER:GetCurrentApplicationsList() >= MAX_GUILD_FINDER_APPLICATIONS_PER_ACCOUNT then
                    return false, GetString("SI_GUILDAPPLICATIONRESPONSE", GUILD_APP_RESPONSE_MAX_APPLICATIONS_PENDING)
                elseif GUILD_BROWSER_MANAGER:HasPendingApplicationToGuild(self.currentGuildId) then
                    return false, GetString("SI_GUILDAPPLICATIONRESPONSE", GUILD_APP_RESPONSE_OUTSTANDING_APPLICATION)
                elseif GetNumGuilds() >= MAX_GUILDS then
                    return false, GetString("SI_GUILDAPPLICATIONRESPONSE", GUILD_APP_RESPONSE_IN_MAX_GUILDS)
                elseif IsPlayerInGuild(self.currentGuildId) then
                    return false, GetString("SI_GUILDAPPLICATIONRESPONSE", GUILD_APP_RESPONSE_ALREADY_MEMBER)
                end
                return true
            end,
            callback = function()
                local selectedData = self:GetMainList():GetSelectedData()
                selectedData.onSelectFunction()
            end,
        },

        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),

        -- Report
        {
            name = GetString(SI_GUILD_BROWSER_REPORT_GUILD_KEYBIND),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                local function ReportCallback()
                    GUILD_BROWSER_MANAGER:AddReportedGuild(self.currentGuildId)
                end
                GUILD_BROWSER_GAMEPAD:OnReportingGuild()
                local guildData = GUILD_BROWSER_MANAGER:GetGuildData(self.currentGuildId)
                ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGuildTicketScene(guildData.guildName, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_LISTING, ReportCallback)
            end,
        },

        -- Open Guild Link (super special keybind)
        {
            name = GetString(SI_GAMEPAD_GUILD_LINK_KEYBIND),

            keybind = "UI_SHORTCUT_SECONDARY",

            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            callback = function()
                if #self.links > 0 then
                    local currentLink = self.links[self.currentLinkIndex]
                    if currentLink then
                        local text, color, linkType, guildId = ZO_LinkHandler_ParseLink(currentLink.link)
                        self:SetGuildToShow(tonumber(guildId))
                        self:RefreshInfoPanel()
                    end
                end
            end,

            visible = function()
                if #self.links > 0 then
                    local currentLink = self.links[self.currentLinkIndex]
                    if currentLink then
                        return currentLink.linkType == GUILD_LINK_TYPE
                    end
                end
                return false
            end
        },

        -- cycle tooltip
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            name = GetString(SI_GAMEPAD_CYCLE_TOOLTIP_BINDING),

            keybind = "UI_SHORTCUT_INPUT_RIGHT",

            callback = function()
                self.currentLinkIndex = self.currentLinkIndex + 1
                if self.currentLinkIndex > #self.links then
                    self.currentLinkIndex = 1
                end
                self:RefreshTooltip()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end,

            visible = function() return #self.links > 1 end,
        },
    }
end

function ZO_GuildBrowser_GuildInfo_Gamepad:ShowWithGuild(guildId)
    self:SetGuildToShow(guildId)
    SCENE_MANAGER:Push("guildBrowserGuildInfoGamepad")
end

function ZO_GuildBrowser_GuildInfo_Gamepad:GetAllianceIcon(alliance)
    return ZO_GetLargeAllianceSymbolIcon(alliance)
end

function ZO_GuildBrowser_GuildInfo_Gamepad:RefreshInfoPanel()
    ZO_GuildBrowser_GuildInfo_Shared.RefreshInfoPanel(self)

    self.headerData = 
    {
        titleText = GetGuildNameAttribute(self.currentGuildId)
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    local guildData = GUILD_BROWSER_MANAGER:GetGuildData(self.currentGuildId)
    if guildData then
        self.sizeLabelPair.value:SetText(guildData.size)
        self.personalitiesLabelPair.value:SetText(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString("SI_GUILDPERSONALITYATTRIBUTEVALUE", guildData.personality)))
        self.languagesLabelPair.value:SetText(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString("SI_GUILDLANGUAGEATTRIBUTEVALUE", guildData.language)))
        self.guildTraderLabelPair.value:SetText(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, guildData.guildTraderText))
        self.foundedLabelPair.value:SetText(guildData.foundedDateText)
        self.activitiesLabel:SetText(guildData.activitiesText)
        self.playtimeLabelPair.value:SetText(ZO_GuildFinder_Manager.CreatePlaytimeRangeText(guildData))
        self.rolesLabelPair.value:SetText(ZO_GuildFinder_Manager.GetRoleIconsText(guildData.roles))
        self.minCPLabelPair.value:SetText(guildData.minimumCP)
    
        ZO_ClearNumericallyIndexedTable(self.links)
        self.currentLinkIndex = 1
        ZO_ExtractLinksFromText(guildData.headerMessage, ZO_VALID_LINK_TYPES_CHAT, self.links)
        ZO_ExtractLinksFromText(guildData.recruitmentMessage, ZO_VALID_LINK_TYPES_CHAT, self.links)
    end

    self:RefreshTooltip()
    self:BuildActionList()
end

function ZO_GuildBrowser_GuildInfo_Gamepad:RefreshTooltip()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    local links = self.links
    if #links > 0 then
        local currentLinkData = links[self.currentLinkIndex]
        local linkType = currentLinkData.linkType
        local link = currentLinkData.link

        if linkType == COLLECTIBLE_LINK_TYPE then
            GAMEPAD_TOOLTIPS:LayoutCollectibleFromLink(GAMEPAD_RIGHT_TOOLTIP, link)
        elseif linkType == ACHIEVEMENT_LINK_TYPE then
            GAMEPAD_TOOLTIPS:LayoutAchievementFromLink(GAMEPAD_RIGHT_TOOLTIP, link)
        elseif linkType == ITEM_LINK_TYPE then
            GAMEPAD_TOOLTIPS:LayoutItem(GAMEPAD_RIGHT_TOOLTIP, link)
        elseif linkType == GUILD_LINK_TYPE then
            GAMEPAD_TOOLTIPS:LayoutGuildLink(GAMEPAD_RIGHT_TOOLTIP, link)
        end

        return
    end
end

function ZO_GuildBrowser_GuildInfo_Gamepad:SetInLoadingMode(shouldHide)
    self.infoPanel:SetHidden(shouldHide)
    self.refreshMessageLabel:SetHidden(not shouldHide)
end

function ZO_GuildBrowser_GuildInfo_Gamepad:OnShowing()
    ZO_GuildBrowser_GuildInfo_Shared.OnShowing(self)
end

function ZO_GuildBrowser_GuildInfo_Gamepad:OnHidden()
    ZO_GuildBrowser_GuildInfo_Shared.OnHidden(self)
end

function ZO_GuildBrowser_GuildInfo_Gamepad:InitializeSubmitDialog()
    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_SUBMIT_GUILD_FINDER_APPLICATION",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup = function(dialog)
            ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_TITLE))
            self.applicationSubmissionText = GUILD_BROWSER_MANAGER:GetSavedApplicationMessage()

            local ICON_SIZE = 32
            local displayData =
            {
                data1 =
                {
                    header = GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_CHARACTER_LABEL),
                    value = zo_strformat(SI_GAMEPAD_GUILD_BROWSER_GUILD_LIST_CONTEXTUAL_INFO_FORMATTER, GetRawUnitName("player"))
                },
                data2 =
                {
                    header = GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_LEVEL_LABEL),
                    value = zo_strformat(SI_GAMEPAD_GUILD_BROWSER_GUILD_LIST_CONTEXTUAL_INFO_FORMATTER, ZO_GetLevelOrChampionPointsString(GetUnitLevel("player"), GetUnitChampionPoints("player"), ICON_SIZE))
                },
                data3 =
                {
                    header = GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_CLASS_LABEL),
                    value = zo_strformat(SI_GAMEPAD_GUILD_BROWSER_GUILD_LIST_CONTEXTUAL_INFO_FORMATTER, GetUnitClass("player"))
                },
                data4 =
                {
                    header = GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_ACHIEVEMENT_POINTS_LABEL),
                    value = zo_strformat(SI_GAMEPAD_GUILD_BROWSER_GUILD_LIST_CONTEXTUAL_INFO_FORMATTER, GetEarnedAchievementPoints())
                },
            }

            local DONT_LIMIT_NUM_ENTRIES = nil
            dialog:setupFunc(DONT_LIMIT_NUM_ENTRIES, displayData)
        end,
        parametricList =
        {
            -- Application Message
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem_Multiline",
                header = GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_MESSAGE_HEADER),
                templateData = 
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)
                        local dialog = data.dialog

                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_APPLICATION_MESSAGE_LENGTH)
                        control.editBoxControl:SetDefaultText(GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_DEFAULT_EDIT_TEXT))
                        control.editBoxControl.textChangedCallback = function(control)
                                                                        self.applicationSubmissionText = control:GetText()
                                                                     end
                        data.control = control

                        if self.applicationSubmissionText == "" then
                            control.resetFunction = function()
                                control.editBoxControl.textChangedCallback = nil
                                control.editBoxControl:SetText("")
                            end
                        else
                            control.editBoxControl:SetText(self.applicationSubmissionText)
                        end
                    end,
                    callback = function(dialog)
                        local data = dialog.entryList:GetTargetData()
                        local edit = data.control.editBoxControl

                        edit:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                },
            },

            -- Apply To Guild
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData =
                {
                    text = GetString(SI_GUILD_BROWSER_GUILD_INFO_APPLY_TO_GUILD),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local applicationResult = SubmitGuildFinderApplication(self.currentGuildId, self.applicationSubmissionText)
                        if applicationResult ~= GUILD_APP_RESPONSE_APPLICATION_SENT then
                            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_APPLICATION_FAILED", nil, { mainTextParams = { GetString("SI_GUILDAPPLICATIONRESPONSE", applicationResult) } })
                        end

                        ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_SUBMIT_GUILD_FINDER_APPLICATION")
                    end,
                }
            },
        },
        blockDialogReleaseOnPress = true,
        buttons = 
        {
            -- Select
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
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_SUBMIT_GUILD_FINDER_APPLICATION")
                end,
            },
        },
    })
end

-- XML functions
----------------

function ZO_GuildBrowser_GuildInfo_Gamepad_OnInitialized(control)
    GUILD_BROWSER_GUILD_INFO_GAMEPAD = ZO_GuildBrowser_GuildInfo_Gamepad:New(control)
end
