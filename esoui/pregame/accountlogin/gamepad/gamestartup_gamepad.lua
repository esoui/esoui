--[[
    Server selectors abstract out the platform specific details of deciding which platform to connect to, they should implement:
    OnDeferredInitialize()
    OnShowing()
    GetServerEntries() -> list of EntryData objects
    GetCurrentlySelectedEntry() -> EntryData object
    OnPlayButtonPressed()
    OnSelectedFromInitialList(entryData)
    OnSelected(entryData)
]]--

-- PC server select lists all platforms from platforms.xml directly.
local ZO_PCServerSelector = ZO_InitializingObject:Subclass()

function ZO_PCServerSelector:Initialize(owner)
    self.owner = owner
end

function ZO_PCServerSelector:OnDeferredInitialize()
    local entries = {}

    for platformIndex = 1, GetNumPlatforms() do
        local platformName = GetPlatformInfo(platformIndex)
        local entryData = ZO_GamepadEntryData:New(ZO_GetLocalizedServerName(platformName))
        entryData.platformName = platformName
        entryData.platformIndex = platformIndex
        table.insert(entries, entryData)
    end

    self.entries = entries
end

function ZO_PCServerSelector:OnShowing()
    self.selectedPlatformName = GetCVar("LastPlatform")
end

function ZO_PCServerSelector:GetServerEntries()
    return self.entries
end

function ZO_PCServerSelector:GetCurrentlySelectedEntry()
    local entries = self:GetServerEntries()
    for _, entry in ipairs(entries) do
        if entry.platformName == self.selectedPlatformName then
            return entry
        end
    end
    return nil
end

function ZO_PCServerSelector:OnPlayButtonPressed()
    -- do nothing, we already saved/applied our choice
end

function ZO_PCServerSelector:OnSelectedFromInitialList(entryData)
    -- Called when selecting a server for the first time
    SetCVar("IsServerSelected", "true")
    SetCVar("LastPlatform", entryData.platformName)
    SetSelectedPlatform(entryData.platformIndex)
    self.selectedPlatformName = entryData.platformName
end

function ZO_PCServerSelector:OnSelected(entryData)
    if entryData.platformName ~= self.selectedPlatformName then
        SetCVar("LastPlatform", entryData.platformName)
        SetSelectedPlatform(entryData.platformIndex)
        self.selectedPlatformName = entryData.platformName
        CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", RequestAnnouncements, GetString(SI_GAMEPAD_PREGAME_LOADING))
    end
end

-- Console server select pulls a platform list from console title storage, and picks the first platform from that list. A different platform list will be loaded depending on whether you pick NA or EU.
local ZO_ConsoleServerSelector = ZO_InitializingObject:Subclass()

function ZO_ConsoleServerSelector:Initialize(owner)
    self.owner = owner
end

function ZO_ConsoleServerSelector:OnDeferredInitialize()
    local entries = {}

    for choice = CONSOLE_SERVER_ITERATION_BEGIN, CONSOLE_SERVER_ITERATION_END do
        local entryData = ZO_GamepadEntryData:New(GetString("SI_CONSOLESERVERCHOICE", choice))
        entryData.serverChoice = choice
        table.insert(entries, entryData)
    end

    self.entries = entries

    local function OnPlatformsListLoaded(_, serverChoice)
        self:OnConsolePlatformsListLoaded(serverChoice)
    end
    EVENT_MANAGER:RegisterForEvent("ConsoleServerSelector", EVENT_PLATFORMS_LIST_LOADED, OnPlatformsListLoaded)

    self:SetConsoleLastSelectedPlatform()
end

function ZO_ConsoleServerSelector:OnShowing()
    if not self.selectedServerChoice then
        self.selectedServerChoice = tonumber(GetCVar("SelectedServer"))
    end
end

function ZO_ConsoleServerSelector:GetServerEntries()
    return self.entries
end

function ZO_ConsoleServerSelector:GetCurrentlySelectedEntry()
    for _, entry in ipairs(self:GetServerEntries()) do
        if entry.serverChoice == self.selectedServerChoice then
            return entry
        end
    end
    return nil
end

function ZO_ConsoleServerSelector:OnPlayButtonPressed()
    if tonumber(GetCVar("SelectedServer")) ~= self.selectedServerChoice then
        SetCVar("SelectedServer", self.selectedServerChoice)
        SavePlayerConsoleProfile() --Save only on entering into game
    end
end

function ZO_ConsoleServerSelector:OnSelectedFromInitialList(entryData)
    -- Called when selecting a server for the first time
    self.selectedServerChoice = entryData.serverChoice
    SetCVar("IsServerSelected", "true")
    SetCVar("SelectedServer", self.selectedServerChoice)
    SavePlayerConsoleProfile()
    CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", function() LoadPlatformsList(self.selectedServerChoice) end, GetString(SI_GAMEPAD_PREGAME_LOADING))
end

function ZO_ConsoleServerSelector:OnSelected(entryData)
    -- if user already backed out to IIS we don't have an active profile anymore, so don't kick off a platforms list load
    if self.owner.canCancelOrLoadPlatforms == true and self.selectedServerChoice ~= entryData.serverChoice then
        CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", function() LoadPlatformsList(entryData.serverChoice) end, GetString(SI_GAMEPAD_PREGAME_LOADING))
        self.owner.canCancelOrLoadPlatforms = false
        self.selectedServerChoice = entryData.serverChoice
    end
end

function ZO_ConsoleServerSelector:SetConsoleLastSelectedPlatform()
    --Set the platform to the last logged in platform.
    local lastPlatform = GetCVar("LastPlatform")
    if lastPlatform ~= nil then
        for platformIndex = 1, GetNumPlatforms() do
            local platformName = GetPlatformInfo(platformIndex)
            if platformName == lastPlatform then
                SetSelectedPlatform(platformIndex)
            end
        end
    end
end

function ZO_ConsoleServerSelector:OnConsolePlatformsListLoaded(serverChoice)
    self.selectedServerChoice = serverChoice
    -- if we've already exited this state or backed out to IIS, don't do anything
    if PregameStateManager_GetCurrentState() == "GameStartup" then
        self:SetConsoleLastSelectedPlatform()
        RequestAnnouncements()
    end
end

----
-- ZO_GameStartup_Gamepad
----

local ENTRY_TYPE =
{
    PLAY_BUTTON = "PlayButton",
    VO_LANGUAGE = "VoiceOverLanguage",
    EDIT_BOX = "EditBox",
    SETTINGS = "Settings",
    ANNOUNCEMENTS = "Announcements",
    CREDITS = "Credits",
    QUIT = "Quit",
}

local ENGLISH_VO_LANGUAGE_TEXT = zo_strupper(GetString("SI_OFFICIALLANGUAGE", OFFICIAL_LANGUAGE_ENGLISH))

local g_userOpenedStore = false

local ZO_GameStartup_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_GameStartup_Gamepad:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control)

    self.gotMOTD = false
    self.isWaitingForDurangoAccountSelection = false
    self.canCancelOrLoadPlatforms = true
    self.profileSaveInProgress = false
    if IsConsoleUI() then
        self.serverSelector = ZO_ConsoleServerSelector:New(self)
    elseif ZO_IsPCUI() then
        self.serverSelector = ZO_PCServerSelector:New(self)
    elseif IsGamepadUISupported() then
        internalassert(false, "Server selection not implemented")
    end

    local gameStartup_Gamepad_Fragment = ZO_FadeSceneFragment:New(self.control)
    self.scene = ZO_Scene:New("GameStartup", SCENE_MANAGER)
    GAME_STARTUP_MAIN_GAMEPAD_SCENE = self.scene
    self.scene:AddFragment(gameStartup_Gamepad_Fragment)

    self.announcementFragment = ZO_FadeSceneFragment:New(GameStartup_GamepadMiddlePane)
    self.serverAlertFragment = ZO_FadeSceneFragment:New(GameStartup_Gamepad_ServerAlert)

    self.UpdateDownloadStateHandler = function()
        self:UpdateDownloadState()
    end

    GAME_STARTUP_MAIN_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialize()
            self.serverSelector:OnShowing()
            self:PopulateMainList()
            self:SetCurrentList(self.mainList)

            if self.psnFreeTrialEnded then
                KEYBIND_STRIP:AddKeybindButtonGroup(self.freeTrialEndKeybindDescriptor)

                local platformStore = GetString(SI_FREE_TRIAL_PLATFORM_STORE_PS4)

                --[[ The player needs to purchase the game, no need to wait on RequestAnnouncements to get something that we're going to overwrite anyway ]]--
                self.announcement:SetText(zo_strformat(SI_FREE_TRIAL_EXPIRED_ANNOUNCEMENT, platformStore))
                self.gotMOTD = false
            else
                KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)

                --[[ if we don't have an MOTD, kick off RequestAnnouncements and show a loading animation. The loading animation is dismissed in OnAnnouncementsResult() below ]]--
                if not self.gotMOTD then
                    CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", RequestAnnouncements, GetString(SI_GAMEPAD_PREGAME_LOADING))
                else
                    self.gotMOTD = false
                    self.canCancelOrLoadPlatforms = true
                end
            end

            -- Order matters:
            self:CheckForAdditionalContent()
            self:SetUpdateDownloadProgressEnabled(true)
        elseif newState == SCENE_HIDDEN then
            self:SetUpdateDownloadProgressEnabled(false)
            self:Deactivate()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.psnFreeTrialEnded and self.freeTrialEndKeybindDescriptor or self.mainKeybindStripDescriptor)
        end
    end)

    GAME_STARTUP_INITIAL_SERVER_SELECT_GAMEPAD_SCENE = ZO_Scene:New("InitialGameStartup", SCENE_MANAGER)
    GAME_STARTUP_INITIAL_SERVER_SELECT_GAMEPAD_SCENE:AddFragment(gameStartup_Gamepad_Fragment)

    GAME_STARTUP_INITIAL_SERVER_SELECT_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialize()
            self:PopulateInitialList()
            self:SetCurrentList(self.initialList)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.initialKeybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            self:Deactivate()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.initialKeybindStripDescriptor)
        end
    end)

    local function OnEntitlementUpdated()
        ZO_Dialogs_ReleaseDialog("ADDITIONAL_CONTENT_ENTITLEMENT_WAIT")
        self:CheckForAdditionalContent()
    end

    local function OnStoreClosed()
        -- If we already received the entitlement then no need to wait for it.
        if not CanDownloadAdditionalContent(ADDITIONAL_CONTENT_TYPE_VO) then
            if g_userOpenedStore then
                SetCVar("SelectedEnglishVOLanguage", "1")
                ZO_Dialogs_ShowPlatformDialog("ADDITIONAL_CONTENT_SELECTION_DIALOG", { isFromMenu = g_userOpenedStore })
            else
                ZO_Dialogs_ShowPlatformDialog("ADDITIONAL_CONTENT_ENTITLEMENT_WAIT")
            end
        end
    end

    local function OnStreamingInstallDialogResult(event, result)
        if result == PLATFORM_DIALOG_RESULT_OK then
            if not CanDownloadAdditionalContent(ADDITIONAL_CONTENT_TYPE_VO) then
                if IsConsoleUI() then
                    -- Open store to offer the "purchase" of the additional content entitlement
                    ShowPlatformESOVOAdditionalContentUI()
                else
                    -- Create UI Dialog to fake console store on PC
                    ZO_Dialogs_ShowPlatformDialog("ADDITIONAL_CONTENT_PURCHASE_CONFIRMATION")
                end
            end
        else
            if CanDownloadAdditionalContent(ADDITIONAL_CONTENT_TYPE_VO) then
                if IsConsoleUI() then
                    -- They canceled out of PlayGo and have the entitlement, ask them again.
                    OpenStreamingInstallLanguageChunkPlatformDialog()
                else
                    -- Create UI Dialog to fake console flow that ask about PlayGo on PC
                    ZO_Dialogs_ShowPlatformDialog("PLAYGO_ACCEPT_CONFIRMATION")
                end
            else
                -- They canceled out of PlayGo and don't have the entitlement, return them to VO Language selection dialog.
                if g_userOpenedStore then
                    SetCVar("SelectedEnglishVOLanguage", "1")
                end
                ZO_Dialogs_ShowPlatformDialog("ADDITIONAL_CONTENT_SELECTION_DIALOG", { isFromMenu = g_userOpenedStore })
            end
        end
    end

    EVENT_MANAGER:RegisterForEvent("ZO_GameStartup_Gamepad", EVENT_PLATFORM_ENTITLEMENT_STATE_CHANGED, OnEntitlementUpdated)
    EVENT_MANAGER:RegisterForEvent("ZO_GameStartup_Gamepad", EVENT_PLATFORM_STORE_DIALOG_FINISHED, OnStoreClosed)
    EVENT_MANAGER:RegisterForEvent("ZO_GameStartup_Gamepad", EVENT_STREAMING_INSTALL_DIALOG_FINISHED, OnStreamingInstallDialogResult)
end

function ZO_GameStartup_Gamepad:CheckForAdditionalContent()
    local hasEntitlement = true
    if not IsAdditionalContentUpToDate(ADDITIONAL_CONTENT_TYPE_VO) or GetCVar("SelectedEnglishVOLanguage") == "1" then
        if not IsAdditionalContentDownloading(ADDITIONAL_CONTENT_TYPE_VO) then
            if CanDownloadAdditionalContent(ADDITIONAL_CONTENT_TYPE_VO) then
                DownloadAdditionalContent(ADDITIONAL_CONTENT_TYPE_VO)
                self:ForceListRebuild()
            else
                hasEntitlement = false
                if GetCVar("SelectedEnglishVOLanguage") == "0" then
                    ZO_Dialogs_ShowPlatformDialog("ADDITIONAL_CONTENT_SELECTION_DIALOG", { isFromMenu = g_userOpenedStore })
                    g_userOpenedStore = false
                end
            end
        end
    end

    if hasEntitlement then
        OpenStreamingInstallLanguageChunkPlatformDialog()
    end
end

function ZO_GameStartup_Gamepad:IsDownloadInProgress()
    -- A download is in progress if a Language Pack (Additional Content) is downloading or if the
    -- Base Game is not yet fully installed (in which case a PlayGo download must be in progress)
    local isDownloading = IsAdditionalContentDownloading(ADDITIONAL_CONTENT_TYPE_VO) or not IsGateInstalled("BaseGame")
    return isDownloading
end

function ZO_GameStartup_Gamepad:SetUpdateDownloadProgressEnabled(enabled)
    if enabled then
        -- Start monitoring for changes to the download state and progress.
        EVENT_MANAGER:RegisterForUpdate("ZO_GameStartup_Gamepad.UpdateDownload", 250, self.UpdateDownloadStateHandler)

        -- Perform the initial update immediately.
        self.UpdateDownloadStateHandler()
    else
        EVENT_MANAGER:UnregisterForUpdate("ZO_GameStartup_Gamepad.UpdateDownload")
    end
end

function ZO_GameStartup_Gamepad:UpdateDownloadState()
    local isDownloading = self:IsDownloadInProgress()
    if isDownloading ~= self.isDownloading then
        -- Update the download state and show/hide the download bar fragment.
        self.isDownloading = isDownloading
        if isDownloading then
            self.scene:AddFragment(GAMEPAD_DOWNLOAD_BAR_FRAGMENT)
        else
            self.scene:RemoveFragment(GAMEPAD_DOWNLOAD_BAR_FRAGMENT)
        end

        -- Refresh the list options to ensure that they are consistent with the new download state.
        self:ForceListRebuild()
    end

    if isDownloading then
        -- Update the progress bar while downloading.
        GAMEPAD_DOWNLOAD_BAR:Update()
    end
end

function ZO_GameStartup_Gamepad:PerformDeferredInitialize()
    if self.initialized then return end
    self.initialized = true

    self.serverSelector:OnDeferredInitialize()

    self:InitializeHeaders()
    self:InitializeKeybindDescriptor()
    self:InitializeLists()
    self:InitializeEvents()
    self:InitializeDialogs()
end

function ZO_GameStartup_Gamepad:InitializeHeaders()
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE)
    self:RefreshHeader(GetString(SI_GAME_STARTUP_HEADER))

    self.contentHeader = GameStartup_GamepadMiddlePane:GetNamedChild("Container").header
    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED)
    self.contentHeaderData =
    {
        titleText = GetString(SI_LOGIN_ANNOUNCEMENTS_TITLE),
    }
    ZO_GamepadGenericHeader_Refresh(self.contentHeader, self.contentHeaderData)

    self.announcement = GameStartup_GamepadMiddlePane:GetNamedChild("Container"):GetNamedChild("ContentScrollChildText")
end

function ZO_GameStartup_Gamepad:RefreshHeader(titleText)
    local accountName
    if ZO_IsForceConsoleFlow() then
        accountName = DecorateDisplayName(GetCVar("AccountName"))
    elseif ZO_IsPCUI() then
        -- PC UI will not show account name in the header since we need to specify a username and password
        accountName = ""
    else
        accountName = GetOnlineIdForActiveProfile()
    end

    self.headerData =
    {
        titleText = titleText,
    }
    if accountName ~= "" then
        self.headerData.data1HeaderText = GetString(SI_GAME_STARTUP_GAMEPAD_WELCOME)
        self.headerData.data1Text = accountName
    end
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_GameStartup_Gamepad:InitializeKeybindDescriptor()
    self.mainKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select Control
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,
            callback = function()
                local data = self.mainList:GetTargetData()
                if data.entryType == ENTRY_TYPE.PLAY_BUTTON then
                    if not IsUsingLinkedLogin() then
                        local username = self:GetEnteredUserName()
                        local password = self:GetEnteredPassword()
                        if username == "" then
                            local dialogData =
                            {
                                title = GetString(SI_ESO_ACCOUNT_LOGIN_ERROR_NO_USERNAME_TITLE), 
                                body = GetString(SI_ESO_ACCOUNT_LOGIN_ERROR_NO_USERNAME_TEXT), 
                            }
                            ZO_Dialogs_ShowPlatformDialog("BAD_LOGIN_NO_USERNAME_OR_PASSWORD", dialogData )
                            return
                        elseif password == "" then
                            local dialogData =
                            {
                                title = GetString(SI_ESO_ACCOUNT_LOGIN_ERROR_NO_PASSWORD_TITLE), 
                                body = GetString(SI_ESO_ACCOUNT_LOGIN_ERROR_NO_PASSWORD_TEXT), 
                            }
                            ZO_Dialogs_ShowPlatformDialog("BAD_LOGIN_NO_USERNAME_OR_PASSWORD", dialogData )
                            return
                        end
                    end

                    if self.isWaitingForDurangoAccountSelection == false then
                        self.serverSelector:OnPlayButtonPressed()
                        PregameStateManager_AdvanceStateFromState("GameStartup") -- only advance state from startup state (button spam protection)
                        PlaySound(SOUNDS.DIALOG_ACCEPT)
                    end
                elseif data.entryType == ENTRY_TYPE.VO_LANGUAGE then
                    ZO_Dialogs_ShowPlatformDialog("ADDITIONAL_CONTENT_SELECTION_DIALOG", { isFromMenu = true })
                elseif data.entryType == ENTRY_TYPE.EDIT_BOX then
                    local editBox = data.control.editBox
                    editBox:TakeFocus()
                elseif data.entryType == ENTRY_TYPE.SETTINGS then
                    GAMEPAD_OPTIONS_ROOT_SCENE:AddTemporaryFragment(PREGAME_ANIMATED_BACKGROUND_FRAGMENT)
                    SCENE_MANAGER:Push(GAMEPAD_OPTIONS_ROOT_SCENE:GetName())
                elseif data.entryType == ENTRY_TYPE.CREDITS then
                    GAMEPAD_CREDITS_ROOT_SCENE:AddTemporaryFragment(PREGAME_ANIMATED_BACKGROUND_FRAGMENT)
                    SCENE_MANAGER:Push(GAMEPAD_CREDITS_ROOT_SCENE:GetName())
                elseif data.entryType == ENTRY_TYPE.QUIT then
                    PregameQuit()
                end
            end,
            visible = function()
                local data = self.mainList:GetTargetData()
                if data.entryType == ENTRY_TYPE.PLAY_BUTTON then
                    return not (self.profileSaveInProgress or self:IsDownloadInProgress())
                elseif data.entryType == ENTRY_TYPE.VO_LANGUAGE or data.entryType == ENTRY_TYPE.EDIT_BOX or data.entryType == ENTRY_TYPE.SETTINGS or data.entryType == ENTRY_TYPE.CREDITS or data.entryType == ENTRY_TYPE.QUIT then
                    return true
                end
                return false
            end,
        },
        -- Toggle Password
        {
                keybind = "UI_SHORTCUT_SECONDARY",
                name = function()
                    local data = self.mainList:GetTargetData()
                    local editBoxControl = data.control.editBox

                    local isPassword = editBoxControl:IsPassword()
                    return isPassword and GetString(SI_EDIT_BOX_SHOW_PASSWORD) or GetString(SI_EDIT_BOX_HIDE_PASSWORD)
                end,
                callback = function()
                    local data = self.mainList:GetTargetData()
                    local editBoxControl = data.control.editBox

                    local isPassword = editBoxControl:IsPassword()
                    editBoxControl:SetAsPassword(not isPassword)

                    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
                end,
                visible = function()
                    local data = self.mainList:GetTargetData()
                    return data.isPassword
                end,
            },
        -- Change Profile
        {
            name = function()
                return zo_strformat(SI_GAME_STARTUP_CHANGE_PROFILE, GetOnlineIdForActiveProfile())
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            disabledDuringSceneHiding = true,
            callback = function()
                self.isWaitingForDurangoAccountSelection = true
                -- pick a new profile
                ShowXboxAccountPicker()
            end,
            visible = function()
                return GetUIPlatform() == UI_PLATFORM_XBOX and not self.profileSaveInProgress
            end,
        },
         --Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                -- if we just kicked off a platforms list load request, wait for that to finish before we let the player got back to IIS
                if self.canCancelOrLoadPlatforms == true then
                    PlaySound(SOUNDS.DIALOG_DECLINE)
                    self.canCancelOrLoadPlatforms = false
                    PregameStateManager_SetState("AccountLogin")
                end
            end)
    }

    self.initialKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select Control
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,
            callback = function()
                local data = self.initialList:GetTargetData()
                self.serverSelector:OnSelectedFromInitialList(data)
                PregameStateManager_AdvanceState()
            end,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
        --Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                PlaySound(SOUNDS.DIALOG_DECLINE)
                PregameStateManager_SetState("AccountLogin")
            end)
    }

    self.freeTrialEndKeybindDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Purchase control
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,
            callback = function()
                local platformStore = GetString(SI_FREE_TRIAL_PLATFORM_STORE_PS4)
                ZO_Dialogs_ShowGamepadDialog("FREE_TRIAL_INACTIVE", nil, { mainTextParams = { platformStore }} )
            end,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
            PlaySound(SOUNDS.DIALOG_DECLINE)
            PregameStateManager_SetState("AccountLogin")
        end),
    }
end

function ZO_GameStartup_Gamepad:InitializeEvents()
    local function OnAnnouncementsResult(eventCode, success)
        -- if we've already exited this state or backed out to IIS, don't do anything
        if PregameStateManager_GetCurrentState() == "GameStartup" then
            local message
            if success then
                message = GetAnnouncementMessage()
            else
                message = GetString(SI_LOGIN_ANNOUNCEMENTS_FAILURE)
            end

            self.announcement:SetText(message)
            self.gotMOTD = true

            -- dismiss the loading animation and show the GameStartup screen now that we have MOTD
            SCENE_MANAGER:Show("GameStartup")
        end
    end


    local function OnProfileAccess(saving)
        self.profileSaveInProgress = saving
        self:ForceListRebuild()
    end

    EVENT_MANAGER:RegisterForEvent("GameStartup", EVENT_ANNOUNCEMENTS_RESULT, OnAnnouncementsResult)
    EVENT_MANAGER:RegisterForEvent("GameStartup", EVENT_SAVE_DATA_START, function() OnProfileAccess(true) end)
    EVENT_MANAGER:RegisterForEvent("GameStartup", EVENT_SAVE_DATA_COMPLETE, function() OnProfileAccess(false) end)
    if GetUIPlatform() == UI_PLATFORM_XBOX then
        EVENT_MANAGER:RegisterForEvent("GameStartup", EVENT_DURANGO_ACCOUNT_PICKER_RETURNED, function(eventCode) self.isWaitingForDurangoAccountSelection = false end)
    end
end

function ZO_GameStartup_Gamepad:InitializeLists()
    local function OnServerSelectListChanged(selectedData, oldData, reselectingDuringRebuild)
        self.serverSelector:OnSelected(selectedData)
    end

    local function ServerSelectListSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        if control.horizontalListControl then
            --needs to be cached before Commit potentially changes it
            local lastServerSelectionEntry = self.serverSelector:GetCurrentlySelectedEntry()
            control.horizontalListObject:SetSelectedFromParent(selected)
            control.horizontalListObject:Clear()

            for _, entryData in ipairs(self.serverSelector:GetServerEntries()) do
                control.horizontalListObject:AddEntry(entryData)
            end

            control.horizontalListObject:Commit()
            control.horizontalListObject:SetOnSelectedDataChangedCallback(OnServerSelectListChanged)
            control.horizontalListObject:SetActive(selected)

            local allowEvenIfDisabled = true
            local noAnimation = true
            local index = control.horizontalListObject:FindIndexFromData(lastServerSelectionEntry)
            control.horizontalListObject:SetSelectedIndex(index, allowEvenIfDisabled, noAnimation)

        end
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
    end

    local function MainSetupList(list)
        list:AddDataTemplate("GameStartupLabelEntry", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplate("ZO_GamepadHorizontalListRow", ServerSelectListSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

        local function SetupTextFieldListEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
            ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
            data.control = control
            local editContainer = control:GetNamedChild("TextField")
            local editBox = editContainer:GetNamedChild("Edit")
            control.editBox = editBox

            local function OnTextChanged(...)
                if data.onTextChanged then
                    data.onTextChanged(...)
                end
            end

            editBox:SetHandler("OnTextChanged", OnTextChanged)
            editBox:SetMaxInputChars(data.maxInputChars)
            editBox:SetAsPassword(data.isPassword)

            local initialText = data.initialTextFunction and data.initialTextFunction() or ""
            editBox:SetText(initialText)

            editBox:SetDefaultText(data.defaultText or "")

            control.highlight:SetHidden(not selected)
        end
        local DEFAULT_EQUALITY_FUNCTION = nil
        list:AddDataTemplateWithHeader("ZO_GamepadTextFieldItem", SetupTextFieldListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, DEFAULT_EQUALITY_FUNCTION, "ZO_GamepadMenuEntryFullWidthHeaderTemplate")
    end

    local function InitialSetupList(list)
        list:AddDataTemplate("GameStartupLabelEntry", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end
    self.mainList = self:AddList("Play", MainSetupList)
    self.initialList = self:AddList("Initial", InitialSetupList)
end

function ZO_GameStartup_Gamepad:BuildVODialogEntryList()
    local parametricList = {}

    local voLanguageEntry =
    {
        template = "ZO_GamepadDropdownItem",
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
        header = GetString(SI_ADDITIONAL_CONTENT_VO_ENTRY_HEADER),

        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dialog = data.dialog

                -- Setup vo language dropdown
                local selectedEntry = control.dropdown:GetSelectedItemData()
                dialog.voLanguageDropdown = control.dropdown
                table.insert(dialog.dropdowns, dialog.voLanguageDropdown)

                dialog.voLanguageDropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                dialog.voLanguageDropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                dialog.voLanguageDropdown:SetSelectedItemTextColor(selected)

                dialog.voLanguageDropdown:ClearItems()

                local function ConsoleEntryCallback()
                    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
                    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_ADDITIONAL_CONTENT_CONSOLE_VO_INFO_HEADER), GetString(SI_ADDITIONAL_CONTENT_CONSOLE_VO_INFO_PROMPT))
                end

                local function DefaultEntryCallback()
                    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
                end

                local consoleLanguageText = zo_strupper(GetString("SI_OFFICIALLANGUAGE", GetDefaultPlatformOfficialLanguage()))
                local consoleEntry = dialog.voLanguageDropdown:CreateItemEntry(consoleLanguageText, ConsoleEntryCallback)
                local defaultEntry = dialog.voLanguageDropdown:CreateItemEntry(ENGLISH_VO_LANGUAGE_TEXT, DefaultEntryCallback)
                dialog.voLanguageDropdown:AddItem(consoleEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
                dialog.voLanguageDropdown:AddItem(defaultEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)

                if not selectedEntry or selectedEntry == "" then
                    dialog.voLanguageDropdown:SelectFirstItem()
                else
                    dialog.voLanguageDropdown:TrySelectItemByData(selectedEntry)
                end
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    targetControl.dropdown:Activate()
                end
            end,
            narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
        },
    }
    table.insert(parametricList, voLanguageEntry)

    return parametricList
end

function ZO_GameStartup_Gamepad:BuildTextLanguageDialogEntryList()
    local parametricList = {}

    local textLanguageEntry =
    {
        template = "ZO_GamepadDropdownItem",
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
        header = GetString(SI_ADDITIONAL_CONTENT_TEXT_ENTRY_HEADER),

        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dialog = data.dialog

                local selectedEntry = control.dropdown:GetSelectedItemData()
                dialog.textLanguageDropdown = control.dropdown
                table.insert(dialog.dropdowns, dialog.textLanguageDropdown)

                dialog.textLanguageDropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                dialog.textLanguageDropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                dialog.textLanguageDropdown:SetSelectedItemTextColor(selected)

                dialog.textLanguageDropdown:ClearItems()

                local consoleLanguageText = zo_strupper(GetString("SI_OFFICIALLANGUAGE", GetDefaultPlatformOfficialLanguage()))
                local consoleEntry = dialog.textLanguageDropdown:CreateItemEntry(consoleLanguageText)
                local defaultEntry = dialog.textLanguageDropdown:CreateItemEntry(ENGLISH_VO_LANGUAGE_TEXT)
                dialog.textLanguageDropdown:AddItem(consoleEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
                dialog.textLanguageDropdown:AddItem(defaultEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)

                if not selectedEntry or selectedEntry == "" then
                    dialog.textLanguageDropdown:SelectFirstItem()
                else
                    dialog.textLanguageDropdown:TrySelectItemByData(selectedEntry)
                end

                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, dialog.textLanguageDropdown)
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    targetControl.dropdown:Activate()
                end
            end,
            narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
        },
    }

    table.insert(parametricList, textLanguageEntry)

    return parametricList
end

function ZO_GameStartup_Gamepad:InitializeDialogs()
    local function setupFunction(dialog)
        if not dialog.dropdowns then
            dialog.dropdowns = {}
        end
        dialog:setupFunc()
    end

    local function OnReleaseDialog(dialog)
        if dialog.dropdowns then
            for i, dropdown in ipairs(dialog.dropdowns) do
                dropdown:Deactivate()
            end
            dialog.dropdowns = nil
        end
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end

    ZO_Dialogs_RegisterCustomDialog("ADDITIONAL_CONTENT_SELECTION_DIALOG",
    {
        canQueue = true,
        onlyQueueOnce = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_ADDITIONAL_CONTENT_SELECTION_HEADER,
        },
        mainText =
        {
            text = SI_ADDITIONAL_CONTENT_SELECTION_PROMPT,
        },
        setup = setupFunction,
        parametricList = self:BuildVODialogEntryList(),
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
                enabled = function(dialog)
                    local enabled = true
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        if type(targetData.enabled) == "function" then
                            enabled = targetData.enabled(dialog)
                        else
                            enabled = targetData.enabled
                        end
                    end
                    return enabled
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = function(dialog)
                    if dialog.voLanguageDropdown then
                        if dialog.voLanguageDropdown:GetSelectedItem() == ENGLISH_VO_LANGUAGE_TEXT then
                            return GetString(SI_ADDITIONAL_CONTENT_CONTINUE)
                        else
                            return GetString(SI_ADDITIONAL_CONTENT_DOWNLOAD)
                        end
                    end
                end,
                callback = function(dialog)
                    if dialog.voLanguageDropdown then
                        if dialog.voLanguageDropdown:GetSelectedItem() == ENGLISH_VO_LANGUAGE_TEXT then
                            SetCVar("SelectedEnglishVOLanguage", "1")
                            if not dialog.data or not dialog.data.isFromMenu then
                                ZO_Dialogs_ShowPlatformDialog("TEXT_LANGUAGE_SELECTION_DIALOG")
                            end
                        else
                            SetCVar("SelectedEnglishVOLanguage", "0")
                            g_userOpenedStore = dialog and dialog.data and dialog.data.isFromMenu
                            if IsConsoleUI() then
                                -- Do check for PlayGo before opening the store
                                if not OpenStreamingInstallLanguageChunkPlatformDialog() then
                                    -- Open store to offer the "purchase" of the additional content entitlement
                                    ShowPlatformESOVOAdditionalContentUI()
                                end
                            else
                                -- Create UI Dialog to fake console flow that ask about PlayGo on PC
                                ZO_Dialogs_ShowPlatformDialog("PLAYGO_ACCEPT_CONFIRMATION")
                            end
                        end
                        SaveSettings()
                    end
                    ZO_Dialogs_ReleaseDialogOnButtonPress("ADDITIONAL_CONTENT_SELECTION_DIALOG")
                    self:ForceListRebuild()
                end,
            },
            {
                text = SI_DIALOG_CANCEL,
                keybind = "DIALOG_NEGATIVE",
                callback = function(dialog)
                    -- If the user opened the store and closed it again without getting the entitlement then
                    -- SelectedEnglishVOLanguage needs to be set back to it's original state
                    SetCVar("SelectedEnglishVOLanguage", "1")
                    SaveSettings()
                    self:ForceListRebuild()
                    ZO_Dialogs_ReleaseDialogOnButtonPress("ADDITIONAL_CONTENT_SELECTION_DIALOG")
                end,
                visible = function(dialog)
                    -- Cancel button is only available if user selected English VO rather than downloading the approriate entitlement
                    return dialog.data and dialog.data.isFromMenu
                end,
            },
        },
        onHidingCallback = OnReleaseDialog,
        noChoiceCallback = OnReleaseDialog,
    })

    ZO_Dialogs_RegisterCustomDialog("TEXT_LANGUAGE_SELECTION_DIALOG",
    {
        canQueue = true,
        onlyQueueOnce = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_ADDITIONAL_CONTENT_TEXT_LANGUAGE_HEADER,
        },
        mainText =
        {
            text = SI_ADDITIONAL_CONTENT_TEXT_LANGUAGE_PROMPT,
        },
        setup = setupFunction,
        parametricList = self:BuildTextLanguageDialogEntryList(),
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
                enabled = function(dialog)
                    local enabled = true
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        if type(targetData.enabled) == "function" then
                            enabled = targetData.enabled(dialog)
                        else
                            enabled = targetData.enabled
                        end
                    end
                    return enabled
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = GetString(SI_ADDITIONAL_CONTENT_CONTINUE),
                callback = function(dialog)
                    if dialog.textLanguageDropdown then
                        if dialog.textLanguageDropdown:GetSelectedItem() == ENGLISH_VO_LANGUAGE_TEXT then
                            SetCVar("Language.2", ZoOfficialLanguageDescriptorForZoOfficialLanguage(OFFICIAL_LANGUAGE_ENGLISH))
                        else
                            SetCVar("Language.2", ZoOfficialLanguageDescriptorForZoOfficialLanguage(GetDefaultPlatformOfficialLanguage()))
                            self:ForceListRebuild()
                        end
                    end
                    ZO_Dialogs_ReleaseDialogOnButtonPress("TEXT_LANGUAGE_SELECTION_DIALOG")
                end,
            },
        },
        onHidingCallback = OnReleaseDialog,
        noChoiceCallback = OnReleaseDialog,
    })
end

function ZO_GameStartup_Gamepad:PopulateMainList()
    self:RefreshHeader(GetString(SI_GAME_STARTUP_HEADER))
    self.username, self.password = ZO_GameStartup_Gamepad_GetInitialLoginInfo()
    self.mainList:Clear()

    if self.psnFreeTrialEnded then
        local data = ZO_GamepadEntryData:New(GetString(SI_FREE_TRIAL_MENU_ENTRY_PURCHASE))
        self.mainList:AddEntry("GameStartupLabelEntry", data)
    else
        if not IsUsingLinkedLogin() then
            local usernameEntryData = ZO_GamepadEntryData:New("")
            usernameEntryData.header = GetString(SI_ACCOUNT_NAME)
            usernameEntryData.entryType = ENTRY_TYPE.EDIT_BOX
            usernameEntryData.initialTextFunction = function() return self.username end
            usernameEntryData.defaultText = GetString(SI_LOGON_ACCOUNT_NAME_DEFAULT_TEXT)
            usernameEntryData.maxInputChars = MAX_EMAIL_LENGTH
            usernameEntryData.onTextChanged = function(control)
                self.username = control:GetText()
            end
            self.mainList:AddEntryWithHeader("ZO_GamepadTextFieldItem", usernameEntryData)

            local passwordEntryData = ZO_GamepadEntryData:New("")
            passwordEntryData.header = GetString(SI_PASSWORD)
            passwordEntryData.entryType = ENTRY_TYPE.EDIT_BOX
            passwordEntryData.initialTextFunction = function() return self.password end
            passwordEntryData.defaultText = GetString(SI_PASSWORD)
            passwordEntryData.maxInputChars = MAX_PASSWORD_LENGTH
            passwordEntryData.isPassword = true
            passwordEntryData.onTextChanged = function(control)
                self.password = control:GetText()
            end
            self.mainList:AddEntryWithHeader("ZO_GamepadTextFieldItem", passwordEntryData)
        end

        local playEntryString = GetString(SI_GAME_STARTUP_PLAY)
        if self:IsDownloadInProgress() then
            playEntryString = GetString(SI_CONSOLE_GAME_DOWNLOAD_UPDATING)
        end

        local playEntryData = ZO_GamepadEntryData:New(playEntryString)
        playEntryData.entryType = ENTRY_TYPE.PLAY_BUTTON
        self.mainList:AddEntry("GameStartupLabelEntry", playEntryData)

        if GetCVar("SelectedEnglishVOLanguage") == "1" then
            local additionalContentEntryData = ZO_GamepadEntryData:New(GetString(SI_GAME_STARTUP_VO_LANGUAGE_SELECT))
            additionalContentEntryData.entryType = ENTRY_TYPE.VO_LANGUAGE
            self.mainList:AddEntry("GameStartupLabelEntry", additionalContentEntryData)
        end

        local serverSelectEntryData = ZO_GamepadEntryData:New(GetString(SI_GAME_STARTUP_SERVER_SELECT))
        self.mainList:AddEntry("ZO_GamepadHorizontalListRow", serverSelectEntryData)

        local settingsEntryData = ZO_GamepadEntryData:New(GetString(SI_GAME_MENU_SETTINGS))
        settingsEntryData.entryType = ENTRY_TYPE.SETTINGS
        self.mainList:AddEntry("GameStartupLabelEntry", settingsEntryData)

        local announcementEntryData = ZO_GamepadEntryData:New(GetString(SI_LOGIN_ANNOUNCEMENTS_TITLE))
        announcementEntryData.entryType = ENTRY_TYPE.ANNOUNCEMENTS
        self.mainList:AddEntry("GameStartupLabelEntry", announcementEntryData)

        local creditsEntryData = ZO_GamepadEntryData:New(GetString(SI_GAME_MENU_CREDITS))
        creditsEntryData.entryType = ENTRY_TYPE.CREDITS
        self.mainList:AddEntry("GameStartupLabelEntry", creditsEntryData)

        if ZO_IsPCUI() then
            local quitEntryData = ZO_GamepadEntryData:New(GetString(SI_GAME_MENU_QUIT))
            quitEntryData.entryType = ENTRY_TYPE.QUIT
            self.mainList:AddEntry("GameStartupLabelEntry", quitEntryData)
        end
    end

    self.mainList:Commit()
end

function ZO_GameStartup_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if (selectedData and selectedData.entryType ~= ENTRY_TYPE.ANNOUNCEMENTS) and not GAME_STARTUP_SERVERALERT_GAMEPAD.serverAlert:IsControlHidden() then
        GAME_STARTUP_MAIN_GAMEPAD_SCENE:RemoveFragment(self.announcementFragment)
        GAME_STARTUP_MAIN_GAMEPAD_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        GAME_STARTUP_MAIN_GAMEPAD_SCENE:AddFragment(self.serverAlertFragment)
    else
        GAME_STARTUP_MAIN_GAMEPAD_SCENE:RemoveFragment(self.serverAlertFragment)
        GAME_STARTUP_MAIN_GAMEPAD_SCENE:AddFragment(self.announcementFragment)
        GAME_STARTUP_MAIN_GAMEPAD_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    end
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

function ZO_GameStartup_Gamepad:PopulateInitialList()
    self:RefreshHeader(GetString(SI_GAME_STARTUP_SERVER_SELECT))
    self.initialList:Clear()

    for _, entryData in ipairs(self.serverSelector:GetServerEntries()) do
        self.initialList:AddEntry("GameStartupLabelEntry", entryData)
    end

    self.initialList:Commit()
end

function ZO_GameStartup_Gamepad:ForceListRebuild()
    if self.mainList then
        -- force a rebuild of the list
        self:PopulateMainList()
    end
end

function ZO_GameStartup_Gamepad:SetPsnFreeTrialEnded(psnFreeTrialEnded)
    if psnFreeTrialEnded then
        internalassert(ZO_IsPlaystationPlatform(), "ingame free trial ended dialog only supported for playstation")
    end
    self.psnFreeTrialEnded = psnFreeTrialEnded
end

function ZO_GameStartup_Gamepad:GetEnteredUserName()
    return self.username
end

function ZO_GameStartup_Gamepad:GetEnteredPassword()
    return self.password
end

function ZO_GameStartup_Gamepad_GetInitialLoginInfo()
    local username = GetCVar("AccountName")
    local password = ""
    return username, password
end

----
-- ZO_GameStartup_ServerAlert_Gamepad
----

local ZO_GameStartup_ServerAlert_Gamepad = ZO_InitializingObject:Subclass()

function ZO_GameStartup_ServerAlert_Gamepad:Initialize(control)
    self.control = control

    self.serverAlert = control:GetNamedChild("ServerAlert")
    self.serverAlertLabel = self.serverAlert:GetNamedChild("Text")
    self.serverAlertImage = self.serverAlert:GetNamedChild("AlertImage")

    local function OnAnnouncementsResult(eventCode, success)
        local serverAlertMessage = success and GetServerAlertMessage()
        if serverAlertMessage and serverAlertMessage ~= "" then
            self.serverAlert:SetHidden(false)
            self.serverAlertImage:SetTexture("EsoUI/Art/Login/login_icon_yield.dds")
            self.serverAlertLabel:SetText(serverAlertMessage)
        else
            local serverNoticeMessage = success and GetServerNoticeMessage()
            if serverNoticeMessage and serverNoticeMessage ~= "" then
                self.serverAlert:SetHidden(false)
                self.serverAlertImage:SetTexture("EsoUI/Art/Login/login_icon_info.dds")
                self.serverAlertLabel:SetText(serverNoticeMessage)
            else
                self.serverAlert:SetHidden(true)
            end
        end
    end

    EVENT_MANAGER:RegisterForEvent("GameStartup_Gamepad", EVENT_ANNOUNCEMENTS_RESULT, OnAnnouncementsResult)
end

---------------
-- Global XML
---------------

function ZO_GameStartup_Gamepad_Initialize(control)
    GAME_STARTUP_GAMEPAD = ZO_GameStartup_Gamepad:New(control)
end

function ZO_GameStartup_Gamepad_ServerAlert_Initialize(control)
    GAME_STARTUP_SERVERALERT_GAMEPAD = ZO_GameStartup_ServerAlert_Gamepad:New(control)
end