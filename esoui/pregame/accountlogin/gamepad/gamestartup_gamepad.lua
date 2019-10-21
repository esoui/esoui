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

-- Heron server select behaves like PC server select; it lists all platforms from platforms.xml directly.
local ZO_HeronServerSelector = ZO_Object:Subclass()

function ZO_HeronServerSelector:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_HeronServerSelector:Initialize(owner)
    self.owner = owner
end

function ZO_HeronServerSelector:OnDeferredInitialize()
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

function ZO_HeronServerSelector:OnShowing()
    self.selectedPlatformName = GetCVar("LastPlatform")
end

function ZO_HeronServerSelector:GetServerEntries()
    return self.entries
end

function ZO_HeronServerSelector:GetCurrentlySelectedEntry()
    local entries = self:GetServerEntries()
    for _, entry in ipairs(entries) do
        if entry.platformName == self.selectedPlatformName then
            return entry
        end
    end
    return nil
end

function ZO_HeronServerSelector:OnPlayButtonPressed()
    -- do nothing, we already saved/applied our choice
end

function ZO_HeronServerSelector:OnSelectedFromInitialList(entryData)
    -- Called when selecting a server for the first time
    SetCVar("IsServerSelected", "true")
    SetCVar("LastPlatform", entryData.platformName)
    SetSelectedPlatform(entryData.platformIndex)
    self.selectedPlatformName = entryData.platformName
end

function ZO_HeronServerSelector:OnSelected(entryData)
    if entryData.platformName ~= self.selectedPlatformName then
        SetCVar("LastPlatform", entryData.platformName)
        SetSelectedPlatform(entryData.platformIndex)
        self.selectedPlatformName = entryData.platformName
        CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", RequestAnnouncements, GetString(SI_GAMEPAD_PREGAME_LOADING))
    end
end

-- Console server select pulls a platform list from console title storage, and picks the first platform from that list. A different platform list will be loaded depending on whether you pick NA or EU.
local ZO_ConsoleServerSelector = ZO_Object:Subclass()

function ZO_ConsoleServerSelector:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ConsoleServerSelector:Initialize(owner)
    self.owner = owner
end

function ZO_ConsoleServerSelector:OnDeferredInitialize()
    local entries = {}

    local entryData = ZO_GamepadEntryData:New(GetString("SI_CONSOLESERVERCHOICE", CONSOLE_SERVER_NORTH_AMERICA))
    entryData.serverChoice = CONSOLE_SERVER_NORTH_AMERICA
    table.insert(entries, entryData)

    local entryData = ZO_GamepadEntryData:New(GetString("SI_CONSOLESERVERCHOICE", CONSOLE_SERVER_EUROPE))
    entryData.serverChoice = CONSOLE_SERVER_EUROPE
    table.insert(entries, entryData)
    self.entries = entries

    local function OnPlatformsListLoaded(_, serverChoice)
        self:OnConsolePlatformsListLoaded(server)
    end
    EVENT_MANAGER:RegisterForEvent("ConsoleServerSelector", EVENT_PLATFORMS_LIST_LOADED, OnPlatformsListLoaded)

    self:SetConsoleLastSelectedPlatform()
end

function ZO_ConsoleServerSelector:OnShowing()
    self.selectedServerChoice = tonumber(GetCVar("SelectedServer"))
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

local ZO_GameStartup_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_GameStartup_Gamepad:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function ZO_GameStartup_Gamepad:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control)
    self.control = control
    self.gotMOTD = false
    self.isWaitingForDurangoAccountSelection = false
    self.canCancelOrLoadPlatforms = true
    self.profileSaveInProgress = false
    if IsConsoleUI() then
        self.serverSelector = ZO_ConsoleServerSelector:New(self)
    elseif IsHeronUI() then
        self.serverSelector = ZO_HeronServerSelector:New(self)
    elseif IsGamepadUISupported() then
        internalassert(false, "Server selection not implemented")
    end

    local gameStartup_Gamepad_Fragment = ZO_FadeSceneFragment:New(self.control)
    GAME_STARTUP_MAIN_GAMEPAD_SCENE = ZO_Scene:New("GameStartup", SCENE_MANAGER)
    GAME_STARTUP_MAIN_GAMEPAD_SCENE:AddFragment(gameStartup_Gamepad_Fragment)
    GAME_STARTUP_MAIN_GAMEPAD_SCENE:AddFragment(ZO_FadeSceneFragment:New(GameStartup_GamepadMiddlePane))

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

    self.announcement = GameStartup_GamepadMiddlePane:GetNamedChild("Container"):GetNamedChild("Content")
end

function ZO_GameStartup_Gamepad:RefreshHeader(titleText)
    self.headerData =
    {
        titleText = titleText,
    }
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
                if self.isWaitingForDurangoAccountSelection == false then
                    local data = self.mainList:GetTargetData()
                    if data.allowKeybind then
                        self.serverSelector:OnPlayButtonPressed()
                        PregameStateManager_AdvanceStateFromState("GameStartup") -- only advance state from startup state (button spam protection)
                        PlaySound(SOUNDS.DIALOG_ACCEPT)
                    end
                end
            end,
            visible = function()
                local data = self.mainList:GetTargetData()
                return data.allowKeybind and IsGateInstalled("BaseGame") and not self.profileSaveInProgress
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

    local function EntryDataMatchesPlatformName(platformName, entryData)
        return platformName == entryData.platformName
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
    end

    local function InitialSetupList(list)
        list:AddDataTemplate("GameStartupLabelEntry", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end
    self.mainList = self:AddList("Play", MainSetupList)
    self.initialList = self:AddList("Initial", InitialSetupList)
end

function ZO_GameStartup_Gamepad:PopulateMainList()
    self:RefreshHeader(GetString(SI_GAME_STARTUP_HEADER))
    self.mainList:Clear()

    if self.psnFreeTrialEnded then
        local data = ZO_GamepadEntryData:New(GetString(SI_FREE_TRIAL_MENU_ENTRY_PURCHASE))
        self.mainList:AddEntry("GameStartupLabelEntry", data)
    else
        local optionString = GetString(SI_GAME_STARTUP_PLAY)
        if not IsGateInstalled("BaseGame") then
            optionString = GetString(SI_CONSOLE_GAME_DOWNLOAD_UPDATING)
        end

        local data = ZO_GamepadEntryData:New(optionString)
        data.allowKeybind = true
        self.mainList:AddEntry("GameStartupLabelEntry", data)

        data = ZO_GamepadEntryData:New(GetString(SI_GAME_STARTUP_SERVER_SELECT))
        self.mainList:AddEntry("ZO_GamepadHorizontalListRow", data)
    end

    self.mainList:Commit()
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
        internalassert(GetUIPlatform() == UI_PLATFORM_PS4, "ingame free trial ended dialog only supported for playstation")
    end
    self.psnFreeTrialEnded = psnFreeTrialEnded
end

function ZO_GameStartup_Gamepad_Initialize(self)
    GAME_STARTUP_GAMEPAD = ZO_GameStartup_Gamepad:New(self)
end
