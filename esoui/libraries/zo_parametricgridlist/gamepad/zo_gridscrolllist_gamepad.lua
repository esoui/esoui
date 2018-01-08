ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE_GAMEPAD = "ZO_GridScrollList_Entry_Template_Gamepad"
ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE_DIMENSIONS_GAMEPAD = 64
ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_GAMEPAD = "ZO_GridScrollList_Entry_Header_Template_Gamepad"
ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_HEIGHT = 33
ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD = 10

local SELECT_CATEGORY_PREVIOUS = -1
local SELECT_CATEGORY_NEXT = 1

-- ZO_GridScrollList_Gamepad --

ZO_GridScrollList_Gamepad = ZO_GridScrollList:Subclass()

function ZO_GridScrollList_Gamepad:New(...)
    return ZO_GridScrollList.New(self, ...)
end

function ZO_GridScrollList_Gamepad:Initialize(...)
    ZO_GridScrollList.Initialize(self, ...)

    self.dimOnDeactivate = false

    ZO_ScrollList_EnableSelection(self.list, "ZO_GridScrollList_Highlight_Gamepad", function(previousData, newData, selectedDuringRebuild) self:OnSelectionChanged(previousData, newData, selectedDuringRebuild) end)

    self:InitializeTriggerKeybinds()

    self.horizontalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.verticalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
end

function ZO_GridScrollList_Gamepad:InitializeTriggerKeybinds()
    self.gridListTriggerKeybinds =
    {
        {
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,

            callback = function()
                self:SelectNextCategory(SELECT_CATEGORY_PREVIOUS)
            end,
        },

        {
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,

            callback = function()
                self:SelectNextCategory(SELECT_CATEGORY_NEXT)
            end,
        }
    }
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

function ZO_GridScrollList_Gamepad:SetDimsOnDeactivate(dimOnDeactivate)
    if self.dimOnDeactivate ~= dimOnDeactivate then
        self.dimOnDeactivate = dimOnDeactivate
        -- If we set this to true, we want to have the control go to its default alpha state
        if dimOnDeactivate then
            ZO_GamepadOnDefaultActivatedChanged(self.list, self.active)
        end
    end
end

function ZO_GridScrollList_Gamepad:UpdateDirectionalInput()
    local moveX, moveY = self.horizontalMovementController:CheckMovement(), self.verticalMovementController:CheckMovement()
    if moveX ~= MOVEMENT_CONTROLLER_NO_CHANGE or moveY ~= MOVEMENT_CONTROLLER_NO_CHANGE then
        self:HandleMoveInDirection(moveX, moveY)
    end
end

do
    local MOVE_DIRECTION_TABLE =
    {
        [MOVEMENT_CONTROLLER_NO_CHANGE] = ZO_SCROLL_MOVEMENT_DIRECTION_NONE,
        [MOVEMENT_CONTROLLER_MOVE_NEXT] = ZO_SCROLL_MOVEMENT_DIRECTION_POSITIVE,
        [MOVEMENT_CONTROLLER_MOVE_PREVIOUS] = ZO_SCROLL_MOVEMENT_DIRECTION_NEGATIVE
    }

    function ZO_GridScrollList_Gamepad:HandleMoveInDirection(moveX, moveY)
        local scrollXDirection, scrollYDirection = MOVE_DIRECTION_TABLE[moveX], MOVE_DIRECTION_TABLE[moveY]
        ZO_ScrollList_SelectNextDataInDirection(self.list, scrollXDirection, scrollYDirection)
    end
end

function ZO_GridScrollList_Gamepad:OnSelectionChanged(previousData, newData, selectedDuringRebuild)
    self:FireCallbacks("SelectedDataChanged", previousData, newData)
end

function ZO_GridScrollList_Gamepad:SetOnSelectedDataChangedCallback(onSelectedDataChangedCallback)
    self:RegisterCallback("SelectedDataChanged", onSelectedDataChangedCallback)
end

function ZO_GridScrollList_Gamepad:ClearGridList(retainScrollPosition)
    ZO_GridScrollList.ClearGridList(self, retainScrollPosition)
    ZO_ScrollList_ResetLastHoldPosition(self.list)
end

function ZO_GridScrollList_Gamepad:CommitGridList()
    ZO_GridScrollList.CommitGridList(self)
    ZO_ScrollList_RefreshLastHoldPosition(self.list)
    if self.active then
        self:RefreshSelection()
    end
end

function ZO_GridScrollList_Gamepad:Activate(foregoDirectionalInput)
    if self.active ~= true then
        self.active = true

        if self.dimOnDeactivate then
            ZO_GamepadOnDefaultActivatedChanged(self.list, self.active)
        end

        self:AddTriggerKeybinds()
        ZO_ScrollList_AutoSelectData(self.list)

        if not foregoDirectionalInput then
            self:SetDirectionalInputEnabled(true)
        end
    end
end

function ZO_GridScrollList_Gamepad:Deactivate(foregoDirectionalInput)
    if self.active ~= false then
        self.active = false

        if self.dimOnDeactivate then
            ZO_GamepadOnDefaultActivatedChanged(self.list, self.active)
        end

        self:RemoveTriggerKeybinds()
        ZO_ScrollList_SelectData(self.list, nil)

        if not foregoDirectionalInput then
            self:SetDirectionalInputEnabled(false)
        end
    end
end

function ZO_GridScrollList_Gamepad:IsActive()
    return self.active
end

function ZO_GridScrollList_Gamepad:GetSelectedData()
    return ZO_ScrollList_GetSelectedData(self.list)
end

function ZO_GridScrollList_Gamepad:RefreshSelection()
    ZO_ScrollList_AutoSelectData(self.list)
end

function ZO_GridScrollList_Gamepad:AddTriggerKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.gridListTriggerKeybinds)
end

function ZO_GridScrollList_Gamepad:RemoveTriggerKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gridListTriggerKeybinds)
end

function ZO_GridScrollList_Gamepad:ScrollDataToCenter(data)
    ZO_GridScrollList.ScrollDataToCenter(self, data)
    ZO_ScrollList_RefreshLastHoldPosition(self.list)
end

function ZO_GridScrollList_Gamepad:SelectNextCategory(direction)
    local currentlySelectedData = self:GetSelectedData()
    if not currentlySelectedData then
        return
    end

    local listData = ZO_ScrollList_GetDataList(self.list)
    local nextDataIndex = ZO_ScrollList_GetDataIndex(self.list, currentlySelectedData.dataEntry) + direction

    if nextDataIndex <= 0 or nextDataIndex > #listData then
        -- we are already at the end of our list
        return
    end

    -- if we are going backwards and hit a non-grid cell, we need to keep going until we find one so we don't just select the same value
    if direction == SELECT_CATEGORY_PREVIOUS then
        while listData[nextDataIndex].typeId ~= ZO_GRID_LIST_OPERATION_ADD_CELL do
            nextDataIndex = nextDataIndex + direction
            if nextDataIndex == 0 or nextDataIndex == #listData then
                -- could not find an acceptable target, we are at the selectable end of our list
                return
            end
        end
    end


    while nextDataIndex > 0 and nextDataIndex <= #listData do
        local potentialData = listData[nextDataIndex]
        local potentialDataType = potentialData.typeId
        if potentialDataType == ZO_GRID_LIST_OPERATION_ADD_HEADER then
            -- we found a header, select the first entry under it
            local lookAheadIndex = nextDataIndex + 1
            local dataAfterHeader = listData[lookAheadIndex]
            ZO_ScrollList_SelectData(self.list, listData[lookAheadIndex].data)
            ZO_ScrollList_ScrollDataToCenter(self.list, lookAheadIndex)
            ZO_ScrollList_RefreshLastHoldPosition(self.list)
            return
        end

        nextDataIndex = nextDataIndex + direction
    end

    -- could not find another header, so just pick the last selectable value we found
    ZO_ScrollList_SelectData(self.list, listData[nextDataIndex - direction].data)
    ZO_ScrollList_ScrollDataToCenter(self.list, nextDataIndex - direction)
    ZO_ScrollList_RefreshLastHoldPosition(self.list)
end