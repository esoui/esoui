ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE_GAMEPAD = "ZO_GridScrollList_Entry_Template_Gamepad"
ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE_DIMENSIONS_GAMEPAD = 64
ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_GAMEPAD = "ZO_GridScrollList_Entry_Header_Template_Gamepad"
ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD = 10

-- ZO_GridScrollList_Gamepad --

ZO_GridScrollList_Gamepad = ZO_GridScrollList:Subclass()

function ZO_GridScrollList_Gamepad:New(...)
    return ZO_GridScrollList.New(self, ...)
end

function ZO_GridScrollList_Gamepad:Initialize(...)
    ZO_GridScrollList.Initialize(self, ...)

    ZO_ScrollList_EnableSelection(self.list, "ZO_GamepadInteractiveSortFilterDefaultHighlight", function(previousData, newData, selectedDuringRebuild) self:OnSelectionChanged(previousData, newData, selectedDuringRebuild) end)

    self.horizontalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.verticalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
end

function ZO_GridScrollList_Gamepad:SetDirectionalInputEnabled(enabled)
    if self.directionalInputEnabled ~= enabled then
        self.directionalInputEnabled = enabled
        if enabled then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end
    end
end

do
    local MOVE_DIRECTION_TABLE =
    {
        [MOVEMENT_CONTROLLER_NO_CHANGE] = ZO_SCROLL_MOVEMENT_DIRECTION_NONE,
        [MOVEMENT_CONTROLLER_MOVE_NEXT] = ZO_SCROLL_MOVEMENT_DIRECTION_POSITIVE,
        [MOVEMENT_CONTROLLER_MOVE_PREVIOUS] = ZO_SCROLL_MOVEMENT_DIRECTION_NEGATIVE
    }

    function ZO_GridScrollList_Gamepad:UpdateDirectionalInput()
        local moveX, moveY = self.horizontalMovementController:CheckMovement(), self.verticalMovementController:CheckMovement()
        if moveX ~= MOVEMENT_CONTROLLER_NO_CHANGE or moveY ~= MOVEMENT_CONTROLLER_NO_CHANGE then
            local scrollXDirection, scrollYDirection = MOVE_DIRECTION_TABLE[moveX], MOVE_DIRECTION_TABLE[moveY]
            ZO_ScrollList_SelectNextDataInDirection(self.list, scrollXDirection, scrollYDirection)
        end
    end
end

function ZO_GridScrollList_Gamepad:OnSelectionChanged(previousData, newData, selectedDuringRebuild)
    self:FireCallbacks("SelectedDataChanged", previousData, newData)
end

function ZO_GridScrollList_Gamepad:SetOnSelectedDataChangedCallback(onSelectedDataChangedCallback)
    self:RegisterCallback("SelectedDataChanged", onSelectedDataChangedCallback)
end

function ZO_GridScrollList_Gamepad:CommitGridList()
    ZO_ScrollList_ResetLastHoldPosition(self.list)
    ZO_GridScrollList.CommitGridList(self)
end

function ZO_GridScrollList_Gamepad:Activate()
    self:SetDirectionalInputEnabled(true)
    ZO_ScrollList_AutoSelectData(self.list)
end

function ZO_GridScrollList_Gamepad:Deactivate()
    self:SetDirectionalInputEnabled(false)
end
