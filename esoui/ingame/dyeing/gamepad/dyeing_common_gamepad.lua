ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_X = 3
ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_Y = 4

function ZO_Dyeing_Gamepad_Highlight(control, dyeControl)
    local sharedHighlight = control.highlight

    local selected = false
    if dyeControl then
        sharedHighlight:ClearAnchors()
        sharedHighlight:SetParent(dyeControl)
        sharedHighlight:SetAnchor(TOPLEFT, dyeControl, TOPLEFT, -ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_X, -ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_Y)
        sharedHighlight:SetAnchor(BOTTOMRIGHT, dyeControl, BOTTOMRIGHT, ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_X, ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_Y)
        selected = true
    end

    sharedHighlight:SetHidden(not selected)
end

-- A base radial menu with some customized behavior for the gamepad dyeing screen.
ZO_Dyeing_RadialMenu_Gamepad = ZO_RadialMenu:Subclass()
local DEFAULT_ROTATION_ANGLE = (2 * math.pi) * (3 / 5)
local FOCUS_ENTRY_SCALE = 1.3

function ZO_Dyeing_RadialMenu_Gamepad:New(control, template, sharedHighlight)
    local DISABLE_MOUSE = false
    local SELECT_IN_CENTER = true

    return ZO_RadialMenu.New(self, sharedHighlight, control, template, nil, nil, nil, {ZO_DI_LEFT_STICK}, DISABLE_MOUSE, SELECT_IN_CENTER)
end

function ZO_Dyeing_RadialMenu_Gamepad:Initialize(sharedHighlight, ...)
    ZO_RadialMenu.Initialize(self, ...)

    self.swatchInterpolator = ZO_SimpleControlScaleInterpolator:New(1.0, FOCUS_ENTRY_SCALE)
    self:ResetToDefaultPositon()
    self.currentlyActive = false
    self.controlsBySlot = {}
    self.isAllFocused = false
    self.previousSelectedControl = nil
    self:SetCustomControlSetUpFunction(function(control, data) data.setupFunc(control, data) end)
    self:SetActivateOnShow(false)
    self.sharedHighlight = sharedHighlight
    -- NOTE: This does not call self:SetOnSelectionChangedCallback as we want to bypass the custom behaviour.
    ZO_RadialMenu.SetOnSelectionChangedCallback(self, function(...) self:OnSelectionChanged(...) end)
end

function ZO_Dyeing_RadialMenu_Gamepad:ResetToDefaultPositon()
    local outerRadius = zo_max(self.control:GetDimensions()) * .5
    self.oldSelectionX = math.sin(DEFAULT_ROTATION_ANGLE) * outerRadius
    self.oldSelectionY = math.cos(DEFAULT_ROTATION_ANGLE) * outerRadius
end

function ZO_Dyeing_RadialMenu_Gamepad:FocusAll()
    if not self.isAllFocused then
        for entrySlot, control in pairs(self.controlsBySlot) do
            if control.shouldHighlight then
                self.swatchInterpolator:ScaleUp(control)
            end
        end
        self.isAllFocused = true
    end
end

function ZO_Dyeing_RadialMenu_Gamepad:DefocusAll()
    if self.isAllFocused then
        for entrySlot, control in pairs(self.controlsBySlot) do
            self.swatchInterpolator:ScaleDown(control)
        end
        self.isAllFocused = false
    end
end

function ZO_Dyeing_RadialMenu_Gamepad:HighlightAll(dyeSlot)
    for entrySlot, control in pairs(self.controlsBySlot) do
        ZO_Dyeing_Gamepad_Highlight(control, control.dyeControls[dyeSlot])
    end
end

function ZO_Dyeing_RadialMenu_Gamepad:OnSelectionChanged(entry)
    if self.previousSelectedControl ~= self.selectedControl then
        if self.previousSelectedControl then
            self.swatchInterpolator:ScaleDown(self.previousSelectedControl)
        end
        self.previousSelectedControl = self.selectedControl
        if self.selectedControl then
            self.swatchInterpolator:ScaleUp(self.selectedControl)
            if self.sharedHighlight then
                self.sharedHighlight:ClearAnchors()
                self.sharedHighlight:SetAnchor(CENTER, self.selectedControl, CENTER, 0, 0)
                self.sharedHighlight:SetHidden(false)
            end
        elseif self.sharedHighlight then
            self.sharedHighlight:SetHidden(true)
        end
    end

    if self.externalOnSelectionChangedCallback then
        self.externalOnSelectionChangedCallback(entry)
    end
end

function ZO_Dyeing_RadialMenu_Gamepad:SetOnSelectionChangedCallback(callback)
    self.externalOnSelectionChangedCallback = callback
end

local SUPPRESS_SOUND = true

function ZO_Dyeing_RadialMenu_Gamepad:Activate(...)
    ZO_RadialMenu.Activate(self, ...)
    if not self.currentlyActive then
        self.virtualMouseX = self.oldSelectionX
        self.virtualMouseY = self.oldSelectionY
        self.selectIfCentered = true
        self:UpdateSelectedEntryFromVirtualMousePosition(SUPPRESS_SOUND)
        self.currentlyActive = true
    end
end

function ZO_Dyeing_RadialMenu_Gamepad:Deactivate(...)
    if self.currentlyActive then
        self.oldSelectionX = self.virtualMouseX
        self.oldSelectionY = self.virtualMouseY
        self.selectIfCentered = false
        self.currentlyActive = false
    end
    ZO_RadialMenu.Deactivate(self, ...)
end

function ZO_Dyeing_RadialMenu_Gamepad:Show(...)
    ZO_RadialMenu.Show(self, ...)
    self:Populate()
end
