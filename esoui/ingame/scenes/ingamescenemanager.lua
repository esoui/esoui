local function IsSafeForSystemToCaptureMouseCursor()
    return IsMouseWithinClientArea() and not IsUserAdjustingClientWindow()
end

TOPLEVEL_LOCKS_UI_MODE = true
ZO_REMOTE_SCENE_CHANGE_ORIGIN = REMOTE_SCENE_STATE_CHANGE_ORIGIN_INGAME

local ZO_IngameSceneManager = ZO_SceneManager:Subclass()

function ZO_IngameSceneManager:New()
    local manager = ZO_SceneManager.New(self)

    manager.topLevelWindows = {}
    manager.numTopLevelShown = 0
    manager.initialized = false
    manager.hudSceneName = "hud"
    manager.hudUISceneName = "hudui"
    manager.hudUISceneHidesAutomatically = true
    manager.exitUIModeOnChatFocusLost = false

    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_NEW_MOVEMENT_IN_UI_MODE, function() manager:OnNewMovementInUIMode() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_GAME_CAMERA_ACTIVATED, function() manager:OnGameCameraActivated() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_GAME_FOCUS_CHANGED, function(_, hasFocus) manager:OnGameFocusChanged(hasFocus) end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_ENTER_GROUND_TARGET_MODE, function() manager:OnEnterGroundTargetMode() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_PLAYER_ACTIVATED, function() manager:OnLoadingScreenDropped() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_PLAYER_DEACTIVATED, function() manager:OnLoadingScreenShown() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_GLOBAL_MOUSE_UP, function() manager:OnGlobalMouseUp() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_MOUNTED_STATE_CHANGED, function() manager:OnMountStateChanged() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_DISPLAY_TUTORIAL, function(eventCode, ...) manager:OnTutorialStart(...) end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() manager:OnGamepadPreferredModeChanged() end)

    return manager
end

function ZO_IngameSceneManager:IsInUIMode()
    if(IsGameCameraActive()) then
        return IsGameCameraUIModeActive()
    end

    return false
end

function ZO_IngameSceneManager:IsLockedInUIMode()
    if(IsGameCameraActive()) then
        for topLevel, _ in pairs(self.topLevelWindows) do
            if(topLevel.locksUIMode and not topLevel:IsControlHidden()) then
                return true
            end
        end
    end

    return false
end

function ZO_IngameSceneManager:SetInUIMode(inUI)
    if(IsGameCameraActive()) then
        if(inUI ~= self:IsInUIMode()) then
            if(inUI) then
                SetGameCameraUIMode(true)
                self:SetBaseScene(self.hudUISceneName)
                ZO_RadialMenu.ForceActiveMenuClosed()
                DIRECTIONAL_INPUT:Activate(self, GuiRoot)
                return true
            else
                if(not self:IsLockedInUIMode() and DoesGameHaveFocus() and IsSafeForSystemToCaptureMouseCursor()) then
                    self.manuallyEnteredHUDUIMode = nil
                    EndLooting()
                    SetGameCameraUIMode(false)
                    self:HideTopLevels()
                    DIRECTIONAL_INPUT:Deactivate(self)
                    self:SetBaseScene(self.hudSceneName)
                    self:ShowBaseScene()
                    MAIN_MENU_MANAGER:ForceClearBlockingScenes()
                    return true
                end
            end
        end
    end
    return false
end

function ZO_IngameSceneManager:UpdateDirectionalInput()
    --Consume the sticks when we're in UI mode so they don't leak through into the camera and movement processing.
    DIRECTIONAL_INPUT:Consume(ZO_DI_LEFT_STICK, ZO_DI_RIGHT_STICK)
end

--UI Mode Life Cycle

function ZO_IngameSceneManager:ConsiderExitingUIMode(showingHUDUI)
    if(self.hudUISceneHidesAutomatically and self.numTopLevelShown == 0 and showingHUDUI and DoesGameHaveFocus() and not CHAT_SYSTEM:IsTextEntryOpen()) then
        return self:SetInUIMode(false)
    end
end

function ZO_IngameSceneManager:OnGameFocusChanged()
    if(IsGameCameraActive() and IsPlayerActivated()) then
        if(DoesGameHaveFocus() and IsSafeForSystemToCaptureMouseCursor()) then
            if self.actionRequiredTutorialThatActivatedWithoutFocus then
                self:ClearActionRequiredTutorialBlockers()
                self.actionRequiredTutorialThatActivatedWithoutFocus = false
                return
            end
            
            local mousedOverControl = WINDOW_MANAGER:GetMouseOverControl()
            if(not mousedOverControl or mousedOverControl == GuiRoot) then
                if(self:IsInUIMode()) then
                    self:ConsiderExitingUIMode(self:IsShowingBaseScene())
                end
            end
        else
            if(not self:IsInUIMode()) then
                self:SetInUIMode(true)
                self:ShowBaseScene()
            end
        end
    end
end

local ONLY_CONSIDER_MOUSE_VISIBILITY_WHILE_MOVING = true

function ZO_IngameSceneManager:OnChatInputStart()
    self.exitUIModeOnChatFocusLost = false
    if GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_RETURN_CURSOR_ON_CHAT_FOCUS) and IsGameCameraActive() then
        if not self:IsInUIMode() and SCENE_MANAGER:IsShowingBaseScene() then
            self:SetInUIMode(true)
            self:ShowBaseScene()
            HideMouse(ONLY_CONSIDER_MOUSE_VISIBILITY_WHILE_MOVING)

            self:CallWhen(self.hudUISceneName, SCENE_HIDDEN, function()
                if self.exitUIModeOnChatFocusLost then
                    -- something other than ending chat input is making us exit UI mode, just return to the old state and normal UI mode behavior
                    ShowMouse(ONLY_CONSIDER_MOUSE_VISIBILITY_WHILE_MOVING)
                    self.exitUIModeOnChatFocusLost = false
                end
            end)

            self.exitUIModeOnChatFocusLost = true
        end
    end
end

function ZO_IngameSceneManager:OnChatInputEnd()
    if self.exitUIModeOnChatFocusLost then
        self.exitUIModeOnChatFocusLost = false

        ShowMouse(ONLY_CONSIDER_MOUSE_VISIBILITY_WHILE_MOVING)
        self:SafelyAttemptToExitUIMode()
    end
end

function ZO_IngameSceneManager:OnTutorialStart(tutorialIndex)
    --Only HUD Brief tutorial types can have the Action Required flag set true.
    if IsTutorialActionRequired(tutorialIndex) then
        TUTORIAL_SYSTEM:ForceRemoveAll() --Make sure no tutorial is showing before turning off UI mode
        if DoesGameHaveFocus() and IsSafeForSystemToCaptureMouseCursor() then
            self:ClearActionRequiredTutorialBlockers()
        else
            self.actionRequiredTutorialThatActivatedWithoutFocus = true
        end
    end
end

function ZO_IngameSceneManager:ClearActionRequiredTutorialBlockers()
    local interactionType = GetInteractionType()
    if interactionType ~= INTERACTION_NONE then
        EndInteraction(interactionType)
    end

    if IsInteractionPending() then
        EndPendingInteraction()
    end
    
    self:HideTopLevels()
    ZO_Dialogs_ReleaseAllDialogs()
    self:SetInUIMode(false)
end

function ZO_IngameSceneManager:OnGamepadPreferredModeChanged()
    self:RestoreHUDScene()
    self:RestoreHUDUIScene()   

    --if a scene was already shown when we change input mode, hide it
    if not self:IsShowingBaseScene() and self.currentScene and self.currentScene:IsShowing() then
        self:SetInUIMode(false)
    end
end

function ZO_IngameSceneManager:SafelyAttemptToExitUIMode()
    if(IsGameCameraActive() and IsPlayerActivated()) then
        if(not self.manuallyEnteredHUDUIMode) then
            local mousedOverControl = WINDOW_MANAGER:GetMouseOverControl()
            if(not mousedOverControl or mousedOverControl == GuiRoot) then
                if(self:IsInUIMode() and IsSafeForSystemToCaptureMouseCursor()) then
                    self:ConsiderExitingUIMode(self:IsShowingBaseScene())
                end
            end
        end
    end
end

function ZO_IngameSceneManager:OnGlobalMouseUp()
    if(not IsConsoleUI()) then
        self:SafelyAttemptToExitUIMode()
    end
end

function ZO_IngameSceneManager:OnEnterGroundTargetMode()
    self:SetInUIMode(false)
end

do
    local OVERRIDING_SCENE_NAMES =
    {
        ["market"] = true,
        ["gamepad_market_pre_scene"] = true,
        ["gamepad_market"] = true,
        ["gamepad_market_preview"] = true,
        ["dyeStampConfirmationKeyboard"] = true,
        ["dyeStampConfirmationGamepad"] = true,
        ["inventory"] = true,
        ["gamepad_inventory_root"] = true,
        ["collectionsBook"] = true,
        ["gamepadCollectionsBook"] = true,
    }

    function ZO_IngameSceneManager:DoesCurrentSceneOverrideMountStateChange()
        if self.currentScene then
            local currentSceneName = self.currentScene:GetName()
            if OVERRIDING_SCENE_NAMES[currentSceneName] then
                if self:IsShowing(currentSceneName) then
                    return true
                end
            end
        end

        return false
    end

    function ZO_IngameSceneManager:OnMountStateChanged()
        -- The market screen causes a dismount and blocks mounting so we need to ignore this on that screen
        if not self:DoesCurrentSceneOverrideMountStateChange()
	    then
            self:SetInUIMode(false)
        end
    end
end

function ZO_IngameSceneManager:OnLoadingScreenDropped()
    self.hudSceneName = "hud"
    self.hudUISceneName = "hudui"
    self.hudUISceneHidesAutomatically = true
    if(IsGameCameraActive()) then
        if(self:IsInUIMode()) then
            if(not self:SetInUIMode(false)) then
                self:SetBaseScene("hudui")
                self:ShowBaseScene()
            end
        else
            self:SetBaseScene("hud")
            self:ShowBaseScene()
        end
    else
        self:SetBaseScene("hudui")
        self:ShowBaseScene()
    end
end

function ZO_IngameSceneManager:OnLoadingScreenShown()
    if(IsGameCameraActive()) then
        self:SetInUIMode(true)
    end
end

function ZO_IngameSceneManager:OnGameCameraActivated()
    if(IsPlayerActivated()) then
        if(self:IsShowing(self.hudSceneName) or self:IsShowingNext(self.hudSceneName)) then
            self:SetInUIMode(false)
        elseif(self:IsInUIMode()) then
            self:ConsiderExitingUIMode(self:IsShowingBaseScene())
        end

        if(not DoesGameHaveFocus()) then
            self:OnGameFocusChanged(false)
        end
    end
end

function ZO_IngameSceneManager:OnPreSceneStateChange(scene, currentState, nextState)
    if(IsGameCameraActive()) then
        if(nextState == SCENE_SHOWING and scene ~= self.baseScene) then
            if(not self:IsInUIMode()) then
                self:SetInUIMode(true)
            end
        end
    end
end

function ZO_IngameSceneManager:OnNextSceneRemovedFromQueue(oldNextScene, newNextScene)
    --if the old next scene was booted out, reconsider if we want to exit UI mode based on what the new next scene is
    ZO_SceneManager.OnNextSceneRemovedFromQueue(self, oldNextScene, newNextScene)
    if(IsGameCameraActive()) then
        if(self.currentScene:GetState() == SCENE_HIDING and newNextScene == self.baseScene) then
            if(self:IsInUIMode()) then
                local SHOWING_HUD_UI = true
                self:ConsiderExitingUIMode(SHOWING_HUD_UI)
            end
        end
    end
end

function ZO_IngameSceneManager:OnSceneStateChange(scene, oldState, newState)
    if(IsGameCameraActive()) then
        if(newState == SCENE_HIDING and self.nextScene == self.baseScene) then
            if(self:IsInUIMode()) then
                local SHOWING_HUD_UI = true
                self:ConsiderExitingUIMode(SHOWING_HUD_UI)
            end
        elseif(newState == SCENE_SHOWING) then
            if(IsGameCameraSiegeControlled()) then
                if(scene:GetName() ~= self.hudSceneName and scene:GetName() ~= self.hudUISceneName) then
                    ReleaseGameCameraSiegeControlled()
                end
            end
        end
    end
    ZO_SceneManager.OnSceneStateChange(self, scene, oldState, newState)
end

function ZO_IngameSceneManager:OnNewMovementInUIMode()
    if not self:IsShowingBaseScene() then
        self:ShowBaseScene()
    else
        self:ConsiderExitingUIMode(self:IsShowingBaseScene())
    end
end

--HUD

function ZO_IngameSceneManager:SetHUDScene(hudSceneName)
   local oldHudScene = self.hudSceneName
   self.hudSceneName = hudSceneName
   if(self:IsShowing(oldHudScene)) then
        self:SetBaseScene(hudSceneName)
        self:Show(hudSceneName)
   end
end

function ZO_IngameSceneManager:RestoreHUDScene()
    self:SetHUDScene("hud")
end

function ZO_IngameSceneManager:SetHUDUIScene(hudUISceneName, hidesAutomatically)
    local oldHUDUIScene = self.hudUISceneName
    self.hudUISceneName = hudUISceneName
    self.hudUISceneHidesAutomatically = hidesAutomatically
    if(self:IsShowing(oldHUDUIScene)) then
        self:SetBaseScene(hudUISceneName)
        self:Show(hudUISceneName)
    end
end

function ZO_IngameSceneManager:RestoreHUDUIScene()
    self:SetHUDUIScene("hudui", true)
end

--Top Levels

function ZO_IngameSceneManager:RegisterTopLevel(topLevel, locksUIMode)
    topLevel.locksUIMode = locksUIMode
    self.topLevelWindows[topLevel] = true
end

function ZO_IngameSceneManager:HideTopLevel(topLevel)
    if(not topLevel:IsControlHidden() and self.topLevelWindows[topLevel] == true) then
        topLevel:SetHidden(true)
        self.numTopLevelShown = self.numTopLevelShown - 1
        if(IsGameCameraActive()) then
            self:ConsiderExitingUIMode(self:IsShowingBaseScene() or self:IsShowingBaseSceneNext())
        end
    end
end

function ZO_IngameSceneManager:ShowTopLevel(topLevel)
    if(topLevel:IsControlHidden() and self.topLevelWindows[topLevel] == true) then
        topLevel:SetHidden(false)
        self.numTopLevelShown = self.numTopLevelShown + 1
        if(IsGameCameraActive()) then
            if(not self:IsInUIMode()) then
                self:SetInUIMode(true)
                self:ShowBaseScene()
            end
        end
    end    
end

function ZO_IngameSceneManager:ToggleTopLevel(topLevel)
    if(topLevel:IsControlHidden()) then
        self:ShowTopLevel(topLevel)
    else
        self:HideTopLevel(topLevel)
    end
end

local function GetMenuObject()
    return SYSTEMS:GetObject("mainMenu")
end

--Alt Key Functions
function ZO_IngameSceneManager:OnToggleUIModeBinding()
    if(IsGameCameraActive()) then
        if(self:IsInUIMode()) then
            self:SetInUIMode(false)
        else
            if GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_DISABLED then
                --disable housing if going to a menu, but not a from mouse mode back to crosshair
                HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED)
            end
            self:SetInUIMode(true)
            GetMenuObject():ShowLastCategory()
        end
    else
        self:ShowBaseScene()
    end
end

--Escape Key Functions
local function HideSpecialWindow(window)
    if(not window:IsControlHidden()) then
        window:SetHidden(true)
        return true
    end
    
    return false
end

function ZO_IngameSceneManager:HideTopLevels()
    local topLevelHidden = false
    for topLevel, _ in pairs(self.topLevelWindows) do
        if(not topLevel:IsControlHidden()) then
            self:HideTopLevel(topLevel)
            topLevelHidden = true
        end
    end

    return topLevelHidden
end

function ZO_IngameSceneManager:OnToggleGameMenuBinding()
    if SYSTEMS:IsShowing("dyeing") then
        SYSTEMS:GetObject("dyeing"):AttemptExit()
        return
    end

    if not IsInGamepadPreferredMode() and GUILD_RANKS:AttemptSaveIfBlocking() then
        -- The guild ranks scene was the current blocking scene, so we can return early here.
        return
    end

    local SHOW_BASE_SCENE = true
    if SYSTEMS:GetObject("guild_heraldry"):AttemptSaveIfBlocking(SHOW_BASE_SCENE) then
        return
    end

    if(IsPlayerGroundTargeting()) then
        CancelCast()
        return
    end
    
    if(IsGameCameraSiegeControlled()) then
        ReleaseGameCameraSiegeControlled()
        return
    end

    if(ZO_Dialogs_IsShowingDialog()) then
        ZO_Dialogs_ReleaseAllDialogs()
        return
    end

    if(IsGameCameraPreferredTargetValid()) then
        ClearGameCameraPreferredTarget()
        return
    end

    if PopupTooltip and not PopupTooltip:IsControlHidden() then
        ZO_PopupTooltip_Hide()
        return
    end

    if(self:IsShowingBaseScene() and not self:IsInUIMode()) then
        local interactionType = GetInteractionType()
        --hidey holes are the first interaction type to have two parts and we don't want hitting
        --Esc to take the player out of a hideyhole.
        if(interactionType ~= INTERACTION_NONE and interactionType ~= INTERACTION_HIDEYHOLE) then
            EndInteraction(interactionType)
            return
        end

        if(IsInteractionPending()) then
            EndPendingInteraction()
            return
        end
    end    

    if(self:IsLockedInUIMode()) then
        return
    end

    if(self:IsShowing(self.hudUISceneName) and self.hudUISceneName ~= "hudui") then
        self:RestoreHUDUIScene()
        return
    end

    --Top Levels and Scenes
    local topLevelHidden = self:HideTopLevels()

    local baseSceneShown = false
    if(not self:IsShowingBaseScene()) then
        self:ShowBaseScene()
        baseSceneShown = true
    end

    --System Menu Toggle
    if(not (topLevelHidden or baseSceneShown)) then
        SCENE_MANAGER:Toggle("gameMenuInGame")
    end
end

--Period Key Functionality
function ZO_IngameSceneManager:OnToggleHUDUIBinding()
    if(IsGameCameraActive()) then
        if(self:IsInUIMode()) then
            self:SetInUIMode(false)
        else
            self.manuallyEnteredHUDUIMode = true
            self:Show(self.hudUISceneName)
        end
    end 
end

--Global API

function ZO_SceneManager_ToggleUIModeBinding()
    SCENE_MANAGER:OnToggleUIModeBinding()
end

function ZO_SceneManager_ToggleGameMenuBinding()
    SCENE_MANAGER:OnToggleGameMenuBinding()
end

function ZO_SceneManager_ToggleHUDUIBinding()
    SCENE_MANAGER:OnToggleHUDUIBinding()
end

SCENE_MANAGER = ZO_IngameSceneManager:New()
