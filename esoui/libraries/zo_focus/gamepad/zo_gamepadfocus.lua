--[[
    Each entry can contain the following:
    local entry = 
    {
        control,                                            -- Control to focus on. Can be nil.
        data,                                               -- Data associated with the focus. Can be nil.
        highlight,                                          -- Highlight texture that is alpha'ed in and out via the highlightFadeAnimation when focus is lost/received.  Can be nil.
        highlightFadeAnimation,                             -- Animation to play on a highlight texture. If nil, and highlight exists, will create a FocusAlphaFadeAnimation connected to the highlight texture
        iconScaleAnimation,                                 -- Animation to play on an icon. If nil, and entry.control.icon exists, will create a FocusIconScaleAnimation connected to entry.control.icon. If false, no animation will be created or played.
        activate = function(control, data) blah() end,      -- Function that is called when focused is received.  If nil, defaults to control:Activate() if that function exists.
        deactivate = function(control, data) blah() end,    -- Function that is called when focused is lost.  If nil, defaults to control:Deactivate() if that function exists.
        canFocus = function(control) return true end,       -- Function that returns a boolean indicating whether the control can receive focus.  If nil, defaults to true.
    }
--]]

local FOCUS_MOVEMENT_TYPES = 
{
    MOVE_NEXT = 1,
    MOVE_PREVIOUS = 2,
}

local function GamepadListPlaySound(movementType)
    if movementType == FOCUS_MOVEMENT_TYPES.MOVE_NEXT then
        PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
    elseif movementType == FOCUS_MOVEMENT_TYPES.MOVE_PREVIOUS then
        PlaySound(SOUNDS.GAMEPAD_MENU_UP)
    end
end

ZO_GamepadFocus = ZO_Object:Subclass()

function ZO_GamepadFocus:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

--[[
    Initializes a GamepadFocus with an optional movementController or direction.

    If movementController is not nil, one will be created using direction. If direction
     is not specified, it will default to vertical.
]]
function ZO_GamepadFocus:Initialize(control, movementController, direction)
    self.data = {}
    self.control = control
    self.index = nil
    self.savedIndex = nil
    self:InitializeMovementController(movementController, direction)
    self:SetActive(false)
    self:SetPlaySoundFunction(GamepadListPlaySound)

    self.directionalInputEnabled = true
end

function ZO_GamepadFocus:InitializeMovementController(movementController, direction)
    self.movementController = movementController or ZO_MovementController:New(direction or MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
end

function ZO_GamepadFocus:SetActive(active, retainFocus)
    if self.active ~= active then
        self.active = active

        if self.active then
            self:SetFocusByIndex(self.savedIndex ~= 0 and self.savedIndex or 1)
            if self.directionalInputEnabled then
                DIRECTIONAL_INPUT:Activate(self, self.control)
            end
        else
            self.savedIndex = self.index
            if not retainFocus then
                self:ClearFocus()
            end
            DIRECTIONAL_INPUT:Deactivate(self)
        end
    end
end

function ZO_GamepadFocus:IsActive()
    return self.active
end

function ZO_GamepadFocus:SetFocusChangedCallback(onFocusChangedFunction)
    self.onFocusChangedFunction = onFocusChangedFunction
end

function ZO_GamepadFocus:SetLeaveFocusAtBeginningCallback(onLeaveFocusAtBeginningFunction)
    self.onLeaveFocusAtBeginningFunction = onLeaveFocusAtBeginningFunction
end

function ZO_GamepadFocus:Activate(retainFocus)
    self:SetActive(true, retainFocus)
end

function ZO_GamepadFocus:Deactivate(retainFocus)
    self:SetActive(false, retainFocus)
end

function ZO_GamepadFocus:AddEntry(entry)
    table.insert(self.data, entry)

    if not entry.highlightFadeAnimation and entry.highlight then
        entry.highlightFadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("FocusAlphaFadeAnimation", entry.highlight)
    end
    if entry.control and entry.control.icon and entry.iconScaleAnimation == nil then
        entry.iconScaleAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("FocusIconScaleAnimation", entry.control.icon)
    end

    if entry.highlightFadeAnimation then
        if entry.highlight then
            entry.highlight:SetHidden(false)
        end
        entry.highlightFadeAnimation:PlayInstantlyToStart()
    end
    if entry.iconScaleAnimation then
        entry.iconScaleAnimation:PlayInstantlyToStart()
    end
end

local function DefaultEqualityFunction(item, value)
    return value.control == item
end

function ZO_GamepadFocus:RemoveMatchingEntries(compareItem, equalityFunction)
    if not equalityFunction then
        equalityFunction = DefaultEqualityFunction
    end

    local focus = self:GetFocus()
    local shouldUpdateFocus = false
    for k, v in ipairs(self.data) do
        if equalityFunction(compareItem, v) then
            if focus and k <= focus then
                self:ClearFocus()
                shouldUpdateFocus = true
                -- k == focus is a special case
                if k < focus then
                    focus = focus - 1
                end
            end
            table.remove(self.data, k)
        end
    end
    if shouldUpdateFocus then
        self:SetFocusByIndex(zo_clamp(focus, 1, #self.data))
    end
end

function ZO_GamepadFocus:RemoveAllEntries()
    self:ClearFocus()

    for k in ipairs(self.data) do
        self.data[k] = nil
    end

    self.savedIndex = nil
end

local function EnableFocus(data, index)
    if index and #data > 0 and index <= #data then
        local item = data[index]
        if item.activate then
            item.activate(item.control, item.data)
        elseif item.control and (item.control.Activate ~= nil) then
            item.control:Activate()
        end

        if item.highlightFadeAnimation then
            item.highlightFadeAnimation:PlayForward()
        end
        if item.iconScaleAnimation then
            item.iconScaleAnimation:PlayForward()
        end

        return true
    end
end

local function DisableFocus(data, index)
    if index and #data > 0 and (index <= #data) then
        local item = data[index]
        if item.deactivate then
            item.deactivate(item.control, item.data)
        elseif item.control and (item.control.Deactivate ~= nil) then
            item.control:Deactivate()
        end

        if item.highlightFadeAnimation then
            item.highlightFadeAnimation:PlayBackward()
        end
        if item.iconScaleAnimation then
            item.iconScaleAnimation:PlayBackward()
        end

        return true
    end
end

function ZO_GamepadFocus:GetFocusItem(includeSavedFocus)
    local focusIndex = self:GetFocus(includeSavedFocus)
    return self:GetItem(focusIndex)
end

function ZO_GamepadFocus:GetItem(index)
    if index then
        return self.data[index]
    end
    return nil
end

function ZO_GamepadFocus:GetItemCount()
    return #self.data
end

function ZO_GamepadFocus:IsFocused(control)
    local isControlFocused = false

    local focusItem = self:GetFocusItem()
    if focusItem and focusItem.control and focusItem.control == control then
        isControlFocused = true
    end

    return isControlFocused
end

function ZO_GamepadFocus:SetFocusToMatchingEntry(compareItem, equalityFunction)
    local didSetFocus
    if not equalityFunction then
        equalityFunction = DefaultEqualityFunction
    end

    local focus = self:GetFocus()
    local shouldUpdateFocus = false
    for k, v in ipairs(self.data) do
        if equalityFunction(compareItem, v) then
            self:SetFocusByIndex(k)
            didSetFocus = true
            break
        end
    end
    return didSetFocus
end

function ZO_GamepadFocus:SetFocusToFirstEntry(setIfInactive)
    self:SetFocusByIndex(1, setIfInactive)
end

function ZO_GamepadFocus:SetFocusByIndex(newIndex, setIfInactive)
    if self.index then
        local oldIndex = self.index
        self.index = nil -- Set to nil before calling DisableFocus() to guard against recursion.
        DisableFocus(self.data, oldIndex)
    end

    -- DisableFocus() could have triggered a SetFocus(), so we need to check whether self.index is nil before enabling focus again.
    if newIndex and not self.index then
        if (not setIfInactive) and (not self.active) then
            self.savedIndex = newIndex
        elseif EnableFocus(self.data, newIndex) then
            -- EnableFocus() could have triggered a SetFocus, so we need to check self.index again.
            if not self.index then
                self.index = newIndex
                self.savedIndex = newIndex -- Needed if setIfInactive so that activate "restores" focus properly.
            end
        end
    end

    if self.onFocusChangedFunction then
        self.onFocusChangedFunction(self:GetFocusItem())
    end
end

function ZO_GamepadFocus:SetSelectedIndex(newIndex, setIfInactive)
    self:SetFocusByIndex(newIndex, setIfInactive)
end

function ZO_GamepadFocus:GetFocus(includeSavedFocus)
    if self.active then
        return self.index
    elseif includeSavedFocus then
        return self.savedIndex
    end
end

function ZO_GamepadFocus:ClearFocus()
    self:SetFocusByIndex(nil)
end

local function FindPrevFocusIndex(oldIndex, focusItems)
    if not oldIndex then
        return nil
    end

    local newIndex = oldIndex - 1
    while newIndex >= 1 do
        local data = focusItems[newIndex]
        if not data.canFocus or data.canFocus(data.control) then
            return newIndex
        end
        newIndex = newIndex - 1
    end
end

local function FindNextFocusIndex(oldIndex, focusItems)
    if not oldIndex then
        return nil
    end

    local newIndex = oldIndex + 1
    while newIndex <= #focusItems do
        local data = focusItems[newIndex]
        if not data.canFocus or data.canFocus(data.control) then
            return newIndex
        end
        newIndex = newIndex + 1
    end
end

function ZO_GamepadFocus:MovePrevious()
    local index = FindPrevFocusIndex(self.index, self.data)
    if index then
        self:SetFocusByIndex(index)
        self.onPlaySoundFunction(FOCUS_MOVEMENT_TYPES.MOVE_PREVIOUS)
    else
        if self.onLeaveFocusAtBeginningFunction then
            self.onLeaveFocusAtBeginningFunction()
        end
    end
end

function ZO_GamepadFocus:MoveNext()
    local index = FindNextFocusIndex(self.index, self.data)
    if index then
        self:SetFocusByIndex(index)
        self.onPlaySoundFunction(FOCUS_MOVEMENT_TYPES.MOVE_NEXT)
    end
end
 
function ZO_GamepadFocus:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self:MoveNext()
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self:MovePrevious()
    end
end

function ZO_GamepadFocus:SetPlaySoundFunction(fn)
    self.onPlaySoundFunction = fn
end

function ZO_GamepadFocus:SetDirectionalInputEnabled(enabled)
    self.directionalInputEnabled = enabled
    if enabled then
        DIRECTIONAL_INPUT:Activate(self, self.control)
    else
        DIRECTIONAL_INPUT:Deactivate(self)
    end
end