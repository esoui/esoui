------------------------
-- MultiFocusArea Base --
------------------------

ZO_GamepadMultiFocusArea_Base = ZO_Object:Subclass()

function ZO_GamepadMultiFocusArea_Base:New(...)
    local focus = ZO_Object.New(self)
    focus:Initialize(...)
    return focus
end

function ZO_GamepadMultiFocusArea_Base:Initialize(manager, activateCallback, deactivateCallback)
    self.manager = manager
    self.activateCallback = activateCallback
    self.deactivateCallback = deactivateCallback
end

function ZO_GamepadMultiFocusArea_Base:SetupSiblings(previous, next)
    self:SetPreviousSibling(previous)
    self:SetNextSibling(next)
end

function ZO_GamepadMultiFocusArea_Base:SetPreviousSibling(previous)
    self.previousFocus = previous
end

function ZO_GamepadMultiFocusArea_Base:SetNextSibling(next)
    self.nextFocus = next
end

function ZO_GamepadMultiFocusArea_Base:SetKeybindDescriptor(keybindDescriptor)
    if self.active and self.keybindDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindDescriptor)
    end

    self.keybindDescriptor = keybindDescriptor

    -- If set active before keybindDescriptor was set, add keybindDescriptor to the keybind strip
    if self.active and self.keybindDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindDescriptor)
    end
end

function ZO_GamepadMultiFocusArea_Base:AppendKeybind(keybind)
    self.keybindDescriptor[#self.keybindDescriptor + 1] = keybind
end

function ZO_GamepadMultiFocusArea_Base:UpdateKeybinds()
    if self.keybindDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindDescriptor)
    end
end

function ZO_GamepadMultiFocusArea_Base:Activate()
    if not self.active then
        self.active = true

        if self.activateCallback then
            self.activateCallback()
        end

        if self.keybindDescriptor then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindDescriptor)
        end
    end
end

function ZO_GamepadMultiFocusArea_Base:Deactivate()
    if self.active then
        self.active = false

        if self.keybindDescriptor then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindDescriptor)
        end

        if self.deactivateCallback then
            self.deactivateCallback()
        end
    end
end

function ZO_GamepadMultiFocusArea_Base:HandleMovement(horizontalResult, verticalResult)
    return false -- override in derived classes if desired
end

function ZO_GamepadMultiFocusArea_Base:HandleMovementInternal(horizontalResult, verticalResult)
    local consumed = false
    if verticalResult == MOVEMENT_CONTROLLER_MOVE_NEXT then
        consumed = self:HandleMoveNext()
    elseif verticalResult == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        consumed = self:HandleMovePrevious()
    end

    if not consumed then
        consumed = self:HandleMovement(horizontalResult, verticalResult)
    end

    return consumed
end

function ZO_GamepadMultiFocusArea_Base:HandleMovePrevious()
	local consumed = false
    local selectableFocus = self.manager:GetPreviousSelectableFocusArea(self)
    if selectableFocus then
        self.manager:SelectFocusArea(selectableFocus)
        consumed = true
    end
    return consumed
end

function ZO_GamepadMultiFocusArea_Base:HandleMoveNext()
	local consumed = false
    local selectableFocus = self.manager:GetNextSelectableFocusArea(self)
    if selectableFocus then
        self.manager:SelectFocusArea(selectableFocus)
        consumed = true
    end
    return consumed
end

function ZO_GamepadMultiFocusArea_Base:CanBeSelected()
    return true -- override in derived classes
end

function ZO_GamepadMultiFocusArea_Base:IsFocused()
    return self.active
end

----------------------------
-- MultiFocusArea Manager --
----------------------------

ZO_GamepadMultiFocusArea_Manager = ZO_InitializingObject:Subclass()

function ZO_GamepadMultiFocusArea_Manager:Initialize()
	self.focusAreas = {}
    self.horizontalFocusAreaMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.verticalFocusAreaMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
end

function ZO_GamepadMultiFocusArea_Manager:GetPreviousSelectableFocusArea(startFocusArea)
    local currentFocusArea = startFocusArea
    while currentFocusArea do
        local nextPreviousArea = currentFocusArea.previousFocus
        if nextPreviousArea and nextPreviousArea:CanBeSelected() then
            return nextPreviousArea
        end

        currentFocusArea = nextPreviousArea
    end

    return nil
end

function ZO_GamepadMultiFocusArea_Manager:GetNextSelectableFocusArea(startFocusArea)
    local currentFocusArea = startFocusArea
    while currentFocusArea do
        local nextSelectableArea = currentFocusArea.nextFocus
        if nextSelectableArea and nextSelectableArea:CanBeSelected() then
            return nextSelectableArea
        end

        currentFocusArea = nextSelectableArea
    end

    return nil
end

function ZO_GamepadMultiFocusArea_Manager:SelectFocusArea(focusArea)
    if self.currentFocalArea ~= focusArea then
        local hasActiveFocus = self:HasActiveFocus()
        if self.currentFocalArea and hasActiveFocus then
            self.currentFocalArea:Deactivate()
        end

        self.currentFocalArea = focusArea

        if focusArea and hasActiveFocus then
            focusArea:Activate()
        end

        self:OnFocusChanged()
    end
end

function ZO_GamepadMultiFocusArea_Manager:ActivateFocusArea(focusArea)
    local hasActiveFocus = self:HasActiveFocus()
    if self.currentFocalArea and hasActiveFocus then
        self.currentFocalArea:Deactivate()
    end

    self.currentFocalArea = focusArea

    if focusArea then
        focusArea:Activate()
    end

    self:OnFocusChanged()
end

function ZO_GamepadMultiFocusArea_Manager:OnFocusChanged()
    -- override in derived classes for desired behaviour
end

function ZO_GamepadMultiFocusArea_Manager:GetCurrentFocus()
    return self.currentFocalArea
end

function ZO_GamepadMultiFocusArea_Manager:IsCurrentFocusArea(focusArea)
    return self.currentFocalArea == focusArea
end

function ZO_GamepadMultiFocusArea_Manager:UpdateActiveFocusKeybinds()
    if self.currentFocalArea then
        self.currentFocalArea:UpdateKeybinds()
    end
end

function ZO_GamepadMultiFocusArea_Manager:ActivateCurrentFocus()
    if self.currentFocalArea then
        self.currentFocalArea:Activate()
    end
end

function ZO_GamepadMultiFocusArea_Manager:DeactivateCurrentFocus()
    if self.currentFocalArea then
        self.currentFocalArea:Deactivate()
    end
end

function ZO_GamepadMultiFocusArea_Manager:HasActiveFocus()
    for _, focus in ipairs(self.focusAreas) do
        if focus:IsFocused() then
            return true
        end
    end

    return false
end

function ZO_GamepadMultiFocusArea_Manager:HandleMoveCurrentFocus(horizontalResult, verticalResult)
    if self.currentFocalArea then
        self.currentFocalArea:HandleMovementInternal(horizontalResult, verticalResult)
    end
end

function ZO_GamepadMultiFocusArea_Manager:AddNextFocusArea(focusArea)
	local previousFocus
	if #self.focusAreas > 0 then
		previousFocus = self.focusAreas[#self.focusAreas]
		previousFocus:SetNextSibling(focusArea)
	end
	focusArea:SetPreviousSibling(previousFocus)
	table.insert(self.focusAreas, focusArea)
end

function ZO_GamepadMultiFocusArea_Manager:AddPreviousFocusArea(focusArea)
	local previousFocus
	if #self.focusAreas > 0 then
		previousFocus = self.focusAreas[1]
		previousFocus:SetPreviousSibling(focusArea)
	end
	focusArea:SetNextSibling(previousFocus)
	table.insert(self.focusAreas, 1, focusArea)
end

function ZO_GamepadMultiFocusArea_Manager:UpdateDirectionalInput()
    local horizontalResult, verticalResult = self.horizontalFocusAreaMovementController:CheckMovement(), self.verticalFocusAreaMovementController:CheckMovement()
    if horizontalResult ~= MOVEMENT_CONTROLLER_NO_CHANGE or verticalResult ~= MOVEMENT_CONTROLLER_NO_CHANGE then
        self:HandleMoveCurrentFocus(horizontalResult, verticalResult)
    end
end
