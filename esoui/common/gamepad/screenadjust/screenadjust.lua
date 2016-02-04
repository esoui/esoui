local ScreenAdjust = ZO_Object:Subclass()

function ScreenAdjust:New(...)
    local adjust = ZO_Object.New(self)
    adjust:Initialize(...)
    return adjust
end

function ScreenAdjust:Initialize(control, sceneName)
    self.control = control
    self.sceneName = sceneName
    self.readyToSave = false

    self:InitializeKeybindButtons()
    self:RefreshGuiDimensions()

    local sceneFragment = ZO_FadeSceneFragment:New(control)

    -- adjust screen to be used from options menus
    local scene = ZO_Scene:New(sceneName, SCENE_MANAGER)
    scene:AddFragment(sceneFragment)

    scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWN then
            local SAVE_INITIAL_SCREEN_SIZE = true
            self:InitializeSize(SAVE_INITIAL_SCREEN_SIZE)
            if IsInGamepadPreferredMode() then
                DIRECTIONAL_INPUT:Activate(self, self.control)
            end
            self.readyToSave = true

        elseif newState == SCENE_HIDING then
            if SCENE_MANAGER:IsCurrentSceneGamepad() then
                DIRECTIONAL_INPUT:Deactivate(self)
            end
        end
    end)

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function(_, width, height)
        self:RefreshGuiDimensions()
        if scene:IsShowing() then
            local IGNORE_INITIAL_SCREEN_SIZE = false
            self:InitializeSize(IGNORE_INITIAL_SCREEN_SIZE)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("ScreenAdjustResizeEvent", 
                                EVENT_ALL_GUI_SCREENS_RESIZE_STARTED, 
                                function()
                                    self.saveButton:SetEnabled(false)
                                    self.saveButton:SetText(GetString(SI_SETTING_SHOW_SCREEN_ADJUST_DISABLED))
                                end)

    EVENT_MANAGER:RegisterForEvent("ScreenAdjustResizeEvent", 
                                EVENT_ALL_GUI_SCREENS_RESIZED, 
                                function()
                                    self.saveButton:SetText(GetString(SI_SAVE))
                                    self.saveButton:SetEnabled(true)
                                end)
end

function ScreenAdjust:InitializeKeybindButtons()
    local bindsContainer = self.control:GetNamedChild("InstructionsBinds")

    local adjustButton = bindsContainer:GetNamedChild("Adjust")
    adjustButton:SetText(GetString(SI_SCREEN_ADJUST))
    if GetGamepadType() == GAMEPAD_TYPE_PS4 then
        adjustButton:SetCustomKeyIcon("EsoUI/Art/Buttons/Gamepad/PS4/Nav_Ps4_LS_Slide_Scroll.dds")
    else
        adjustButton:SetCustomKeyIcon("EsoUI/Art/Buttons/Gamepad/XBox/Nav_XBone_LS_Slide_Scroll.dds")
    end
    adjustButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)

    self.saveButton = bindsContainer:GetNamedChild("Save")
    self.saveButton:SetText(GetString(SI_SAVE))
    self.saveButton:SetKeybind("SCREEN_ADJUST_SAVE")
    self.saveButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
    self.saveButton:SetClickSound(SOUNDS.DIALOG_ACCEPT)
    self.saveButton:SetCallback(function()
        -- only allow resizing once the previous one has been completed.
        if not IsGUIResizing() then
            self:Commit()
            SCENE_MANAGER:Hide(self.sceneName)
        end
    end)

    self.cancelButton = bindsContainer:GetNamedChild("Cancel")
    self.cancelButton:SetText(GetString(SI_CANCEL))
    self.cancelButton:SetKeybind("SCREEN_ADJUST_CANCEL")
    self.cancelButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
    self.cancelButton:SetClickSound(SOUNDS.DIALOG_DECLINE)
    self.cancelButton:SetCallback(function()
        self:RevertChanges()
        SCENE_MANAGER:Hide(self.sceneName)
    end)
end

function ScreenAdjust:RefreshGuiDimensions()
    self.rootWidth, self.rootHeight = GuiRoot:GetDimensions()
end

function ScreenAdjust:InitializeSize(storeInitialValues)
    local STARTING_PERCENTAGE = 0.9
    self:SetSize(self.rootWidth * STARTING_PERCENTAGE, self.rootHeight * STARTING_PERCENTAGE)
    local x, y, width, height = GetOverscanOffsets()

    -- reset to max screen
    if(x ~= 0 or y ~= 0 or width ~= 0 or height ~= 0) then
        SetOverscanOffsets(0, 0, 0, 0)
    end

    if storeInitialValues then
        -- store these values in case the user cancels out
        self.xOffsetInitialValue = x
        self.yOffsetInitialValue = y
        self.widthOffsetInitialValue = width
        self.heightOffsetInitialValue = height
    end
end

function ScreenAdjust:SetSize(width, height)
    local MIN_PERCENTAGE = 0.9
    width = zo_clamp(width, self.rootWidth * MIN_PERCENTAGE, self.rootWidth)
    height = zo_clamp(height, self.rootHeight * MIN_PERCENTAGE, self.rootHeight)
    self.width = width
    self.height = height
    self.control:SetDimensions(width, height)
end

function ScreenAdjust:Commit()
    if (self.readyToSave) then
        local xUI = self.control:GetLeft()
        local yUI = self.control:GetTop()
        local xScreenSpace = xUI * GetUIGlobalScale()
        local yScreenSpace = yUI * GetUIGlobalScale()

        --overscan offsets are in screen space so multiply by global scale to convert the UI coordinates to screen space (pixels)
        SetOverscanOffsets(xScreenSpace, yScreenSpace, -2 * xScreenSpace, -2 * yScreenSpace)
        self.readyToSave = false
    end
end

function ScreenAdjust:RevertChanges()
    SetOverscanOffsets(self.xOffsetInitialValue, self.yOffsetInitialValue, self.widthOffsetInitialValue, self.heightOffsetInitialValue)
end

function ScreenAdjust:OnSave()
    self.saveButton:OnClicked()
end

function ScreenAdjust:OnCancel()
    self.cancelButton:OnClicked()
end

function ScreenAdjust:UpdateDirectionalInput()
    local currentTimeMs = GetGameTimeMilliseconds()
    if self.lastFrameMs == nil then
        self.lastFrameMs = currentTimeMs
    end
    local MAX_TIME_MS = 100
    local deltaTimeMs = zo_min(currentTimeMs - self.lastFrameMs, MAX_TIME_MS)

    self.lastFrameMs = currentTimeMs

    local dx, dy = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK)

    -- negative X direction is to make it larger
    dx = -dx

    -- make sure to make scaling uniform
    if zo_abs(dx) > zo_abs(dy) then
        dy = dx
    else
        dx = dy
    end

    local SCALE_RATE = 0.0001
    local xRate = SCALE_RATE * self.rootWidth
    local yRate = SCALE_RATE * self.rootHeight
    dx = dx * deltaTimeMs * xRate
    dy = dy * deltaTimeMs * yRate

    self:SetSize(self.width + dx, self.height + dy)
end

--Global XML
function ZO_ScreenAdjust_Handle_OnSave()
    if SCENE_MANAGER:IsShowing("screenAdjust") then
        SCREEN_ADJUST:OnSave()
    elseif SCENE_MANAGER:IsShowing("screenAdjustIntro") then
        SCREEN_ADJUST_INTRO:OnSave()
    end
end

function ZO_ScreenAdjust_Handle_OnCancel()
    if SCENE_MANAGER:IsShowing("screenAdjust") then
        SCREEN_ADJUST:OnCancel()
    elseif SCENE_MANAGER:IsShowing("screenAdjustIntro") then
        SCREEN_ADJUST_INTRO:OnCancel()
    end
end

function ZO_ScreenAdjust_OnInitialized(self)
    SCREEN_ADJUST = ScreenAdjust:New(self, "screenAdjust")
end

function ZO_ScreenAdjustIntro_OnInitialized(self)
    SCREEN_ADJUST_INTRO = ScreenAdjust:New(self, "screenAdjustIntro")
end