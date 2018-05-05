--------------
--Focus Grid--
--------------

ZO_GamepadInteractiveSortFilterFocusArea_Grid = ZO_GamepadMultiFocusArea_Base:Subclass()

function ZO_GamepadInteractiveSortFilterFocusArea_Grid:HandleMovement(horizontalResult, verticalResult)
    self.gridList:HandleMoveInDirection(horizontalResult, verticalResult)
    return true
end

function ZO_GamepadInteractiveSortFilterFocusArea_Grid:CanBeSelected()
    return self.gridList:HasEntries()
end

function ZO_GamepadInteractiveSortFilterFocusArea_Grid:HandleMovePrevious()
    local consumed = false
    if self.gridList:AtTopOfGrid() then
        consumed = ZO_GamepadMultiFocusArea_Base.HandleMovePrevious(self)
    end
    return consumed
end

ZO_Restyle_Station_Helper_Panel_Gamepad = ZO_Object:MultiSubclass(ZO_GamepadMultiFocusArea_Manager, ZO_CallbackObject)

function ZO_Restyle_Station_Helper_Panel_Gamepad:New(...)
    local panel = ZO_CallbackObject.New(self)
    panel:Initialize(...)
    return panel
end

function ZO_Restyle_Station_Helper_Panel_Gamepad:Initialize()
	ZO_GamepadMultiFocusArea_Manager.Initialize(self)
    self.isActive = false
end

function ZO_Restyle_Station_Helper_Panel_Gamepad:RebuildList()
    assert(false) -- must be overridden in derived classes
end

function ZO_Restyle_Station_Helper_Panel_Gamepad:EndSelection()
	self:FireCallbacks("PanelSelectionEnd", self)
end

function ZO_Restyle_Station_Helper_Panel_Gamepad:Activate()
    self.isActive = true
end

function ZO_Restyle_Station_Helper_Panel_Gamepad:Deactivate()
    self.isActive = false
end

function ZO_Restyle_Station_Helper_Panel_Gamepad:IsActive()
    return self.isActive
end

function ZO_Restyle_Station_Helper_Panel_Gamepad:OnShowing()
    -- override in derived classes
end

function ZO_Restyle_Station_Helper_Panel_Gamepad:OnHide()
    if self.isActive then
        self:Deactivate()
    end
end