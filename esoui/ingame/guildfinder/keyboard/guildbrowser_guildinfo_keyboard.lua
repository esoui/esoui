------------------
-- Guild Finder --
------------------

-- ZO_GuildBrowser_GuildInfo_Keyboard
--------------------------------------

ZO_GUILD_BROWSER_GUILD_INFO_RECRUITMENT_MESSAGE_BASE_OFFSET_Y = 20

ZO_GuildBrowser_GuildInfo_Keyboard = ZO_GuildBrowser_GuildInfo_Shared:Subclass()

function ZO_GuildBrowser_GuildInfo_Keyboard:New(...)
    return ZO_GuildBrowser_GuildInfo_Shared.New(self, ...)
end

function ZO_GuildBrowser_GuildInfo_Keyboard:Initialize(control)
    ZO_GuildBrowser_GuildInfo_Shared.Initialize(self, control)

    self.topSection = control:GetNamedChild("TopSection")
    self.infoPanel = control:GetNamedChild("InfoPanel")
    self.refreshMessageLabel = control:GetNamedChild("RefreshMessage")

    self.heraldry = self.topSection:GetNamedChild("Heraldry")
    self.allianceIcon = self.topSection:GetNamedChild("AllianceIcon")
    self.guildNameLabel = self.topSection:GetNamedChild("GuildName")
    self.guildTraderLabel = self.topSection:GetNamedChild("GuildTrader")

    self.sizeLabel = self.topSection:GetNamedChild("Size")
    self.foundedLabel = self.topSection:GetNamedChild("Founded")
    self.personalitiesLabel = self.topSection:GetNamedChild("Personalities")
    self.languagesLabel = self.topSection:GetNamedChild("Languages")
    self.playtimeLabel = self.topSection:GetNamedChild("Playtime")

    self.rolesLabel = self.topSection:GetNamedChild("Roles")
    self.minCPLabel = self.topSection:GetNamedChild("MinCP")

    local infoContainerControl = control:GetNamedChild("InfoPanelScrollChild")
    self.activitiesLabel = infoContainerControl:GetNamedChild("Activities")
    self.headerMessageLabel = infoContainerControl:GetNamedChild("HeaderMessage")
    self.recruitmentMessageLabel = infoContainerControl:GetNamedChild("RecruitmentMessage")

    self.backButton = control:GetNamedChild("Back")
    self.backButton.OnMouseUp = function(control, upInside)
                                    if upInside then
                                        self:Close()
                                        PlaySound(SOUNDS.GUILD_FINDER_BACK_FROM_SELECTED_GUILD)
                                    end
                                end
    self.backButtonText = self.backButton:GetNamedChild("Text")

    self:InitializeKeybindStripDescriptor()
    
    local ALWAYS_ANIMATE = true
    KEYBOARD_GUILD_BROWSER_GUILD_INFO_FRAGMENT = ZO_FadeSceneFragment:New(self.control, ALWAYS_ANIMATE)
    KEYBOARD_GUILD_BROWSER_GUILD_INFO_FRAGMENT:RegisterCallback("StateChange", function(oldState, state)
                                                                if state == SCENE_FRAGMENT_SHOWING then
                                                                    self:OnShowing()
                                                                elseif state == SCENE_FRAGMENT_HIDING then
                                                                    self:OnHiding()
                                                                elseif state == SCENE_FRAGMENT_HIDDEN then
                                                                    self:OnHidden()
                                                                end
                                                            end)

    KEYBOARD_LINK_GUILD_INFO_SCENE = ZO_Scene:New("linkGuildInfoKeyboard", SCENE_MANAGER)
    KEYBOARD_LINK_GUILD_INFO_SCENE:RegisterCallback("StateChange", function(oldState, state)
                                                                if state == SCENE_SHOWING then
                                                                    self:OnInfoSceneShowing()
                                                                elseif state == SCENE_HIDDEN then
                                                                    self:OnInfoSceneHidden()
                                                                end
                                                            end)

    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, self.OnLinkClicked, self)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, self.OnLinkClicked, self)
end

function ZO_GuildBrowser_GuildInfo_Keyboard:IsShown()
    KEYBOARD_GUILD_BROWSER_GUILD_INFO_FRAGMENT:IsShowing()
end

function ZO_GuildBrowser_GuildInfo_Keyboard:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Apply To Guild
        {
            name = GetString(SI_GUILD_BROWSER_GUILD_INFO_APPLY_TO_GUILD),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                local guildData = GUILD_BROWSER_MANAGER:GetGuildData(self.currentGuildId)
                if guildData then
                    ZO_Dialogs_ShowDialog("SUBMIT_GUILD_FINDER_APPLICATION")
                else
                    local data =
                    {
                        guildId = self.currentGuildId,
                        onCloseFunction = function() self:Close() end,
                    }
                    ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_APPLICATION_STALE", data, { mainTextParams = { GetString("SI_GUILDAPPLICATIONRESPONSE", GUILD_APP_RESPONSE_GUILD_DATA_OUT_OF_DATE) } })
                end
            end,
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
            visible = function()
                return GetGuildRecruitmentStatusAttribute(self.currentGuildId) == GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_LISTED
            end,
        },

        -- Report
        {
            name = GetString(SI_GUILD_BROWSER_REPORT_GUILD_KEYBIND),
            keybind = "UI_SHORTCUT_REPORT_PLAYER",
            callback = function()
                local function ReportCallback()
                    GUILD_BROWSER_MANAGER:AddReportedGuild(self.currentGuildId)
                end
                local guildData = GUILD_BROWSER_MANAGER:GetGuildData(self.currentGuildId)
                ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGuildTicketScene(guildData.guildName, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_LISTING, ReportCallback)
            end,
        },
    }
end

function ZO_GuildBrowser_GuildInfo_Keyboard:RefreshInfoPanel()
    ZO_GuildBrowser_GuildInfo_Shared.RefreshInfoPanel(self)

    local guildData = GUILD_BROWSER_MANAGER:GetGuildData(self.currentGuildId)
    if guildData then
        ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.sizeLabel, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_SIZE)), guildData.size)
        ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.activitiesLabel, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ACTIVITIES)), guildData.activitiesText)
        ZO_GuildFinder_Manager.SetTextForMetaDataAttributeKeyboard(self.personalitiesLabel, GUILD_META_DATA_ATTRIBUTE_PERSONALITIES, "SI_GUILDPERSONALITYATTRIBUTEVALUE", guildData.personality)
        ZO_GuildFinder_Manager.SetTextForMetaDataAttributeKeyboard(self.languagesLabel, GUILD_META_DATA_ATTRIBUTE_LANGUAGES, "SI_GUILDLANGUAGEATTRIBUTEVALUE", guildData.language)
        ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.guildTraderLabel, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_KIOSK)), guildData.guildTraderText)
        ZO_GuildFinder_Manager.SetTextForNoGrammarValuePairKeyboard(self.foundedLabel, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_FOUNDED_DATE)), guildData.foundedDateText)

        ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.rolesLabel, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ROLES)), ZO_GuildFinder_Manager.GetRoleIconsText(guildData.roles))
        ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.minCPLabel, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP)), guildData.minimumCP)

        local formattedTimeRange = ZO_GuildFinder_Manager.CreatePlaytimeRangeText(guildData)
        ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.playtimeLabel, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString(SI_GUILD_FINDER_GUILD_INFO_PLAYTIME_HEADER)), formattedTimeRange)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GuildBrowser_GuildInfo_Keyboard:GetAllianceIcon(alliance)
    return ZO_GetAllianceSymbolIcon(alliance)
end

function ZO_GuildBrowser_GuildInfo_Keyboard:Close()
    SCENE_MANAGER:RemoveFragment(KEYBOARD_GUILD_BROWSER_GUILD_INFO_FRAGMENT)
    if self.closeCallback then
        self.closeCallback()
        self.closeCallback = nil
    end
end

function ZO_GuildBrowser_GuildInfo_Keyboard:SetInLoadingMode(shouldHide)
    self.topSection:SetHidden(shouldHide)
    self.infoPanel:SetHidden(shouldHide)
    self.refreshMessageLabel:SetHidden(not shouldHide)
end

function ZO_GuildBrowser_GuildInfo_Keyboard:ShowWithGuild(guildId, closeCallback)
    self.closeCallback = closeCallback
    self:SetGuildToShow(guildId)
    SCENE_MANAGER:AddFragment(KEYBOARD_GUILD_BROWSER_GUILD_INFO_FRAGMENT)
    -- showing the fragment will override the panel's visibility. Need to reset it properly here
    local shouldHidePanel = GUILD_BROWSER_MANAGER:GetGuildData(guildId) == nil
    self:SetInLoadingMode(shouldHidePanel)
end

function ZO_GuildBrowser_GuildInfo_Keyboard:OnApplyToGuildSubmit(message)
    local applicationResult = SubmitGuildFinderApplication(self.currentGuildId, message)

    if applicationResult ~= GUILD_APP_RESPONSE_APPLICATION_SENT then
        ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_APPLICATION_FAILED", nil, { mainTextParams = { GetString("SI_GUILDAPPLICATIONRESPONSE", applicationResult) } })
    else
        GUILD_BROWSER_GUILD_INFO_KEYBOARD:Close()
    end
end

function ZO_GuildBrowser_GuildInfo_Keyboard:OnShowing()
    ZO_GuildBrowser_GuildInfo_Shared.OnShowing(self)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildBrowser_GuildInfo_Keyboard:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildBrowser_GuildInfo_Keyboard:OnHidden()
    ZO_GuildBrowser_GuildInfo_Shared.OnHidden(self)
end

-- Link Guild Info Scene Functions
-----------------------------------

function ZO_GuildBrowser_GuildInfo_Keyboard:OnInfoSceneShowing()
    self.backButtonText:SetText(GetString(SI_GUILD_BROWSER_GUILD_INFO_EXIT_BUTTON))
    self:RefreshInfoPanel()
end

function ZO_GuildBrowser_GuildInfo_Keyboard:OnInfoSceneHidden()
    local sceneGroup = SCENE_MANAGER:GetSceneGroup("guildsSceneGroup")
    if GetNumGuilds() == 0 then
        GUILD_SELECTOR:SelectGuildFinder()
        sceneGroup:SetActiveScene("guildBrowserKeyboard")
    else
        GUILD_SELECTOR:SelectGuildByIndex(1)
        sceneGroup:SetActiveScene("guildHome")
    end
    self.backButtonText:SetText(GetString(SI_GUILD_BROWSER_GUILD_INFO_BACK_BUTTON))
end

function ZO_GuildBrowser_GuildInfo_Keyboard:OnLinkClicked(link, button, text, color, linkType, ...)
    if linkType == GUILD_LINK_TYPE and button == MOUSE_BUTTON_INDEX_LEFT then
        local guildId = tonumber(select(1, ...))
        if IsInGamepadPreferredMode() then -- extreme edge case, since you can click links while in Gamepad Mode when on a PC
            GUILD_BROWSER_GUILD_INFO_GAMEPAD:ShowWithGuild(guildId)
        else
            self:SetGuildToShow(guildId)
            if KEYBOARD_LINK_GUILD_INFO_SCENE:IsShowing() then
                self:RefreshInfoPanel()
            else
                MAIN_MENU_KEYBOARD:ShowSceneGroup("guildsSceneGroup", "linkGuildInfoKeyboard")
            end
            self.closeCallback = function() SCENE_MANAGER:HideCurrentScene() end
        end
        return true
    end
end

-- XML functions
----------------

local function SubmitApplicationDialogSetup(dialog, data)
    dialog.guildId = GUILD_BROWSER_GUILD_INFO_KEYBOARD:GetCurrentGuildId()

    local guildData = GUILD_BROWSER_MANAGER:GetGuildData(dialog.guildId)

    local guildNameLabel = dialog:GetNamedChild("GuildName")
    guildNameLabel:SetText(zo_strformat(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_GUILD_NAME, ZO_WHITE:Colorize(guildData.guildName)))

    local characterNameLabel = dialog:GetNamedChild("CharacterName")
    characterNameLabel:SetText(zo_strformat(SI_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_CHARACTER_LABEL), ZO_WHITE:Colorize(GetRawUnitName("player"))))

    local ICON_SIZE = 24
    local levelNameLabel = dialog:GetNamedChild("Level")
    levelNameLabel:SetText(zo_strformat(SI_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_LEVEL_LABEL), ZO_WHITE:Colorize(ZO_GetLevelOrChampionPointsString(GetUnitLevel("player"), GetUnitChampionPoints("player"), ICON_SIZE))))

    local classPointsNameLabel = dialog:GetNamedChild("Class")
    classPointsNameLabel:SetText(zo_strformat(SI_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_CLASS_LABEL), ZO_WHITE:Colorize(GetUnitClass("player"))))

    local achievementPointsNameLabel = dialog:GetNamedChild("AchievementPoints")
    achievementPointsNameLabel:SetText(zo_strformat(SI_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_ACHIEVEMENT_POINTS_LABEL), ZO_WHITE:Colorize(GetEarnedAchievementPoints())))

    local editHeader = dialog:GetNamedChild("ApplicationHeader")
    editHeader:SetText(zo_strformat(SI_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_MESSAGE_HEADER)))

    local editLabel = dialog:GetNamedChild("ApplicationMessageEdit")
    editLabel:SetMaxInputChars(MAX_GUILD_APPLICATION_MESSAGE_LENGTH)
    editLabel:SetText(GUILD_BROWSER_MANAGER:GetSavedApplicationMessage())
end

function ZO_SubmitGuildFinderApplication_Dialog_OnInitialized(control)
    ZO_Dialogs_RegisterCustomDialog("SUBMIT_GUILD_FINDER_APPLICATION",
    {
        customControl = control,
        setup = SubmitApplicationDialogSetup,
        title =
        {
            text = SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control =   control:GetNamedChild("Submit"),
                text =      GetString(SI_GUILD_BROWSER_SUBMIT_APPLICATION_DIALOG_BUTTON_SUBMIT),
                callback =  function(dialog)
                                local message = dialog:GetNamedChild("ApplicationMessageEdit"):GetText()
                                GUILD_BROWSER_GUILD_INFO_KEYBOARD:OnApplyToGuildSubmit(message)
                            end,
            },
            [2] =
            {
                control =   control:GetNamedChild("Cancel"),
                text =      SI_DIALOG_CANCEL,
            }
        }
    })
end

function ZO_GuildBrowser_GuildInfo_Keyboard_OnInitialized(control)
    GUILD_BROWSER_GUILD_INFO_KEYBOARD = ZO_GuildBrowser_GuildInfo_Keyboard:New(control)
end