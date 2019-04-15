----------------------
--Sort/Filter List
----------------------
ZO_SortFilterList_Gamepad = ZO_SortFilterList:Subclass()

function ZO_SortFilterList_Gamepad:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function ZO_SortFilterList_Gamepad:Initialize(...)
    ZO_SortFilterList.Initialize(self, ...)
    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self.isActive = false
end

function ZO_SortFilterList_Gamepad:InitializeSortFilterList(control, highlightTemplate)
    ZO_SortFilterList.InitializeSortFilterList(self, control)
    highlightTemplate = highlightTemplate or "ZO_GamepadInteractiveSortFilterDefaultHighlight"
    ZO_ScrollList_EnableSelection(self.list, highlightTemplate, function(oldData, newData) self:OnSelectionChanged(oldData, newData) end)
end

function ZO_SortFilterList_Gamepad:SetDirectionalInputEnabled(enabled)
    if self.directionalInputEnabled ~= enabled then
        self.directionalInputEnabled = enabled
        if enabled then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end
    end
end

function ZO_SortFilterList_Gamepad:IsActivated()
    return self.isActive
end

function ZO_SortFilterList_Gamepad:Activate()
    if not self.isActive then
        self.isActive = true

        self:SetDirectionalInputEnabled(true)
        ZO_ScrollList_AutoSelectData(self.list)
    end
end

function ZO_SortFilterList_Gamepad:Deactivate()
    if self.isActive then
        self:SetDirectionalInputEnabled(false)
        ZO_ScrollList_SelectData(self.list, nil)

        self.isActive = false
    end
end

function ZO_SortFilterList_Gamepad:MovePrevious()
    if not ZO_ScrollList_AtTopOfList(self.list) then
        PlaySound(SOUNDS.GAMEPAD_MENU_UP)
        ZO_ScrollList_SelectPreviousData(self.list)
        self:UpdateKeybinds()
    end
end

function ZO_SortFilterList_Gamepad:MoveNext()
    if not ZO_ScrollList_AtBottomOfList(self.list) then
        PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
        ZO_ScrollList_SelectNextData(self.list)
        self:UpdateKeybinds()
    end
end

function ZO_SortFilterList_Gamepad:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self:MoveNext()
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self:MovePrevious()
    end
end

function ZO_SortFilterList_Gamepad:SetEmptyText(emptyText)
    self.emptyRow = CreateControlFromVirtual("$(parent)EmptyRow", self.list, "ZO_SortFilterListEmptyRow_Gamepad")
    GetControl(self.emptyRow, "Message"):SetText(emptyText)
end