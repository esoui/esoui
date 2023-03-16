local ScreenAdjust = ZO_Object:Subclass()

function ScreenAdjust:New(...)
    local adjust = ZO_Object.New(self)
    adjust:Initialize(...)
    return adjust
end

function ScreenAdjust:Initialize(control)
    self.control = control
    self.readyToSave = false
    self.growthRate = 0

    self:InitializeInstructions()
    self:RefreshGuiDimensions()

    SCREEN_ADJUST_SCENE_FRAGMENT = ZO_FadeSceneFragment:New(control)

    SCREEN_ADJUST_SCENE_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        end
    end)

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function(_, width, height)
        self:RefreshGuiDimensions()
        if SCREEN_ADJUST_SCENE_FRAGMENT:IsShowing() then
            local IGNORE_INITIAL_SCREEN_SIZE = false
            self:InitializeSize(IGNORE_INITIAL_SCREEN_SIZE)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("ScreenAdjustResizeEvent", EVENT_ALL_GUI_SCREENS_RESIZE_STARTED, function()
        if SCREEN_ADJUST_SCENE_FRAGMENT:IsShowing() then
            local saveButton = self:GetActiveSaveButton()
            saveButton:SetEnabled(false)
            saveButton:SetText(GetString(SI_SETTING_SHOW_SCREEN_ADJUST_DISABLED))
        end
    end)

    EVENT_MANAGER:RegisterForEvent("ScreenAdjustResizeEvent", EVENT_ALL_GUI_SCREENS_RESIZED, function()
        if SCREEN_ADJUST_SCENE_FRAGMENT:IsShowing() then
            local saveButton = self:GetActiveSaveButton()
            saveButton:SetText(GetString(SI_SAVE))
            saveButton:SetEnabled(true)
        end
    end)

    self:InitializeNarrationInfo()
end

function ScreenAdjust:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return SCREEN_ADJUST_SCENE_FRAGMENT:IsShowing()
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SCREEN_ADJUST_INSTRUCTIONS)))
            return narrations
        end,
        additionalInputNarrationFunction = function()
            local narrationData = {}

            if ZO_Keybindings_ShouldShowGamepadKeybind() then
                --Get the narration data for adjusting the screen
                local screenAdjustNarrationData =
                {
                    name = GetString(SI_SCREEN_ADJUST),
                    --The gamepad keybind for screen adjust isn't a real keybind so just use the key that gives us the narration we want here
                    keybindName = ZO_Keybindings_GetNarrationStringFromKeys(KEY_GAMEPAD_LEFT_STICK, KEY_INVALID, KEY_INVALID, KEY_INVALID, KEY_INVALID),
                    enabled = true,
                }
                table.insert(narrationData, screenAdjustNarrationData)
            else
                --Get the narration data for adjusting the screen
                local NO_NAME = nil
                ZO_CombineNumericallyIndexedTables(narrationData, ZO_GetCombinedDirectionalInputNarrationData(NO_NAME, NO_NAME, NO_NAME, GetString(SI_SCREEN_ADJUST)))
            end

            --Narration for the save keybind
            local saveButtonData = self.gamepadSaveButton:GetKeybindButtonNarrationData()
            if saveButtonData then
                table.insert(narrationData, saveButtonData)
            end

            --Narration for the cancel keybind
            local cancelData = self.gamepadCancelButton:GetKeybindButtonNarrationData()
            if cancelData then
                table.insert(narrationData, cancelData)
            end
            return narrationData
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("screenAdjust", narrationInfo)
end

function ScreenAdjust:InitializeInstructions()
    -- gamepad instructions
    do
        self.gamepadInstructions = self.control:GetNamedChild("GamepadInstructions")
        local gamepadButtons = self.gamepadInstructions:GetNamedChild("Binds")
        local growShrinkButton = gamepadButtons:GetNamedChild("GrowShrink")
        growShrinkButton:SetText(GetString(SI_SCREEN_ADJUST))
        growShrinkButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
        ZO_GamepadTypeBasedControl_OnInitialized(growShrinkButton)
        growShrinkButton:SetUpdateCallback(function(keybindButton)
            keybindButton:SetCustomKeyIcon(GetGamepadLeftStickSlideAndScrollIcon())
        end)

        self.gamepadSaveButton = gamepadButtons:GetNamedChild("Save")
        self.gamepadSaveButton:SetText(GetString(SI_SAVE))
        self.gamepadSaveButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
        self.gamepadSaveButton:SetKeybind("SCREEN_ADJUST_SAVE")
        self.gamepadSaveButton:SetCallback(function()
            self:Save()
        end)

        self.gamepadCancelButton = gamepadButtons:GetNamedChild("Cancel")
        self.gamepadCancelButton:SetText(GetString(SI_CANCEL))
        self.gamepadCancelButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
        self.gamepadCancelButton:SetKeybind("SCREEN_ADJUST_CANCEL")
        self.gamepadCancelButton:SetCallback(function()
            self:Cancel()
        end)
    end

    -- keyboard instructions
    do
        self.keyboardInstructions = self.control:GetNamedChild("KeyboardInstructions")
        local keyboardButtons = self.keyboardInstructions:GetNamedChild("Binds")
        local growButton = keyboardButtons:GetNamedChild("Grow")
        growButton:SetText(GetString(SI_SCREEN_ADJUST_GROW))
        growButton:SetKeybind("SCREEN_ADJUST_GROW")

        local shrinkButton = keyboardButtons:GetNamedChild("Shrink")
        shrinkButton:SetText(GetString(SI_SCREEN_ADJUST_SHRINK))
        shrinkButton:SetKeybind("SCREEN_ADJUST_SHRINK")

        self.keyboardSaveButton = keyboardButtons:GetNamedChild("Save")
        self.keyboardSaveButton:SetText(GetString(SI_SAVE))
        self.keyboardSaveButton:SetKeybind("SCREEN_ADJUST_SAVE")
        self.keyboardSaveButton:SetCallback(function()
            self:Save()
        end)

        local cancelButton = keyboardButtons:GetNamedChild("Cancel")
        cancelButton:SetText(GetString(SI_CANCEL))
        cancelButton:SetKeybind("SCREEN_ADJUST_CANCEL")
        cancelButton:SetCallback(function()
            self:Cancel()
        end)
    end
end

function ScreenAdjust:GetActiveSaveButton()
    return SCENE_MANAGER:IsCurrentSceneGamepad() and self.gamepadSaveButton or self.keyboardSaveButton
end

function ScreenAdjust:OnShowing()
    local SAVE_INITIAL_SCREEN_SIZE = true
    self:InitializeSize(SAVE_INITIAL_SCREEN_SIZE)

    local isGamepadScene = SCENE_MANAGER:IsCurrentSceneGamepad()
    self.gamepadInstructions:SetHidden(not isGamepadScene)
    self.keyboardInstructions:SetHidden(isGamepadScene)
end

function ScreenAdjust:OnShown()
    self.readyToSave = true
    self:SetGrowthRate(0)

    if SCENE_MANAGER:IsCurrentSceneGamepad() then
        DIRECTIONAL_INPUT:Activate(self, self.control)
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("screenAdjust")
    end
    self.control:SetHandler("OnUpdate", function()
        self:UpdateSize()
    end)
end

function ScreenAdjust:OnHiding()
    if SCENE_MANAGER:IsCurrentSceneGamepad() then
        DIRECTIONAL_INPUT:Deactivate(self)
    end

    self.control:SetHandler("OnUpdate", nil)
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
    if self.readyToSave then
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

function ScreenAdjust:Save()
    -- only allow resizing once the previous one has been completed.
    if not IsGUIResizing() then
        PlaySound(SOUNDS.DIALOG_ACCEPT)
        self:Commit()
        SCENE_MANAGER:Hide("screenAdjust")
    end
end

function ScreenAdjust:Cancel()
    PlaySound(SOUNDS.DIALOG_DECLINE)
    self:RevertChanges()
    SCENE_MANAGER:Hide("screenAdjust")
end

function ScreenAdjust:SetGrowthRate(value)
    self.growthRate = value
end

function ScreenAdjust:AddToGrowthRate(value)
    self.growthRate = self.growthRate + value
end

function ScreenAdjust:UpdateSize()
    local currentTimeMs = GetGameTimeMilliseconds()
    if self.lastFrameMs == nil then
        self.lastFrameMs = currentTimeMs
    end
    local MAX_TIME_MS = 100
    local deltaTimeMs = zo_min(currentTimeMs - self.lastFrameMs, MAX_TIME_MS)

    self.lastFrameMs = currentTimeMs

    local SCALE_RATE = 0.0001 -- fraction of root size per ms
    local xRate = SCALE_RATE * self.rootWidth
    local yRate = SCALE_RATE * self.rootHeight
    local dx = self.growthRate * deltaTimeMs * xRate
    local dy = self.growthRate * deltaTimeMs * yRate

    self:SetSize(self.width + dx, self.height + dy)
end

function ScreenAdjust:UpdateDirectionalInput()
    local dx, dy = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK)

    -- negative X direction is to make it larger
    dx = -dx

    -- make sure to make scaling uniform
    if zo_abs(dx) > zo_abs(dy) then
        self:SetGrowthRate(dx)
    else
        self:SetGrowthRate(dy)
    end
end

--Global XML
function ZO_ScreenAdjust_Handle_OnSave()
    if SCENE_MANAGER:IsShowing("screenAdjust") then
        SCREEN_ADJUST:Save()
    end
end

function ZO_ScreenAdjust_Handle_OnCancel()
    if SCENE_MANAGER:IsShowing("screenAdjust") then
        SCREEN_ADJUST:Cancel()
    end
end

function ZO_ScreenAdjust_SetGrowthRate(value)
    if SCENE_MANAGER:IsShowing("screenAdjust") then
        SCREEN_ADJUST:SetGrowthRate(value)
    end
end

function ZO_ScreenAdjust_AddToGrowthRate(value)
    if SCENE_MANAGER:IsShowing("screenAdjust") then
        SCREEN_ADJUST:AddToGrowthRate(value)
    end
end

function ZO_ScreenAdjust_OnInitialized(self)
    SCREEN_ADJUST = ScreenAdjust:New(self)
end
