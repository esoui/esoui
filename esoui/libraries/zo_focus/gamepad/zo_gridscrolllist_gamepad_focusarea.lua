ZO_GridScrollList_Gamepad_FocusArea = ZO_GamepadMultiFocusArea_Base:Subclass()

function ZO_GridScrollList_Gamepad_FocusArea:Initialize(gridList, manager)
    self.gridList = gridList

    local FOREGO_DIRECTIONAL_INPUT = true

    local function GridActivateCallback()
        self.gridList:Activate(FOREGO_DIRECTIONAL_INPUT)
    end

    local function GridDeactivateCallback()
        self.gridList:Deactivate(FOREGO_DIRECTIONAL_INPUT)
    end
    ZO_GamepadMultiFocusArea_Base.Initialize(self, manager, GridActivateCallback, GridDeactivateCallback)
end

function ZO_GridScrollList_Gamepad_FocusArea:HandleMovement(horizontalResult, verticalResult)
    self.gridList:HandleMoveInDirection(horizontalResult, verticalResult)
    return true
end

function ZO_GridScrollList_Gamepad_FocusArea:CanBeSelected()
    return self.gridList:HasEntries()
end

function ZO_GridScrollList_Gamepad_FocusArea:HandleMovePrevious()
    if self:CanBeSelected() and not self.gridList:AtTopOfGrid() then
        -- let the grid handle the move if we can move up in the grid
        return false
    end

    return ZO_GamepadMultiFocusArea_Base.HandleMovePrevious(self)
end

function ZO_GridScrollList_Gamepad_FocusArea:HandleMoveNext()
    if self:CanBeSelected() and not self.gridList:AtBottomOfGrid() then
        -- let the grid handle the move if we can move down in the grid
        return false
    end

    return ZO_GamepadMultiFocusArea_Base.HandleMoveNext(self)
end