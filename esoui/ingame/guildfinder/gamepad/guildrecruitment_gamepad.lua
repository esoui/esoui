------------------
-- Guild Finder --
------------------
ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_GUILD_LISTING = 1
ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_APPLICATIONS = 2
ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_RESPONSE_MESSAGE = 3
ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_BLACKLIST = 4

ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_COLUMN_WIDTH = 350
ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_INDENT_X = 10

local ZO_GuildRecruitment_Gamepad = ZO_GuildRecruitment_Shared:Subclass()

function ZO_GuildRecruitment_Gamepad:New(...)
    return ZO_GuildRecruitment_Shared.New(self, ...)
end

function ZO_GuildRecruitment_Gamepad:Initialize(control)
    ZO_GuildRecruitment_Shared.Initialize(self, control)

    self.exitHelperPanelFunction = function()
        self:DeactiveCurrentPanel()
    end

    local function GetGuildRecruitmentStatus()
        local recruitmentMessage, headerMessage, recruitmentStatus = GetGuildRecruitmentInfo(self.guildId)
        return GetString("SI_GUILDRECRUITMENTSTATUSATTRIBUTEVALUE", recruitmentStatus)
    end

    self.headerData =
    {
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_RECRUITMENT_HEADER_GUILD_LABEL),
        data1Text = function() return GetGuildName(self.guildId) end,
        data2HeaderText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_STATUS),
        data2Text = GetGuildRecruitmentStatus,
    }

    GUILD_RECRUITMENT_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self.control, true)
    GUILD_RECRUITMENT_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, state)
                                                                if state == SCENE_FRAGMENT_SHOWING then
                                                                    self:OnShowing()
                                                                elseif state == SCENE_FRAGMENT_HIDING then
                                                                    self:OnHiding()
                                                                end
                                                            end)
end

-- functions needed to be part of the Gamepad Guild Home

function ZO_GuildRecruitment_Gamepad:SetMainList(list)
    self.recruitmentList = list
end

function ZO_GuildRecruitment_Gamepad:SetOptionsList(optionsList)
    self.optionsList = optionsList
end

function ZO_GuildRecruitment_Gamepad:SetOwningScreen(owningScreen)
    self.owningScreen = owningScreen
end

function ZO_GuildRecruitment_Gamepad:OnTargetChanged(list, selectedData, oldSelectedData)
    if selectedData ~= nil then
        self:DeactiveCurrentPanel()
        self:HideCurrentCategory()
        self.currentCategory = selectedData.category
        self:ShowCurrentCategory()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

-- end Gamepad Guild Home functions

function ZO_GuildRecruitment_Gamepad:IsSceneShown()
    return GUILD_RECRUITMENT_GAMEPAD_FRAGMENT:IsShowing()
end

function ZO_GuildRecruitment_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = 
    { 
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                if self.currentCategory == ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_RESPONSE_MESSAGE then
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_GUILD_RECRUITMENT_RESPONSE_MESSAGE")
                else
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                    self:ActivateCurrentPanel()
                end
            end,
            visible = function()
                local helperPanel = self.categoryToHelperPanel[self.currentCategory]
                return helperPanel and helperPanel:CanBeActivated()
            end,
        },

        -- contextual action (GuildListing: Link in Chat, Blacklist: Add Player)
        {
            name = function()
                if self.currentCategory == ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_GUILD_LISTING then
                    return GetString(SI_GUILD_RECRUITMENT_LINK_IN_CHAT)
                elseif self.currentCategory == ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_BLACKLIST then
                    return GetString(SI_GUILD_RECRUITMENT_BLACKLIST_PLAYER_ACTION_TEXT)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            enabled = function()
                if self.currentCategory == ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_GUILD_LISTING then
                    local numMembers, _, _, numInvitees = GetGuildInfo(self.guildId)
                    if numMembers + numInvitees >= MAX_GUILD_MEMBERS then
                        return false, GetString(SI_GUILD_RECRUITMENT_MAX_GUILDS_CANT_LINK)
                    end
                elseif self.currentCategory == ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_BLACKLIST then
                    if GetNumGuildBlacklistEntries(self.guildId) >= MAX_GUILD_BLACKLISTED_PLAYERS then
                        return false, GetString("SI_GUILDBLACKLISTRESPONSE", GUILD_BLACKLIST_RESPONSE_BLACKLIST_FULL)
                    end
                end
                return true
            end,
            visible = function()
                local showForGuildListing = self.currentCategory == ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_GUILD_LISTING and GetGuildRecruitmentStatus(self.guildId) == GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_LISTED
                local showForBlacklist = self.currentCategory == ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_BLACKLIST
                return showForGuildListing or showForBlacklist
            end,
            callback = function()
                if self.currentCategory == ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_GUILD_LISTING then
                    local link = GetGuildRecruitmentLink(self.guildId, LINK_STYLE_BRACKETS)
                    ZO_LinkHandler_InsertLinkAndSubmit(link)
                elseif self.currentCategory == ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_BLACKLIST then
                    local data =
                    {
                        guildId = self.guildId,
                    }
                    ZO_Dialogs_ShowPlatformDialog(ZO_GUILD_RECRUITMENT_GAMEPAD_BLACKLIST_PLAYER_DIALOG_NAME, data)
                end
            end,
        },

        -- back
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                GAMEPAD_GUILD_HUB:SetEnterInSingleGuildList(true)
                SCENE_MANAGER:Hide("gamepad_guild_home")
            end,
        },
    }
end

function ZO_GuildRecruitment_Gamepad:PerformDeferredInitialization()
    if self.deferredInitialized then 
        return
    end
    self.deferredInitialized = true

    self:InitializeKeybindStripDescriptors()
    self:InitializeResponseMessageDialog()
    self:InitializeCategoryListData()
end

function ZO_GuildRecruitment_Gamepad:RefreshKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_Gamepad:InitializeCategoryListData()
    self.categoryData = {}
    self.categoryToHelperPanel = {}

    -- Guild Listing
    local guildListData = ZO_GamepadEntryData:New(GetString(SI_GUILD_RECRUITMENT_CATEGORY_GUILD_LISTING), "EsoUI/Art/GuildFinder/Gamepad/gp_guildRecruitment_menuIcon_guildListing.dds")
    guildListData.category = ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_GUILD_LISTING
    guildListData:SetIconTintOnSelection(true)
    table.insert(self.categoryData, guildListData)
    self.categoryToHelperPanel[ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_GUILD_LISTING] = GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD

    -- Applications List
    local applicationsData = ZO_GamepadEntryData:New(GetString(SI_GUILD_RECRUITMENT_CATEGORY_APPLICATIONS), "EsoUI/Art/GuildFinder/Gamepad/gp_guildRecruitment_menuIcon_applications.dds")
    applicationsData:SetIconTintOnSelection(true)
    applicationsData.category = ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_APPLICATIONS
    applicationsData.visible = function() return DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_MANAGE_APPLICATIONS) end
    applicationsData.narrationText = function(entryData, entryControl)
        local narrations = {}

        -- Generate the standard parametric list entry narration
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        --Generate the narration for the applications list being empty
        ZO_AppendNarration(narrations, GUILD_RECRUITMENT_APPLICATIONS_GAMEPAD:GetEmptyRowNarration())

        return narrations
    end
    table.insert(self.categoryData, applicationsData)
    self.categoryToHelperPanel[ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_APPLICATIONS] = GUILD_RECRUITMENT_APPLICATIONS_GAMEPAD

    -- Response Message
    local responseMessageData = ZO_GamepadEntryData:New(GetString(SI_GUILD_RECRUITMENT_DEFAULT_RESPONSE_HEADER), "EsoUI/Art/GuildFinder/Gamepad/gp_guildRecruitment_menuIcon_response_message.dds")
    responseMessageData:SetIconTintOnSelection(true)
    responseMessageData.category = ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_RESPONSE_MESSAGE
    responseMessageData.visible = function() return DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_MANAGE_APPLICATIONS) end
    responseMessageData.narrationText = function(entryData, entryControl)
        local narrations = {}

        -- Generate the standard parametric list entry narration
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        -- Helper panel
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_RECRUITMENT_DEFAULT_RESPONSE_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_RECRUITMENT_DEFAULT_RESPONSE_DESCRIPTION)))

        local defaultResponseMessageText = GUILD_RECRUITMENT_RESPONSE_MESSAGE_GAMEPAD:GetDefaultMessageText()
        if defaultResponseMessageText == "" then
            defaultResponseMessageText = GetString(SI_GUILD_RECRUITMENT_DEFAULT_RESPONSE_DEFAULT_TEXT)
        end
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(defaultResponseMessageText))

        return narrations
    end
    table.insert(self.categoryData, responseMessageData)
    self.categoryToHelperPanel[ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_RESPONSE_MESSAGE] = GUILD_RECRUITMENT_RESPONSE_MESSAGE_GAMEPAD

    -- Blacklist
    local blackListData = ZO_GamepadEntryData:New(GetString(SI_GUILD_RECRUITMENT_CATEGORY_BLACKLIST), "EsoUI/Art/GuildFinder/Gamepad/gp_guildRecruitment_menuIcon_blacklist.dds")
    blackListData:SetIconTintOnSelection(true)
    blackListData.category = ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_BLACKLIST
    blackListData.visible =  function() return DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_MANAGE_BLACKLIST) end
    blackListData.narrationText = function(entryData, entryControl)
        local narrations = {}

        -- Generate the standard parametric list entry narration
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        --Generate the narration for the blacklist being empty
        ZO_AppendNarration(narrations, GUILD_RECRUITMENT_BLACKLIST_GAMEPAD:GetEmptyRowNarration())

        return narrations
    end
    table.insert(self.categoryData, blackListData)
    self.categoryToHelperPanel[ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_BLACKLIST] = GUILD_RECRUITMENT_BLACKLIST_GAMEPAD
end

function ZO_GuildRecruitment_Gamepad:SetGuildId(guildId)
    ZO_GuildRecruitment_Shared.SetGuildId(self, guildId)

    if self.deferredInitialized then
        self:RefreshGuildListingView()
    end
end

function ZO_GuildRecruitment_Gamepad:RefreshGuildPermissionsState()
    if GUILD_RECRUITMENT_GAMEPAD_FRAGMENT:IsShowing() then
        self:RefreshRecruitmentList()
    end
end

function ZO_GuildRecruitment_Gamepad:RefreshGuildListingView()
    if IsPlayerGuildMaster(self.guildId) then
        self.categoryToHelperPanel[ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_GUILD_LISTING] = GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD
    else
        self.categoryToHelperPanel[ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_GUILD_LISTING] = GUILD_RECRUITMENT_GUILD_LISTING_INFO_GAMEPAD
    end
end

function ZO_GuildRecruitment_Gamepad:RefreshRecruitmentList()
    if not self.recruitmentList then
        return
    end

    self.recruitmentList:Clear()

    for i, data in ipairs(self.categoryData) do
        local visible = data.visible or true
        if type(data.visible) == "function" then
            visible = data.visible()
        end

        if visible then
            self.recruitmentList:AddEntry("ZO_GamepadMenuEntryTemplate", data)
        end
    end

    self.recruitmentList:Commit()
end

function ZO_GuildRecruitment_Gamepad:ActivateCurrentPanel()
    local helperPanel = self.categoryToHelperPanel[self.currentCategory]
    if helperPanel then
        helperPanel:RegisterCallback("PanelSelectionEnd", self.exitHelperPanelFunction)
        self.recruitmentList:Deactivate()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        helperPanel:Activate()
    end
end

function ZO_GuildRecruitment_Gamepad:DeactiveCurrentPanel()
    local helperPanel = self.categoryToHelperPanel[self.currentCategory]
    if helperPanel then
        helperPanel:UnregisterCallback("PanelSelectionEnd", self.exitHelperPanelFunction)
        helperPanel:Deactivate()
        self.recruitmentList:Activate()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GuildRecruitment_Gamepad:ShowCurrentCategory()
    if self:IsSceneShown() then
        self:RefreshGuildListingView()
        local helperPanel = self.categoryToHelperPanel[self.currentCategory]
        if helperPanel then
            helperPanel:SetGuildId(self.guildId)
            helperPanel:ShowCategory()
        end
    end
end

function ZO_GuildRecruitment_Gamepad:HideCurrentCategory()
    local helperPanel = self.categoryToHelperPanel[self.currentCategory]
    if helperPanel then
        helperPanel:HideCategory()
    end
end

function ZO_GuildRecruitment_Gamepad:OnShowing()
    self:PerformDeferredInitialization()
    self:RefreshRecruitmentList()
    if self.openApplicationsOnShowing then
        self:ShowApplicationsList()
        self.openApplicationsOnShowing = false
    end
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    GAMEPAD_GUILD_HOME:SetContentHeaderHidden(true)
end

function ZO_GuildRecruitment_Gamepad:OnHiding()
    self:DeactiveCurrentPanel()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    GAMEPAD_GUILD_HOME:SetContentHeaderHidden(false)
end

function ZO_GuildRecruitment_Gamepad:ShowApplicationsList()
    if GUILD_RECRUITMENT_GAMEPAD_FRAGMENT:IsShowing() then
        self.recruitmentList:SetSelectedIndexWithoutAnimation(ZO_GUILD_RECRUITMENT_CATEGORY_GAMEPAD_APPLICATIONS)
    else
        self.openApplicationsOnShowing = true
    end
end

function ZO_GuildRecruitment_Gamepad:InitializeResponseMessageDialog()
    local dialogName = "GAMEPAD_GUILD_RECRUITMENT_RESPONSE_MESSAGE"

    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
    end

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup = function(dialog)
            ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_GUILD_RECRUITMENT_DEFAULT_RESPONSE_HEADER))
            dialog.currentText = GUILD_RECRUITMENT_MANAGER:GetSavedApplicationsDefaultMessage(self.guildId)
            dialog:setupFunc()
        end,
        finishedCallback = function(dialog)
            GUILD_RECRUITMENT_RESPONSE_MESSAGE_GAMEPAD:OnShowing()
        end,
        parametricList =
        {
            -- Edit Box
            {
                template = "ZO_Gamepad_GenericDialog_TextFieldItem_Multiline_Large",
                templateData = 
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)
                        local dialog = data.dialog

                        control.editBoxControl.textChangedCallback = function(control)
                                                                        dialog.currentText = control:GetText()
                                                                     end
                        data.control = control
                        control.editBoxControl:SetDefaultText(GetString(SI_GUILD_RECRUITMENT_DEFAULT_RESPONSE_DEFAULT_TEXT))
                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_APPLICATION_DECLINE_MESSAGE_LENGTH)
                        control.editBoxControl:SetText(dialog.currentText)
                    end,
                    callback = function(dialog)
                        local data = dialog.entryList:GetTargetData()
                        local edit = data.control.editBoxControl

                        edit:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                }
            },

            -- Accept
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = 
                {
                    text = GetString(SI_DIALOG_ACCEPT),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        GUILD_RECRUITMENT_MANAGER:SetSavedApplicationsDefaultMessage(self.guildId, dialog.currentText)
                        ReleaseDialog()
                    end
                }
            },
        },
        blockDialogReleaseOnPress = true,
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
                callback =  function(dialog)
                    ReleaseDialog()
                end,
            },
        },
    })
end

function ZO_GuildRecruitment_Gamepad:GetHeaderData()
    return self.headerData
end

-- XML Functions
------------------

function ZO_GuildRecruitment_Gamepad_OnInitialized(control)
    GUILD_RECRUITMENT_GAMEPAD = ZO_GuildRecruitment_Gamepad:New(control)
end