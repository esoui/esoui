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

function ZO_RadialMenu:Initialize(control, entryTemplate, animationTemplate, entryAnimationTemplate, actionLayerName, directionInputs, enableMouse, selectIfCentered)
    self.control = control

    self.selectedBackground = control:GetNamedChild("SelectedBackground")
    self.unselectedBackground = control:GetNamedChild("UnselectedBackground")
    self.actionLabel = control:GetNamedChild("Action")
    self.directionInputs = directionInputs or DEFAULT_DIRECTIONAL_INPUTS
    self.enableMouse = (enableMouse ~= false) -- nil should be true.
    self.selectIfCentered = (selectIfCentered ~= false) -- nil should be true.
    self.activateOnShow = true

    self.control:SetHandler("OnUpdate", function() self:OnUpdate() end)

    local function ResetEntryControl(entryControl)
        entryControl:SetHidden(true)
        entryControl:ClearAnchors()
        if entryControl.animation then
            entryControl.animation:PlayBackward()
        end
    end
    
    local function CreateEntryControl(objectPool)
        local entryControl = ZO_ObjectPool_CreateNamedControl(control:GetName() .. entryTemplate, entryTemplate, objectPool, control)
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

do
    local atan2 = math.atan2
    local ROTATION_OFFSET = 3 * math.pi / 2

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

do
    local TWO_PI = math.pi * 2

    function ZO_RadialMenu:PerformLayout()
        local width, height = self.control:GetDimensions()
        local halfWidth, halfHeight = width / 2 / self.control:GetScale(), height / 2 / self.control:GetScale()
        local numEntries = #self.entries
        local halfSliceSize = TWO_PI / numEntries / 2

        self.entryPool:ReleaseAllObjects()

        local initialRotation = #self.entries == 2 and math.pi / 2 or 0

        -- For this circle, 0 rotation points straight down from the circle's center and rotation is in CCW direction.
        for i, entry in ipairs(self.entries) do
            local centerAngle = initialRotation + i / numEntries * TWO_PI
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

            entryControl.startX = math.sin(centerAngle - halfSliceSize)
            entryControl.startY = math.cos(centerAngle - halfSliceSize)

            entryControl.endX = math.sin(centerAngle + halfSliceSize)
            entryControl.endY = math.cos(centerAngle + halfSliceSize)

            entryControl.entry = entry
            entry.control = entryControl
        end
    end
end

-- name can be either a text string or a table containing the text in the first entry, and a color table in the second entry
-- e.g.
--      Passing "Test" in name will just set the label to "Test" in white
--      Passing {"Test", {r = 1, g = 0, b = 0}} will set the label to "Test" in the color red

function ZO_RadialMenu:AddEntry(name, inactiveIcon, activeIcon, callback, data)
    self.entries[#self.entries + 1] = { name = name, inactiveIcon = inactiveIcon, activeIcon = activeIcon, callback = callback, data = data }
end

function ZO_RadialMenu:UpdateEntry(name, inactiveIcon, activeIcon, callback, data)
    for i = 1, #self.entries do
        if self.entries[i].name == name then
            self.entries[i].inactiveIcon = inactiveIcon
            self.entries[i].activeIcon= activeIcon
            self.entries[i].callback= callback
            self.entries[i].data = data
        end
    end

    self:Refresh()
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
    self.selectedEntry = nil
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
        RemoveActionLayerByName(self.actionLayerName)
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
        PushActionLayerByName(self.actionLayerName)
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