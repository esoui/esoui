ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE_GAMEPAD = "ZO_GridScrollList_Entry_Template_Gamepad"
ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE_DIMENSIONS_GAMEPAD = 64
ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_GAMEPAD = "ZO_GridScrollList_Entry_Header_Template_Gamepad"
ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_HEIGHT = 33
ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD = 10

local SELECT_CATEGORY_PREVIOUS = -1
local SELECT_CATEGORY_NEXT = 1

-- ZO_AbstractGridScrollList_Gamepad --

ZO_AbstractGridScrollList_Gamepad = ZO_Object:Subclass()

function ZO_AbstractGridScrollList_Gamepad:New(...)
    local grid = ZO_Object.New(self)
    grid:Initialize(...)
    return grid
end

function ZO_AbstractGridScrollList_Gamepad:Initialize(control, selectionTemplate)

    self.dimOnDeactivate = false

    local function SelectionCallback(previousData, newData, selectedDuringRebuild)
        self:OnSelectionChanged(previousData, newData, selectedDuringRebuild)
    end

    local template = selectionTemplate or "ZO_GridScrollList_Highlight_Gamepad"
    ZO_ScrollList_EnableSelection(self.list, template, SelectionCallback)

    self:InitializeTriggerKeybinds()

    self.horizontalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.verticalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)

    SCREEN_NARRATION_MANAGER:RegisterGridList(self)
end

function ZO_AbstractGridScrollList_Gamepad:InitializeTriggerKeybinds()
    self.gridListTriggerKeybinds =
    {
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Grid Scroll List Previous Category",
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,

            callback = function()
                self:SelectNextCategory(ZO_SCROLL_SELECT_CATEGORY_PREVIOUS)
            end,
        },

        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Grid Scroll List Next Category",
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,

            callback = function()
                self:SelectNextCategory(ZO_SCROLL_SELECT_CATEGORY_NEXT)
            end,
        }
    }
end

function ZO_AbstractGridScrollList_Gamepad:SetScrollToExtent(scrollToExtent)
    ZO_ScrollList_SetScrollToExtent(self.list, scrollToExtent)
end

function ZO_AbstractGridScrollList_Gamepad:SetDirectionalInputEnabled(enabled)
    if self.directionalInputEnabled ~= enabled then
        self.directionalInputEnabled = enabled
        if enabled then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end
    end
end

function ZO_AbstractGridScrollList_Gamepad:SetDimsOnDeactivate(dimOnDeactivate)
    if self.dimOnDeactivate ~= dimOnDeactivate then
        self.dimOnDeactivate = dimOnDeactivate
        -- If we set this to true, we want to have the control go to its default alpha state
        if dimOnDeactivate then
            ZO_GamepadOnDefaultActivatedChanged(self.list, self.active)
        end
    end
end

function ZO_AbstractGridScrollList_Gamepad:UpdateDirectionalInput()
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

    function ZO_AbstractGridScrollList_Gamepad:HandleMoveInDirection(moveX, moveY)
        local scrollXDirection, scrollYDirection = MOVE_DIRECTION_TABLE[moveX], MOVE_DIRECTION_TABLE[moveY]

        local currentSelection = ZO_ScrollList_GetSelectedDataIndex(self.list)
        ZO_ScrollList_SelectNextDataInDirection(self.list, scrollXDirection, scrollYDirection)

        if currentSelection ~= ZO_ScrollList_GetSelectedDataIndex(self.list) then
            if scrollYDirection == ZO_SCROLL_MOVEMENT_DIRECTION_POSITIVE then
                PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
            elseif scrollYDirection == ZO_SCROLL_MOVEMENT_DIRECTION_NEGATIVE then
                PlaySound(SOUNDS.GAMEPAD_MENU_UP)
            elseif scrollXDirection == ZO_SCROLL_MOVEMENT_DIRECTION_POSITIVE then
                PlaySound(SOUNDS.GAMEPAD_MENU_RIGHT)
            elseif scrollXDirection == ZO_SCROLL_MOVEMENT_DIRECTION_NEGATIVE then
                PlaySound(SOUNDS.GAMEPAD_MENU_LEFT)
            end
        end
    end
end

function ZO_AbstractGridScrollList_Gamepad:OnSelectionChanged(previousData, newData, selectedDuringRebuild)
    self:FireCallbacks("SelectedDataChanged", previousData, newData)
end

function ZO_AbstractGridScrollList_Gamepad:SetOnSelectedDataChangedCallback(onSelectedDataChangedCallback)
    self:RegisterCallback("SelectedDataChanged", onSelectedDataChangedCallback)
end

function ZO_AbstractGridScrollList_Gamepad:ClearGridList(retainScrollPosition)
    ZO_AbstractGridScrollList.ClearGridList(self, retainScrollPosition)
    ZO_ScrollList_ResetLastHoldPosition(self.list)
end

function ZO_AbstractGridScrollList_Gamepad:CommitGridList()
    ZO_AbstractGridScrollList.CommitGridList(self)
    if self.active then
        self:RefreshSelection()
    end
    ZO_ScrollList_RefreshLastHoldPosition(self.list)
end

function ZO_AbstractGridScrollList_Gamepad:Activate(foregoDirectionalInput)
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

        self:FireCallbacks("OnActivated", self:GetSelectedData())
    end
end

function ZO_AbstractGridScrollList_Gamepad:Deactivate(foregoDirectionalInput)
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

function ZO_AbstractGridScrollList_Gamepad:IsActive()
    return self.active
end

function ZO_AbstractGridScrollList_Gamepad:GetSelectedData()
    return ZO_ScrollList_GetSelectedData(self.list)
end

function ZO_AbstractGridScrollList_Gamepad:GetSelectedDataIndex()
    local selectedData = self:GetSelectedData()
    if selectedData then
        return ZO_ScrollList_GetDataIndex(self.list, selectedData.dataEntry)
    end

    return 0
end

function ZO_AbstractGridScrollList_Gamepad:RefreshSelection(animateInstantly, scrollIntoView)
    ZO_ScrollList_AutoSelectData(self.list, animateInstantly, scrollIntoView)
end

function ZO_AbstractGridScrollList_Gamepad:AddTriggerKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.gridListTriggerKeybinds)
end

function ZO_AbstractGridScrollList_Gamepad:RemoveTriggerKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gridListTriggerKeybinds)
end

function ZO_AbstractGridScrollList_Gamepad:ScrollDataToCenter(data, onScrollCompleteCallback, animateInstantly)
    ZO_AbstractGridScrollList.ScrollDataToCenter(self, data, onScrollCompleteCallback, animateInstantly)
    ZO_ScrollList_RefreshLastHoldPosition(self.list)
end

function ZO_AbstractGridScrollList_Gamepad:SelectNextCategory(direction)
    ZO_ScrollList_SelectFirstIndexInCategory(self.list, direction)
end

function ZO_AbstractGridScrollList_Gamepad:SetHeaderNarrationFunction(headerNarrationFunction)
    self.headerNarrationFunction = headerNarrationFunction
end

function ZO_AbstractGridScrollList_Gamepad:GetHeaderNarration()
    if self.headerNarrationFunction then
        return self.headerNarrationFunction()
    end
end

-- ZO_GridScrollList_Gamepad --

ZO_GridScrollList_Gamepad = ZO_Object.MultiSubclass(ZO_AbstractGridScrollList_Gamepad, ZO_AbstractGridScrollList)

function ZO_GridScrollList_Gamepad:New(...)
    return ZO_AbstractGridScrollList.New(self, ...)
end

function ZO_GridScrollList_Gamepad:Initialize(control, selectionTemplate, autofillRows)
    ZO_AbstractGridScrollList.Initialize(self, control, autofillRows)
    ZO_AbstractGridScrollList_Gamepad.Initialize(self, control, selectionTemplate)
end

--Gets the narration text for the entirety of the grid list
function ZO_GridScrollList_Gamepad:GetNarrationText()
    local narrations = {}
    local dataList = self:GetData()
    for _, data in ipairs(dataList) do
        local entryData = data.data
        if entryData.header then
            table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.header))
        end

        if entryData.narrationText then
            if type(entryData.narrationText) == "function" then
                local narration = entryData.narrationText(entryData)
                if narration then
                    if ZO_IsNarratableObject(narration) then
                        table.insert(narrations, narration)
                    else
                        ZO_CombineNumericallyIndexedTables(narrations, narration)
                    end
                end
            else
                table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.narrationText))
            end
        end
    end
    return narrations
end
