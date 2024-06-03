ZO_GameMenu_PreGame_Keyboard = ZO_InitializingObject:Subclass()

function ZO_GameMenu_PreGame_Keyboard:Initialize(control)
    self.control = control

    local horizontalMenuControl = control:GetNamedChild("HorizontalMenu")
    self.horizontalMenu = ZO_Horizontal_Menu:New(horizontalMenuControl, ZO_HORIZONAL_MENU_ALIGN_LEFT)

    self.gameMenuPregameFragment = ZO_FadeSceneFragment:New(self.control)
    self.scene = ZO_Scene:New("gameMenuPregame", SCENE_MANAGER)
    self.scene:AddFragment(self.gameMenuPregameFragment)
    self.scene:AddFragment(PREGAME_BACKGROUND_FRAGMENT)
    self.scene:AddFragment(LOGIN_BG_FRAGMENT)
    local loginFragment = LOGIN_MANAGER_KEYBOARD:GetRelevantLoginFragment()
    self.scene:AddFragment(loginFragment)

    local function OnHorizontalMenuItemSetup(menuControl, data)
        local name = data.name
        if type(data.name) == "function" then
            name = data.name()
        end

        menuControl:SetText(name)
    end

    local HORIZONTAL_SPACING = 30
    self.horizontalMenu:AddTemplate("ZO_HorizontalMenu_LabelHeader", OnHorizontalMenuItemSetup, HORIZONTAL_SPACING)

    self:BuildMenu()

    -- Quit Option
    local quitOption = self.control:GetNamedChild("Quit")
    local data =
    {
        name = GetString(SI_GAME_MENU_QUIT),
        onSelectedCallback = PregameQuit,
    }
    quitOption.data = data
    OnHorizontalMenuItemSetup(quitOption, data)
end

function ZO_GameMenu_PreGame_Keyboard:GetScene()
    return self.scene
end

function ZO_GameMenu_PreGame_Keyboard:BuildMenu()
    self.horizontalMenu:Reset()

    -- Server Menu Option
     if DoesPlatformSelectServer() then
        local function OnHideServerSelect()
            self.horizontalMenu:Refresh()
        end

        local function OnShowServerSelect(control)
            ZO_Dialogs_ShowDialog("SERVER_SELECT_DIALOG", { onSelectedCallback = OnHideServerSelect })
        end

        local function GetServerMenuItemName()
            local currentServer = GetCVar("LastPlatform")
            currentServer = ZO_GetLocalizedServerName(currentServer)
            return zo_strformat(SI_GAME_MENU_SERVER, currentServer)
        end
        self.serverSelectControl = self.horizontalMenu:AddMenuItem("ServerSelect", GetServerMenuItemName, OnShowServerSelect, OnHideServerSelect)
    end

    -- Settings Menu Option
    local function OnShowSettings(control)
        PREGAME_SETTINGS_KEYBOARD:SetOnExitCallback(control.data.onUnselectedCallback)
        self.scene:AddFragment(SETTINGS_FRAGMENT)
        self.scene:RemoveFragment(self.gameMenuPregameFragment)
        self.scene:RemoveFragment(LOGIN_BG_FRAGMENT)
        local loginFragment = LOGIN_MANAGER_KEYBOARD:GetRelevantLoginFragment()
        self.scene:RemoveFragment(loginFragment)
    end

    local function OnHideSettings()
        if not IsInGamepadPreferredMode() then
            self.control:SetHidden(false)
        end

        self.scene:RemoveFragment(SETTINGS_FRAGMENT)
        self.scene:AddFragment(self.gameMenuPregameFragment)
        self.scene:AddFragment(LOGIN_BG_FRAGMENT)
        local loginFragment = LOGIN_MANAGER_KEYBOARD:GetRelevantLoginFragment()
        self.scene:AddFragment(loginFragment)
    end
    self.horizontalMenu:AddMenuItem("Settings", GetString(SI_GAME_MENU_SETTINGS), OnShowSettings, OnHideSettings)

    -- Credits Menu Option
    local function OnShowCredits(control)
        self.control:SetHidden(true)
        GAME_CREDITS_KEYBOARD:SetOnExitCallback(control.data.onUnselectedCallback)
        self.scene:AddFragment(GAME_CREDITS_KEYBOARD:GetFragment())
        self.scene:RemoveFragment(LOGIN_BG_FRAGMENT)
        local loginFragment = LOGIN_MANAGER_KEYBOARD:GetRelevantLoginFragment()
        self.scene:RemoveFragment(loginFragment)
    end

    local function OnHideCredits()
        self.control:SetHidden(false)
        self.scene:RemoveFragment(GAME_CREDITS_KEYBOARD:GetFragment())
        self.scene:AddFragment(LOGIN_BG_FRAGMENT)
        local loginFragment = LOGIN_MANAGER_KEYBOARD:GetRelevantLoginFragment()
        self.scene:AddFragment(loginFragment)
    end
    self.horizontalMenu:AddMenuItem("Credits", GetString(SI_GAME_MENU_CREDITS), OnShowCredits, OnHideCredits)

    -- Version Menu Option
    local function OnMouseClickVersion(label)
        CopyToClipboard(GetESOFullVersionString())
    end
    
    local function OnMouseEnterVersion(label)
        ZO_SelectableLabel_OnMouseEnter(label)
        InitializeTooltip(InformationTooltip, label, TOPLEFT, 0, -10, BOTTOMLEFT)
        SetTooltipText(InformationTooltip, zo_strformat(SI_VERSION, GetESOFullVersionString()))
    end

    local function OnMouseExitVersion(label)
        ZO_SelectableLabel_OnMouseExit(label)
        ClearTooltip(InformationTooltip)
    end

    local NO_ACTIVATE_FUNCTION = nil
    local NO_DEACTIVATE_FUNCTION = nil
    self.horizontalMenu:AddMenuItem("Version", GetString(SI_VERSION_MENU_ENTRY), OnMouseClickVersion, NO_DEACTIVATE_FUNCTION, OnMouseEnterVersion, OnMouseExitVersion)
end

function ZO_GameMenu_PreGame_Keyboard:IsLoginSceneShowing()
    return not self.control:IsHidden()
end

--Global XML

function ZO_GameMenu_PreGame_Initialize(self)
    GAME_MENU_PREGAME_KEYBOARD = ZO_GameMenu_PreGame_Keyboard:New(self)
end
