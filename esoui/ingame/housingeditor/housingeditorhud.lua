--------------------
--HousingEditor HUD Fragment
--------------------

ZO_HousingEditorHUDFragment = ZO_SceneFragment:Subclass()

function ZO_HousingEditorHUDFragment:New(control)
    return ZO_SceneFragment.New(self, control)
end

function ZO_HousingEditorHUDFragment:Show()
    self:UpdateVisibility()
    ZO_SceneFragment.Show(self)
end

function ZO_HousingEditorHUDFragment:Hide()
    self:UpdateVisibility()
    ZO_SceneFragment.Hide(self)
end

function ZO_HousingEditorHUDFragment:UpdateVisibility()
    local fragmentHidden = not self:IsShowing()
    local playerDead = IsUnitDead("player")
    local hiddenOrDead = fragmentHidden or playerDead
    RETICLE:RequestHidden(hiddenOrDead)
    TUTORIAL_SYSTEM:SuppressTutorialType(TUTORIAL_TYPE_HUD_INFO_BOX, fragmentHidden, TUTORIAL_SUPPRESSED_BY_SCENE)
    SHARED_INFORMATION_AREA:SetSupressed(hiddenOrDead)
end

--------------------
--Housing HUD Fragment
--------------------

local HousingHUDFragment = ZO_HUDFadeSceneFragment:Subclass()

function HousingHUDFragment:New(...)
    return ZO_HUDFadeSceneFragment.New(self, ...)
end

function HousingHUDFragment:Initialize(control)
    ZO_HUDFadeSceneFragment.Initialize(self, control)

    self.keybindButton = self.control:GetNamedChild("KeybindButton")
    ZO_KeybindButtonTemplate_Setup(self.keybindButton, "SHOW_HOUSING_PANEL", function(...) self:OnHousingHUDButtonPressed(...) end, GetString(SI_HOUSING_HUD_FRAGMENT_EDITOR_KEYBIND))
    
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
    control:RegisterForEvent(EVENT_HOUSING_PLAYER_INFO_CHANGED, function(eventId, ...) self:OnPlayerInfoChanged(...) end)

    self:InitializePlatformStyle()
end

do
    local KEYBOARD_PLATFORM_STYLE =
        {
            keybindButtonTemplate = "ZO_KeybindButton_Keyboard_Template",
            keybindButtonAnchor = ZO_Anchor:New(BOTTOMRIGHT, nil, BOTTOMRIGHT, -80, -25),
        }

    local GAMEPAD_PLATFORM_STYLE =
        {
            keybindButtonTemplate = "ZO_KeybindButton_Gamepad_Template",
            keybindButtonAnchor = ZO_Anchor:New(BOTTOMLEFT, nil, BOTTOMLEFT, 80, -40),
        }

    function HousingHUDFragment:InitializePlatformStyle()
        self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_PLATFORM_STYLE, GAMEPAD_PLATFORM_STYLE)
    end
end

function HousingHUDFragment:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.keybindButton, style.keybindButtonTemplate)
    style.keybindButtonAnchor:Set(self.keybindButton)
    self:UpdateKeybind()
end

function HousingHUDFragment:OnShown()
    ZO_HUDFadeSceneFragment.OnShown(self)
    
    self:UpdateKeybind()
end

function HousingHUDFragment:OnHousingHUDButtonPressed()
    if self:IsShowing() then
        local visitorRole = GetHousingVisitorRole()
        if visitorRole == HOUSING_VISITOR_ROLE_EDITOR then
            local isHouseOwner = IsOwnerOfCurrentHouse()
            local canEditHouse = HasAnyEditingPermissionsForCurrentHouse()
            if not isHouseOwner and not canEditHouse then
                HousingEditorJumpToSafeLocation()
            else
                local result = HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)

                if isHouseOwner and IsESOPlusSubscriber() then
                    TriggerTutorial(TUTORIAL_TRIGGER_ENTERED_OWNED_HOUSING_EDITOR_AS_SUBSCRIBER)
                end
            end
        elseif visitorRole == HOUSING_VISITOR_ROLE_PREVIEW then
            SYSTEMS:GetObject("HOUSING_PREVIEW"):ShowDialog()
        end
        PlaySound(SOUNDS.HOUSING_EDITOR_OPEN)
    end
end

do
    local KEYBIND_STRINGS =
        {
            [HOUSING_VISITOR_ROLE_EDITOR] = GetString(SI_HOUSING_HUD_FRAGMENT_EDITOR_KEYBIND),
            [HOUSING_VISITOR_ROLE_PREVIEW] = GetString(SI_HOUSING_HUD_FRAGMENT_PURCHASE_KEYBIND),
            [HOUSING_VISITOR_ROLE_HOME_SHOW] = GetString(SI_HOUSING_HUD_FRAGMENT_VOTE_KEYBIND),
        }

    function HousingHUDFragment:UpdateKeybind()
        local visitorRole = GetHousingVisitorRole()
        local isHouseOwner = IsOwnerOfCurrentHouse()
        local canEditHouse = HasAnyEditingPermissionsForCurrentHouse()

        local keybindString = KEYBIND_STRINGS[visitorRole]
        if visitorRole == HOUSING_VISITOR_ROLE_EDITOR and not isHouseOwner and not canEditHouse then
            keybindString = GetString(SI_HOUSING_EDITOR_SAFE_LOC)
        end

        self.keybindButton:SetText(keybindString)
    end
end

function HousingHUDFragment:CheckShowCopyPermissionsDialog()
    local currentZoneHouseId = GetCurrentZoneHouseId()
    local collectibleId = GetCollectibleIdForHouse(currentZoneHouseId)
    local numHousesUnlocked = GetTotalUnlockedCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_HOUSE)
    if COLLECTIONS_BOOK_SINGLETON:DoesHousePermissionsDialogNeedToBeShownForCollectible(collectibleId) and numHousesUnlocked > 1 then
        local data = { currentHouse = currentZoneHouseId }
        if IsInGamepadPreferredMode() then
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_COPY_HOUSE_PERMISSIONS", data)
        else
            ZO_Dialogs_ShowDialog("COPY_HOUSING_PERMISSIONS", data)
        end
        COLLECTIONS_BOOK_SINGLETON:MarkHouseCollectiblePermissionLoadDialogShown(collectibleId)
    end
end

function HousingHUDFragment:OnPlayerActivated()
    self:UpdateKeybind()
    self:CheckShowCopyPermissionsDialog()
end

function HousingHUDFragment:OnPlayerInfoChanged(wasOwner, permissionsChanged)
    self:UpdateKeybind()
    local isHouseOwner = IsOwnerOfCurrentHouse()
    if not isHouseOwner and permissionsChanged then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, nil, GetString(SI_HOUSING_PLAYER_PERMISSIONS_CHANGED))
    end
end

--------------------
--HousingEditor HUD 
--------------------

ZO_HousingEditorHud = ZO_Object:Subclass()

function ZO_HousingEditorHud:New(...)
    local editor = ZO_Object.New(self)
    editor:Initialize(...)
    return editor
end

function ZO_HousingEditorHud:Initialize(control)
    self.control = control
    
    self.buttonContainer = control:GetNamedChild("ButtonContainer")

    self:RefreshConstants()
    self:InitializeMovementControllers()
    self:InitializeHudControls()

    HOUSING_EDITOR_HUD_SCENE = ZO_Scene:New("housingEditorHud", SCENE_MANAGER)
    HOUSING_EDITOR_HUD_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnDeferredInitialization()
            local currentMode = GetHousingEditorMode()
            if currentMode == HOUSING_EDITOR_MODE_BROWSE then --if someone cancelled out of the browser without selecting anything
                HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
            elseif currentMode == HOUSING_EDITOR_MODE_SELECTION then
                SCENE_MANAGER:AddFragment(ZO_HOUSING_EDITOR_HISTORY_FRAGMENT)
            end
            KEYBIND_STRIP:AddKeybindButtonGroup(self.exitKeybindButtonStripDescriptor)
            KEYBIND_STRIP:RemoveDefaultExit()
            self:UpdateKeybinds()
        elseif newState == SCENE_HIDDEN then
            self:ClearPlacementKeyPresses()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullVisibleKeybindGroup)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.exitKeybindButtonStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            self.currentKeybindDescriptor = nil
        end
    end)

    HOUSING_EDITOR_HUD_UI_SCENE = ZO_Scene:New("housingEditorHudUI", SCENE_MANAGER)
    HOUSING_EDITOR_HUD_UI_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnDeferredInitialization()
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.UIModeKeybindStripDescriptor)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.exitKeybindButtonStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            self:ClearPlacementKeyPresses()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.UIModeKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.exitKeybindButtonStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end)
    SCENE_MANAGER:SetSceneRestoresBaseSceneOnGameMenuToggle("housingEditorHudUI", true)

    local HOUSING_EDITOR_HUD_SCENE_GROUP = ZO_SceneGroup:New("housingEditorHud", "housingEditorHudUI")
    HOUSING_EDITOR_HUD_SCENE_GROUP:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_GROUP_HIDDEN then
            if GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_BROWSE then
                HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED)
                PlaySound(SOUNDS.HOUSING_EDITOR_CLOSED)
            end
        end
    end)

    local function OnHousingModeChanged(eventId, oldMode, newMode)
        self:OnHousingModeChanged(oldMode, newMode)
    end

    local function OnGamepadModeChanged(eventId, isGamepadPreferred)
        if GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_DISABLED and not self.isDirty then
            HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED)   -- turn off housing mode if gamepad mode changes while active
        end

        self.isDirty = true
    end

    local function OnFurnitureChanged()
        self:UpdateKeybinds()
    end

    EVENT_MANAGER:RegisterForEvent("HousingEditor", EVENT_HOUSING_EDITOR_MODE_CHANGED, OnHousingModeChanged)
    EVENT_MANAGER:RegisterForEvent("HousingEditor", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, OnGamepadModeChanged)
    EVENT_MANAGER:RegisterForEvent("HousingEditor", EVENT_HOUSING_FURNITURE_PLACED, OnFurnitureChanged)
    EVENT_MANAGER:RegisterForEvent("HousingEditor", EVENT_HOUSING_FURNITURE_REMOVED, OnFurnitureChanged)
    EVENT_MANAGER:RegisterForEvent("HousingEditor", EVENT_HOUSING_FURNITURE_MOVED, OnFurnitureChanged)
    EVENT_MANAGER:RegisterForEvent("HousingEditor", EVENT_HOUSING_EDITOR_COMMAND_RESULT, OnFurnitureChanged)
    EVENT_MANAGER:RegisterForEvent("HousingEditor", EVENT_HOUSING_EDITOR_LINK_TARGET_CHANGED, OnFurnitureChanged)

    control:SetHandler("OnUpdate", function(_, currentFrameTimeSeconds) self:OnUpdate(currentFrameTimeSeconds) end)

    self.isDirty = true
end

function ZO_HousingEditorHud:RefreshConstants()
    self.pushSpeedPerSecond, self.rotationStep, self.numTickForRotationChange = GetHousingEditorConstants()
    if self.yawMovementController then
        self.yawMovementController:SetAccumulationPerSecondForChange(self.numTickForRotationChange)
        self.pitchMovementController:SetAccumulationPerSecondForChange(self.numTickForRotationChange)
        self.rollMovementController:SetAccumulationPerSecondForChange(self.numTickForRotationChange)
    end
end

function ZO_HousingEditorHud:InitializeMovementControllers()
    local function GetButtonDirection(axis)
        return self:GetButtonDirection(axis)
    end
    
    self.yawMovementController = ZO_MovementController:New(AXIS_TYPE_Y, self.numTickForRotationChange, GetButtonDirection)
    self.pitchMovementController = ZO_MovementController:New(AXIS_TYPE_X, self.numTickForRotationChange, GetButtonDirection)
    self.rollMovementController = ZO_MovementController:New(AXIS_TYPE_Z, self.numTickForRotationChange, GetButtonDirection)
end

function ZO_HousingEditorHud:OnHousingModeEnabled()
    OpenMarket(MARKET_DISPLAY_GROUP_HOUSE_EDITOR)
    self:CleanDirty()

    SCENE_MANAGER:SetHUDScene("housingEditorHud")
    SCENE_MANAGER:SetHUDUIScene("housingEditorHudUI", true)
end

function ZO_HousingEditorHud:OnHousingModeDisabled()
    OnMarketClose()
    SCENE_MANAGER:RestoreHUDScene()
    SCENE_MANAGER:RestoreHUDUIScene()
end

function ZO_HousingEditorHud:OnHousingModeChanged(oldMode, newMode)
    if newMode == HOUSING_EDITOR_MODE_DISABLED then
        self:OnHousingModeDisabled()
    elseif oldMode == HOUSING_EDITOR_MODE_DISABLED then
        self:OnHousingModeEnabled()
    end

    if newMode == HOUSING_EDITOR_MODE_SELECTION then
        SCENE_MANAGER:AddFragment(ZO_HOUSING_EDITOR_HISTORY_FRAGMENT)
    elseif oldMode == HOUSING_EDITOR_MODE_SELECTION then
        SCENE_MANAGER:RemoveFragment(ZO_HOUSING_EDITOR_HISTORY_FRAGMENT)
    end

    if newMode == HOUSING_EDITOR_MODE_BROWSE then
        SYSTEMS:PushScene("housing_furniture_browser")
    elseif oldMode == HOUSING_EDITOR_MODE_BROWSE then --if something external exited the housing mode hide everything
        if SYSTEMS:IsShowing("housing_furniture_browser") then
            SCENE_MANAGER:HideCurrentScene()
        end
    end

    if oldMode == HOUSING_EDITOR_MODE_PLACEMENT then
        self:ClearPlacementKeyPresses()
    end

    self:UpdateKeybinds()
end

function ZO_HousingEditorHud:OnDeferredInitialization()
    if self.initialized then
        return
    end

    self:InitializeKeybindDescriptors()
    self.initialized = true
end

function ZO_HousingEditorHud:UpdateKeybinds()
    if not HOUSING_EDITOR_HUD_UI_SCENE:IsShowing() then
        local currentMode = GetHousingEditorMode()
        local currentModeKeybindDescriptor = self:GetKeybindStripDescriptorForMode(currentMode)
        if self.currentKeybindDescriptor ~= currentModeKeybindDescriptor then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindDescriptor)
            self.currentKeybindDescriptor = currentModeKeybindDescriptor
            if currentModeKeybindDescriptor then
                KEYBIND_STRIP:AddKeybindButtonGroup(currentModeKeybindDescriptor)
            end
        else
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindDescriptor)
        end
    end
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.UIModeKeybindStripDescriptor)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.exitKeybindButtonStripDescriptor)

    if GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT then
        SCENE_MANAGER:AddFragment(HOUSING_EDITOR_HUD_PLACEMENT_MODE_ACTION_LAYER_FRAGMENT)
        if HousingEditorIsSurfaceDragModeEnabled() then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullVisibleKeybindGroup)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
        else
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.pushAndPullVisibleKeybindGroup)
        end 
    else
        SCENE_MANAGER:RemoveFragment(HOUSING_EDITOR_HUD_PLACEMENT_MODE_ACTION_LAYER_FRAGMENT)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullVisibleKeybindGroup)
    end 

    local rotationHidden = GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_PLACEMENT

    if rotationHidden then
        HOUSING_EDITOR_HUD_SCENE:RemoveFragment(HOUSING_EDITOR_ACTION_BAR_FRAGMENT)
    else
        HOUSING_EDITOR_HUD_SCENE:AddFragment(HOUSING_EDITOR_ACTION_BAR_FRAGMENT)
    end
end

function ZO_HousingEditorHud:InitializeHudControls()
    local yawLeftButton = self.buttonContainer:GetNamedChild("YawLeftButton")
    yawLeftButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_yawCW.dds")
    ZO_Keybindings_RegisterLabelForBindingUpdate(yawLeftButton:GetNamedChild("Text"), "HOUSING_EDITOR_YAW_LEFT")

    local yawRightButton = self.buttonContainer:GetNamedChild("YawRightButton")
    yawRightButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_yawCCW.dds")
    ZO_Keybindings_RegisterLabelForBindingUpdate(yawRightButton:GetNamedChild("Text"), "HOUSING_EDITOR_YAW_RIGHT")

    local pitchForwardButton = self.buttonContainer:GetNamedChild("PitchForwardButton")
    pitchForwardButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_pitchCCW.dds")
    ZO_Keybindings_RegisterLabelForBindingUpdate(pitchForwardButton:GetNamedChild("Text"), "HOUSING_EDITOR_PITCH_FORWARD")

    local pitchBackButton = self.buttonContainer:GetNamedChild("PitchBackButton")
    pitchBackButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_pitchCW.dds")
    ZO_Keybindings_RegisterLabelForBindingUpdate(pitchBackButton:GetNamedChild("Text"), "HOUSING_EDITOR_PITCH_BACKWARD")

    local rollLeftButton = self.buttonContainer:GetNamedChild("RollLeftButton")
    rollLeftButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_rollCCW.dds")
    ZO_Keybindings_RegisterLabelForBindingUpdate(rollLeftButton:GetNamedChild("Text"), "HOUSING_EDITOR_ROLL_LEFT")

    local rollRightButton = self.buttonContainer:GetNamedChild("RollRightButton")
    rollRightButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_rollCW.dds")
    ZO_Keybindings_RegisterLabelForBindingUpdate(rollRightButton:GetNamedChild("Text"), "HOUSING_EDITOR_ROLL_RIGHT")
    

    self.hudButtons =
    {
        yawLeftButton,
        yawRightButton,
        pitchForwardButton,
        pitchBackButton,
        rollLeftButton,
        rollRightButton,
    }   
    
    local KEYBOARD_CONSTANTS =
    {
        frame = "EsoUI/Art/ActionBar/abilityFrame64_up.dds",
        dimensions = 50,
        font = "ZoFontGameSmall",
        labelOffsetY = 1,
        buttonOffsetX = 2,
        containerOffsetY = -110,
    }

    local GAMEPAD_CONSTANTS =
    {
        frame = "EsoUI/Art/ActionBar/Gamepad/gp_abilityFrame64.dds",
        dimensions = 64,
        font = "ZoFontGamepad18",
        labelOffsetY = -6,
        buttonOffsetX = 10,
        containerOffsetY = -160,
    }

    local function ApplyStyle(style)
        local lastButton = nil
        for _, button in ipairs(self.hudButtons) do
            button:SetDimensions(style.dimensions, style.dimensions)
            button:GetNamedChild("Frame"):SetTexture(style.frame)
            button:GetNamedChild("Text"):SetFont(style.font)

            local isValid, point, relativeTo, relativePoint, offsetX, offsetY, constrains = button:GetNamedChild("Text"):GetAnchor(0)
            if isValid then
                button:GetNamedChild("Text"):SetAnchor(point, relativeTo, relativePoint, offsetX, style.labelOffsetY, constrains)
            end

            if lastButton then
                button:SetAnchor(LEFT, lastButton, RIGHT, style.buttonOffsetX, 0)
            end
            lastButton = button
        end

        self.buttonContainer:SetAnchor(BOTTOM, nil, BOTTOM, 0, style.containerOffsetY)
    end

    ZO_PlatformStyle:New(ApplyStyle, KEYBOARD_CONSTANTS, GAMEPAD_CONSTANTS) 
end

do
    local ROTATE_YAW_RIGHT = 1
    local ROTATE_YAW_LEFT = 2
    local ROTATE_PITCH_FORWARD = 3
    local ROTATE_PITCH_BACKWARD = 4
    local ROTATE_ROLL_LEFT = 5
    local ROTATE_ROLL_RIGHT = 6
    local PUSH_FORWARD = 7
    local PULL_BACKWARD = 8

    function ZO_HousingEditorHud:GetButtonDirection(axis)
        if axis == AXIS_TYPE_Y then
            return (self.placementKeyPresses[ROTATE_YAW_LEFT] and 1 or 0) + (self.placementKeyPresses[ROTATE_YAW_RIGHT] and -1 or 0)
        elseif axis == AXIS_TYPE_X then
            return (self.placementKeyPresses[ROTATE_PITCH_BACKWARD] and 1 or 0) + (self.placementKeyPresses[ROTATE_PITCH_FORWARD] and -1 or 0)
        elseif axis == AXIS_TYPE_Z then
            return (self.placementKeyPresses[ROTATE_ROLL_RIGHT] and 1 or 0) + (self.placementKeyPresses[ROTATE_ROLL_LEFT] and -1 or 0)
        end
    end

    function ZO_HousingEditorHud:ClearPlacementKeyPresses()
        for i = ROTATE_YAW_RIGHT, PULL_BACKWARD do
            self.placementKeyPresses[i] = false
        end
    end

    function ZO_HousingEditorHud:InitializeKeybindDescriptors()
        local function PlacementCallback(direction, isUp)
            self.placementKeyPresses[direction] = not isUp and GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT
        end
        
        -- Exit
        self.exitKeybindButtonStripDescriptor =
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            {
                name = GetString(SI_EXIT_BUTTON),
                keybind = "DISABLE_HOUSING_EDITOR",
                visible = function()
                        return GetHousingEditorMode() == HOUSING_EDITOR_MODE_SELECTION
                    end,
                callback = function()
                        HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED)
                    end,
                alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            },
        }
        
        self.placementKeyPresses =
        {
            [ROTATE_YAW_RIGHT] = false,
            [ROTATE_YAW_LEFT] = false,
            [ROTATE_PITCH_FORWARD] = false,
            [ROTATE_PITCH_BACKWARD] = false,
            [PUSH_FORWARD] = false,
            [PULL_BACKWARD] = false,
        }

        self.selectionModeKeybindStripDescriptor =
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            --Primary (Selection/Placement)
            {
                name =  GetString(SI_HOUSING_EDITOR_SELECT),
                keybind = "HOUSING_EDITOR_PRIMARY_ACTION",
                callback =  function()
                                local result = HousingEditorSelectTargettedFurniture()
                                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
                                if result == HOUSING_REQUEST_RESULT_SUCCESS then
                                    PlaySound(SOUNDS.HOUSING_EDITOR_PICKUP_ITEM)
                                    return true
                                end
                                return false --if not successful return false so you can jump in editor with a gamepad
                            end,
                order = 10,
            },

            -- Link Furniture
            {
                name = GetString(SI_HOUSING_EDITOR_LINK),
                keybind = "HOUSING_EDITOR_BEGIN_FURNITURE_LINKING",
                callback =  function()
                                local result = HousingEditorBeginLinkingTargettedFurniture()
                                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
                                if result == HOUSING_REQUEST_RESULT_SUCCESS then
                                    PlaySound(SOUNDS.HOUSING_EDITOR_PICKUP_ITEM)
                                end
                            end,
                order = 15,
            },

            --Secondary 
            {
                name = GetString(SI_HOUSING_EDITOR_BROWSE),
                keybind = "HOUSING_EDITOR_SECONDARY_ACTION",
                visible = function() 
                                return IsOwnerOfCurrentHouse()
                            end,
                callback =  function()
                                HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_BROWSE)
                            end,
                order = 20,
            },

             --Jump to safe loc
            {
                name = GetString(SI_HOUSING_EDITOR_SAFE_LOC),
                keybind = "HOUSING_EDITOR_JUMP_TO_SAFE_LOC",
                callback =  function()
                                HousingEditorJumpToSafeLocation()
                            end,
                order = 60,
            },

            -- Undo
            {
                name = GetString(SI_HOUSING_EDITOR_UNDO),
                keybind = "HOUSING_EDITOR_UNDO_ACTION",
                enabled = function() return CanUndoLastHousingEditorCommand() end,
                callback = function()
                                UndoLastHousingEditorCommand()
                           end,
            },

            -- Redo
            {
                name = GetString(SI_HOUSING_EDITOR_REDO),
                keybind = "HOUSING_EDITOR_REDO_ACTION",
                enabled = function() return CanRedoLastHousingEditorCommand() end,
                callback = function()
                                RedoLastHousingEditorCommand()
                           end,
            },
        }

        self.placementModeKeybindStripDescriptor =
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            --Negative
            {
                name = GetString(SI_HOUSING_EDITOR_CANCEL),
                keybind = "HOUSING_EDITOR_NEGATIVE_ACTION",
                callback = function()
                                HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
                            end,
                alignment = KEYBIND_STRIP_ALIGN_LEFT,
            },

            --Primary (Selection/Placement)
            {
                name =  function()
                            local stackCount = HousingEditorGetSelectedFurnitureStackCount()
                            if stackCount <= 1 then
                                return GetString(SI_HOUSING_EDITOR_PLACE)
                            else
                                return zo_strformat(SI_HOUSING_EDITOR_PLACE_WITH_STACK_COUNT, stackCount)
                            end
                        end,
                keybind = "HOUSING_EDITOR_PRIMARY_ACTION",
                callback =  function()
                                local result = HousingEditorRequestSelectedPlacement()
                                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
                                if result == HOUSING_REQUEST_RESULT_SUCCESS then
                                    PlaySound(SOUNDS.HOUSING_EDITOR_PLACE_ITEM)
                                end
                                self:ClearPlacementKeyPresses()
                            end,
                order = 10,
            },

            --Secondary 
            {
                name = GetString(SI_HOUSING_EDITOR_PUT_AWAY),
                keybind = "HOUSING_EDITOR_SECONDARY_ACTION",
                visible = function() 
                                return IsOwnerOfCurrentHouse()
                            end,
                callback =  function()
                                local result = HousingEditorRequestRemoveSelectedFurniture()
                                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
                                if result == HOUSING_REQUEST_RESULT_SUCCESS then
                                    PlaySound(SOUNDS.HOUSING_EDITOR_RETRIEVE_ITEM)
                                end
                            end,
                order = 20,
            },

            --Tertiary (Surface drag for Gamepad, Mouse mode for keyboard)
            {
                name = function()
                            if IsInGamepadPreferredMode() then
                                if HousingEditorIsSurfaceDragModeEnabled() then 
                                    return GetString(SI_HOUSING_EDITOR_SURFACE_DRAG_OFF)
                                else
                                    return GetString(SI_HOUSING_EDITOR_SURFACE_DRAG_ON)
                                end
                            else
                                return GetString(SI_HOUSING_EDITOR_CURSOR_MODE)
                            end
                        end,
                keybind = "HOUSING_EDITOR_TERTIARY_ACTION",
                callback = function()
                                if IsInGamepadPreferredMode() then 
                                    HousingEditorToggleSurfaceDragMode()
                                    self:UpdateKeybinds()
                                else
                                    SCENE_MANAGER:OnToggleHUDUIBinding()
                                end
                           end,
                order = 30,
            },

            --Quaternary (keyboard only)
            {
                name = function()
                            if HousingEditorIsSurfaceDragModeEnabled() then 
                                return GetString(SI_HOUSING_EDITOR_SURFACE_DRAG_OFF)
                            else
                                return GetString(SI_HOUSING_EDITOR_SURFACE_DRAG_ON)
                            end
                        end,
                keybind = "HOUSING_EDITOR_QUATERNARY_ACTION",
                visible = function() return not IsInGamepadPreferredMode() end,
                callback = function() 
                                HousingEditorToggleSurfaceDragMode()
                                self:UpdateKeybinds()
                           end,
                order = 40,
            },

            --Roll Right
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Yaw Right",
                keybind = "HOUSING_EDITOR_YAW_RIGHT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_YAW_RIGHT, isUp)
                            end,
            },

            --Roll Left
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Yaw Left",
                keybind = "HOUSING_EDITOR_YAW_LEFT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_YAW_LEFT, isUp)
                            end,
            },

            --Pitch Right
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Pitch Forward",
                keybind = "HOUSING_EDITOR_PITCH_FORWARD",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_PITCH_FORWARD, isUp)
                            end,
            },

            --Pitch Left
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Pitch Backward",
                keybind = "HOUSING_EDITOR_PITCH_BACKWARD",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_PITCH_BACKWARD, isUp)
                            end,
            },

            --Roll Right
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Roll Right",
                keybind = "HOUSING_EDITOR_ROLL_RIGHT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_ROLL_RIGHT, isUp)
                            end,
            },

            --Roll Left
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Roll Left",
                keybind = "HOUSING_EDITOR_ROLL_LEFT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_ROLL_LEFT, isUp)
                            end,
            },
            --Align to Surface
            {
                name = GetString(SI_HOUSING_EDITOR_ALIGN),
                keybind = "HOUSING_EDITOR_ALIGN_TO_SURFACE",
                callback =  function()
                                HousingEditorAlignFurnitureToSurface()
                            end,
                order = 50,
            },
        }

        self.linkModeKeybindStripDescriptor =
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            --Negative
            {
                name = GetString(SI_HOUSING_EDITOR_EXIT_LINK),
                keybind = "HOUSING_EDITOR_SECONDARY_ACTION",
                callback = function()
                                HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
                            end,
                alignment = KEYBIND_STRIP_ALIGN_LEFT,
            },

            --Primary (Unlink/Link As Child)
            {
                name = function()
                            local linkResult = HousingEditorGetLinkRelationshipFromSelectedChildToPendingFurniture()
                            if linkResult == HOUSING_EDITOR_PENDING_LINK_RELATIONSHIP_LINKED_TO_PARENT then
                                return GetString(SI_HOUSING_EDITOR_REMOVE_PARENT)
                            elseif linkResult == HOUSING_EDITOR_PENDING_LINK_RELATIONSHIP_LINKED_AS_CHILD then
                                return GetString(SI_HOUSING_EDITOR_REMOVE_CHILD)
                            elseif linkResult == HOUSING_EDITOR_PENDING_LINK_RELATIONSHIP_NO_LINK then
                                return GetString(SI_HOUSING_EDITOR_ADD_AS_CHILD)
                            elseif linkResult == HOUSING_EDITOR_PENDING_LINK_RELATIONSHIP_BAD_LINK then
                                return GetString(SI_HOUSING_EDITOR_BAD_LINK_ACTION)
                            end
                       end,
                keybind = "HOUSING_EDITOR_PRIMARY_ACTION",
                visible = function()
                              local linkResult = HousingEditorGetLinkRelationshipFromSelectedChildToPendingFurniture()
                              return linkResult ~= HOUSING_EDITOR_PENDING_LINK_RELATIONSHIP_INVALID
                          end,
                enabled = function()
                                local linkResult = HousingEditorGetLinkRelationshipFromSelectedChildToPendingFurniture()
                                if linkResult == HOUSING_EDITOR_PENDING_LINK_RELATIONSHIP_BAD_LINK then
                                    local result = HousingEditorGetPendingBadLinkResult()
                                    return false, GetString("SI_HOUSINGREQUESTRESULT", result)
                                else
                                    return true
                                end
                          end,
                callback =  function()
                                HousingEditorPerformPendingLinkOperation()
                            end,
                order = 10,
            },

            --Secondary (Remove My Parent)
            {
                name = GetString(SI_HOUSING_EDITOR_REMOVE_PARENT),
                keybind = "HOUSING_EDITOR_TERTIARY_ACTION",
                visible = function() 
                                local linkResult = HousingEditorGetLinkRelationshipFromSelectedChildToPendingFurniture()
                                if linkResult == HOUSING_EDITOR_PENDING_LINK_RELATIONSHIP_INVALID then
                                    return HousingEditorCanRemoveParentFromPendingFurniture() == HOUSING_REQUEST_RESULT_SUCCESS
                                end
                            end,
                callback =  function()
                                HousingEditorRemoveParentFromPendingFurniture()
                            end,
                order = 20,
            },

            --Tertiary (Remove All Children)
            {
                name = GetString(SI_HOUSING_EDITOR_REMOVE_ALL_CHILDREN),
                keybind = "HOUSING_EDITOR_NEGATIVE_ACTION",
                visible = function()
                                local linkResult = HousingEditorGetLinkRelationshipFromSelectedChildToPendingFurniture()
                                if linkResult == HOUSING_EDITOR_PENDING_LINK_RELATIONSHIP_INVALID then
                                    return HousingEditorCanRemoveAllChildrenFromPendingFurniture() == HOUSING_REQUEST_RESULT_SUCCESS
                                end
                           end,
                callback = function()
                                HousingEditorRemoveAllChildrenFromPendingFurniture()
                           end,
                order = 30,
            },
        }

        self.UIModeKeybindStripDescriptor =
        {
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Housing Editor Exit UI Mode",
                keybind = "HOUSING_EDITOR_TERTIARY_ACTION",
                ethereal = true,
                callback = function()
                                if not IsInGamepadPreferredMode() then 
                                    SCENE_MANAGER:OnToggleHUDUIBinding()
                                end
                            end,
            },
        }

        --Push/Pull Visible (for when surface drag is off)
        self.pushAndPullVisibleKeybindGroup =
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            {
            
                name = GetString(SI_HOUSING_EDITOR_PUSH_FORWARD),
                keybind = "HOUSING_EDITOR_PUSH_FORWARD",
                visible = function() return GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT and not HousingEditorIsSurfaceDragModeEnabled() end,
                handlesKeyUp = true,
                callback =  function(isUp)
                                if IsInGamepadPreferredMode() then
                                    PlacementCallback(PUSH_FORWARD, isUp)
                                else
                                    HousingEditorPushFurniture(self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds()) --mousewheel doesn't need the update loop
                                end
                            end,
                order = 70,
            },
            {
                name = GetString(SI_HOUSING_EDITOR_PUSH_BACKWARD),
                keybind = "HOUSING_EDITOR_PULL_BACKWARD",
                visible = function() return GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT and not HousingEditorIsSurfaceDragModeEnabled() end,
                handlesKeyUp = true,
                callback =  function(isUp)
                                if IsInGamepadPreferredMode() then
                                    PlacementCallback(PULL_BACKWARD, isUp)
                                else
                                    HousingEditorPushFurniture(-self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds()) --mousewheel doesn't need the update loop
                                end
                            end,
                order = 80,
            }
        }

        --Push/Pull ethereal (for when surface drag is on, we still want to consume input so the camera doesn't move)
        self.pushAndPullEtherealKeybindGroup =
        {
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Push Forward",
                keybind = "HOUSING_EDITOR_PUSH_FORWARD",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                if IsInGamepadPreferredMode() then
                                    PlacementCallback(PUSH_FORWARD, isUp)
                                else
                                    HousingEditorPushFurniture(self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds()) --mousewheel doesn't need the update loop
                                end
                            end,
            },
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Pull Backward",
                keybind = "HOUSING_EDITOR_PULL_BACKWARD",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                if IsInGamepadPreferredMode() then
                                    PlacementCallback(PULL_BACKWARD, isUp)
                                else
                                    HousingEditorPushFurniture(-self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds()) --mousewheel doesn't need the update loop
                                end
                            end,
            }
        }
    end

    function ZO_HousingEditorHud:GetKeybindStripDescriptorForMode(mode)
        if mode == HOUSING_EDITOR_MODE_SELECTION then
            return self.selectionModeKeybindStripDescriptor
        elseif mode == HOUSING_EDITOR_MODE_PLACEMENT then
            return self.placementModeKeybindStripDescriptor
        elseif mode == HOUSING_EDITOR_MODE_LINK then
            return self.linkModeKeybindStripDescriptor
        end
    end

    function ZO_HousingEditorHud:GetRotationAmount(axis)
        local rotation = 0
        local movementController
        
        if axis == AXIS_TYPE_X then
            movementController = self.pitchMovementController
        elseif axis == AXIS_TYPE_Y then
            movementController = self.yawMovementController
        elseif axis == AXIS_TYPE_Z then
            movementController = self.rollMovementController
        end

        local controllerAtMaxVelocity = movementController:IsAtMaxVelocity()
        if controllerAtMaxVelocity then --if the movement controller is firing at max speed, switch from frame based incrementing to time based (might base this off a button press in the future)
            rotation = self.rotationStep * GetFrameDeltaNormalizedForTargetFramerate()
        else --otherwse do the incremental steps for more finite control
            rotation = self.rotationStep
        end

        local direction = 0
        local movement = movementController:CheckMovement()

        if controllerAtMaxVelocity then
            direction = self:GetButtonDirection(axis) * -1
        elseif movement == MOVEMENT_CONTROLLER_MOVE_NEXT then
            direction = 1
        elseif movement == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            direction = -1
        end

        return rotation * direction
    end
    
    function ZO_HousingEditorHud:OnUpdate(currentFrameTime)
        if GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT then
             local x = self:GetRotationAmount(AXIS_TYPE_X)
             local y = self:GetRotationAmount(AXIS_TYPE_Y)
             local z = self:GetRotationAmount(AXIS_TYPE_Z)

            if x ~= 0 then
                HousingEditorRotateFurniture(AXIS_TYPE_X, x)
            end
            if y ~= 0 then
                HousingEditorRotateFurniture(AXIS_TYPE_Y, y)
            end
            if z ~= 0 then
                HousingEditorRotateFurniture(AXIS_TYPE_Z, z)
            end
                
            if self.placementKeyPresses[PUSH_FORWARD] then
                HousingEditorPushFurniture(self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds())
            end

            if self.placementKeyPresses[PULL_BACKWARD] then
                HousingEditorPushFurniture(-self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds())
            end
        end
    end
end

function ZO_HousingEditorHud:CleanDirty()
    if self.isDirty then
        self.isDirty = false
        self:SetupHousingEditorHudScene()
    end
end

function ZO_HousingEditorHud:SetupHousingEditorHudScene()
    if IsInGamepadPreferredMode() then
        HOUSING_EDITOR_HUD_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_KEYBIND_STRIP_GROUP)
        HOUSING_EDITOR_HUD_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.KEYBOARD_KEYBIND_STRIP_GROUP)

        HOUSING_EDITOR_HUD_UI_SCENE:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
        HOUSING_EDITOR_HUD_UI_SCENE:RemoveFragment(KEYBIND_STRIP_FADE_FRAGMENT)
    else
        HOUSING_EDITOR_HUD_SCENE:AddFragmentGroup(FRAGMENT_GROUP.KEYBOARD_KEYBIND_STRIP_GROUP)
        HOUSING_EDITOR_HUD_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.GAMEPAD_KEYBIND_STRIP_GROUP)

        HOUSING_EDITOR_HUD_UI_SCENE:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
        HOUSING_EDITOR_HUD_UI_SCENE:RemoveFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
    end
end

-----------------------------
--Housing Editor History 
-----------------------------

local MAX_COMMANDS_SHOWN = 6
ZO_HOUSING_EDITOR_HISTORY_ENTRY_DIMENSION_KEYBOARD_X = 290
ZO_HOUSING_EDITOR_HISTORY_ENTRY_DIMENSION_KEYBOARD_Y = 50
ZO_HOUSING_EDITOR_HISTORY_ENTRY_DIMENSION_GAMEPAD_X = 315
ZO_HOUSING_EDITOR_HISTORY_ENTRY_DIMENSION_GAMEPAD_Y = 58
ZO_HOUSING_EDITOR_HISTORY_CONTAINER_DIMENSION_X = ZO_HOUSING_EDITOR_HISTORY_ENTRY_DIMENSION_GAMEPAD_X
ZO_HOUSING_EDITOR_HISTORY_CONTAINER_DIMENSION_Y = ZO_HOUSING_EDITOR_HISTORY_ENTRY_DIMENSION_GAMEPAD_Y * MAX_COMMANDS_SHOWN

ZO_HousingEditorHistory = ZO_Object:Subclass()

function ZO_HousingEditorHistory:New(...)
    local undoStack = ZO_Object.New(self)
    undoStack:Initialize(...)
    return undoStack
end

function ZO_HousingEditorHistory:Initialize(control)
    self.control = control
    self.entryContainer = control:GetNamedChild("Container")
    self.historyTitle = control:GetNamedChild("Header")

    self:SetDefaultIndicies()

    ZO_HOUSING_EDITOR_HISTORY_FRAGMENT = ZO_FadeSceneFragment:New(control)

    ZO_HOUSING_EDITOR_HISTORY_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:UpdateUndoStack()
        end
    end)

    self.historyEntryPool = ZO_ControlPool:New("ZO_HousingEditorHistory_Entry", self.entryContainer)
    self.recentUndoStackControls = {}

    local function OnUndoRedoCommand()
        self:UpdateUndoStack()
    end

    control:RegisterForEvent(EVENT_HOUSING_EDITOR_COMMAND_RESULT, OnUndoRedoCommand)

    ZO_PlatformStyle:New(function() self:ApplyPlatformStyle() end)

    -- Make sure title is setup properly
    self:ApplyPlatformStyle()
end

function ZO_HousingEditorHistory:UpdateUndoStack()
    self.historyEntryPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.recentUndoStackControls)

    local numCommands = GetNumHousingEditorHistoryCommands()
    local currentCommandIndex = GetCurrentHousingEditorHistoryCommandIndex()

    if self.numCommands ~= numCommands then
        self:SetDefaultIndicies()
    else
        local commandDirection = currentCommandIndex - self.lastCommandIndex
        if commandDirection < 0 and currentCommandIndex == self.endingIndex + (MAX_COMMANDS_SHOWN / 2) then
            self:SetContrainedEndingIndex(self.endingIndex - 1)
            if self.startingIndex - self.endingIndex > MAX_COMMANDS_SHOWN then
                self:SetContrainedStartingIndex(self.startingIndex - 1)
            end
        elseif commandDirection > 0 and currentCommandIndex == self.startingIndex  then
            self:SetContrainedStartingIndex(self.startingIndex + 1)
            if self.startingIndex - self.endingIndex > MAX_COMMANDS_SHOWN then
                self:SetContrainedEndingIndex(self.endingIndex + 1)
            end
        end
    end

    local currentCommandControl
    local nextIndex = self.endingIndex
    local lastIndex = self.startingIndex
    local offsetY = 0

    while nextIndex < lastIndex do
        local commandType, name, icon = GetHousingEditorHistoryCommandInfo(nextIndex)
        if commandType ~= HOUSING_EDITOR_COMMAND_TYPE_NONE then
            local isEntryActive = false
            local historyEntry = self.historyEntryPool:AcquireObject()
            ApplyTemplateToControl(historyEntry, ZO_GetPlatformTemplate("ZO_HousingEditorHistory_Entry"))
            table.insert(self.recentUndoStackControls, historyEntry)
            historyEntry:SetAnchor(TOPRIGHT, self.entryContainer, TOPRIGHT, 0, offsetY)
            historyEntry.label:SetText(zo_strformat(SI_HOUSE_HISTORY_COMMAND_FORMATTER, GetString("SI_HOUSINGEDITORCOMMANDTYPE", commandType), name))
            historyEntry.icon:SetTexture(icon)
            if nextIndex + 1 == currentCommandIndex then
                currentCommandControl = historyEntry
                isEntryActive = true
            elseif currentCommandIndex > nextIndex then
                isEntryActive = true
            end

            if isEntryActive then
                historyEntry.label:SetColor(ZO_SELECTED_TEXT:UnpackRGB())
                historyEntry.icon:SetDesaturation(0)
            else
                historyEntry.label:SetColor(ZO_DISABLED_TEXT:UnpackRGB())
                historyEntry.icon:SetDesaturation(1)
            end
            historyEntry.backgroundHighlight:SetHidden(true)
            offsetY = offsetY + historyEntry:GetHeight()
        end

        nextIndex = nextIndex + 1
    end

    if currentCommandControl then
        currentCommandControl.backgroundHighlight:SetHidden(false)
    end

    self.historyTitle:SetHidden(numCommands == 0)

    self.lastCommandIndex = currentCommandIndex
end

function ZO_HousingEditorHistory:SetDefaultIndicies()
    self.numCommands = GetNumHousingEditorHistoryCommands()
    self.lastCommandIndex = GetCurrentHousingEditorHistoryCommandIndex()
    self:SetContrainedStartingIndex(self.lastCommandIndex + 2)
    self:SetContrainedEndingIndex(self.startingIndex - MAX_COMMANDS_SHOWN)
end

function ZO_HousingEditorHistory:SetContrainedStartingIndex(newIndex)
    self.startingIndex = newIndex

    local totalCommands = GetNumHousingEditorHistoryCommands()
    if self.startingIndex > totalCommands then
        self.startingIndex = totalCommands
    end
end

function ZO_HousingEditorHistory:SetContrainedEndingIndex(newIndex)
    self.endingIndex = newIndex
    
    if self.endingIndex < 0 then
        self.endingIndex = 0
    end
end

function ZO_HousingEditorHistory:ApplyPlatformStyle()
    for i,control in ipairs(self.recentUndoStackControls) do
        ApplyTemplateToControl(control, ZO_GetPlatformTemplate("ZO_HousingEditorHistory_Entry"))
        control:ClearAnchors()
        control:SetAnchor(TOPRIGHT, self.entryContainer, TOPRIGHT, 0, control:GetHeight() * (i - 1))
    end

    self.historyTitle:SetFont(IsInGamepadPreferredMode() and "ZoFontGamepadBold34" or "ZoFontWinH2")
end

--[[ Globals ]]--
function ZO_HousingEditorActionBar_OnInitialize(control)
    HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED) --disable if someone reloads ui from editor mode
    HOUSING_EDITOR_SHARED = ZO_HousingEditorHud:New(control)
end

function ZO_HousingHUDFragmentTopLevel_Initialize(control)
    HOUSING_HUD_FRAGMENT = HousingHUDFragment:New(control)
end

function ZO_HousingEditorHistory_Initialize(control)
    HOUSING_EDITOR_UNDO_STACK = ZO_HousingEditorHistory:New(control)
end

function ZO_HousingEditorHistory_Entry_OnInitialized(control)
    control.icon = control:GetNamedChild("Icon")
    control.label = control:GetNamedChild("Label")
    control.background = control:GetNamedChild("Bg")
    control.backgroundHighlight = control:GetNamedChild("Highlight")
end
