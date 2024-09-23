local function IsSafeForSystemToCaptureMouseCursor()
    return IsMouseWithinClientArea() and not IsUserAdjustingClientWindow()
end

TOPLEVEL_LOCKS_UI_MODE = true
ZO_REMOTE_SCENE_CHANGE_ORIGIN = SCENE_MANAGER_MESSAGE_ORIGIN_INGAME
ZO_SceneManager_Leader.AddBypassHideSceneConfirmationReason("GAMEPAD_MODE_CHANGED")

local ZO_IngameSceneManager = ZO_SceneManager_Leader:Subclass()

function ZO_IngameSceneManager:New()
    return  ZO_SceneManager_Leader.New(self)
end

function ZO_IngameSceneManager:Initialize(...)
    ZO_SceneManager_Leader.Initialize(self, ...)

    self.topLevelWindows = {}
    self.restoresBaseSceneOnGameMenuToggle = {}
    self.numTopLevelShown = 0
    self.numRemoteTopLevelShown = 0
    self.initialized = false
    self.hudSceneName = "hud"
    self.hudUISceneName = "hudui"
    self.hudUISceneHidesAutomatically = true
    self.exitUIModeOnChatFocusLost = false
    self.isLoadingScreenShown = true

    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_NEW_MOVEMENT_IN_UI_MODE, function() self:OnNewMovementInUIMode() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_GAME_CAMERA_ACTIVATED, function() self:OnGameCameraActivated() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_GAME_FOCUS_CHANGED, function(_, hasFocus) self:OnGameFocusChanged(hasFocus) end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_ENTER_GROUND_TARGET_MODE, function() self:OnEnterGroundTargetMode() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_PLAYER_ACTIVATED, function() self:OnLoadingScreenDropped() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_PLAYER_DEACTIVATED, function() self:OnLoadingScreenShown() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_GLOBAL_MOUSE_UP, function() self:OnGlobalMouseUp() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_MOUNTED_STATE_CHANGED, function() self:OnMountStateChanged() end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_DISPLAY_TUTORIAL, function(eventCode, ...) self:OnTutorialStart(...) end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function(eventCode, ...) self:OnGamepadPreferredModeChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("IngameSceneManager", EVENT_REMOTE_TOP_LEVEL_CHANGE, function(eventId, ...) self:ChangeRemoteTopLevel(...) end)
end

function ZO_IngameSceneManager:IsInUIMode()
    if IsGameCameraActive() then
        return IsGameCameraUIModeActive()
    end

    return true
end

function ZO_IngameSceneManager:IsLockedInUIMode()
    if IsGameCameraActive() then
        for topLevel, _ in pairs(self.topLevelWindows) do
            if topLevel.locksUIMode and not topLevel:IsControlHidden() then
                return true
            end
        end
    end

    return false
end

function ZO_IngameSceneManager:SetInUIMode(inUIMode, bypassHideSceneConfirmationReason)
    if IsGameCameraActive() then
        if inUIMode ~= self:IsInUIMode() then
            if inUIMode then
                SetGameCameraUIMode(true)
                self:SetBaseScene(self.hudUISceneName)
                ZO_RadialMenu.ForceActiveMenuClosed()
                INTERACTIVE_WHEEL_MANAGER:CancelCurrentInteraction()
                DIRECTIONAL_INPUT:Activate(self, GuiRoot)
                --Clear out any in progress HUD narration when entering the UI
                ClearNarrationQueue(NARRATION_TYPE_HUD)
                return true
            else
                if not self:IsLockedInUIMode() and DoesGameHaveFocus() and IsSafeForSystemToCaptureMouseCursor() then
                    local function ResultCallback(allowed)
                        if allowed then
                            self.manuallyEnteredHUDUIMode = nil
                            EndLooting()
                            SetGameCameraUIMode(false)
                            ZO_ChatSystem_ExitChat()
                            self:HideTopLevels()
                            DIRECTIONAL_INPUT:Deactivate(self)
                            MAIN_MENU_MANAGER:ForceClearBlockingScenes()
                            self:SetBaseScene(self.hudSceneName)
                            --Clear out any in progress UI narration when entering the HUD
                            ClearNarrationQueue(NARRATION_TYPE_UI_SCREEN)
                        end
                    end
                    --Showing the hud scene may fail if the current scene needs confirmation before closing. So we wait to do all of the other parts until after the hide of the current scene succeeds.
                    local DEFAULT_PUSH = nil
                    local DEFAULT_NEXT_SCENE_CLEARS_SCENE_STACK = nil
                    local DEFAULT_NUM_SCENES_NEXT_SCENE_POPS = nil
                    self:ShowWithFollowup(self.hudSceneName, ResultCallback, DEFAULT_PUSH, DEFAULT_NEXT_SCENE_CLEARS_SCENE_STACK, DEFAULT_NUM_SCENES_NEXT_SCENE_POPS, bypassHideSceneConfirmationReason)
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
    if self.hudUISceneHidesAutomatically and self.numTopLevelShown == 0 and self.numRemoteTopLevelShown == 0 and showingHUDUI and DoesGameHaveFocus() and not ZO_GetChatSystem():IsTextEntryOpen() then
        return self:SetInUIMode(false)
    end
end

function ZO_IngameSceneManager:OnGameFocusChanged()
    if IsGameCameraActive() and IsPlayerActivated() then
        if DoesGameHaveFocus() and IsSafeForSystemToCaptureMouseCursor() then
            if self.actionRequiredTutorialThatActivatedWithoutFocus then
                self:ClearActionRequiredTutorialBlockers()
                self.actionRequiredTutorialThatActivatedWithoutFocus = false
                return
            end
            
            local mousedOverControl = WINDOW_MANAGER:GetMouseOverControl()
            if not mousedOverControl or mousedOverControl == GuiRoot then
                if self:IsInUIMode() then
                    self:ConsiderExitingUIMode(self:IsShowingBaseScene())
                end
            end
        else
            if not self:IsInUIMode() then
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

function ZO_IngameSceneManager:OnGamepadPreferredModeChanged(isGamepadPreferred)
    if self.currentScene then
        local shouldShowHUD = false
        local handleGamepadPreferredModeChangedCallback = self.currentScene:GetHandleGamepadPreferredModeChangedCallback()
        if handleGamepadPreferredModeChangedCallback and handleGamepadPreferredModeChangedCallback(isGamepadPreferred) then
            shouldShowHUD = false
        --If we are showing a scene, or will be showing a scene after this one hides and that scene was not opened in the current input mode (gamepad/keyboard) then we need to stop it from showing.
        elseif self.currentScene:IsShowing() and self.currentScene:WasRequestedToShowInGamepadPreferredMode() ~= IsInGamepadPreferredMode() then
            shouldShowHUD = true
        elseif self.nextScene then
            if self.nextScene:WasRequestedToShowInGamepadPreferredMode() ~= IsInGamepadPreferredMode() then
                shouldShowHUD = true
            end
        end

        if shouldShowHUD then
            local FORCE_CLOSE = true
            ZO_Dialogs_ReleaseAllDialogs(FORCE_CLOSE)
            if not self:IsShowingBaseScene() then
                if not self:SetInUIMode(false, ZO_BHSCR_GAMEPAD_MODE_CHANGED) then
                    if self:IsLockedInUIMode() then
                        internalassert(false, "Gamepad preferred mode changed while locked in UI mode: could the player be locked inside a dialog or menu without an input method?")
                    else
                        local DEFAULT_PUSH = nil
                        local DEFAULT_NEXT_SCENE_CLEARS_SCENE_STACK = nil
                        local DEFAULT_NUM_SCENES_NEXT_SCENE_POPS = nil
                        self:Show(self.hudSceneName, DEFAULT_PUSH, DEFAULT_NEXT_SCENE_CLEARS_SCENE_STACK, DEFAULT_NUM_SCENES_NEXT_SCENE_POPS, ZO_BHSCR_GAMEPAD_MODE_CHANGED)
                    end
                end
            end
        end
    end
end

function ZO_IngameSceneManager:SafelyAttemptToExitUIMode()
    if IsGameCameraActive() and IsPlayerActivated() then
        if not self.manuallyEnteredHUDUIMode then
            local focusedControl = WINDOW_MANAGER:GetMouseFocusControl() or WINDOW_MANAGER:GetMouseOverControl()
            if focusedControl == GuiRoot then
                if self:IsInUIMode() and IsSafeForSystemToCaptureMouseCursor() then
                    self:ConsiderExitingUIMode(self:IsShowingBaseScene())
                end
            end
        end
    end
end

function ZO_IngameSceneManager:OnGlobalMouseUp()
    if not IsConsoleUI() then
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
        ["endeavorSealStoreSceneKeyboard"] = true,
        ["gamepad_endeavor_seal_market_pre_scene"] = true,
        ["gamepad_market_pre_scene"] = true,
        ["gamepad_market"] = true,
        ["gamepad_market_preview"] = true,
        ["dyeStampConfirmationKeyboard"] = true,
        ["dyeStampConfirmationGamepad"] = true,
        ["inventory"] = true,
        ["gamepad_inventory_root"] = true,
        ["collectionsBook"] = true,
        ["gamepadCollectionsBook"] = true,
        ["stats"] = true,
        ["outfitStylesBook"] = true,
        ["gamepad_outfits_selection"] = true,
        ["chapterUpgradePreviewGamepad"] = true,
        ["giftInventoryViewGamepad"] = true,
        ["giftInventoryViewKeyboard"] = true,
        ["dailyLoginRewardsPreview_Gamepad"] = true,
        ["dailyLoginRewards"] = true,
        ["tradinghouse"] = true,
        ["guildHeraldry"] = true,
        ["store"] = true,
        ["groupMenuKeyboard"] = true,
        ["promotionalEventsPreview_Gamepad"] = true,
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
        if not self:DoesCurrentSceneOverrideMountStateChange() then
            self:SetInUIMode(false)
        end
    end
end

function ZO_IngameSceneManager:OnLoadingScreenDropped()
    self.hudSceneName = "hud"
    self.hudUISceneName = "hudui"
    self.hudUISceneHidesAutomatically = true

    if self.sceneQueuedForLoadingScreenDrop then
        self:Show(self.sceneQueuedForLoadingScreenDrop)
    else
        if IsGameCameraActive() then
            if self:IsInUIMode() then
                if not self:SetInUIMode(false) then
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

    self.isLoadingScreenShown = false
end

function ZO_IngameSceneManager:OnLoadingScreenShown()
    self.isLoadingScreenShown = true
    if IsGameCameraActive() then
        self:SetInUIMode(true)
    end
end

function ZO_IngameSceneManager:ShowSceneOrQueueForLoadingScreenDrop(sceneName)
    if self.isLoadingScreenShown then
        self.sceneQueuedForLoadingScreenDrop = sceneName
    else
        self:Show(sceneName)
    end
end

function ZO_IngameSceneManager:OnGameCameraActivated()
    if IsPlayerActivated() then
        if self:IsShowing(self.hudSceneName) or self:IsShowingNext(self.hudSceneName) then
            self:SetInUIMode(false)
        elseif self:IsInUIMode() then
            self:ConsiderExitingUIMode(self:IsShowingBaseScene())
        end

        if not DoesGameHaveFocus() then
            self:OnGameFocusChanged(false)
        end
    end
end

function ZO_IngameSceneManager:OnPreSceneStateChange(scene, currentState, nextState)
    if IsGameCameraActive() then
        if nextState == SCENE_SHOWING and scene ~= self.baseScene then
            if not self:IsInUIMode() then
                self:SetInUIMode(true)
            end
        end
    end
end

function ZO_IngameSceneManager:OnNextSceneRemovedFromQueue(oldNextScene, newNextScene)
    --if the old next scene was booted out, reconsider if we want to exit UI mode based on what the new next scene is
    ZO_SceneManager_Leader.OnNextSceneRemovedFromQueue(self, oldNextScene, newNextScene)
    if IsGameCameraActive() then
        if self.currentScene:GetState() == SCENE_HIDING and newNextScene == self.baseScene then
            if self:IsInUIMode() then
                local SHOWING_HUD_UI = true
                self:ConsiderExitingUIMode(SHOWING_HUD_UI)
            end
        end
    end
end

function ZO_IngameSceneManager:OnSceneStateChange(scene, oldState, newState)
    if IsGameCameraActive() then
        if newState == SCENE_HIDING and self.nextScene == self.baseScene then
            if self:IsInUIMode() then
                local SHOWING_HUD_UI = true
                self:ConsiderExitingUIMode(SHOWING_HUD_UI)
            end
        elseif newState == SCENE_SHOWING then
            if IsGameCameraSiegeControlled() then
                if scene:GetName() ~= self.hudSceneName and scene:GetName() ~= self.hudUISceneName then
                    ReleaseGameCameraSiegeControlled()
                end
            end
        end
    end
    ZO_SceneManager_Leader.OnSceneStateChange(self, scene, oldState, newState)
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
   if self:IsShowing(oldHudScene) or self:IsShowingNext(oldHudScene) then
        self:SetBaseScene(hudSceneName)
        self:Show(hudSceneName)
   end
end

function ZO_IngameSceneManager:GetHUDSceneName()
   return self.hudSceneName
end

-- These functions must be called before calling :HideScene() on the HUD. The original HUD 
-- won't be restored properly if :Restore is called from OnHiding or OnHidden of the 
-- temporary HUD scene.
function ZO_IngameSceneManager:RestoreHUDScene()
    self:SetHUDScene("hud")
end

function ZO_IngameSceneManager:SetHUDUIScene(hudUISceneName, hidesAutomatically)
    local oldHUDUIScene = self.hudUISceneName
    self.hudUISceneName = hudUISceneName
    self.hudUISceneHidesAutomatically = hidesAutomatically
    if self:IsShowing(oldHUDUIScene) or self:IsShowingNext(oldHUDUIScene) then
        self:SetBaseScene(hudUISceneName)
        self:Show(hudUISceneName)
    end
end

-- These functions must be called before calling :HideScene() on the HUD. The original HUD 
-- won't be restored properly if :Restore is called from OnHiding or OnHidden of the 
-- temporary HUD scene.
function ZO_IngameSceneManager:RestoreHUDUIScene()
    self:SetHUDUIScene("hudui", true)
end

--Top Levels

function ZO_IngameSceneManager:RegisterTopLevel(topLevel, locksUIMode)
    topLevel.locksUIMode = locksUIMode
    self.topLevelWindows[topLevel] = true
end

function ZO_IngameSceneManager:HideTopLevel(topLevel)
    if not topLevel:IsControlHidden() and self.topLevelWindows[topLevel] == true then
        topLevel:SetHidden(true)
        self.numTopLevelShown = self.numTopLevelShown - 1
        self:OnHideTopLevel()
    end
end

function ZO_IngameSceneManager:OnHideTopLevel()
    if IsGameCameraActive() then
        self:ConsiderExitingUIMode(self:IsShowingBaseScene() or self:IsShowingBaseSceneNext())
    end
end

function ZO_IngameSceneManager:ShowTopLevel(topLevel)
    if topLevel:IsControlHidden() and self.topLevelWindows[topLevel] == true then
        topLevel:SetHidden(false)
        self.numTopLevelShown = self.numTopLevelShown + 1
        self:OnShowTopLevel()
    end    
end

function ZO_IngameSceneManager:OnShowTopLevel()
    if IsGameCameraActive() and not self:IsInUIMode() then
        self:SetInUIMode(true)
        self:ShowBaseScene()
    end
end

function ZO_IngameSceneManager:ToggleTopLevel(topLevel)
    if topLevel:IsControlHidden() then
        self:ShowTopLevel(topLevel)
    else
        self:HideTopLevel(topLevel)
    end
end

function ZO_IngameSceneManager:ChangeRemoteTopLevel(remoteChangeOrigin, remoteChangeType)
    if remoteChangeOrigin ~= ZO_REMOTE_SCENE_CHANGE_ORIGIN then
        if remoteChangeType == REMOTE_SCENE_REQUEST_TYPE_SHOW then
            self.numRemoteTopLevelShown = self.numRemoteTopLevelShown + 1
            self:OnShowTopLevel()
        elseif remoteChangeType == REMOTE_SCENE_REQUEST_TYPE_HIDE then
            self.numRemoteTopLevelShown = zo_max(self.numRemoteTopLevelShown - 1, 0)
            self:OnHideTopLevel()
        end
    end
end

local function GetMenuObject()
    return SYSTEMS:GetObject("mainMenu")
end

--Alt Key Functions
function ZO_IngameSceneManager:OnToggleUIModeBinding()
    if IsGameCameraActive() then
        if self:IsInUIMode() then
            self:SetInUIMode(false)
        else
            if GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_DISABLED then
                --disable housing if going to a menu, but not a from mouse mode back to crosshair
                HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED)
            end
            if self.currentScene and self.currentScene:DoesSceneRestoreHUDSceneFromToggleUIMode() then
                self:RestoreHUDScene()
                self:RestoreHUDUIScene()
                return
            end
            self:SetInUIMode(true)
            GetMenuObject():ShowLastCategory()
        end
    else
        self:ShowBaseScene()
    end
end

--Escape Key Functions
function ZO_IngameSceneManager:HideTopLevels()
    local topLevelHidden = false
    for topLevel, _ in pairs(self.topLevelWindows) do
        if not topLevel:IsControlHidden() then
            self:HideTopLevel(topLevel)
            topLevelHidden = true
        end
    end

    return topLevelHidden
end

function ZO_IngameSceneManager:OnToggleGameMenuBinding()
    if self.hudUISceneName == "housingEditorHud" or self.hudUISceneName == "housingEditorHudUI" then
        HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED)
        return
    end

    local SHOW_BASE_SCENE = true
    if SYSTEMS:GetObject("guild_heraldry"):AttemptSaveIfBlocking(SHOW_BASE_SCENE) then
        return
    end

    if MAIN_MENU_MANAGER:HasBlockingScene() then
        MAIN_MENU_MANAGER:ActivatedBlockingScene_BaseScene()
        return
    end

    if IsPlayerGroundTargeting() then
        CancelCast()
        return
    end
    
    if IsGameCameraSiegeControlled() then
        ReleaseGameCameraSiegeControlled()
        return
    end

    if ZO_Dialogs_IsShowingDialog() then
        ZO_Dialogs_ReleaseAllDialogs()
        return
    end

    if self.currentScene and self.currentScene:DoesSceneRestoreHUDSceneFromToggleGameMenu() then
        self:RestoreHUDScene()
        self:RestoreHUDUIScene()
        return
    end

    if IsGameCameraPreferredTargetValid() then
        ClearGameCameraPreferredTarget()
        return
    end

    if PopupTooltip and not PopupTooltip:IsControlHidden() then
        ZO_PopupTooltip_Hide()
        return
    end

    if self:IsShowingBaseScene() and not self:IsInUIMode() then
        local interactionType = GetInteractionType()
        --hidey holes are the first interaction type to have two parts and we don't want hitting
        --Esc to take the player out of a hideyhole.
        if interactionType ~= INTERACTION_NONE and interactionType ~= INTERACTION_HIDEYHOLE then
            EndInteraction(interactionType)
            return
        end

        if IsInteractionPending() then
            EndPendingInteraction()
            return
        end

        if HousingEditorIsLocalPlayerInPairedFurnitureInteraction() then
            HousingEditorEndLocalPlayerPairedFurnitureInteraction()
            return
        end
    end    

    if self:IsLockedInUIMode() then
        return
    end

    if self:IsShowing(self.hudUISceneName) and not self.restoresBaseSceneOnGameMenuToggle[self.hudUISceneName] then
        self:RestoreHUDUIScene()
        return
    end

    --Top Levels and Scenes
    local topLevelHidden = self:HideTopLevels()

    local baseSceneShown = false
    if not self:IsShowingBaseScene() then
        self:ShowBaseScene()
        baseSceneShown = true
    end

    --System Menu Toggle
    if not (topLevelHidden or baseSceneShown) then
        SCENE_MANAGER:Toggle("gameMenuInGame")
    end
end

--Period Key Functionality
function ZO_IngameSceneManager:OnToggleHUDUIBinding()
    if IsGameCameraActive() then
        if self:IsInUIMode() then
            self:SetInUIMode(false)
        elseif self.hudUISceneName == self.hudSceneName then
            self:SetInUIMode(true)
        else
            self.manuallyEnteredHUDUIMode = true
            self:Show(self.hudUISceneName)
        end
    end 
end

function ZO_IngameSceneManager:SetSceneRestoresBaseSceneOnGameMenuToggle(sceneName, doesRestore)
    self.restoresBaseSceneOnGameMenuToggle[sceneName] = doesRestore
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
