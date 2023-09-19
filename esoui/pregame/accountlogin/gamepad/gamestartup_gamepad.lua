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
    EDIT_BOX = "EditBox",
    SETTINGS = "Settings",
    ANNOUNCEMENTS = "Announcements",
    CREDITS = "Credits",
    QUIT = "Quit",
}

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
    GAME_STARTUP_MAIN_GAMEPAD_SCENE = ZO_Scene:New("GameStartup", SCENE_MANAGER)
    GAME_STARTUP_MAIN_GAMEPAD_SCENE:AddFragment(gameStartup_Gamepad_Fragment)

    self.announcementFragment = ZO_FadeSceneFragment:New(GameStartup_GamepadMiddlePane)
    self.serverAlertFragment = ZO_FadeSceneFragment:New(GameStartup_Gamepad_ServerAlert)

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

        elseif newState == SCENE_HIDDEN then
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
end

function ZO_GameStartup_Gamepad:PerformDeferredInitialize()
    if self.initialized then return end
    self.initialized = true

    self.serverSelector:OnDeferredInitialize()

    self:InitializeHeaders()
    self:InitializeKeybindDescriptor()
    self:InitializeLists()
    self:InitializeEvents()
    if IsConsoleUI() then
        GAMEPAD_DOWNLOAD_BAR:RegisterCallback("DownloadComplete", function() self:ForceListRebuild() end)
    end
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
    self.mainKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select Control
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,
            callback = function()
                local data = self.mainList:GetTargetData()
                if data.entryType == ENTRY_TYPE.PLAY_BUTTON then
                    if self.isWaitingForDurangoAccountSelection == false then
                        self.serverSelector:OnPlayButtonPressed()
                        PregameStateManager_AdvanceStateFromState("GameStartup") -- only advance state from startup state (button spam protection)
                        PlaySound(SOUNDS.DIALOG_ACCEPT)
                    end
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
                    return IsGateInstalled("BaseGame") and not self.profileSaveInProgress
                elseif data.entryType == ENTRY_TYPE.EDIT_BOX or data.entryType == ENTRY_TYPE.SETTINGS or data.entryType == ENTRY_TYPE.CREDITS or data.entryType == ENTRY_TYPE.QUIT then
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
            usernameEntryData.maxInputChars = MAX_EMAIL_LENGTH
            usernameEntryData.onTextChanged = function(control)
                self.username = control:GetText()
            end
            self.mainList:AddEntryWithHeader("ZO_GamepadTextFieldItem", usernameEntryData)

            local passwordEntryData = ZO_GamepadEntryData:New("")
            passwordEntryData.header = GetString(SI_PASSWORD)
            passwordEntryData.entryType = ENTRY_TYPE.EDIT_BOX
            passwordEntryData.initialTextFunction = function() return self.password end
            passwordEntryData.maxInputChars = MAX_PASSWORD_LENGTH
            passwordEntryData.isPassword = true
            passwordEntryData.onTextChanged = function(control)
                self.password = control:GetText()
            end
            self.mainList:AddEntryWithHeader("ZO_GamepadTextFieldItem", passwordEntryData)
        end

        local playEntryString = GetString(SI_GAME_STARTUP_PLAY)
        if not IsGateInstalled("BaseGame") then
            playEntryString = GetString(SI_CONSOLE_GAME_DOWNLOAD_UPDATING)
        end

        local playEntryData = ZO_GamepadEntryData:New(playEntryString)
        playEntryData.entryType = ENTRY_TYPE.PLAY_BUTTON
        self.mainList:AddEntry("GameStartupLabelEntry", playEntryData)

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