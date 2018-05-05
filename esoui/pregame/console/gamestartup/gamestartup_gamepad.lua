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

    local gameStartup_Gamepad_Fragment = ZO_FadeSceneFragment:New(self.control)
    GAME_STARTUP_MAIN_GAMEPAD_SCENE = ZO_Scene:New("GameStartup", SCENE_MANAGER)
    GAME_STARTUP_MAIN_GAMEPAD_SCENE:AddFragment(gameStartup_Gamepad_Fragment)
    GAME_STARTUP_MAIN_GAMEPAD_SCENE:AddFragment(ZO_FadeSceneFragment:New(GameStartup_GamepadMiddlePane))

    GAME_STARTUP_MAIN_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
                if newState == SCENE_SHOWING then
                    if not self.serverSelection then
                        self.serverSelection = tonumber(GetCVar("SelectedServer"))
                    end

                    self:PerformDeferredInitialize()
                    self:PopulateMainList()
                    self:SetCurrentList(self.mainList)

                    if self.mustPurchaseGame then
                        KEYBIND_STRIP:AddKeybindButtonGroup(self.freeTrialEndKeybindDescriptor)

                        --[[ The player needs to purchase the game, no need to wait on RequestAnnouncements to get something that we're going to overwrite anyway ]]--
                        local platformStore = ""
                        if GetUIPlatform() == UI_PLATFORM_PS4 then
                            platformStore = GetString(SI_FREE_TRIAL_PLATFORM_STORE_PS4)
                        end

                        self.announcement:SetText(zo_strformat(SI_FREE_TRIAL_EXPIRED_ANNOUNCEMENT, platformStore))
                        self.gotMOTD = false
                    else
                        KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)

                        --[[ if we don't have an MOTD, kick off RequestAnnouncements and show a loading animation. The loading animation is dismissed in OnAnnouncementsResult() below ]]--
                        if not self.gotMOTD then
                            CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", RequestAnnouncements, GetString(SI_CONSOLE_PREGAME_LOADING))
                        else
                            self.gotMOTD = false
                            self.canCancelOrLoadPlatforms = true
                        end
                    end

                elseif newState == SCENE_HIDDEN then
                    self:Deactivate()
                
                    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mustPurchaseGame and self.freeTrialEndKeybindDescriptor or self.mainKeybindStripDescriptor)
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

    ZO_Dialogs_RegisterCustomDialog("FREE_TRIAL_INACTIVE", {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_FREE_TRIAL_PURCHASE_DIALOG_HEADER,
        },
        mainText =
        {
            text = SI_FREE_TRIAL_PURCHASE_DIALOG_BODY,
        },
        noChoiceCallback = function()
                if IsConsoleUI() then
                    ZO_Disconnect()
                end
            end,
        buttons = 
        {
            {
                text = SI_FREE_TRIAL_PURCHASE_KEYBIND,
                keybind = "DIALOG_PRIMARY",
                callback = function()
                        if IsConsoleUI() then
                           ShowConsoleESOGameClientUI()
                           ZO_Disconnect()
                        end
                    end,
            },
            {
                text = SI_GAMEPAD_BACK_OPTION,
                keybind = "DIALOG_NEGATIVE",
                callback = function()
                        if IsConsoleUI() then
                            ZO_Disconnect()
                        end
                    end,
            },
        },
    })
end

function ZO_GameStartup_Gamepad:PerformDeferredInitialize()
    if self.initialized then return end
    self.initialized = true

    self:SetToLastLoggedInPlatform() --Set Platform on initial show

    self:InitializeHeaders()
    self:InitializeKeybindDescriptor()
    self:InitializeLists()
    self:InitializeEvents()
    GAMEPAD_DOWNLOAD_BAR:RegisterCallback("DownloadComplete", function() self:ForceListRebuild() end)
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
                        if tonumber(GetCVar("SelectedServer")) ~= self.serverSelection then
                            SetCVar("SelectedServer", self.serverSelection)
                            SavePlayerConsoleProfile() --Save only on entering into game
                        end
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
                self.serverSelection = data.server
                SetCVar("IsServerSelected", "true") --Store Server is Selected
                SetCVar("SelectedServer", self.serverSelection)
                SavePlayerConsoleProfile()
                PregameStateManager_AdvanceState()
                CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", function() LoadPlatformsList(data.server) end, GetString(SI_CONSOLE_PREGAME_LOADING))
            end,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
        --Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                PlaySound(SOUNDS.DIALOG_DECLINE)
                PregameStateManager_SetState("AccountLogin")
            end)
    }

    self.freeTrialEndKeybindDescriptor= {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Purchase control
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,
            callback = function()
                local platformStore = ""

                if GetUIPlatform() == UI_PLATFORM_PS4 then
                    platformStore = GetString(SI_FREE_TRIAL_PLATFORM_STORE_PS4)
                end

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
            if(success) then
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

    local function OnPlatformsListLoaded(eventCode, server)
        self.serverSelection = server
        -- if we've already exited this state or backed out to IIS, don't do anything
        if PregameStateManager_GetCurrentState() == "GameStartup" then
            self:SetToLastLoggedInPlatform()
            RequestAnnouncements()
        end
    end

    local function OnProfileAccess(saving)
        self.profileSaveInProgress = saving
        self:ForceListRebuild()
    end

    EVENT_MANAGER:RegisterForEvent("GameStartup", EVENT_ANNOUNCEMENTS_RESULT, OnAnnouncementsResult)
    EVENT_MANAGER:RegisterForEvent("GameStartup", EVENT_PLATFORMS_LIST_LOADED, OnPlatformsListLoaded)
    EVENT_MANAGER:RegisterForEvent("GameStartup", EVENT_DURANGO_ACCOUNT_PICKER_RETURNED, function(eventCode) self.isWaitingForDurangoAccountSelection = false end)
    EVENT_MANAGER:RegisterForEvent("GameStartup", EVENT_SAVE_DATA_START, function() OnProfileAccess(true) end)
    EVENT_MANAGER:RegisterForEvent("GameStartup", EVENT_SAVE_DATA_COMPLETE, function() OnProfileAccess(false) end)
end

function ZO_GameStartup_Gamepad:InitializeLists()
    local function MainSetupList(list)
        local function HorizontalScrollListSelectionChanged(selectedData, oldData, reselectingDuringRebuild)  
            if not (reselectingDuringRebuild == false) and (self.serverSelection ~= selectedData.server) then
                -- if user already backed out to IIS we don't have an active profile anymore, so don't kick off a platforms list load
                if self.canCancelOrLoadPlatforms == true then
                    CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", function() LoadPlatformsList(selectedData.server) end, GetString(SI_CONSOLE_PREGAME_LOADING))
                    self.canCancelOrLoadPlatforms = false
                    self.serverSelection = selectedData.server
                end
            end
        end
    
        local function HorizontalListEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)       
            if control.horizontalListControl then
                local currentSetting = self.serverSelection --needs to be cached before Commit potentially changes it
                control.horizontalListObject:SetSelectedFromParent(selected)
                control.horizontalListObject:Clear()
            
                local entryData =
                {
                    text = GetString("SI_CONSOLESERVERCHOICE", CONSOLE_SERVER_NORTH_AMERICA),
                    server = CONSOLE_SERVER_NORTH_AMERICA,
                }
                control.horizontalListObject:AddEntry(entryData) 

                entryData =
                {
                    text = GetString("SI_CONSOLESERVERCHOICE", CONSOLE_SERVER_EUROPE),
                    server = CONSOLE_SERVER_EUROPE,
                }
                control.horizontalListObject:AddEntry(entryData) 
                control.horizontalListObject:Commit()
                control.horizontalListObject:SetOnSelectedDataChangedCallback(HorizontalScrollListSelectionChanged)
                control.horizontalListObject:SetActive(selected)
                
                local index = (currentSetting == CONSOLE_SERVER_NORTH_AMERICA) and 1 or 2
                local allowEvenIfDisabled = true
                local noAnimation = true
                control.horizontalListObject:SetSelectedDataIndex(index, allowEvenIfDisabled, noAnimation)
            end
            ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
            KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
        end
        list:AddDataTemplate("GameStartupLabelEntry", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplate("ZO_GamepadHorizontalListRow",  HorizontalListEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end

    local function InitialSetupList(list)
        list:AddDataTemplate("GameStartupLabelEntry", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end
    self.mainList = self:AddList("Play", MainSetupList )
    self.initialList = self:AddList("Initial", InitialSetupList)
end

function ZO_GameStartup_Gamepad:SetToLastLoggedInPlatform()
    --Set the platform to the last logged in platform.
    local lastPlat = GetCVar("LastPlatform")
    if lastPlat ~= nil then
        for platformIndex = 1, GetNumPlatforms() do
            local platformName = GetPlatformInfo(platformIndex)            
            if platformName == lastPlat then
                SetSelectedPlatform(platformIndex)
            end
        end
    end
end

function ZO_GameStartup_Gamepad:PopulateMainList()
    self:RefreshHeader(GetString(SI_GAME_STARTUP_HEADER))
    self.mainList:Clear()

    if self.mustPurchaseGame then
        local data = ZO_GamepadEntryData:New(GetString(SI_FREE_TRIAL_MENU_ENTRY_PURCHASE))
        self.mainList:AddEntry("GameStartupLabelEntry", data)
    else
        local optionString = GetString(SI_GAME_STARTUP_PLAY)
        if(not IsGateInstalled("BaseGame")) then
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

    local data = ZO_GamepadEntryData:New(GetString("SI_CONSOLESERVERCHOICE", CONSOLE_SERVER_NORTH_AMERICA))
    data.server = CONSOLE_SERVER_NORTH_AMERICA
    self.initialList:AddEntry("GameStartupLabelEntry", data)

    data = ZO_GamepadEntryData:New(GetString("SI_CONSOLESERVERCHOICE", CONSOLE_SERVER_EUROPE))
    data.server = CONSOLE_SERVER_EUROPE
    self.initialList:AddEntry("GameStartupLabelEntry", data)

    self.initialList:Commit()
end

function ZO_GameStartup_Gamepad:ForceListRebuild()
    if(self.mainList) then
        -- force a rebuild of the list
        self:PopulateMainList()
    end
end

function ZO_GameStartup_Gamepad:SetMustPurchaseGame(mustPurchaseGame)
    self.mustPurchaseGame = mustPurchaseGame
end

function ZO_GameStartup_Gamepad_Initialize(self)
    GAME_STARTUP_GAMEPAD = ZO_GameStartup_Gamepad:New(self)
end
