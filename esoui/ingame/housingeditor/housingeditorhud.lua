--HousingEditor HUD Fragment
--------------------

ZO_HousingEditorHUDFragment = ZO_SimpleSceneFragment:Subclass()

function ZO_HousingEditorHUDFragment:New(control)
    local fragment = ZO_SimpleSceneFragment.New(self, control)
    return fragment
end

function ZO_HousingEditorHUDFragment:Show()
    self:UpdateVisibility()
    ZO_SimpleSceneFragment.Show(self)
end

function ZO_HousingEditorHUDFragment:Hide()
    self:UpdateVisibility()
    ZO_SimpleSceneFragment.Hide(self)
end

function ZO_HousingEditorHUDFragment:UpdateVisibility()
    local fragmentHidden = not self:IsShowing()
    local playerDead = IsUnitDead("player")
    local hiddenOrDead = fragmentHidden or playerDead
    RETICLE:RequestHidden(hiddenOrDead)
end

ZO_HousingEditorHud = ZO_Object:Subclass()

function ZO_HousingEditorHud:New(...)
    local editor = ZO_Object.New(self)
    editor:Initialize(...)
    return editor
end

function ZO_HousingEditorHud:Initialize(control)
    self.control = control
    
    self.buttonContainer = control:GetNamedChild("ButtonContainer")

    HOUSING_EDITOR_HUD_SCENE = ZO_Scene:New("housingEditorHud", SCENE_MANAGER)
    HOUSING_EDITOR_HUD_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnDeferredInitialization()
            KEYBIND_STRIP:RemoveDefaultExit()            
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end)

    HOUSING_EDITOR_HUD_UI_SCENE = ZO_Scene:New("housingEditorHudUI", SCENE_MANAGER)
    HOUSING_EDITOR_HUD_UI_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.UIModeKeybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.UIModeKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end)

    local function SetHousingEditorMode(eventId, oldMode, newMode)
        self:OnHousingModeChanged(oldMode, newMode)
    end

    local function GamepadModeChanged(eventId, isGamepadPreferred)        
        if GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_DISABLED and not self.isDirty then
            HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED)   -- turn off housing mode if gamepad mode changes while active
        end

        self.isDirty = true
    end

    EVENT_MANAGER:RegisterForEvent("HousingEditor", EVENT_HOUSING_EDITOR_MODE_CHANGED, SetHousingEditorMode)
    EVENT_MANAGER:RegisterForEvent("HousingEditor", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, GamepadModeChanged)

    control:SetHandler("OnUpdate", function(_, currentFrameTimeSeconds) self:OnUpdate(currentFrameTimeSeconds) end)

    self.isDirty = true
end

function ZO_HousingEditorHud:OnHousingModeEnabled()
    if SCENE_MANAGER:IsShowingBaseScene() then
        self:CleanDirty()

        SCENE_MANAGER:SetHUDScene("housingEditorHud")
        SCENE_MANAGER:SetHUDUIScene("housingEditorHudUI", true)
    end
end

function ZO_HousingEditorHud:OnHousingModeDisabled()
    SCENE_MANAGER:RestoreHUDScene()
    SCENE_MANAGER:RestoreHUDUIScene()
end

function ZO_HousingEditorHud:OnHousingModeChanged(oldMode, newMode)
    if newMode == HOUSING_EDITOR_MODE_DISABLED then
        self:OnHousingModeDisabled()
    elseif newMode ~= HOUSING_EDITOR_MODE_DISABLED and oldMode == HOUSING_EDITOR_MODE_DISABLED then
        self:OnHousingModeEnabled()
    end

    if newMode == HOUSING_EDITOR_MODE_BROWSE then
        SYSTEMS:PushScene("housing_furniture_browser")
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
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.UIModeKeybindStripDescriptor)

    local rotationHidden = GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_PLACEMENT
    self.buttonContainer:SetHidden(rotationHidden)
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

    function ZO_HousingEditorHud:InitializeKeybindDescriptors()
        local function PlacementCallback(direction, isUp)
            self.placementKeyPresses[direction] = not isUp and GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT
        end
        
        local function IsCurrentlyRotating()
            for i = ROTATE_YAW_RIGHT, PULL_BACKWARD do
                if self.placementKeyPresses[i] then
                    return true
                end
            end
            return false
        end

        -- Exit
        local g_ExitKeybind =
        {
            name = GetString(SI_EXIT_BUTTON),
            keybind = "DISABLE_HOUSING_EDITOR",
            callback = function() 
                    if not IsCurrentlyRotating() then
                        HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED) 
                    end
                end,
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
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
        self.keybindStripDescriptor =
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            --Negative
            {
                name = function()
                            local mode = GetHousingEditorMode() 
                            if mode == HOUSING_EDITOR_MODE_PLACEMENT then
                                return "[debug] Undo"
                            elseif mode == HOUSING_EDITOR_MODE_SELECTION then
                                return GetString(SI_EXIT_BUTTON)
                            end
                        end,
                keybind = "HOUSING_EDITOR_NEGATIVE_ACTION",
                visible = function()
                                local mode = GetHousingEditorMode()  
                                return  mode == HOUSING_EDITOR_MODE_PLACEMENT or
                                        mode == HOUSING_EDITOR_MODE_SELECTION
                            end,
                callback = function()
                                local mode = GetHousingEditorMode()  
                                if mode == HOUSING_EDITOR_MODE_PLACEMENT then
                                    HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
                                elseif mode == HOUSING_EDITOR_MODE_SELECTION then
                                    HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED)
                                end
                            end,
                alignment = KEYBIND_STRIP_ALIGN_LEFT,
            },

            -- Primary
            {
                name =  function()
                            local mode = GetHousingEditorMode()
                            if mode == HOUSING_EDITOR_MODE_PLACEMENT then
                                return "[debug] Place"
                            elseif mode == HOUSING_EDITOR_MODE_SELECTION then
                                return "[debug] Select"
                            end
                        end,
                keybind = "HOUSING_EDITOR_PRIMARY_ACTION",        
                visible =   function()
                                local mode = GetHousingEditorMode()
                                return  mode == HOUSING_EDITOR_MODE_PLACEMENT or
                                        mode == HOUSING_EDITOR_MODE_SELECTION
                            end,
                callback =  function()
                                local mode = GetHousingEditorMode() 
                                if mode == HOUSING_EDITOR_MODE_PLACEMENT then
                                    HousingEditorRequestPlacement()
                                elseif mode == HOUSING_EDITOR_MODE_SELECTION then
                                    HousingEditorSelectFurniture()
                                end
                            end,
            },

            --Tertiary
            {
                name = "[debug] Surface Drag",
                keybind = "HOUSING_EDITOR_TERTIARY_ACTION",
                visible = function() return GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT end,
                callback = function() HousingEditorToggleSurfaceDragMode() end,
            },

            --Secondary
            {
                name =  function() 
                            local mode = GetHousingEditorMode()
                            if mode == HOUSING_EDITOR_MODE_PLACEMENT then
                                return "[debug] Put Away"
                            elseif mode == HOUSING_EDITOR_MODE_SELECTION then
                                return "[debug] Browse"
                            end
                        end,
                keybind = "HOUSING_EDITOR_SECONDARY_ACTION",
                visible = function() 
                            local mode = GetHousingEditorMode()
                            return mode ~= HOUSING_EDITOR_MODE_DISABLED
                                     end,
                callback =  function()
                                local mode = GetHousingEditorMode()
                                if mode == HOUSING_EDITOR_MODE_PLACEMENT then
                                    HousingEditorRequestRemoveFurniture()
                                else
                                    HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_BROWSE)
                                end
                            end,
            },

            --Roll Right
            {
                name = "[debug] Rotate Yaw Right",
                keybind = "HOUSING_EDITOR_YAW_RIGHT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_YAW_RIGHT, isUp)
                            end,
            },

            --Roll Left
            {
                name = "[debug] Rotate Yaw Left",
                keybind = "HOUSING_EDITOR_YAW_LEFT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_YAW_LEFT, isUp)
                            end,
            },

            --Pitch Right
            {
                name = "[debug] Pitch Forward",
                keybind = "HOUSING_EDITOR_PITCH_FORWARD",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_PITCH_FORWARD, isUp)
                            end,
            },

            --Pitch Left
            {
                name = "[debug] Pitch Backward",
                keybind = "HOUSING_EDITOR_PITCH_BACKWARD",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_PITCH_BACKWARD, isUp)
                            end,
            },

            --Roll Right
            {
                name = "[debug] Roll Right",
                keybind = "HOUSING_EDITOR_ROLL_RIGHT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_ROLL_RIGHT, isUp)
                            end,
            },

            --Roll Left
            {
                name = "[debug] Roll Left",
                keybind = "HOUSING_EDITOR_ROLL_LEFT",
                ethereal = true,
                handlesKeyUp = true,
                callback =  function(isUp)
                                PlacementCallback(ROTATE_ROLL_LEFT, isUp)
                            end,
            },

            --Push Forward
            {
                name = "[debug] Forward",
                keybind = "HOUSING_EDITOR_PUSH_FORWARD",
                visible = function() return GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT end,
                handlesKeyUp = true,
                callback =  function(isUp)
                                if IsInGamepadPreferredMode() then
                                    PlacementCallback(PUSH_FORWARD, isUp)
                                else
                                    HousingEditorPushFurniture(5) --mousewheel doesn't need the update loop
                                end
                            end,
            },

            --Pull Backward
            {
                name = "[debug] Backward",
                keybind = "HOUSING_EDITOR_PULL_BACKWARD",
                visible = function() return GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT end,
                handlesKeyUp = true,
                callback =  function(isUp)
                                if IsInGamepadPreferredMode() then
                                    PlacementCallback(PULL_BACKWARD, isUp)
                                else
                                    HousingEditorPushFurniture(-5) --mousewheel doesn't need the update loop
                                end
                            end,
            },

            --Align to Surface
            {
                name = "[debug] Align",
                keybind = "HOUSING_EDITOR_ALIGN_TO_SURFACE",
                visible = function() return GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT end,
                callback =  function()
                                HousingEditorAlignFurnitureToSurface()
                            end,
            },

            --Jump to safe loc
            {
                name = "[debug] Jump Safe",
                keybind = "HOUSING_EDITOR_JUMP_TO_SAFE_LOC",
                visible = function() return GetHousingEditorMode() == HOUSING_EDITOR_MODE_SELECTION end,
                callback =  function()
                                HousingEditorJumpToSafeLocation()
                            end,
            },
            g_ExitKeybind,
        }

        self.UIModeKeybindStripDescriptor =
        {
            g_ExitKeybind
        }
    end

    function ZO_HousingEditorHud:OnUpdate(currentFrameTimeMS)
        if GetHousingEditorMode() == HOUSING_EDITOR_MODE_PLACEMENT then
            if self.placementKeyPresses[ROTATE_YAW_RIGHT] then
                HousingEditorRotateFurniture(AXIS_TYPE_Y, 1.5 * math.pi)
            end

            if self.placementKeyPresses[ROTATE_YAW_LEFT] then
                HousingEditorRotateFurniture(AXIS_TYPE_Y, -1.5 * math.pi)
            end
                
            if self.placementKeyPresses[ROTATE_PITCH_FORWARD] then
                HousingEditorRotateFurniture(AXIS_TYPE_X, -1.5 * math.pi)
            end

            if self.placementKeyPresses[ROTATE_PITCH_BACKWARD] then
                HousingEditorRotateFurniture(AXIS_TYPE_X, 1.5 * math.pi)
            end

            if self.placementKeyPresses[ROTATE_ROLL_LEFT] then
                HousingEditorRotateFurniture(AXIS_TYPE_Z, 1.5 * math.pi)
            end

            if self.placementKeyPresses[ROTATE_ROLL_RIGHT] then
                HousingEditorRotateFurniture(AXIS_TYPE_Z, -1.5 * math.pi)
            end
                
            if self.placementKeyPresses[PUSH_FORWARD] then
                HousingEditorPushFurniture(5)
            end

            if self.placementKeyPresses[PULL_BACKWARD] then
                HousingEditorPushFurniture(-5)
            end
        end
    end
end

function ZO_HousingEditorHud:CleanDirty()
    if self.isDirty then
        self.isDirty = false
        self:SetupSceneFragments()
    end
end

function ZO_HousingEditorHud:SetupSceneFragments()
    if IsInGamepadPreferredMode() then
        HOUSING_EDITOR_HUD_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_HOUSING_EDITOR_HUD_SCENE_BACKDROP_GROUP)
        HOUSING_EDITOR_HUD_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.KEYBOARD_HOUSING_EDITOR_HUD_SCENE_BACKDROP_GROUP)

        HOUSING_EDITOR_HUD_UI_SCENE:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
        HOUSING_EDITOR_HUD_UI_SCENE:RemoveFragment(KEYBIND_STRIP_FADE_FRAGMENT)
    else
        HOUSING_EDITOR_HUD_SCENE:AddFragmentGroup(FRAGMENT_GROUP.KEYBOARD_HOUSING_EDITOR_HUD_SCENE_BACKDROP_GROUP)
        HOUSING_EDITOR_HUD_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.GAMEPAD_HOUSING_EDITOR_HUD_SCENE_BACKDROP_GROUP)

        HOUSING_EDITOR_HUD_UI_SCENE:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
        HOUSING_EDITOR_HUD_UI_SCENE:RemoveFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
    end
end

--[[ Globals ]]--
function ZO_HousingEditorHud_OnInitialize(control)
    HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED) --disable if someone reloads ui from editor mode
    HOUSING_EDITOR_SHARED = ZO_HousingEditorHud:New(control)
end