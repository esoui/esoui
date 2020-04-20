HOUSING_EDITOR_POSITION_AXIS_X1 = 1
HOUSING_EDITOR_POSITION_AXIS_X2 = 2
HOUSING_EDITOR_POSITION_AXIS_Y1 = 3
HOUSING_EDITOR_POSITION_AXIS_Y2 = 4
HOUSING_EDITOR_POSITION_AXIS_Z1 = 5
HOUSING_EDITOR_POSITION_AXIS_Z2 = 6
HOUSING_EDITOR_ROTATION_AXIS_X1 = 7
HOUSING_EDITOR_ROTATION_AXIS_X2 = 8
HOUSING_EDITOR_ROTATION_AXIS_Y1 = 9
HOUSING_EDITOR_ROTATION_AXIS_Y2 = 10
HOUSING_EDITOR_ROTATION_AXIS_Z1 = 11
HOUSING_EDITOR_ROTATION_AXIS_Z2 = 12

local PI = math.pi
local TWO_PI = 2 * PI
local HALF_PI = 0.5 * PI
local QUARTER_PI = 0.25 * PI

local AXIS_INDICATOR_ALPHA_ACTIVE_PERCENTAGE = 0.9
local AXIS_INDICATOR_ALPHA_INACTIVE_PERCENTAGE = 0
local AXIS_INDICATOR_ALPHA_MAX_PERCENTAGE = 0.9
local AXIS_INDICATOR_RGB_WEIGHT_MIN_PERCENTAGE = 0.8
local AXIS_INDICATOR_RGB_WEIGHT_MAX_PERCENTAGE = 1.3
local AXIS_INDICATOR_SCALE_MAX = 3
local AXIS_INDICATOR_SCALE_MIN = 1
local AXIS_INDICATOR_VISIBILITY_YAW_OFFSET_ANGLE = math.rad(2)
local AXIS_KEYBIND_RGB_WEIGHT_MIN_PERCENTAGE = 0.3
local AXIS_KEYBIND_RGB_WEIGHT_MAX_PERCENTAGE = 0.7
local ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M = 2.25
local TRANSLATION_AXIS_RANGE_MAX_CM = 10000
-- Texture height / width, specified in pixels.
local TRANSLATION_AXIS_INDICATOR_ASPECT_RATIO = 216 / 374
local TRANSLATION_AXIS_INDICATOR_LOCAL_X_DIMENSION_M = 1.5
local TRANSLATION_AXIS_INDICATOR_LOCAL_Y_DIMENSION_M = TRANSLATION_AXIS_INDICATOR_LOCAL_X_DIMENSION_M * TRANSLATION_AXIS_INDICATOR_ASPECT_RATIO

-- Yaw offset, in radians, for the Y-axis indicator while in pickup mode.
-- This slight offset allows the axis to remain visible and interactive
-- while it is rotationally locked to the camera's heading.
local Y_AXIS_INDICATOR_YAW_OFFSET_RAD = -(PI * 15 / 180)

local X_AXIS_NEGATIVE_INDICATOR_COLOR = ZO_ColorDef:New(0.2, 0, 1, 1)
local X_AXIS_POSITIVE_INDICATOR_COLOR = ZO_ColorDef:New(0.2, 0, 1, 1)
local Y_AXIS_NEGATIVE_INDICATOR_COLOR = ZO_ColorDef:New(1, 0.2, 0, 1)
local Y_AXIS_POSITIVE_INDICATOR_COLOR = ZO_ColorDef:New(1, 0.2, 0, 1)
local Z_AXIS_NEGATIVE_INDICATOR_COLOR = ZO_ColorDef:New(0, 1, 0.2, 1)
local Z_AXIS_POSITIVE_INDICATOR_COLOR = ZO_ColorDef:New(0, 1, 0.2, 1)

local PRESS_AND_HOLD_ACCELERATION_INTERVAL_MS = 1000
local PRECISION_POSITION_OR_ORIENTATION_UPDATE_INTERVAL_MS = 100

local PRECISION_MOVE_UNITS_CM = {1, 10, 100}
local PRECISION_ROTATE_UNITS_DEG = {0.05, 1, 15}
local PRECISION_ROTATE_INTERVALS_MS = {[0.05] = 120000, [1] = 9000, [15] = 1200}
local PICKUP_ROTATE_INTERVALS_MS = 1200
local PICKUP_AXIS_INDICATOR_DISTANCE_CM = 1000

local DEFAULT_PRECISION_MOVE_UNITS_CM = 10
local DEFAULT_PRECISION_ROTATE_UNITS_DEG = math.rad(15)

local PRECISION_UNIT_ADJUSTMENT_INCREMENT = 1
local PRECISION_UNIT_ADJUSTMENT_DECREMENT = 2

local TEXTURE_ARROW_DIRECTION = "EsoUI/Art/Housing/direction_arrow.dds"
local TEXTURE_ARROW_DIRECTION_INVERSE = "EsoUI/Art/Housing/direction_inverse_arrow.dds"
local TEXTURE_ARROW_ROTATION_FORWARD = "EsoUI/Art/Housing/dual_rotation_arrow.dds"
local TEXTURE_ARROW_ROTATION_REVERSE = "EsoUI/Art/Housing/dual_rotation_arrow_reverse.dds"
local TEXTURE_HOUSE_ICON = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuicon_home.dds"

local function AngleDistance(angle1, angle2)
    local delta = math.abs(angle1 - angle2) % TWO_PI
    return delta < PI and delta or (TWO_PI - delta)
end

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

    self.precisionMoveButtonContainer = control:GetNamedChild("PrecisionMoveButtonContainer")
    self.precisionMoveButtons = self.precisionMoveButtonContainer:GetNamedChild("PrecisionMoveButtons")
    self.precisionMoveUnitsLabel = self.precisionMoveButtonContainer:GetNamedChild("PrecisionMoveUnitsLabel")
    self.precisionPositionLabel = self.precisionMoveButtonContainer:GetNamedChild("PrecisionPositionLabel")

    self.precisionRotateButtonContainer = control:GetNamedChild("PrecisionRotateButtonContainer")
    self.precisionRotateButtons = self.precisionRotateButtonContainer:GetNamedChild("PrecisionRotateButtons")
    self.precisionRotateUnitsLabel = self.precisionRotateButtonContainer:GetNamedChild("PrecisionRotateUnitsLabel")
    self.precisionOrientationLabel = self.precisionRotateButtonContainer:GetNamedChild("PrecisionOrientationLabel")

    self:RefreshConstants()
    self:InitializeHudControls()
    self:InitializeMovementControllers()
    self:OnDeferredInitialization()

    HOUSING_EDITOR_HUD_SCENE = ZO_Scene:New("housingEditorHud", SCENE_MANAGER)
    HOUSING_EDITOR_HUD_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnDeferredInitialization()
            local currentMode = GetHousingEditorMode()
            if currentMode == HOUSING_EDITOR_MODE_BROWSE then -- If someone cancelled out of the browser without selecting anything.
                HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
            elseif currentMode == HOUSING_EDITOR_MODE_SELECTION then
                SCENE_MANAGER:AddFragment(ZO_HOUSING_EDITOR_HISTORY_FRAGMENT)
            end
            self:ClearPlacementKeyPresses()
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
            if GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_SELECTION then
                -- Add the HUD UI keybinds for any mode other than Selection.
                -- This is to prevent duplicate keybind registration that would result from Selection
                -- and UI mode both sharing the housing editor's tertiary action keybind.
                KEYBIND_STRIP:RemoveDefaultExit()
                KEYBIND_STRIP:AddKeybindButtonGroup(self.UIModeKeybindStripDescriptor)
                KEYBIND_STRIP:AddKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
                KEYBIND_STRIP:AddKeybindButtonGroup(self.exitKeybindButtonStripDescriptor)
            end
            self:UnregisterDragMouseAxis()
            self:RegisterAxisVisibilityUpdates()
            self:UpdateAxisIndicators()
        elseif newState == SCENE_HIDDEN then
            self:ClearPlacementKeyPresses()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.UIModeKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.exitKeybindButtonStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            self:UnregisterAxisVisibilityUpdates()
            self:UpdateAxisIndicators()
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
            HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED)   -- Turn off housing mode if gamepad mode changes while active.
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

    do
        local EPSILON_CM = 1
        local EPSILON_RAD = math.rad(1)
        local g_previousX, g_previousY, g_previousZ, g_previousPitch, g_previousYaw, g_previousRoll = 0, 0, 0, 0, 0, 0

        self.axisIndicatorUpdateHandler = function()
            if self.translationIndicators then
                local furnitureId = HousingEditorGetSelectedFurnitureId()
                if furnitureId then
                    local pitch, yaw, roll = HousingEditorGetFurnitureOrientation(furnitureId)
                    local centerX, centerY, centerZ = HousingEditorGetFurnitureWorldCenter(furnitureId)

                    if AngleDistance(pitch, g_previousPitch) > EPSILON_RAD or AngleDistance(yaw, g_previousYaw) > EPSILON_RAD or AngleDistance(roll, g_previousRoll) > EPSILON_RAD then
                        g_previousPitch, g_previousYaw, g_previousRoll = pitch, yaw, roll
                    else
                        pitch, yaw, roll = g_previousPitch, g_previousYaw, g_previousRoll
                    end

                    if math.abs(centerX - g_previousX) > EPSILON_CM or math.abs(centerY - g_previousY) > EPSILON_CM or math.abs(centerZ - g_previousZ) > EPSILON_CM then
                        g_previousX, g_previousY, g_previousZ = centerX, centerY, centerZ
                    else
                        centerX, centerY, centerZ = g_previousX, g_previousY, g_previousZ
                    end

                    -- Order here matters:
                    self:MoveAxisIndicators(centerX, centerY, centerZ, pitch, yaw, roll)
                    self.axisIndicatorWindow:SetHidden(false)
                end
            end
        end
    end

    control:SetHandler("OnUpdate", function(_, currentFrameTimeMS) self:OnUpdate(currentFrameTimeMS) end)
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

function ZO_HousingEditorHud:InitializePlacementSettings()
    HousingEditorSetPlacementType(HOUSING_EDITOR_PLACEMENT_TYPE_PICKUP)
    HousingEditorSetPrecisionMoveUnits(DEFAULT_PRECISION_MOVE_UNITS_CM)
    HousingEditorSetPrecisionRotateUnits(DEFAULT_PRECISION_ROTATE_UNITS_DEG)
end

function ZO_HousingEditorHud:InitializeMovementControllers()
    local function GetButtonDirection(axis)
        return self:GetButtonDirection(axis)
    end

    self.yawMovementController = ZO_MovementController:New(AXIS_TYPE_Y, self.numTickForRotationChange, GetButtonDirection)
    self.pitchMovementController = ZO_MovementController:New(AXIS_TYPE_X, self.numTickForRotationChange, GetButtonDirection)
    self.rollMovementController = ZO_MovementController:New(AXIS_TYPE_Z, self.numTickForRotationChange, GetButtonDirection)
    self.movementControllers = {self.yawMovementController, self.pitchMovementController, self.rollMovementController}
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
        HousingEditorSetPlacementType(HOUSING_EDITOR_PLACEMENT_TYPE_PICKUP)
        SYSTEMS:PushScene("housing_furniture_browser")
    elseif oldMode == HOUSING_EDITOR_MODE_BROWSE then -- If something external exited the housing mode hide everything.
        if SYSTEMS:IsShowing("housing_furniture_browser") then
            SCENE_MANAGER:HideCurrentScene()
        end
    end

    if oldMode == HOUSING_EDITOR_MODE_PLACEMENT then
        HousingEditorSetPlacementType(HOUSING_EDITOR_PLACEMENT_TYPE_PICKUP)
        self:ClearPlacementKeyPresses()
        self:UpdateAxisIndicators()
    end

    self:UpdateKeybinds()
end

function ZO_HousingEditorHud:OnDeferredInitialization()
    if self.initialized then
        return
    end
    self.initialized = true
    self:InitializePlacementSettings()
    self:InitializeAxisIndicators()
    self:InitializeKeybindDescriptors()
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
        local hideRotate = false
        local hidePrecisionRotate = true
        local hidePrecisionMove = true

        SCENE_MANAGER:AddFragment(HOUSING_EDITOR_HUD_PLACEMENT_MODE_ACTION_LAYER_FRAGMENT)

        if self:IsPrecisionEditingEnabled() then
            hideRotate = true
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullVisibleKeybindGroup)
            if self:IsPrecisionPlacementRotationMode() then
                hidePrecisionRotate = false
            else
                hidePrecisionMove = false
            end
        else
            if HousingEditorIsSurfaceDragModeEnabled() then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullVisibleKeybindGroup)
                KEYBIND_STRIP:AddKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
            else
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pushAndPullEtherealKeybindGroup)
                KEYBIND_STRIP:AddKeybindButtonGroup(self.pushAndPullVisibleKeybindGroup)
            end
        end

        self:UpdateMovementControllerUnits()
        self.buttonContainer:SetHidden(hideRotate)
        self.precisionRotateButtonContainer:SetHidden(hidePrecisionRotate)
        self.precisionMoveButtonContainer:SetHidden(hidePrecisionMove)
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

function ZO_HousingEditorHud:IsPrecisionEditingEnabled()
    return HousingEditorGetPlacementType() == HOUSING_EDITOR_PLACEMENT_TYPE_PRECISION
end

function ZO_HousingEditorHud:TogglePrecisionEditing()
    HousingEditorTogglePlacementType()
end

function ZO_HousingEditorHud:IsPrecisionPlacementMoveMode()
    return HousingEditorGetPrecisionPlacementMode() == HOUSING_EDITOR_PRECISION_PLACEMENT_MODE_MOVE
end

function ZO_HousingEditorHud:IsPrecisionPlacementRotationMode()
    return HousingEditorGetPrecisionPlacementMode() == HOUSING_EDITOR_PRECISION_PLACEMENT_MODE_ROTATE
end

function ZO_HousingEditorHud:TogglePrecisionPlacementMode()
    HousingEditorTogglePrecisionPlacementMode()
    self:ClearPlacementKeyPresses()
end

function ZO_HousingEditorHud:UpdateMovementControllerUnits()
    local accumulationCoefficient = self:IsPrecisionEditingEnabled() and 2 or 1
    local accumulationPerSecondForChange = accumulationCoefficient * self.numTickForRotationChange

    for _, controller in ipairs(self.movementControllers) do
        controller:SetAccumulationPerSecondForChange(accumulationPerSecondForChange)
    end
end

function ZO_HousingEditorHud:InitializeAxisIndicators()
    local indicatorName = "ZO_HousingEditorAxisIndicators"

    local window = WINDOW_MANAGER:CreateTopLevelWindow(indicatorName)
    self.axisIndicatorWindow = window
    window:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    window:SetMouseEnabled(false)
    window:Create3DRenderSpace()
    window:SetDrawLayer(DL_BACKGROUND)
    window:SetDrawTier(DT_LOW)
    window:SetHidden(true)

    self.cameraControlName = indicatorName .. "CameraControl"
    local cameraControl = WINDOW_MANAGER:CreateControl(self.cameraControlName, window, CT_TEXTURE)
    self.cameraControl = cameraControl
    cameraControl:SetMouseEnabled(false)
    cameraControl:Create3DRenderSpace()
    cameraControl:SetHidden(true)

    -- Array order matters here for visual control ordering.
    self.translationIndicators = {
        {axis = HOUSING_EDITOR_POSITION_AXIS_X1, pairedAxis = HOUSING_EDITOR_POSITION_AXIS_X2, sizeX = TRANSLATION_AXIS_INDICATOR_LOCAL_X_DIMENSION_M, sizeY = TRANSLATION_AXIS_INDICATOR_LOCAL_Y_DIMENSION_M, offsetX = -0.5, color = X_AXIS_NEGATIVE_INDICATOR_COLOR, inactiveAlpha = AXIS_INDICATOR_ALPHA_ACTIVE_PERCENTAGE, yaw = 0},
        {axis = HOUSING_EDITOR_POSITION_AXIS_X2, pairedAxis = HOUSING_EDITOR_POSITION_AXIS_X1, sizeX = TRANSLATION_AXIS_INDICATOR_LOCAL_X_DIMENSION_M, sizeY = TRANSLATION_AXIS_INDICATOR_LOCAL_Y_DIMENSION_M, offsetX =  0.5, color = X_AXIS_POSITIVE_INDICATOR_COLOR, texture = TEXTURE_ARROW_DIRECTION_INVERSE, inactiveAlpha = AXIS_INDICATOR_ALPHA_ACTIVE_PERCENTAGE, yaw = PI},
        {axis = HOUSING_EDITOR_POSITION_AXIS_Y1, pairedAxis = HOUSING_EDITOR_POSITION_AXIS_Y2, sizeX = TRANSLATION_AXIS_INDICATOR_LOCAL_Y_DIMENSION_M, sizeY = TRANSLATION_AXIS_INDICATOR_LOCAL_X_DIMENSION_M, offsetY = -0.5, color = Y_AXIS_NEGATIVE_INDICATOR_COLOR, texture = TEXTURE_ARROW_DIRECTION_INVERSE, inactiveAlpha = AXIS_INDICATOR_ALPHA_ACTIVE_PERCENTAGE, rotation = HALF_PI},
        {axis = HOUSING_EDITOR_POSITION_AXIS_Y2, pairedAxis = HOUSING_EDITOR_POSITION_AXIS_Y1, sizeX = TRANSLATION_AXIS_INDICATOR_LOCAL_Y_DIMENSION_M, sizeY = TRANSLATION_AXIS_INDICATOR_LOCAL_X_DIMENSION_M, offsetY =  0.5, color = Y_AXIS_POSITIVE_INDICATOR_COLOR, inactiveAlpha = AXIS_INDICATOR_ALPHA_ACTIVE_PERCENTAGE, rotation = -HALF_PI},
        {axis = HOUSING_EDITOR_POSITION_AXIS_Z1, pairedAxis = HOUSING_EDITOR_POSITION_AXIS_Z2, sizeX = TRANSLATION_AXIS_INDICATOR_LOCAL_X_DIMENSION_M, sizeY = TRANSLATION_AXIS_INDICATOR_LOCAL_Y_DIMENSION_M, offsetZ = -0.5, color = Z_AXIS_NEGATIVE_INDICATOR_COLOR, inactiveAlpha = AXIS_INDICATOR_ALPHA_ACTIVE_PERCENTAGE, yaw = -HALF_PI},
        {axis = HOUSING_EDITOR_POSITION_AXIS_Z2, pairedAxis = HOUSING_EDITOR_POSITION_AXIS_Z1, sizeX = TRANSLATION_AXIS_INDICATOR_LOCAL_X_DIMENSION_M, sizeY = TRANSLATION_AXIS_INDICATOR_LOCAL_Y_DIMENSION_M, offsetZ =  0.5, color = Z_AXIS_POSITIVE_INDICATOR_COLOR, texture = TEXTURE_ARROW_DIRECTION_INVERSE, inactiveAlpha = AXIS_INDICATOR_ALPHA_ACTIVE_PERCENTAGE, yaw = HALF_PI},
    }
    self.rotationIndicators = {
        {axis = HOUSING_EDITOR_ROTATION_AXIS_X1, sizeX = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, sizeY = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, inactiveAlpha = AXIS_INDICATOR_ALPHA_ACTIVE_PERCENTAGE,   scale = 1.0, color = X_AXIS_NEGATIVE_INDICATOR_COLOR, texture = TEXTURE_ARROW_ROTATION_FORWARD, pitch = HALF_PI, yaw = -HALF_PI},
        {axis = HOUSING_EDITOR_ROTATION_AXIS_X2, sizeX = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, sizeY = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, inactiveAlpha = AXIS_INDICATOR_ALPHA_INACTIVE_PERCENTAGE, scale = 1.0, color = X_AXIS_POSITIVE_INDICATOR_COLOR, texture = TEXTURE_ARROW_ROTATION_REVERSE, pitch = HALF_PI, yaw =  HALF_PI},
        {axis = HOUSING_EDITOR_ROTATION_AXIS_Y1, sizeX = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, sizeY = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, inactiveAlpha = AXIS_INDICATOR_ALPHA_ACTIVE_PERCENTAGE,   scale = 0.75, color = Y_AXIS_NEGATIVE_INDICATOR_COLOR, texture = TEXTURE_ARROW_ROTATION_FORWARD, yaw = 0},
        {axis = HOUSING_EDITOR_ROTATION_AXIS_Y2, sizeX = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, sizeY = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, inactiveAlpha = AXIS_INDICATOR_ALPHA_INACTIVE_PERCENTAGE, scale = 0.75, color = Y_AXIS_POSITIVE_INDICATOR_COLOR, texture = TEXTURE_ARROW_ROTATION_REVERSE, roll = PI, yaw = 0},
        {axis = HOUSING_EDITOR_ROTATION_AXIS_Z1, sizeX = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, sizeY = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, inactiveAlpha = AXIS_INDICATOR_ALPHA_ACTIVE_PERCENTAGE,   scale = 0.5, color = Z_AXIS_NEGATIVE_INDICATOR_COLOR, texture = TEXTURE_ARROW_ROTATION_FORWARD, yaw =  HALF_PI},
        {axis = HOUSING_EDITOR_ROTATION_AXIS_Z2, sizeX = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, sizeY = ROTATION_AXIS_INDICATOR_LOCAL_DIMENSIONS_M, inactiveAlpha = AXIS_INDICATOR_ALPHA_INACTIVE_PERCENTAGE, scale = 0.5, color = Z_AXIS_POSITIVE_INDICATOR_COLOR, texture = TEXTURE_ARROW_ROTATION_REVERSE, yaw = -HALF_PI, roll = PI},
    }

    self.allAxisIndicators = {}
    local axisIndicators = {}
    for _, indicator in ipairs(self.translationIndicators) do
        table.insert(axisIndicators, indicator)
    end
    for _, indicator in ipairs(self.rotationIndicators) do
        table.insert(axisIndicators, indicator)
    end

    local function OnMouseEnter(...)
        self:OnMouseEnterAxis(...)
    end
    local function OnMouseExit(...)
        self:OnMouseExitAxis(...)
    end
    local function OnMouseDown(...)
        self:OnMouseDownAxis(...)
    end

    for _, indicator in ipairs(axisIndicators) do
        local control = WINDOW_MANAGER:CreateControl(indicatorName .. indicator.axis, window, CT_TEXTURE)
        indicator.control = control
        self.allAxisIndicators[indicator.axis] = indicator
        control.axis = indicator
        control:SetAddressMode(TEX_MODE_CLAMP)
        control:SetAnchor(CENTER, window, CENTER, 0, 0)
        control:SetBlendMode(TEX_BLEND_MODE_ALPHA)
        control:SetColor(indicator.color:UnpackRGBA())
        control:SetTexture(indicator.texture or TEXTURE_ARROW_DIRECTION)
        control:SetTextureReleaseOption(RELEASE_TEXTURE_AT_ZERO_REFERENCES)
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 1)
        self:RotateAndScaleAxisIndicator(indicator.control, indicator.rotation or 0)

        local scale = indicator.scale or 1
        local width = scale * indicator.sizeX
        local height = scale * indicator.sizeY
        local offsetX, offsetY, offsetZ = indicator.offsetX or 0, indicator.offsetY or 0, indicator.offsetZ or 0
        control:Create3DRenderSpace()
        control:Set3DLocalDimensions(width, height)
        control:Set3DRenderSpaceOrigin(width * offsetX, height * offsetY, width * offsetZ)
        control:Set3DRenderSpaceOrientation(indicator.pitch or 0, indicator.yaw or 0, indicator.roll or 0)
        control:SetMouseEnabled(true)
        control:SetHandler("OnMouseEnter", OnMouseEnter)
        control:SetHandler("OnMouseExit", OnMouseExit)
        control:SetHandler("OnMouseDown", OnMouseDown)
    end
end

function ZO_HousingEditorHud:RegisterAxisVisibilityUpdates()
    if GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT then
        EVENT_MANAGER:RegisterForUpdate("ZO_HousingEditorHud_OnUpdateAxisVisibility", 1, function() self:OnUpdateAxisVisibility() end)
    end
end

function ZO_HousingEditorHud:UnregisterAxisVisibilityUpdates()
    EVENT_MANAGER:UnregisterForUpdate("ZO_HousingEditorHud_OnUpdateAxisVisibility")
end

function ZO_HousingEditorHud:OnUpdateAxisVisibility()
    if GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_PLACEMENT or not self:IsPrecisionEditingEnabled() or not self:IsPrecisionPlacementMoveMode() then
        self:UnregisterAxisVisibilityUpdates()
        return
    end

    if self.focusAxis then
        return
    end

    local furnitureId = HousingEditorGetSelectedFurnitureId()
    local _, yaw = HousingEditorGetFurnitureOrientation(furnitureId)
    local cameraX, cameraY, cameraZ, originX, originY, originZ = self:GetCameraAndAxisIndicatorOrigins()
    local relativeX, relativeZ = ZO_Rotate2D(yaw, cameraX - originX, cameraZ - originZ)
    local horizontalAngle = math.atan2(relativeX, relativeZ)
    local deltaY = cameraY - originY
    local axes = self.translationIndicators

    axes[1].control:SetHidden(horizontalAngle >= 0)
    axes[2].control:SetHidden(horizontalAngle < 0)
    axes[3].control:SetHidden(deltaY >= 0)
    axes[4].control:SetHidden(deltaY < 0)
    axes[5].control:SetHidden(math.abs(horizontalAngle) <= HALF_PI)
    axes[6].control:SetHidden(math.abs(horizontalAngle) > HALF_PI)
end

function ZO_HousingEditorHud:OnMouseEnterAxis(control, ...)
    if not self.focusAxis then
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, AXIS_INDICATOR_RGB_WEIGHT_MAX_PERCENTAGE)
    end
end

function ZO_HousingEditorHud:OnMouseExitAxis(control, ...)
    if not self.focusAxis then
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, AXIS_INDICATOR_RGB_WEIGHT_MIN_PERCENTAGE)
    end
end

function ZO_HousingEditorHud:OnMouseDownAxis(control, mouseButton)
    if mouseButton == MOUSE_BUTTON_INDEX_LEFT then
        local mouseX, mouseY = GetUIMousePosition()
        self:RegisterDragMouseAxis(control.axis, mouseX, mouseY)
    end
end

do
    local function GetVisibleTranslationRange(originX, originY, originZ, horizontalAngleRadians)
        -- Offset horizontally or vertically based on the optional horizontalAngleRadians parameter.
        local worldOffsetX, worldOffsetY, worldOffsetZ = 0, 0, 0
        if horizontalAngleRadians then
            worldOffsetX = math.sin(horizontalAngleRadians) * TRANSLATION_AXIS_RANGE_MAX_CM
            worldOffsetZ = math.cos(horizontalAngleRadians) * TRANSLATION_AXIS_RANGE_MAX_CM
        else
            worldOffsetY = -TRANSLATION_AXIS_RANGE_MAX_CM
        end

        -- Clip the translation range's end points at the camera view frustum bounds.
        local worldX1 = originX - 0.5 * worldOffsetX
        local worldY1 = originY - 0.5 * worldOffsetY
        local worldZ1 = originZ - 0.5 * worldOffsetZ
        local worldX2 = originX + 0.5 * worldOffsetX
        local worldY2 = originY + 0.5 * worldOffsetY
        local worldZ2 = originZ + 0.5 * worldOffsetZ
        local clippedX1, clippedY1, clippedZ1, clippedX2, clippedY2, clippedZ2 = HousingEditorClipLineSegmentToViewFrustum(worldX1, worldY1, worldZ1, worldX2, worldY2, worldZ2)

        -- Calculate the normalized base offset of the initial furniture position.
        local translationDistance = zo_distance3D(clippedX1, clippedY1, clippedZ1, clippedX2, clippedY2, clippedZ2)
        local originOffset = zo_distance3D(clippedX1, clippedY1, clippedZ1, originX, originY, originZ)
        local normalizedOffset = originOffset / translationDistance

        local translationRange =
        {
            minX = clippedX1,
            minY = clippedY1,
            minZ = clippedZ1,
            maxX = clippedX2,
            maxY = clippedY2,
            maxZ = clippedZ2,
            deltaX = clippedX2 - clippedX1,
            deltaY = clippedY2 - clippedY1,
            deltaZ = clippedZ2 - clippedZ1,
            baseOffset = normalizedOffset,
        }
        return translationRange
    end

    function ZO_HousingEditorHud:RegisterDragMouseAxis(axis, mouseX, mouseY)
        local selectedFurnitureId = HousingEditorGetSelectedFurnitureId()
        if selectedFurnitureId and not self.focusAxis then
            local cameraX, cameraY, cameraZ, originX, originY, originZ = self:GetCameraAndAxisIndicatorOrigins()
            self.focusAngle = math.atan2(cameraX - originX, cameraZ - originZ)
            self.focusAxis = axis
            self.focusOffset = 0
            self.focusOriginX = mouseX
            self.focusOriginY = mouseY
            self.focusInitialX, self.focusInitialY, self.focusInitialZ = HousingEditorGetFurnitureWorldPosition(selectedFurnitureId)
            self.focusInitialPitch, self.focusInitialYaw, self.focusInitialRoll = HousingEditorGetFurnitureOrientation(selectedFurnitureId)

            for _, indicator in pairs(self.allAxisIndicators) do
                local isActiveAxis = indicator.axis == self.focusAxis.axis or indicator.axis == self.focusAxis.pairedAxis
                if isActiveAxis then
                    indicator.control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, AXIS_INDICATOR_RGB_WEIGHT_MAX_PERCENTAGE)
                end
                indicator.control:SetHidden(not isActiveAxis)
            end

            if self.focusAxis.axis == HOUSING_EDITOR_POSITION_AXIS_X1 or self.focusAxis.axis == HOUSING_EDITOR_POSITION_AXIS_X2 then
                self.focusRangeAxis = GetVisibleTranslationRange(self.focusInitialX, self.focusInitialY, self.focusInitialZ, self.focusInitialYaw + HALF_PI)
            elseif self.focusAxis.axis == HOUSING_EDITOR_POSITION_AXIS_Y1 or self.focusAxis.axis == HOUSING_EDITOR_POSITION_AXIS_Y2 then
                self.focusRangeAxis = GetVisibleTranslationRange(self.focusInitialX, self.focusInitialY, self.focusInitialZ)
            elseif self.focusAxis.axis == HOUSING_EDITOR_POSITION_AXIS_Z1 or self.focusAxis.axis == HOUSING_EDITOR_POSITION_AXIS_Z2 then
                self.focusRangeAxis = GetVisibleTranslationRange(self.focusInitialX, self.focusInitialY, self.focusInitialZ, self.focusInitialYaw)
            end

            EVENT_MANAGER:RegisterForUpdate("ZO_HousingEditorHud_DragMouseAxis", 1, function() self:OnDragMouseAxis() end)
            EVENT_MANAGER:RegisterForEvent("ZO_HousingEditorHud_OnMouseUp", EVENT_GLOBAL_MOUSE_UP, function() self:UnregisterDragMouseAxis() end)
        end
    end
end

function ZO_HousingEditorHud:UnregisterDragMouseAxis()
    if self.focusAxis then
        EVENT_MANAGER:UnregisterForUpdate("ZO_HousingEditorHud_DragMouseAxis")
        EVENT_MANAGER:UnregisterForEvent("ZO_HousingEditorHud_OnMouseUp", EVENT_GLOBAL_MOUSE_UP)

        self.focusAxis.control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, AXIS_INDICATOR_RGB_WEIGHT_MIN_PERCENTAGE)
        self.focusOffset, self.focusAxis, self.focusOriginX, self.focusOriginY = nil, nil, nil, nil
        self.focusInitialX, self.focusInitialY, self.focusInitialZ = nil, nil, nil
        self.focusInitialPitch, self.focusInitialYaw, self.focusInitialRoll = nil, nil, nil
        self.focusRangeAxis = nil
        self:UpdateAxisIndicators()
    end
end

function ZO_HousingEditorHud:OnDragMouseAxis()
    local selectedFurnitureId = HousingEditorGetSelectedFurnitureId()
    local axis = self.focusAxis
    if not selectedFurnitureId or not axis or not IsGameCameraUIModeActive() then
        self:UnregisterDragMouseAxis()
        return
    end

    local screenX, screenY = GuiRoot:GetDimensions()
    local mouseX, mouseY = GetUIMousePosition()
    local normalizedMouseX, normalizedMouseY = mouseX / screenX, mouseY / screenY
    local normalizedMouseOriginX, normalizedMouseOriginY = self.focusOriginX / screenX, self.focusOriginY / screenY
    local normalizedOffsetX = normalizedMouseX - normalizedMouseOriginX
    local normalizedOffsetY = normalizedMouseY - normalizedMouseOriginY
    local axisType = axis.axis

    if axisType >= HOUSING_EDITOR_POSITION_AXIS_X1 and axisType <= HOUSING_EDITOR_POSITION_AXIS_Z2 then
        self:OnDragMousePosition(normalizedOffsetX, normalizedOffsetY)
        return
    end

    if axisType >= HOUSING_EDITOR_ROTATION_AXIS_X1 and axisType <= HOUSING_EDITOR_ROTATION_AXIS_Z2 then
        local cameraX, cameraY, cameraZ = self:GetCameraOrigin()
        self:OnDragMouseRotation(cameraX, cameraY, cameraZ, normalizedOffsetX, normalizedOffsetY)
        return
    end
end

do
    local function InterpolateTranslationRange(translationRange, progress)
        local x = translationRange.minX + translationRange.deltaX * progress
        local y = translationRange.minY + translationRange.deltaY * progress
        local z = translationRange.minZ + translationRange.deltaZ * progress
        return x, y, z
    end

    function ZO_HousingEditorHud:OnDragMousePosition(normalizedOffsetX, normalizedOffsetY)
        local axisType = self.focusAxis.axis
        local translationRange = self.focusRangeAxis
        local normalizedOffset

        if axisType == HOUSING_EDITOR_POSITION_AXIS_X1 or axisType == HOUSING_EDITOR_POSITION_AXIS_X2 then
            local viewAngle = (GetPlayerCameraHeading() - self.focusInitialYaw) % TWO_PI
            local baseOffset = translationRange.baseOffset
            if viewAngle > HALF_PI and viewAngle < (HALF_PI + PI) then
                normalizedOffset = baseOffset - normalizedOffsetX
            else
                normalizedOffset = baseOffset + normalizedOffsetX
            end
        elseif axisType == HOUSING_EDITOR_POSITION_AXIS_Z1 or axisType == HOUSING_EDITOR_POSITION_AXIS_Z2 then
            local viewAngle = (GetPlayerCameraHeading() - self.focusInitialYaw + HALF_PI) % TWO_PI
            local baseOffset = translationRange.baseOffset
            if viewAngle > HALF_PI and viewAngle < (HALF_PI + PI) then
                normalizedOffset = baseOffset - normalizedOffsetX
            else
                normalizedOffset = baseOffset + normalizedOffsetX
            end
        elseif axisType == HOUSING_EDITOR_POSITION_AXIS_Y1 or axisType == HOUSING_EDITOR_POSITION_AXIS_Y2 then
            normalizedOffset = translationRange.baseOffset + normalizedOffsetY
        end

        if translationRange then
            local x, y, z = InterpolateTranslationRange(translationRange, zo_clamp(normalizedOffset, 0, 1))
            local result = HousingEditorAdjustPrecisionEditingPosition(x, y, z)
            ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
            self.axisIndicatorUpdateHandler()
        end
    end
end

function ZO_HousingEditorHud:OnDragMouseRotation(cameraX, cameraY, cameraZ, normalizedOffsetX, normalizedOffsetY)
    local axis = self.focusAxis
    local axisType = axis.axis
    local normalizedOffsetRadians = normalizedOffsetX * 2 * TWO_PI
    local axisIndicatorAngleRadians = normalizedOffsetRadians
    local indicatorX, indicatorY, indicatorZ = self:GetAxisIndicatorOrigin()
    local currentX, currentY, currentZ = HousingEditorGetFurnitureWorldPosition(HousingEditorGetSelectedFurnitureId())
    local relativeX, relativeY, relativeZ = cameraX - indicatorX, cameraY - indicatorY, cameraZ - indicatorZ
    local offsetAxis

    if axisType == HOUSING_EDITOR_ROTATION_AXIS_X1 or axisType == HOUSING_EDITOR_ROTATION_AXIS_X2 then
        offsetAxis = AXIS_TYPE_Y
    elseif axisType == HOUSING_EDITOR_ROTATION_AXIS_Y1 or axisType == HOUSING_EDITOR_ROTATION_AXIS_Y2 then
        offsetAxis = AXIS_TYPE_Z
    elseif axisType == HOUSING_EDITOR_ROTATION_AXIS_Z1 or axisType == HOUSING_EDITOR_ROTATION_AXIS_Z2 then
        offsetAxis = AXIS_TYPE_X
    end

    -- Update the rotation offset and/or axis indicator values to match the focused axis.
    if self:IsPrecisionEditingEnabled() then
        if offsetAxis == AXIS_TYPE_X then
            if relativeX > 0 then
                normalizedOffsetRadians, axisIndicatorAngleRadians = -normalizedOffsetRadians, -axisIndicatorAngleRadians
            end
        elseif offsetAxis == AXIS_TYPE_Y then
            normalizedOffsetRadians = -normalizedOffsetRadians
        elseif offsetAxis == AXIS_TYPE_Z then
            if relativeZ > 0 then
                normalizedOffsetRadians, axisIndicatorAngleRadians = -normalizedOffsetRadians, -axisIndicatorAngleRadians
            end
        end
    else
        if offsetAxis == AXIS_TYPE_X then
            normalizedOffsetRadians, axisIndicatorAngleRadians = -normalizedOffsetRadians, -axisIndicatorAngleRadians
        elseif offsetAxis == AXIS_TYPE_Y then
            normalizedOffsetRadians = -normalizedOffsetRadians
        elseif offsetAxis == AXIS_TYPE_Z then
            normalizedOffsetRadians, axisIndicatorAngleRadians = -normalizedOffsetRadians, -axisIndicatorAngleRadians
        end
    end

    if normalizedOffsetRadians then
        if self:IsPrecisionEditingEnabled() then
            HousingEditorAdjustPendingFurnitureRotation(HousingEditorCalculateRotationAboutAxis(offsetAxis, normalizedOffsetRadians, self.focusInitialPitch, self.focusInitialYaw, self.focusInitialRoll))
            self:RotateAndScaleAxisIndicator(axis.control, axisIndicatorAngleRadians)
        else
            local pitch, yaw, roll = 0, 0, 0
            local previousOffset = -(self.focusOffset or 0)

            self.focusOffset = normalizedOffsetRadians
            if offsetAxis == AXIS_TYPE_X then
                pitch = normalizedOffsetRadians + previousOffset
            elseif offsetAxis == AXIS_TYPE_Y then
                yaw = normalizedOffsetRadians + previousOffset
            else
                roll = normalizedOffsetRadians + previousOffset
            end

            HousingEditorAdjustPendingFurnitureRotation(pitch, yaw, roll)
            self:RotateAndScaleAxisIndicator(axis.control, axisIndicatorAngleRadians)
        end
    end
end

-- Sets the vertex UV coordinates for an axis indicator by the specified rotation angle (theta).
function ZO_HousingEditorHud:RotateAndScaleAxisIndicator(control, theta)
    local topLeftX, topLeftY = ZO_Rotate2D(theta, -0.5, -0.5)
    local topRightX, topRightY = ZO_Rotate2D(theta,  0.5, -0.5)
    local bottomLeftX, bottomLeftY = ZO_Rotate2D(theta, -0.5,  0.5)
    local bottomRightX, bottomRightY = ZO_Rotate2D(theta,  0.5,  0.5)

	control:SetVertexUV(VERTEX_POINTS_TOPLEFT, 0.5 + topLeftX, 0.5 + topLeftY)
	control:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 0.5 + topRightX, 0.5 + topRightY)
	control:SetVertexUV(VERTEX_POINTS_BOTTOMLEFT, 0.5 + bottomLeftX, 0.5 + bottomLeftY)
	control:SetVertexUV(VERTEX_POINTS_BOTTOMRIGHT, 0.5 + bottomRightX, 0.5 + bottomRightY)
end

function ZO_HousingEditorHud:GetCameraOrigin()
    Set3DRenderSpaceToCurrentCamera(self.cameraControlName)
    return GuiRender3DPositionToWorldPosition(self.cameraControl:Get3DRenderSpaceOrigin())
end

function ZO_HousingEditorHud:GetAxisIndicatorOrigin()
    return GuiRender3DPositionToWorldPosition(self.axisIndicatorWindow:Get3DRenderSpaceOrigin())
end

function ZO_HousingEditorHud:GetAxisIndicatorOrientation()
    return self.axisIndicatorWindow:Get3DRenderSpaceOrientation()
end

function ZO_HousingEditorHud:GetCameraAndAxisIndicatorOrigins()
    local cameraX, cameraY, cameraZ = self:GetCameraOrigin()
    local originX, originY, originZ = self:GetAxisIndicatorOrigin()
    return cameraX, cameraY, cameraZ, originX, originY, originZ
end

function ZO_HousingEditorHud:GetCameraForwardVector()
    Set3DRenderSpaceToCurrentCamera(self.cameraControlName)
    local forwardX, forwardY, forwardZ = self.cameraControl:Get3DRenderSpaceForward()
    return forwardX, forwardY, forwardZ
end

function ZO_HousingEditorHud:CalculateDynamicAxisIndicatorScale(cameraX, cameraY, cameraZ, worldX, worldY, worldZ)
    local screenX, screenY = GuiRoot:GetDimensions()
    local distance = zo_distance3D(cameraX, cameraY, cameraZ, worldX, worldY, worldZ)
    local worldWidth, worldHeight = GetWorldDimensionsOfViewFrustumAtDepth(distance)
    local frustumScaleX, frustumScaleY = worldWidth / screenX, worldHeight / screenY
    local scaleX, scaleY = 1, 1

    if frustumScaleX < AXIS_INDICATOR_SCALE_MIN then
        scaleX = frustumScaleX / AXIS_INDICATOR_SCALE_MIN
    elseif frustumScaleX > AXIS_INDICATOR_SCALE_MAX then
        scaleX = frustumScaleX / AXIS_INDICATOR_SCALE_MAX
    end

    if frustumScaleY < AXIS_INDICATOR_SCALE_MIN then
        scaleY = frustumScaleY / AXIS_INDICATOR_SCALE_MIN
    elseif frustumScaleY > AXIS_INDICATOR_SCALE_MAX then
        scaleY = frustumScaleY / AXIS_INDICATOR_SCALE_MAX
    end

    return scaleX, scaleY
end

function ZO_HousingEditorHud:MoveAxisIndicators(worldX, worldY, worldZ, pitch, yaw, roll)
    local cameraX, cameraY, cameraZ = self:GetCameraOrigin()
    local axisIndicators, renderX, renderY, renderZ, renderYaw, scaleX, scaleY

    if self:IsPrecisionEditingEnabled() and self:IsPrecisionPlacementMoveMode() then
        axisIndicators = self.translationIndicators
    else
        axisIndicators = self.rotationIndicators
    end

    if self:IsPrecisionEditingEnabled() then
        renderX, renderY, renderZ = WorldPositionToGuiRender3DPosition(worldX, worldY, worldZ)
        if self:IsPrecisionPlacementRotationMode() then
            renderYaw = 0
        else
            renderYaw = yaw
        end
        scaleX, scaleY = self:CalculateDynamicAxisIndicatorScale(cameraX, cameraY, cameraZ, worldX, worldY, worldZ)
    else
        local distance = PICKUP_AXIS_INDICATOR_DISTANCE_CM
        local forwardX, forwardY, forwardZ = self:GetCameraForwardVector()
        local reticleX, reticleY, reticleZ = cameraX + forwardX * distance, cameraY + forwardY * distance, cameraZ + forwardZ * distance

        renderX, renderY, renderZ = WorldPositionToGuiRender3DPosition(reticleX, reticleY, reticleZ)
        renderYaw = GetPlayerCameraHeading()
        scaleX, scaleY = 1, 1
    end

    for index, axis in ipairs(axisIndicators) do
        local scaledX, scaledY = axis.sizeX * (axis.scale or 1) * scaleX, axis.sizeY * (axis.scale or 1) * scaleY
        axis.control:Set3DLocalDimensions(scaledX, scaledY)
        axis.control:Set3DRenderSpaceOrigin(scaledX * (axis.offsetX or 0), scaledY * (axis.offsetY or 0), scaledX * (axis.offsetZ or 0))
    end

    local cameraHeading = GetPlayerCameraHeading()
    local horizontalAngle = (renderYaw - cameraHeading) % HALF_PI
    if horizontalAngle < QUARTER_PI then
        renderYaw = renderYaw + AXIS_INDICATOR_VISIBILITY_YAW_OFFSET_ANGLE
    else
        renderYaw = renderYaw - AXIS_INDICATOR_VISIBILITY_YAW_OFFSET_ANGLE
    end

    self.axisIndicatorWindow:Set3DRenderSpaceOrigin(renderX, renderY, renderZ)
    self.axisIndicatorWindow:Set3DRenderSpaceOrientation(0, renderYaw, 0)
end

function ZO_HousingEditorHud:UpdateAxisIndicators()
    if self.translationIndicators and self.rotationIndicators then
        local isPlacementMode = GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT
        local isPrecisionMode = self:IsPrecisionEditingEnabled()
        local isUIMode = IsGameCameraUIModeActive()

        if not isPlacementMode then
            EVENT_MANAGER:UnregisterForUpdate("HousingEditor_AxisIndicators")
            self.axisIndicatorWindow:SetHidden(true)
        else
            local hideTranslation = self:IsPrecisionPlacementRotationMode() or not isPrecisionMode
            local hideRotation = not hideTranslation

            if not hideTranslation then
                local cameraX, cameraY, cameraZ, originX, originY, originZ = self:GetCameraAndAxisIndicatorOrigins()
                local relativeX, relativeY, relativeZ = cameraX - originX, cameraY - originY, cameraZ - originZ
                local horizontalAngle = math.atan2(relativeX, relativeZ)
                local relativeXZ = math.sqrt(relativeX * relativeX + relativeZ * relativeZ)
                local verticalAngle = math.atan2(relativeY, relativeXZ)
                local _, indicatorYaw, _ = self:GetAxisIndicatorOrientation()
                local verticalIndicatorYaw = horizontalAngle - indicatorYaw

                -- Pitch the X- and Z-axis indicators to lay flat when significantly above or below the player.
                local pitch = zo_clamp(2 * verticalAngle, -HALF_PI, HALF_PI)
                pitch = math.abs(pitch) < QUARTER_PI and 0 or HALF_PI

                self.translationIndicators[1].control:Set3DRenderSpaceOrientation(pitch, self.translationIndicators[1].yaw, 0)
                self.translationIndicators[2].control:Set3DRenderSpaceOrientation(-pitch, self.translationIndicators[2].yaw, 0)
                self.translationIndicators[3].control:Set3DRenderSpaceOrientation(0, verticalIndicatorYaw, 0)
                self.translationIndicators[4].control:Set3DRenderSpaceOrientation(0, verticalIndicatorYaw, 0)
                self.translationIndicators[5].control:Set3DRenderSpaceOrientation(pitch, self.translationIndicators[5].yaw, 0)
                self.translationIndicators[6].control:Set3DRenderSpaceOrientation(-pitch, self.translationIndicators[6].yaw, 0)
            end

            for _, indicator in ipairs(self.translationIndicators) do
                local alpha = indicator.control:GetAlpha()
                indicator.control:SetHidden(hideTranslation or alpha <= 0)
            end

            for _, indicator in ipairs(self.rotationIndicators) do
                local alpha = indicator.control:GetAlpha()
                indicator.control:SetHidden(hideRotation or alpha <= 0)
            end

            EVENT_MANAGER:RegisterForUpdate("HousingEditor_AxisIndicators", 1, self.axisIndicatorUpdateHandler)
        end
    end
end

function ZO_HousingEditorHud:InitializeHudControls()
    do
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
    
        self.pickupRotateHudButtons =
        {
            yawLeftButton,
            yawRightButton,
            pitchForwardButton,
            pitchBackButton,
            rollLeftButton,
            rollRightButton,
        }

        for _, button in ipairs(self.pickupRotateHudButtons) do
            button.precisionMode = false
        end
    end

    do
        local moveLeftButton = self.precisionMoveButtons:GetNamedChild("PrecisionMoveLeftButton")
        moveLeftButton.backdrop = moveLeftButton:GetNamedChild("Backdrop")
        moveLeftButton.icon = moveLeftButton:GetNamedChild("Icon")
        moveLeftButton.icon:SetTextureCoordsRotation(0)
        ZO_Keybindings_RegisterLabelForBindingUpdate(moveLeftButton:GetNamedChild("Text"), "HOUSING_EDITOR_YAW_LEFT")

        local moveRightButton = self.precisionMoveButtons:GetNamedChild("PrecisionMoveRightButton")
        moveRightButton.backdrop = moveRightButton:GetNamedChild("Backdrop")
        moveRightButton.icon = moveRightButton:GetNamedChild("Icon")
        moveRightButton.icon:SetTextureCoordsRotation(PI)
        ZO_Keybindings_RegisterLabelForBindingUpdate(moveRightButton:GetNamedChild("Text"), "HOUSING_EDITOR_YAW_RIGHT")

        local moveForwardButton = self.precisionMoveButtons:GetNamedChild("PrecisionMoveForwardButton")
        moveForwardButton.backdrop = moveForwardButton:GetNamedChild("Backdrop")
        moveForwardButton.icon = moveForwardButton:GetNamedChild("Icon")
        moveForwardButton.icon:SetTextureCoordsRotation(0)
        ZO_Keybindings_RegisterLabelForBindingUpdate(moveForwardButton:GetNamedChild("Text"), "HOUSING_EDITOR_PITCH_FORWARD")

        local moveBackButton = self.precisionMoveButtons:GetNamedChild("PrecisionMoveBackButton")
        moveBackButton.backdrop = moveBackButton:GetNamedChild("Backdrop")
        moveBackButton.icon = moveBackButton:GetNamedChild("Icon")
        moveBackButton.icon:SetTextureCoordsRotation(PI)
        ZO_Keybindings_RegisterLabelForBindingUpdate(moveBackButton:GetNamedChild("Text"), "HOUSING_EDITOR_PITCH_BACKWARD")

        local moveUpButton = self.precisionMoveButtons:GetNamedChild("PrecisionMoveUpButton")
        moveUpButton.backdrop = moveUpButton:GetNamedChild("Backdrop")
        moveUpButton.icon = moveUpButton:GetNamedChild("Icon")
        moveUpButton.icon:SetTextureCoordsRotation(HALF_PI)
        ZO_Keybindings_RegisterLabelForBindingUpdate(moveUpButton:GetNamedChild("Text"), "HOUSING_EDITOR_ROLL_RIGHT")

        local moveDownButton = self.precisionMoveButtons:GetNamedChild("PrecisionMoveDownButton")
        moveDownButton.backdrop = moveDownButton:GetNamedChild("Backdrop")
        moveDownButton.icon = moveDownButton:GetNamedChild("Icon")
        moveDownButton.icon:SetTextureCoordsRotation(-HALF_PI)
        ZO_Keybindings_RegisterLabelForBindingUpdate(moveDownButton:GetNamedChild("Text"), "HOUSING_EDITOR_ROLL_LEFT")

        self.precisionMoveHudButtons =
        {
            moveLeftButton,
            moveRightButton,
            moveForwardButton,
            moveBackButton,
            moveDownButton,
            moveUpButton,
        }

        for _, button in ipairs(self.precisionMoveHudButtons) do
            button.precisionMode = true
        end
    end

    do
        local rotateYawLeftButton = self.precisionRotateButtons:GetNamedChild("PrecisionYawLeftButton")
        rotateYawLeftButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_yawCW.dds")
        ZO_Keybindings_RegisterLabelForBindingUpdate(rotateYawLeftButton:GetNamedChild("Text"), "HOUSING_EDITOR_YAW_LEFT")

        local rotateYawRightButton = self.precisionRotateButtons:GetNamedChild("PrecisionYawRightButton")
        rotateYawRightButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_yawCCW.dds")
        ZO_Keybindings_RegisterLabelForBindingUpdate(rotateYawRightButton:GetNamedChild("Text"), "HOUSING_EDITOR_YAW_RIGHT")

        local rotatePitchForwardButton = self.precisionRotateButtons:GetNamedChild("PrecisionPitchForwardButton")
        rotatePitchForwardButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_pitchCCW.dds")
        ZO_Keybindings_RegisterLabelForBindingUpdate(rotatePitchForwardButton:GetNamedChild("Text"), "HOUSING_EDITOR_PITCH_FORWARD")

        local rotatePitchBackButton = self.precisionRotateButtons:GetNamedChild("PrecisionPitchBackButton")
        rotatePitchBackButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_pitchCW.dds")
        ZO_Keybindings_RegisterLabelForBindingUpdate(rotatePitchBackButton:GetNamedChild("Text"), "HOUSING_EDITOR_PITCH_BACKWARD")

        local rotateRollLeftButton = self.precisionRotateButtons:GetNamedChild("PrecisionRollLeftButton")
        rotateRollLeftButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_rollCCW.dds")
        ZO_Keybindings_RegisterLabelForBindingUpdate(rotateRollLeftButton:GetNamedChild("Text"), "HOUSING_EDITOR_ROLL_LEFT")

        local rotateRollRightButton = self.precisionRotateButtons:GetNamedChild("PrecisionRollRightButton")
        rotateRollRightButton:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Housing/housing_axisControlIcon_rollCW.dds")
        ZO_Keybindings_RegisterLabelForBindingUpdate(rotateRollRightButton:GetNamedChild("Text"), "HOUSING_EDITOR_ROLL_RIGHT")

        self.precisionRotateHudButtons =
        {
            rotateYawLeftButton,
            rotateYawRightButton,
            rotatePitchForwardButton,
            rotatePitchBackButton,
            rotateRollLeftButton,
            rotateRollRightButton,
        }

        for _, button in ipairs(self.precisionRotateHudButtons) do
            button.precisionMode = true
        end
    end

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
        local allHudButtons = {self.pickupRotateHudButtons, self.precisionMoveHudButtons, self.precisionRotateHudButtons}
        for _, buttons in ipairs(allHudButtons) do
            local lastButton = nil
            for _, button in ipairs(buttons) do
                button:SetDimensions(style.dimensions, style.dimensions)
                button:GetNamedChild("Frame"):SetTexture(style.frame)
                button:GetNamedChild("Text"):SetFont(style.font)

                local isValid, point, relativeTo, relativePoint, offsetX, offsetY, constraints = button:GetNamedChild("Text"):GetAnchor(0)
                if isValid then
                    button:GetNamedChild("Text"):SetAnchor(point, relativeTo, relativePoint, offsetX, style.labelOffsetY, constraints)
                end

                if lastButton then
                    button:SetAnchor(LEFT, lastButton, RIGHT, style.buttonOffsetX, 0)
                end
                lastButton = button
            end
        end

        self.buttonContainer:SetAnchor(BOTTOM, nil, BOTTOM, 0, style.containerOffsetY)
        self.precisionMoveButtonContainer:SetAnchor(BOTTOM, nil, BOTTOM, 0, style.containerOffsetY)
        self.precisionRotateButtonContainer:SetAnchor(BOTTOM, nil, BOTTOM, 0, style.containerOffsetY)
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

    local PRECISION_MOVE_LEFT = 9
    local PRECISION_MOVE_RIGHT = 10
    local PRECISION_MOVE_FORWARD = 11
    local PRECISION_MOVE_BACKWARD = 12
    local PRECISION_MOVE_UP = 13
    local PRECISION_MOVE_DOWN = 14

    local PRECISION_ROTATE_YAW_RIGHT = 15
    local PRECISION_ROTATE_YAW_LEFT = 16
    local PRECISION_ROTATE_PITCH_FORWARD = 17
    local PRECISION_ROTATE_PITCH_BACKWARD = 18
    local PRECISION_ROTATE_ROLL_LEFT = 19
    local PRECISION_ROTATE_ROLL_RIGHT = 20

    local KEYPRESS_MIN = 1
    local KEYPRESS_MAX = 20

    function ZO_HousingEditorHud:GetAdjacentPrecisionUnits(unitList, currentUnit, direction)
        local index = (ZO_IndexOfElementInNumericallyIndexedTable(unitList, currentUnit) or 1) - 1
        return unitList[((index + direction) % #unitList) + 1]
    end

    function ZO_HousingEditorHud:AdjustPrecisionUnits(unitType, adjustmentType)
        local direction

        if adjustmentType == PRECISION_UNIT_ADJUSTMENT_INCREMENT then
            direction = 1
        elseif adjustmentType == PRECISION_UNIT_ADJUSTMENT_DECREMENT then
            direction = -1
        end

        if unitType == HOUSING_EDITOR_PRECISION_PLACEMENT_MODE_MOVE then
            local unitList = PRECISION_MOVE_UNITS_CM
            local currentUnits = HousingEditorGetPrecisionMoveUnits()
            HousingEditorSetPrecisionMoveUnits(self:GetAdjacentPrecisionUnits(unitList, currentUnits, direction))
        elseif unitType == HOUSING_EDITOR_PRECISION_PLACEMENT_MODE_ROTATE then
            local unitList = PRECISION_ROTATE_UNITS_DEG
            local currentUnits = zo_roundToNearest(math.deg(HousingEditorGetPrecisionRotateUnits()), 0.001)
            HousingEditorSetPrecisionRotateUnits(math.rad(self:GetAdjacentPrecisionUnits(unitList, currentUnits, direction)))
        end
    end

    function ZO_HousingEditorHud:GetButtonDirection(axis)
        local precisionEditing = self:IsPrecisionEditingEnabled()
        local precisionEditingRotateMode = self:IsPrecisionPlacementRotationMode()

        -- Translate the specified axis' keypress states into the corresponding translational or rotational coefficient.
        if axis == AXIS_TYPE_Y then
            if precisionEditing then
                if precisionEditingRotateMode then
                    return (self.placementKeyPresses[PRECISION_ROTATE_YAW_LEFT] and 1 or 0) + (self.placementKeyPresses[PRECISION_ROTATE_YAW_RIGHT] and -1 or 0)
                else
                    return (self.placementKeyPresses[PRECISION_MOVE_UP] and 1 or 0) + (self.placementKeyPresses[PRECISION_MOVE_DOWN] and -1 or 0)
                end
            else
                return (self.placementKeyPresses[ROTATE_YAW_LEFT] and 1 or 0) + (self.placementKeyPresses[ROTATE_YAW_RIGHT] and -1 or 0)
            end
        elseif axis == AXIS_TYPE_X then
            if precisionEditing then
                if precisionEditingRotateMode then
                    return (self.placementKeyPresses[PRECISION_ROTATE_PITCH_BACKWARD] and 1 or 0) + (self.placementKeyPresses[PRECISION_ROTATE_PITCH_FORWARD] and -1 or 0)
                else
                    return (self.placementKeyPresses[PRECISION_MOVE_BACKWARD] and -1 or 0) + (self.placementKeyPresses[PRECISION_MOVE_FORWARD] and 1 or 0)
                end
            else
                return (self.placementKeyPresses[ROTATE_PITCH_BACKWARD] and 1 or 0) + (self.placementKeyPresses[ROTATE_PITCH_FORWARD] and -1 or 0)
            end
        elseif axis == AXIS_TYPE_Z then
            if precisionEditing then
                if precisionEditingRotateMode then
                    return (self.placementKeyPresses[PRECISION_ROTATE_ROLL_RIGHT] and 1 or 0) + (self.placementKeyPresses[PRECISION_ROTATE_ROLL_LEFT] and -1 or 0)
                else
                    return (self.placementKeyPresses[PRECISION_MOVE_LEFT] and 1 or 0) + (self.placementKeyPresses[PRECISION_MOVE_RIGHT] and -1 or 0)
                end
            else
                return (self.placementKeyPresses[ROTATE_ROLL_RIGHT] and 1 or 0) + (self.placementKeyPresses[ROTATE_ROLL_LEFT] and -1 or 0)
            end
        end
    end

    function ZO_HousingEditorHud:RefreshPlacementKeyPresses()
        local frameTimeMS = GetFrameTimeMilliseconds()
        local x, y, z, pitch, yaw, roll = 0, 0, 0, 0, 0, 0
        local furnitureId = HousingEditorGetSelectedFurnitureId()

        if furnitureId and self:IsPrecisionEditingEnabled() then
            x, y, z = HousingEditorGetFurnitureWorldCenter(furnitureId)
            pitch, yaw, roll = HousingEditorGetFurnitureOrientation(furnitureId)

            local nextPrecisionPositionOrOrientationUpdateMS = self.nextPrecisionPositionOrOrientationUpdateMS or 0
            if frameTimeMS > nextPrecisionPositionOrOrientationUpdateMS then
                self.nextPrecisionPositionOrOrientationUpdateMS = frameTimeMS + PRECISION_POSITION_OR_ORIENTATION_UPDATE_INTERVAL_MS

                if self:IsPrecisionPlacementMoveMode() then
                    local xText = string.format("%d", x)
                    local yText = string.format("%d", y)
                    local zText = string.format("%d", z)
                    local positionText = GetString(SI_HOUSING_EDITOR_CURRENT_FURNITURE_POSITION)

                    positionText = string.gsub(string.gsub(string.gsub(positionText, "<<1>>", xText), "<<2>>", yText), "<<3>>", zText)
                    self.precisionPositionLabel:SetText(positionText)
                elseif self:IsPrecisionPlacementRotationMode() then
                    pitch = math.deg(pitch or 0) % 360
                    yaw = math.deg(yaw or 0) % 360
                    roll = math.deg(roll or 0) % 360
                    if pitch > 359.94 then pitch = 0 end
                    if yaw > 359.94 then yaw = 0 end
                    if roll > 359.94 then roll = 0 end

                    local pitchText = string.format("%.1f", pitch)
                    local yawText = string.format("%.1f", yaw)
                    local rollText = string.format("%.1f", roll)
                    local orientationText = GetString(SI_HOUSING_EDITOR_CURRENT_FURNITURE_ORIENTATION)

                    orientationText = string.gsub(string.gsub(string.gsub(orientationText, "<<1>>", pitchText), "<<2>>", yawText), "<<3>>", rollText)
                    self.precisionOrientationLabel:SetText(orientationText)
                end

                self.precisionPositionLabel:SetHidden(false)
                self.precisionOrientationLabel:SetHidden(false)
            end
        else
            self.precisionPositionLabel:SetHidden(true)
            self.precisionOrientationLabel:SetHidden(true)
        end

        local isAnyKeyPressed = false
        local activeIntervalMS = 0

        for keypress = KEYPRESS_MIN, KEYPRESS_MAX do
            local key = self.placementKeys[keypress]
            if key then
                if self.placementKeyPresses[keypress] then
                    if not key.keypressStartMS then
                        key.keypressStartMS = frameTimeMS
                    end
                    key.keypressDurationMS = frameTimeMS - key.keypressStartMS
                    key.keypressIntervalMS = ZO_EaseOutQuadratic(math.min(1, key.keypressDurationMS / PRESS_AND_HOLD_ACCELERATION_INTERVAL_MS))
                    activeIntervalMS = math.max(activeIntervalMS, key.keypressIntervalMS)
                    isAnyKeyPressed = true
                elseif key.keypressStartMS then
                    key.keypressStartMS = nil
                    key.keypressDurationMS = nil
                    key.keypressIntervalMS = nil
                end
            end
        end

        local isPrecisionMode = self:IsPrecisionEditingEnabled()
        local rotationInterval = PICKUP_ROTATE_INTERVALS_MS
        if isPrecisionMode then
            local rotationUnits = zo_roundToNearest(math.deg(HousingEditorGetPrecisionRotateUnits()), 0.001)
            rotationInterval = PRECISION_ROTATE_INTERVALS_MS[rotationUnits] or 10000
        end

        for keypress = KEYPRESS_MIN, KEYPRESS_MAX do
            local key = self.placementKeys[keypress]
            if key then
                if key.keypressStartMS then
                    local duration = key.keypressDurationMS
                    local interval = key.keypressIntervalMS
                    local weight = zo_lerp(AXIS_KEYBIND_RGB_WEIGHT_MIN_PERCENTAGE, AXIS_KEYBIND_RGB_WEIGHT_MAX_PERCENTAGE, interval)

                    if key.backdrop then
                        key.backdrop:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, weight)
                    else
                        key:GetNamedChild("Icon"):SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 1 + weight)
                    end

                    if key.axis and key.precisionMode == isPrecisionMode then
                        local axis = key.axis
                        local axisType = axis.axis
                        local control = axis.control
                        local rotationOffset = (duration / rotationInterval) * TWO_PI
                        local rotation = axis.rotation or 0
                        local alpha = zo_lerp(key.axis.inactiveAlpha, AXIS_INDICATOR_ALPHA_MAX_PERCENTAGE, interval)

                        weight = zo_lerp(AXIS_INDICATOR_RGB_WEIGHT_MIN_PERCENTAGE, AXIS_INDICATOR_RGB_WEIGHT_MAX_PERCENTAGE, interval)
                        control:SetAlpha(alpha)
                        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, weight)

                        if axisType == HOUSING_EDITOR_ROTATION_AXIS_X1 then
                            rotation = rotation + rotationOffset
                        elseif axisType == HOUSING_EDITOR_ROTATION_AXIS_X2 then
                            rotation = rotation - rotationOffset
                        elseif axisType == HOUSING_EDITOR_ROTATION_AXIS_Y1 then
                            rotation = rotation + rotationOffset
                        elseif axisType == HOUSING_EDITOR_ROTATION_AXIS_Y2 then
                            rotation = rotation - rotationOffset
                        elseif axisType == HOUSING_EDITOR_ROTATION_AXIS_Z1 then
                            rotation = rotation + rotationOffset
                        elseif axisType == HOUSING_EDITOR_ROTATION_AXIS_Z2 then
                            rotation = rotation - rotationOffset
                        end

                        self:RotateAndScaleAxisIndicator(control, rotation)
                    end
                else
                    if key.backdrop then
                        key.backdrop:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, AXIS_KEYBIND_RGB_WEIGHT_MIN_PERCENTAGE)
                    else
                        key:GetNamedChild("Icon"):SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 1)
                    end

                    if key.axis and key.precisionMode == isPrecisionMode then
                        local control = key.axis.control
                        local alpha = activeIntervalMS > 0 and 0 or key.axis.inactiveAlpha
                        control:SetAlpha(alpha)
                        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, AXIS_INDICATOR_RGB_WEIGHT_MIN_PERCENTAGE)
                    end
                end
            end
        end
    end

    function ZO_HousingEditorHud:ClearPlacementKeyPresses()
        if not self.placementKeyPresses then
            return
        end

        for i = KEYPRESS_MIN, KEYPRESS_MAX do
            self.placementKeyPresses[i] = false

            local key = self.placementKeys[i]
            if key and key.keypressStartMS then
                key.keypressStartMS = nil
                key:GetNamedChild("Icon"):SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 1)
            end
        end
    end

    function ZO_HousingEditorHud:InitializeKeybindDescriptors()
        local function PlacementCallback(direction, isUp)
            self.placementKeyPresses[direction] = not isUp and GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT
        end

        local function RefreshUnits()
            self:UpdateMovementControllerUnits()
            self:UpdateKeybinds()
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
            [ROTATE_ROLL_RIGHT] = false,
            [ROTATE_ROLL_LEFT] = false,

            [PUSH_FORWARD] = false,
            [PULL_BACKWARD] = false,

            [PRECISION_MOVE_RIGHT] = false,
            [PRECISION_MOVE_LEFT] = false,
            [PRECISION_MOVE_FORWARD] = false,
            [PRECISION_MOVE_BACKWARD] = false,
            [PRECISION_MOVE_UP] = false,
            [PRECISION_MOVE_DOWN] = false,

            [PRECISION_ROTATE_YAW_RIGHT] = false,
            [PRECISION_ROTATE_YAW_LEFT] = false,
            [PRECISION_ROTATE_PITCH_FORWARD] = false,
            [PRECISION_ROTATE_PITCH_BACKWARD] = false,
            [PRECISION_ROTATE_ROLL_RIGHT] = false,
            [PRECISION_ROTATE_ROLL_LEFT] = false,
        }

        self.placementKeys =
        {
            [ROTATE_YAW_RIGHT] = self.pickupRotateHudButtons[2],
            [ROTATE_YAW_LEFT] = self.pickupRotateHudButtons[1],
            [ROTATE_PITCH_FORWARD] = self.pickupRotateHudButtons[3],
            [ROTATE_PITCH_BACKWARD] = self.pickupRotateHudButtons[4],
            [ROTATE_ROLL_LEFT] = self.pickupRotateHudButtons[5],
            [ROTATE_ROLL_RIGHT] = self.pickupRotateHudButtons[6],
            [PUSH_FORWARD] = nil,
            [PULL_BACKWARD] = nil,

            [PRECISION_MOVE_LEFT] = self.precisionMoveHudButtons[1],
            [PRECISION_MOVE_RIGHT] = self.precisionMoveHudButtons[2],
            [PRECISION_MOVE_FORWARD] = self.precisionMoveHudButtons[3],
            [PRECISION_MOVE_BACKWARD] = self.precisionMoveHudButtons[4],
            [PRECISION_MOVE_DOWN] = self.precisionMoveHudButtons[5],
            [PRECISION_MOVE_UP] = self.precisionMoveHudButtons[6],

            [PRECISION_ROTATE_YAW_LEFT] = self.precisionRotateHudButtons[1],
            [PRECISION_ROTATE_YAW_RIGHT] = self.precisionRotateHudButtons[2],
            [PRECISION_ROTATE_PITCH_FORWARD] = self.precisionRotateHudButtons[3],
            [PRECISION_ROTATE_PITCH_BACKWARD] = self.precisionRotateHudButtons[4],
            [PRECISION_ROTATE_ROLL_LEFT] = self.precisionRotateHudButtons[5],
            [PRECISION_ROTATE_ROLL_RIGHT] = self.precisionRotateHudButtons[6],
        }

        do
            local axes = self.translationIndicators
            self.precisionMoveHudButtons[1].axis = axes[1]
            self.precisionMoveHudButtons[2].axis = axes[2]
            self.precisionMoveHudButtons[3].axis = axes[5]
            self.precisionMoveHudButtons[4].axis = axes[6]
            self.precisionMoveHudButtons[5].axis = axes[4]
            self.precisionMoveHudButtons[6].axis = axes[3]
        end

        do
            local axes = self.rotationIndicators

            self.pickupRotateHudButtons[1].axis = axes[1]
            self.pickupRotateHudButtons[2].axis = axes[2]
            self.pickupRotateHudButtons[3].axis = axes[5]
            self.pickupRotateHudButtons[4].axis = axes[6]
            self.pickupRotateHudButtons[5].axis = axes[3]
            self.pickupRotateHudButtons[6].axis = axes[4]

            self.precisionRotateHudButtons[1].axis = axes[1]
            self.precisionRotateHudButtons[2].axis = axes[2]
            self.precisionRotateHudButtons[3].axis = axes[5]
            self.precisionRotateHudButtons[4].axis = axes[6]
            self.precisionRotateHudButtons[5].axis = axes[3]
            self.precisionRotateHudButtons[6].axis = axes[4]
        end

        self.selectionModeKeybindStripDescriptor =
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            --Primary (Selection/Placement)
            {
                name =  GetString(SI_HOUSING_EDITOR_SELECT),
                keybind = "HOUSING_EDITOR_PRIMARY_ACTION",
                callback =  function()
                                HousingEditorSetPlacementType(HOUSING_EDITOR_PLACEMENT_TYPE_PICKUP)
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

            --Tertiary 
            {
                name = GetString(SI_HOUSING_EDITOR_PRECISION_EDIT),
                keybind = "HOUSING_EDITOR_TERTIARY_ACTION",
                callback =  function()
                                HousingEditorSetPlacementType(HOUSING_EDITOR_PLACEMENT_TYPE_PRECISION)
                                local result = HousingEditorSelectTargettedFurniture()
                                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
                                if result == HOUSING_REQUEST_RESULT_SUCCESS then
                                    TriggerTutorial(TUTORIAL_TRIGGER_HOUSING_EDITOR_ENTERED_PRECISION_PLACEMENT_MODE)
                                    PlaySound(SOUNDS.HOUSING_EDITOR_PICKUP_ITEM)
                                    return
                                end
                                HousingEditorSetPlacementType(HOUSING_EDITOR_PLACEMENT_TYPE_PICKUP)
                            end,
                order = 12,
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
                alignment = KEYBIND_STRIP_ALIGN_LEFT,
                name = GetString(SI_HOUSING_EDITOR_UNDO),
                keybind = "HOUSING_EDITOR_UNDO_ACTION",
                enabled = function() return CanUndoLastHousingEditorCommand() end,
                callback = function()
                                UndoLastHousingEditorCommand()
                           end,
            },

            -- Redo
            {
                alignment = KEYBIND_STRIP_ALIGN_LEFT,
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

        self.precisionMovePlacementModeKeybindStripDescriptor =
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


            --Primary (Placement)
            {
                name =  GetString(SI_HOUSING_EDITOR_PLACE),
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

            --Secondary (Swap to Rotate Mode)
            {
                name = GetString(SI_HOUSING_EDITOR_PRECISION_ROTATE_MODE),
                keybind = "HOUSING_EDITOR_SECONDARY_ACTION",
                callback =  function()
                                self:TogglePrecisionPlacementMode()
                                self:UpdateKeybinds()
                            end,
                order = 20,
            },

            --Tertiary (Cycle Movement Units for Gamepad, Mouse mode for keyboard)
            {
                name = function()
                            if IsInGamepadPreferredMode() then
                                return zo_strformat(SI_HOUSING_EDITOR_PRECISION_MOVE_UNITS, ZO_CommaDelimitDecimalNumber(HousingEditorGetPrecisionMoveUnits()))
                            else
                                return GetString(SI_HOUSING_EDITOR_CURSOR_MODE)
                            end
                        end,
                keybind = "HOUSING_EDITOR_TERTIARY_ACTION",
                callback = function()
                                if IsInGamepadPreferredMode() then 
                                    self:AdjustPrecisionUnits(HOUSING_EDITOR_PRECISION_PLACEMENT_MODE_MOVE, PRECISION_UNIT_ADJUSTMENT_INCREMENT)
                                    RefreshUnits()
                                else
                                    SCENE_MANAGER:OnToggleHUDUIBinding()
                                end
                           end,
                order = 30,
            },

            --Quaternary (Cycle Movement Units)
            {
                name = function()
                    return zo_strformat(SI_HOUSING_EDITOR_PRECISION_MOVE_UNITS, ZO_CommaDelimitDecimalNumber(HousingEditorGetPrecisionMoveUnits()))
                end,
                keybind = "HOUSING_EDITOR_QUATERNARY_ACTION",
                visible = function()
                    return not IsInGamepadPreferredMode()
                end,
                callback = function()
                               self:AdjustPrecisionUnits(HOUSING_EDITOR_PRECISION_PLACEMENT_MODE_MOVE, PRECISION_UNIT_ADJUSTMENT_INCREMENT)
                               RefreshUnits()
                           end,
                order = 40,
            },

            --Straighten
            {
                name = GetString(SI_HOUSING_EDITOR_STRAIGHTEN),
                keybind = "HOUSING_EDITOR_JUMP_TO_SAFE_LOC",
                callback = function() 
                                HousingEditorStraightenFurniture()
                           end,
                order = 50,
            },

            --Precision Move Right
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Yaw Right",
                keybind = "HOUSING_EDITOR_YAW_RIGHT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_MOVE_RIGHT, isUp)
                            end,
            },

            --Precision Move Left
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Yaw Left",
                keybind = "HOUSING_EDITOR_YAW_LEFT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_MOVE_LEFT, isUp)
                            end,
            },

            --Precision Move Forward
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Pitch Forward",
                keybind = "HOUSING_EDITOR_PITCH_FORWARD",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_MOVE_FORWARD, isUp)
                            end,
            },

            --Precision Move Backward
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Pitch Backward",
                keybind = "HOUSING_EDITOR_PITCH_BACKWARD",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_MOVE_BACKWARD, isUp)
                            end,
            },

            --Precision Move Up
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Roll Right",
                keybind = "HOUSING_EDITOR_ROLL_RIGHT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_MOVE_UP, isUp)
                            end,
            },

            --Precision Move Down
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Roll Left",
                keybind = "HOUSING_EDITOR_ROLL_LEFT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_MOVE_DOWN, isUp)
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

        self.precisionRotatePlacementModeKeybindStripDescriptor =
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

            --Primary (Placement)
            {
                name =  GetString(SI_HOUSING_EDITOR_PLACE),
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

            --Secondary (Swap to Move Mode)
            {
                name = GetString(SI_HOUSING_EDITOR_PRECISION_MOVE_MODE),
                keybind = "HOUSING_EDITOR_SECONDARY_ACTION",
                callback =  function()
                                self:TogglePrecisionPlacementMode()
                                self:UpdateKeybinds()
                            end,
                order = 20,
            },

            --Tertiary (Cycle Rotation Units for Gamepad, Mouse mode for keyboard)
            {
                name = function()
                            if IsInGamepadPreferredMode() then
                                return zo_strformat(SI_HOUSING_EDITOR_PRECISION_ROTATE_UNITS, ZO_CommaDelimitDecimalNumber(zo_roundToNearest(math.deg(HousingEditorGetPrecisionRotateUnits()), 0.01)))
                            else
                                return GetString(SI_HOUSING_EDITOR_CURSOR_MODE)
                            end
                        end,
                keybind = "HOUSING_EDITOR_TERTIARY_ACTION",
                callback = function()
                                if IsInGamepadPreferredMode() then 
                                    self:AdjustPrecisionUnits(HOUSING_EDITOR_PRECISION_PLACEMENT_MODE_ROTATE, PRECISION_UNIT_ADJUSTMENT_INCREMENT)
                                    RefreshUnits()
                                else
                                    SCENE_MANAGER:OnToggleHUDUIBinding()
                                end
                           end,
                order = 30,
            },

            --Quaternary (Cycle Rotation Units)
            {
                name = function()
                    return zo_strformat(SI_HOUSING_EDITOR_PRECISION_ROTATE_UNITS, ZO_CommaDelimitDecimalNumber(zo_roundToNearest(math.deg(HousingEditorGetPrecisionRotateUnits()), 0.01)))
                end,
                keybind = "HOUSING_EDITOR_QUATERNARY_ACTION",
                visible = function()
                    return not IsInGamepadPreferredMode()
                end,
                callback = function()
                               self:AdjustPrecisionUnits(HOUSING_EDITOR_PRECISION_PLACEMENT_MODE_ROTATE, PRECISION_UNIT_ADJUSTMENT_INCREMENT)
                               RefreshUnits()
                           end,
                order = 40,
            },

            --Straighten
            {
                name = GetString(SI_HOUSING_EDITOR_STRAIGHTEN),
                keybind = "HOUSING_EDITOR_JUMP_TO_SAFE_LOC",
                callback = function() 
                                HousingEditorStraightenFurniture()
                           end,
                order = 50,
            },

            --Precision Roll Right
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Yaw Right",
                keybind = "HOUSING_EDITOR_YAW_RIGHT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_ROTATE_YAW_RIGHT, isUp)
                            end,
            },

            --Precision Roll Left
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Yaw Left",
                keybind = "HOUSING_EDITOR_YAW_LEFT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_ROTATE_YAW_LEFT, isUp)
                            end,
            },

            --Precision Pitch Right
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Pitch Forward",
                keybind = "HOUSING_EDITOR_PITCH_FORWARD",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_ROTATE_PITCH_FORWARD, isUp)
                            end,
            },

            --Precision Pitch Left
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Pitch Backward",
                keybind = "HOUSING_EDITOR_PITCH_BACKWARD",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_ROTATE_PITCH_BACKWARD, isUp)
                            end,
            },

            --Precision Roll Right
            {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Roll Right",
                keybind = "HOUSING_EDITOR_ROLL_RIGHT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_ROTATE_ROLL_RIGHT, isUp)
                            end,
            },

            --Precision Roll Left
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Furniture Roll Left",
                keybind = "HOUSING_EDITOR_ROLL_LEFT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(PRECISION_ROTATE_ROLL_LEFT, isUp)
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
                                    HousingEditorPushSelectedObject(self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds()) --mousewheel doesn't need the update loop
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
                                    HousingEditorPushSelectedObject(-self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds()) --mousewheel doesn't need the update loop
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
                                    HousingEditorPushSelectedObject(self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds()) --mousewheel doesn't need the update loop
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
                                    HousingEditorPushSelectedObject(-self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds()) --mousewheel doesn't need the update loop
                                end
                            end,
            }
        }
    end

    function ZO_HousingEditorHud:GetKeybindStripDescriptorForMode(mode)
        if mode == HOUSING_EDITOR_MODE_SELECTION then
            return self.selectionModeKeybindStripDescriptor
        elseif mode == HOUSING_EDITOR_MODE_PLACEMENT then
            if self:IsPrecisionEditingEnabled() then
                if self:IsPrecisionPlacementRotationMode() then
                    return self.precisionRotatePlacementModeKeybindStripDescriptor
                else
                    return self.precisionMovePlacementModeKeybindStripDescriptor
                end
            else
                return self.placementModeKeybindStripDescriptor
            end
        elseif mode == HOUSING_EDITOR_MODE_LINK then
            return self.linkModeKeybindStripDescriptor
        end
    end

    function ZO_HousingEditorHud:GetAxisDelta(axis)
        local direction = 0
        local rotation = 0
        local movementController
        
        if axis == AXIS_TYPE_X then
            movementController = self.pitchMovementController
        elseif axis == AXIS_TYPE_Y then
            movementController = self.yawMovementController
        elseif axis == AXIS_TYPE_Z then
            movementController = self.rollMovementController
        end

        local movement = movementController:CheckMovement()

        if movement == MOVEMENT_CONTROLLER_MOVE_NEXT then
            direction = 1
        elseif movement == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            direction = -1
        end

        if self:IsPrecisionEditingEnabled() then
            rotation = 1
        else
            -- If the movement controller is firing at max speed, switch from frame based incrementing to time based (might base this off a button press in the future).
            if movementController:IsAtMaxVelocity() then
                rotation = self.rotationStep * GetFrameDeltaNormalizedForTargetFramerate()
                direction = self:GetButtonDirection(axis) * -1
            else
                rotation = self.rotationStep
            end
        end

        return rotation * direction
    end

    function ZO_HousingEditorHud:OnUpdate()
        if GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT then
            self:UpdateAxisIndicators()

            local x = self:GetAxisDelta(AXIS_TYPE_X)
            local y = self:GetAxisDelta(AXIS_TYPE_Y)
            local z = self:GetAxisDelta(AXIS_TYPE_Z)

            if self:IsPrecisionEditingEnabled() then
                if self:IsPrecisionPlacementRotationMode() then
                    if x ~= 0 then
                        HousingEditorRotateFurniture(AXIS_TYPE_X, x)
                    end
                    if y ~= 0 then
                        HousingEditorRotateFurniture(AXIS_TYPE_Y, y)
                    end
                    if z ~= 0 then
                        HousingEditorRotateFurniture(AXIS_TYPE_Z, z)
                    end
                else
                    local result = HOUSING_REQUEST_RESULT_SUCCESS
                    if x ~= 0 then
                        result = HousingEditorMoveFurniture(AXIS_TYPE_X, x)
                    end
                    if y ~= 0 then
                        result = HousingEditorMoveFurniture(AXIS_TYPE_Y, y)
                    end
                    if z ~= 0 then
                        result = HousingEditorMoveFurniture(AXIS_TYPE_Z, z)
                    end
                    ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
                end
            else
                if x ~= 0 then
                    HousingEditorRotateFurniture(AXIS_TYPE_X, x)
                end
                if y ~= 0 then
                    HousingEditorRotateFurniture(AXIS_TYPE_Y, y)
                end
                if z ~= 0 then
                    HousingEditorRotateFurniture(AXIS_TYPE_Z, z)
                end
            end
                
            if self.placementKeyPresses[PUSH_FORWARD] then
                HousingEditorPushSelectedObject(self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds())
            end

            if self.placementKeyPresses[PULL_BACKWARD] then
                HousingEditorPushSelectedObject(-self.pushSpeedPerSecond * GetFrameDeltaTimeSeconds())
            end

            self:RefreshPlacementKeyPresses()
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
    HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED) -- Disable if someone reloads ui from editor mode.
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
