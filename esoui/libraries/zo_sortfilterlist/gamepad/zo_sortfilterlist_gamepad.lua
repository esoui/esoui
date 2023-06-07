----------------------
--Sort/Filter List
----------------------
ZO_SortFilterList_Gamepad = ZO_SortFilterList:Subclass()

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

function ZO_SortFilterList_Gamepad:Activate(animateInstantly, scrollAutoSelectedDataIntoView)
    if not self.isActive then
        self.isActive = true

        self:SetDirectionalInputEnabled(true)
        ZO_ScrollList_AutoSelectData(self.list, animateInstantly, scrollAutoSelectedDataIntoView)
        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self, NARRATE_HEADER)
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
    if not self.emptyRow then
        self.emptyRow = CreateControlFromVirtual("$(parent)EmptyRow", self.list, "ZO_SortFilterListEmptyRow_Gamepad")
    end
    self.emptyRow:GetNamedChild("Message"):SetText(emptyText)
    self.emptyText = emptyText
end

function ZO_SortFilterList_Gamepad:OnSelectionChanged(previouslySelected, selected)
   ZO_SortFilterList.OnSelectionChanged(self, previouslySelected, selected)
   SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self)
end

function ZO_SortFilterList_Gamepad:GetHeaderNarration()
    --Can be overridden
end

function ZO_SortFilterList_Gamepad:GetFooterNarration()
    --Can be overridden
end

function ZO_SortFilterList_Gamepad:GetNarrationText()
    --Can be overridden
end

function ZO_SortFilterList_Gamepad:GetAdditionalInputNarrationFunction()
    --Can be overridden
end

function ZO_SortFilterList_Gamepad:GetEmptyRowNarration()
    local narrations = {}
    if self.emptyRow and not self.emptyRow:IsHidden() then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.emptyText))
    end
    return narrations
end
