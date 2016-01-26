----------------------
--Sort/Filter List
----------------------
ZO_SortFilterList_Gamepad = ZO_SortFilterList:Subclass()

function ZO_SortFilterList_Gamepad:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function ZO_SortFilterList_Gamepad:Initialize(...)
    ZO_SortFilterListBase.Initialize(self)
    self:InitializeSortFilterList(...)
end

function ZO_SortFilterList_Gamepad:InitializeSortFilterList(control, magnitudeQueryFunction, scrollListAsBlock)
    ZO_SortFilterList.InitializeSortFilterList(self, control)

    self.scrollListAsBlock = scrollListAsBlock

    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL, nil, magnitudeQueryFunction)
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

function ZO_SortFilterList_Gamepad:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if self.scrollListAsBlock then
            self:MoveNextAsBlock()
        else
            self:MoveNext()
        end
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if self.scrollListAsBlock then
            self:MovePreviousAsBlock()
        else
            self:MovePrevious()
        end
    end
end

function ZO_SortFilterList_Gamepad:MovePrevious()
    if not ZO_ScrollList_AtTopOfList(self.list) then
        ZO_ScrollList_SelectPreviousData(self.list)
        self:RefreshVisible()
        self:UpdateKeybinds()
    end
end

function ZO_SortFilterList_Gamepad:MoveNext()
    if not ZO_ScrollList_AtBottomOfList(self.list) then
        ZO_ScrollList_SelectNextData(self.list)
        self:RefreshVisible()
        self:UpdateKeybinds()
    end
end

function ZO_SortFilterList_Gamepad:MovePreviousAsBlock()
    if ZO_ScrollList_CanScrollUp(self.list) then
        local atTop, topData = ZO_ScrollList_AtTopOfVisible(self.list)

        if atTop then
            ZO_ScrollList_SelectPreviousData(self.list)
        else
            ZO_ScrollList_SelectDataAndScrollIntoView(self.list, topData)
        end

        self:RefreshVisible()
    end
end

function ZO_SortFilterList_Gamepad:MoveNextAsBlock()
    if ZO_ScrollList_CanScrollDown(self.list) then
        local atBottom, bottomData = ZO_ScrollList_AtBottomOfVisible(self.list)

        if atBottom then
            ZO_ScrollList_SelectNextData(self.list)
        else
            ZO_ScrollList_SelectDataAndScrollIntoView(self.list, bottomData)
        end

        self:RefreshVisible()
    end
end

function ZO_SortFilterList_Gamepad:SetEmptyText(emptyText)
    self.emptyRow = CreateControlFromVirtual("$(parent)EmptyRow", self.list, "ZO_SortFilterListEmptyRow_Gamepad")
    GetControl(self.emptyRow, "Message"):SetText(emptyText)
end