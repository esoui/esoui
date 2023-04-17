-- Ordinal indices are mapped beginning from the entry positioned nearest to this angle in either direction.
--   0 deg = bottom-most entry
--  90 deg = left-most entry
-- 180 deg = top-most entry
-- 270 deg = right-most entry
-- Note that preference can be given to the entry slightly to the left or right of an exact angle;
-- For example, 179 degrees would give preference to the right, top-most entry when there are an
-- odd number of entries in the radial menu.
ZO_RADIAL_MENU_PREFERRED_ORDINAL_STARTING_ANGLE_RADIANS = math.rad(179)

-- The rotational direction in which ordinal indices increment.
--  -1 = Clockwise
--   1 = Counter-clockwise
ZO_RADIAL_MENU_ORDINAL_DIRECTION = -1

ZO_RadialMenu = ZO_Object:Subclass()

function ZO_RadialMenu:New(...)
    local radialMenu = ZO_Object.New(self)
    radialMenu:Initialize(...)
    return radialMenu
end

local g_activeMenu = nil
local MIN_DISTANCE = 10 -- The distance the mouse has to move before we start selecting anything
local DEFAULT_DIRECTIONAL_INPUTS = {ZO_DI_LEFT_STICK, ZO_DI_RIGHT_STICK}

function ZO_RadialMenu.ForceActiveMenuClosed()
    if g_activeMenu then
        g_activeMenu:Clear()
    end
end

function ZO_RadialMenu:Initialize(control, entryTemplate, animationTemplate, entryAnimationTemplate, actionLayerName, directionInputs, enableMouse, selectIfCentered, showKeybinds)
    self.control = control

    self.selectedBackground = control:GetNamedChild("SelectedBackground")
    self.unselectedBackground = control:GetNamedChild("UnselectedBackground")
    self.actionLabel = control:GetNamedChild("Action")
    self.directionInputs = directionInputs or DEFAULT_DIRECTIONAL_INPUTS
    self.enableMouse = (enableMouse ~= false) -- nil should be true.
    self.selectIfCentered = (selectIfCentered ~= false) -- nil should be true.
    self.activateOnShow = true
    self.showKeybinds = showKeybinds

    self.control:SetHandler("OnUpdate", function() self:OnUpdate() end)

    local function ResetEntryControl(entryControl)
        entryControl:SetHidden(true)
        entryControl:ClearAnchors()
        if entryControl.animation then
            entryControl.animation:PlayBackward()
        end

        if entryControl.keybindLabel then
            ZO_Keybindings_UnregisterLabelForBindingUpdate(entryControl.keybindLabel)
            entryControl.keybindLabel:SetHidden(true)
        end
    end
    
    local function CreateEntryControl(objectPool)
        local entryControl = ZO_ObjectPool_CreateNamedControl(control:GetName() .. "Entry", entryTemplate, objectPool, control)
        entryControl.icon = entryControl:GetNamedChild("Icon")
        if entryAnimationTemplate then
            entryControl.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual(entryAnimationTemplate, entryControl)
        end
        return entryControl
    end

    self.entryPool = ZO_ObjectPool:New(CreateEntryControl, ResetEntryControl)
    self.entries = {}

    if animationTemplate then
        self.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual(animationTemplate, control)
        self.animation:SetHandler("OnStop", function() self:OnAnimationStopped() end)
    end

    self.actionLayerName = actionLayerName

    self:Clear()
end

function ZO_RadialMenu:SetActivateOnShow(activateOnShow)
    self.activateOnShow = activateOnShow
end

function ZO_RadialMenu:SetOnClearCallback(callback)
    self.onClearCallback = callback
end

function ZO_RadialMenu:SetOnSelectionChangedCallback(callback)
    self.onSelectionChangedCallback = callback
end

function ZO_RadialMenu:SetCustomControlSetUpFunction(setupFunction)
    self.setupFunction = setupFunction
end

function ZO_RadialMenu:SelectCurrentEntry()
    if self:IsShown() and self.selectedEntry and self.selectedEntry.callback and (not self.animation or not self.animation:IsPlayingBackward()) then
        self.selectedEntry.callback(self)
        self:Clear(true)
    else
        self:Clear()
    end
end

local function Dot(x1, y1, x2, y2)
    return x1 * x2 + y1 * y2
end

local function SetupActionLabel(actionLabel, textData)
    if actionLabel then
        if textData then
            actionLabel:SetHidden(false)

            if type(textData) == "table"
            then
                actionLabel:SetText(textData[1])
                actionLabel:SetColor(textData[2].r, textData[2].g, textData[2].b, 1)
            else
                actionLabel:SetText(textData)
                actionLabel:SetColor(1, 1, 1, 1)
            end
        else
            actionLabel:SetHidden(true)
        end
    end
end

function ZO_RadialMenu:FindSelectedEntry(x, y, suppressSound)
    local shouldSelect = true

    if not self.selectIfCentered then
        local lenSquared = Dot(self.virtualMouseX, self.virtualMouseY, self.virtualMouseX, self.virtualMouseY)
        local outerRadius = zo_max(self.control:GetDimensions()) * .5
        local innerRadius = zo_max(outerRadius * .35, MIN_DISTANCE + 1)
        if lenSquared < innerRadius * innerRadius then
            shouldSelect = false
            self.selectedEntry = nil
            self.selectedControl = nil
            if self.onSelectionChangedCallback then
                self.onSelectionChangedCallback(nil)
            end
        end
    end

    for key, entryControl in pairs(self.entryPool:GetActiveObjects()) do   
        if shouldSelect and Dot(x, y, -entryControl.startY, entryControl.startX) < 0 and Dot(x, y, -entryControl.endY, entryControl.endX) > 0 then
            if self.selectedEntry ~= entryControl.entry then
                self.selectedEntry = entryControl.entry
                self.selectedControl = entryControl
                if not suppressSound then
                    PlaySound(SOUNDS.RADIAL_MENU_MOUSEOVER)
                end
                if self.onSelectionChangedCallback then
                    self.onSelectionChangedCallback(self.selectedEntry)
                end
            end

            SetupActionLabel(self.actionLabel, self.selectedEntry.name)

            if entryControl.icon then
                entryControl.icon:SetTexture(self.selectedEntry.activeIcon)
            end
            if entryControl.animation then
                entryControl.animation:PlayForward()
            end
        else
            if entryControl.icon then
                entryControl.icon:SetTexture(entryControl.entry.inactiveIcon)
            end
            if entryControl.animation then
                entryControl.animation:PlayBackward()
            end
        end
    end
end

do
    local MIN_DISTANCE_SQUARED = MIN_DISTANCE * MIN_DISTANCE

    function ZO_RadialMenu:ShouldUpdateSelection()
        local lenSquared = Dot(self.virtualMouseX, self.virtualMouseY, self.virtualMouseX, self.virtualMouseY)

        if not self.selectedEntry and lenSquared < MIN_DISTANCE_SQUARED then
            return false
        end

        local outerRadius = zo_max(self.control:GetDimensions()) * .5
        if lenSquared > outerRadius * outerRadius then
            local len = zo_sqrt(lenSquared)
            self.virtualMouseX = self.virtualMouseX / len * outerRadius
            self.virtualMouseY = self.virtualMouseY / len * outerRadius
        elseif self.selectIfCentered then
            local innerRadius = zo_max(outerRadius * .35, MIN_DISTANCE + 1)
            if lenSquared < innerRadius * innerRadius then
                return false --don't update the selection while we're in the inner radius
            end
        end

        return true
    end

    function ZO_RadialMenu:UpdateVirtualMousePosition()
        if self.enableMouse then
            local deltaX, deltaY = GetUIMouseDeltas()
            if deltaX ~= 0 or deltaY ~= 0 then
                self.virtualMouseX = self.virtualMouseX + deltaX
                self.virtualMouseY = self.virtualMouseY + deltaY

                return self:ShouldUpdateSelection()
            end
        end
        return false
    end

    function ZO_RadialMenu:UpdateVirtualMousePositionFromGamepad()
        local outerRadius = zo_max(self.control:GetDimensions()) * .5
        local x, y = DIRECTIONAL_INPUT:GetXY(unpack(self.directionInputs))
        if (not self.selectIfCentered) or (x ~= 0) or (y ~= 0) then
            self.virtualMouseX = x * outerRadius
            self.virtualMouseY = -y * outerRadius
            
            return self:ShouldUpdateSelection()
        end
        return false
    end   
end

function ZO_RadialMenu:SetOnUpdateRotationFunction(rotationFunc)
    self.onUpdateRotationFunc = rotationFunc
end

function ZO_RadialMenu:SetShowKeybinds(showKeybinds)
    self.showKeybinds = showKeybinds
end

--Specifies an action layer to push specifically when showing the keybinds on the wheel
function ZO_RadialMenu:SetKeybindActionLayer(keybindActionLayer)
    self.keybindActionLayer = keybindActionLayer
end

function ZO_RadialMenu:ShouldShowKeybinds()
    if type(self.showKeybinds) == "function" then
        return self.showKeybinds()
    else
        return self.showKeybinds
    end
end

do
    local atan2 = math.atan2
    local ROTATION_OFFSET = 3 * ZO_HALF_PI

    function ZO_RadialMenu:UpdateSelectedEntryFromVirtualMousePosition(suppressSound)
        self:FindSelectedEntry(self.virtualMouseX, self.virtualMouseY, suppressSound)
        local hasSelection = (self.selectedEntry ~= nil)
        local rotation = atan2(-self.virtualMouseY, self.virtualMouseX) + ROTATION_OFFSET
        if self.selectedBackground then
            self.selectedBackground:SetHidden(not hasSelection)
            self.selectedBackground:SetTextureRotation(rotation)
        end
        if self.unselectedBackground then
            self.unselectedBackground:SetHidden(hasSelection)
        end
        if self.onUpdateRotationFunc then
            self.onUpdateRotationFunc(rotation)
        end
    end

    function ZO_RadialMenu:OnUpdate()
        if not IsInGamepadPreferredMode() then
            if self:UpdateVirtualMousePosition() then
                self:UpdateSelectedEntryFromVirtualMousePosition()
            end
        end
    end
    
    function ZO_RadialMenu:UpdateDirectionalInput()
        if self:UpdateVirtualMousePositionFromGamepad() then
            self:UpdateSelectedEntryFromVirtualMousePosition()
        end
    end
end

-- Returns the angle (radians) alloted per Entry and
-- the starting Entry's offset angle (radians).
function ZO_RadialMenu:GetArcAnglePerEntryAndStartingOffsetAngle()
    local numEntries = #self.entries
    if numEntries == 0 then
        return 0, 0
    end

    local arcAnglePerEntryRadians = ZO_TWO_PI / numEntries
    local startingOffsetAngleRadians = (numEntries == 2 and ZO_HALF_PI or 0) + arcAnglePerEntryRadians
    return arcAnglePerEntryRadians, startingOffsetAngleRadians
end

-- Returns the Entry at the ordinal position [1..n] beginning with the entry nearest to
-- ZO_RADIAL_MENU_PREFERRED_ORDINAL_STARTING_ANGLE_RADIANS and progressing clockwise or
-- counter-clockwise as defined by ZO_RADIAL_MENU_ORDINAL_DIRECTION.
function ZO_RadialMenu:GetOrdinalEntry(ordinalIndex)
    local numEntries = #self.entries
    if ordinalIndex > numEntries then
        -- Invalid ordinal index and/or no entries exist.
        return nil
    end

    -- Determine the shortest arc distance between the positional angle
    -- of the first entry and the preferred starting ordinal angle.
    local arcAnglePerEntryRadians, startingOffsetAngleRadians = self:GetArcAnglePerEntryAndStartingOffsetAngle()
    local preferredStartingAngleDistanceRadians = (ZO_RADIAL_MENU_PREFERRED_ORDINAL_STARTING_ANGLE_RADIANS - startingOffsetAngleRadians) % ZO_TWO_PI

    -- Determine the entry index offset of the starting ordinal index.
    local startingOrdinalEntryIndexOffset = zo_round(preferredStartingAngleDistanceRadians / arcAnglePerEntryRadians)

    -- Determine the final entry index associated with the requested ordinal
    -- index and clamp within the range [1..n] for n entries.
    local ordinalEntryIndex = startingOrdinalEntryIndexOffset + ((ordinalIndex - 1) * ZO_RADIAL_MENU_ORDINAL_DIRECTION)
    ordinalEntryIndex = (ordinalEntryIndex % numEntries) + 1

    return self.entries[ordinalEntryIndex]
end

-- Returns an iterator that iterates over each Entry in the ordinal
-- order defined by ZO_RadialMenu:GetOrdinalEntry.
function ZO_RadialMenu:OrdinalEntryIterator()
    local ordinalIndex = 0
    return function()
        ordinalIndex = ordinalIndex + 1
        local entry = self:GetOrdinalEntry(ordinalIndex)
        if entry then
            return ordinalIndex, entry
        end
        return nil, nil
    end
end

-- Invokes callbackFunction once for each Entry in the ordinal
-- order defined by ZO_RadialMenu:GetOrdinalEntry.
function ZO_RadialMenu:ForEachOrdinalEntry(callbackFunction)
    for ordinalIndex, entry in self:OrdinalEntryIterator() do
        callbackFunction(ordinalIndex, entry)
    end
end

function ZO_RadialMenu:PerformLayout()
    local width, height = self.control:GetDimensions()
    local halfWidth, halfHeight = width / 2 / self.control:GetScale(), height / 2 / self.control:GetScale()
    local arcAnglePerEntryRadians, initialRotation = self:GetArcAnglePerEntryAndStartingOffsetAngle()
    local halfArcAnglePerEntryRadians = arcAnglePerEntryRadians * 0.5

    self.entryPool:ReleaseAllObjects()

    -- For this circle, 0 rotation points straight down from the circle's center and rotation is in CCW direction.
    for i, entry in ipairs(self.entries) do
        local centerAngle = initialRotation + (i - 1) * arcAnglePerEntryRadians
        local x = math.sin(centerAngle)
        local y = math.cos(centerAngle)

        --- math.sin is returning very small numbers instead of 0 for PI and TWO_PI
        if math.abs(x) < 0.01 then
            x = 0
        end

        local entryControl = self.entryPool:AcquireObject()
        if entryControl.icon then
            entryControl.icon:SetTexture(entry.inactiveIcon)

            if entryControl.label then
                entryControl.label:ClearAnchors()
                if x > 0 then
                    entryControl.label:SetAnchor(LEFT, entryControl.icon, RIGHT, 15, 0)
                elseif x < 0 then
                    entryControl.label:SetAnchor(RIGHT, entryControl.icon, LEFT, -15, 0)
                elseif y > 0 then        
                    entryControl.label:SetAnchor(TOP, entryControl.icon, BOTTOM, 0, 0)
                else
                    entryControl.label:SetAnchor(BOTTOM, entryControl.icon, TOP, 0, -5)
                end
            end
        end

        if self.setupFunction then
            self.setupFunction(entryControl, entry.data)
        end

        entryControl:SetAnchor(CENTER, nil, CENTER, x * halfWidth, y * halfHeight)
        entryControl:SetHidden(false)

        entryControl.startX = math.sin(centerAngle - halfArcAnglePerEntryRadians)
        entryControl.startY = math.cos(centerAngle - halfArcAnglePerEntryRadians)

        entryControl.centerX = x
        entryControl.centerY = y

        entryControl.endX = math.sin(centerAngle + halfArcAnglePerEntryRadians)
        entryControl.endY = math.cos(centerAngle + halfArcAnglePerEntryRadians)

        entryControl.entry = entry
        entry.control = entryControl
    end

    --If we're showing keybinds, do the layout for those now
    --We need to do this *after* the rest of the layout has been completed so we can correctly calculate the ordinal indices
    if self:ShouldShowKeybinds() then
        self:LayoutOrdinalKeybinds()
    end
end

do
    local function LayoutOrdinalKeybind(ordinalIndex, entry)
        local control = entry.control
        if control and control.keybindLabel then
            ZO_Keybindings_RegisterLabelForBindingUpdate(control.keybindLabel, ZO_GetRadialMenuActionNameForOrdinalIndex(ordinalIndex))
            control.keybindLabel:SetHidden(false)
        end
    end

    function ZO_RadialMenu:LayoutOrdinalKeybinds()
        self:ForEachOrdinalEntry(LayoutOrdinalKeybind)
    end
end

-- name can be either a text string or a table containing the text in the first entry, and a color table in the second entry
-- e.g.
--      Passing "Test" in name will just set the label to "Test" in white
--      Passing {"Test", {r = 1, g = 0, b = 0}} will set the label to "Test" in the color red

function ZO_RadialMenu:AddEntry(name, inactiveIcon, activeIcon, callback, data)
    self.entries[#self.entries + 1] = { name = name, inactiveIcon = inactiveIcon, activeIcon = activeIcon, callback = callback, data = data }
end

function ZO_RadialMenu:UpdateEntriesByName(name, inactiveIcon, activeIcon, callback, data)
    for i, entry in ipairs(self.entries) do
        if self.entries[i].name == name then
            self.entries[i].inactiveIcon = inactiveIcon
            self.entries[i].activeIcon = activeIcon
            self.entries[i].callback = callback
            self.entries[i].data = data
        end
    end

    self:Refresh()
end

function ZO_RadialMenu:UpdateFirstEntryByFilter(filterFunction, name, inactiveIcon, activeIcon, callback, data)
    for i, entry in ipairs(self.entries) do
        if filterFunction(entry) then
            self.entries[i].name = name
            self.entries[i].inactiveIcon = inactiveIcon
            self.entries[i].activeIcon = activeIcon
            self.entries[i].callback = callback
            self.entries[i].data = data
            break
        end
    end

    self:Refresh()
end

function ZO_RadialMenu:SelectFirstEntryByFilter(filterFunction)
    for i, entry in ipairs(self.entries) do
        if filterFunction(entry) then
            --Set the virtual mouse position to the center of the control we are trying to select
            self.virtualMouseX = entry.control.centerX
            self.virtualMouseY = entry.control.centerY
            self:UpdateSelectedEntryFromVirtualMousePosition()
            return true
        end
    end

    return false
end

function ZO_RadialMenu:SelectOrdinalEntry(ordinalIndex)
    local entry = self:GetOrdinalEntry(ordinalIndex)
    if entry then
        --Set the virtual mouse position to the center of the control we are trying to select
        self.virtualMouseX = entry.control.centerX
        self.virtualMouseY = entry.control.centerY
        self:UpdateSelectedEntryFromVirtualMousePosition()
        return true
    end

    return false
end

function ZO_RadialMenu:OnAnimationStopped()
    if self.animation:IsPlayingBackward() then
        self:FinalizeClear()
    end
end

function ZO_RadialMenu:Clear(entrySelected)
    ZO_ClearNumericallyIndexedTable(self.entries)

    if not self.control:IsHidden() then
        if entrySelected then
            PlaySound(SOUNDS.RADIAL_MENU_SELECTION)
        else
            PlaySound(SOUNDS.RADIAL_MENU_CLOSE)
        end

        if self.animation then
            self.animation:PlayBackward()
        else
            self:FinalizeClear()
        end
    end
end

function ZO_RadialMenu:Activate()
    DIRECTIONAL_INPUT:Activate(self, self.control)
end

function ZO_RadialMenu:Deactivate()
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_RadialMenu:ClearSelection()
    self.virtualMouseX = 0
    self.virtualMouseY = 0
    if self.selectedEntry ~= nil then
        self.selectedEntry = nil
        if self.onSelectionChangedCallback then
            self.onSelectionChangedCallback(nil)
        end
    end
    self:UpdateSelectedEntryFromVirtualMousePosition()
end

function ZO_RadialMenu:FinalizeClear()
    if g_activeMenu == self then
        g_activeMenu = nil
    end
    self.entryPool:ReleaseAllObjects()
    self.control:SetHidden(true)
    if self.actionLabel then
        self.actionLabel:SetHidden(true)
    end
    if self.selectedBackground then
        self.selectedBackground:SetHidden(true)
    end
    if self.unselectedBackground then
        self.unselectedBackground:SetHidden(false)
    end
    
    if self.onClearCallback and (not self.animation or not self.animation:IsPlaying()) then
        self.onClearCallback(self)
    end

    if self.actionLayerName then
        if type(self.actionLayerName) == "table" then
            for _, actionLayer in pairs(self.actionLayerName) do
                RemoveActionLayerByName(actionLayer)
            end
        else
            RemoveActionLayerByName(self.actionLayerName)
        end
    end

    if self:ShouldShowKeybinds() and self.keybindActionLayer then
        RemoveActionLayerByName(self.keybindActionLayer)
    end

    self:ClearSelection()
    self:Deactivate()
end

function ZO_RadialMenu:Show(suppressSound)
    if g_activeMenu then
        g_activeMenu:FinalizeClear()
    end
    g_activeMenu = self

    self:ClearSelection()

    if self.control:IsHidden() and not suppressSound then
        PlaySound(SOUNDS.RADIAL_MENU_OPEN)
    end

    self.control:SetHidden(false)

    if self.animation then
        self.animation:PlayForward()
    end
    self:PerformLayout()
    if self.actionLayerName then
        if type(self.actionLayerName) == "table" then
            for _, actionLayer in pairs(self.actionLayerName) do
                PushActionLayerByName(actionLayer)
            end
        else
            PushActionLayerByName(self.actionLayerName)
        end
    end

    if self:ShouldShowKeybinds() and self.keybindActionLayer then
        PushActionLayerByName(self.keybindActionLayer)
    end

    if self.activateOnShow then
        self:Activate()
    end
end

--Helper functions added to clear and refresh the menu while it is still showing
function ZO_RadialMenu:ResetData()
    ZO_ClearNumericallyIndexedTable(self.entries)
    self.entryPool:ReleaseAllObjects()
end

function ZO_RadialMenu:Refresh()
    self:ClearSelection()
    self:PerformLayout()
end

function ZO_RadialMenu:IsShown()
    return not self.control:IsControlHidden()
end

function ZO_RadialMenu:GetEntries()
    return self.entries
end

--Helper function that gets the corresponding action name for a given ordinal index
function ZO_GetRadialMenuActionNameForOrdinalIndex(ordinalIndex)
    internalassert(ordinalIndex <= 10, "Invalid ordinal index")
    internalassert(ZO_IsIngameUI(), "Radial menu action hotkeys do not exist in this GUI")
    return "ACCESSIBLE_WHEEL_HOTKEY_SLOT_" .. ordinalIndex
end

--Helper function that gets whether or not togglable wheels are enabled
function ZO_AreTogglableWheelsEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_ACCESSIBLE_QUICKWHEELS)
end