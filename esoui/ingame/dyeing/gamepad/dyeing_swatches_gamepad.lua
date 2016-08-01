ZO_Dyeing_Swatches_Gamepad = ZO_Object:Subclass()

ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_UP = "up"
ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_DOWN = "down"
ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_LEFT = "left"
ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_RIGHT = "right"

local SWATCHES_LAYOUT_OPTIONS_GAMEPAD = {
        padding = 10,
        leftMargin = 30,
        topMargin = 20,
        rightMargin = 17,
        bottomMargin = 10,
        selectionScale = ZO_DYEING_SWATCH_SELECTION_SCALE,
    }

function ZO_Dyeing_Swatches_Gamepad:New(...)
    local swatches = ZO_Object.New(self)
    swatches:Initialize(...)
    return swatches
end

local HIGHLIGHT_DIMENSIONS = 3

function ZO_Dyeing_Swatches_Gamepad:Initialize(owner, control, sharedHighlight, savedVars, selectionChangedCallback, moveOutCallback, verticalController)
    self.control = control
    self.savedVars = savedVars
    self.dirty = true
    self.selectionChangedCallback = selectionChangedCallback
    self.moveOutCallback = moveOutCallback
    self.sharedHighlight = sharedHighlight
    self.hasSelection = false

    self.selectedDyeRow = 1
    self.selectedDyeCol = 1
    self.swatchesByPosition = {}
    self.positionByDyeId = {}
    self.unlockedDyeIds = {}

    self.verticalMovementController = verticalController or ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self.horizontalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    self.headerPool = ZO_ControlPool:New("ZO_Dye_Gamepad_ColorLabel", control)
    local CAN_SELECT_LOCKED = true
    self.swatchPool = ZO_Dyeing_InitializeSwatchPool(owner, sharedHighlight, control, "ZO_DyeingSwatch_Gamepad", CAN_SELECT_LOCKED, HIGHLIGHT_DIMENSIONS)

    control:SetHandler("OnEffectivelyShown", function()
                    if self.dirty then
                        self:RefreshDyeLayout_Internal()
                    end
                end)
end

local SUPPRESS_SOUND = true

function ZO_Dyeing_Swatches_Gamepad:Deactivate(retainSelection)
    DIRECTIONAL_INPUT:Deactivate(self)
    if not retainSelection then
        local selectedSwatch = self:GetSelectedSwatch()
        if selectedSwatch then
            self:OnSelectionChanged(selectedSwatch, nil, SUPPRESS_SOUND)
        end
    end
    self.hasSelection = retainSelection
end

function ZO_Dyeing_Swatches_Gamepad:Activate()
    DIRECTIONAL_INPUT:Activate(self, self.control)
    self.hasSelection = true
    local selectedSwatch = self:GetSelectedSwatch()
    self:OnSelectionChanged(nil, selectedSwatch, SUPPRESS_SOUND)
end

function ZO_Dyeing_Swatches_Gamepad:UpdateRowVisible(direction)
    local numRows = #self.swatchesByPosition

    if numRows ~= 0 then
        local nextRowID = zo_clamp(self.selectedDyeRow + direction, 1, numRows)
        local nextSwatch = self.swatchesByPosition[nextRowID][1] -- We don't care which we get, we just need a swatch, so take the first one, which we know exists.
        local scrollOffset = select(6, self.control:GetAnchor(0))

        local nextRowPosition = (direction < 0) and nextSwatch.effectiveTop or nextSwatch.effectiveBottom
        nextRowPosition = nextRowPosition + scrollOffset

        local width, height = self.control:GetDimensions()
        height = height + scrollOffset
        local scrollOffsetChange
        if nextRowPosition < 0 then
            scrollOffsetChange = -nextRowPosition
        elseif nextRowPosition > height then
            scrollOffsetChange = height - nextRowPosition
        else
            -- No scrolling change needed.
        end

        if scrollOffsetChange then
            local newScrollOffset = scrollOffset + scrollOffsetChange

            self.control:ClearAnchors()
            self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, newScrollOffset)
            self.control:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, 0, 0)
        end
    else
        self.control:ClearAnchors()
        self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
        self.control:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, 0, 0)
    end
end

function ZO_Dyeing_Swatches_Gamepad:ChangeSelectedDyeRow(direction)
    local numRows = #self.swatchesByPosition
    local noRows = (numRows == 0)

    if (direction > 0) and (noRows or (self.selectedDyeRow == numRows)) and self.moveOutCallback then
        self.moveOutCallback(ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_DOWN, self.selectedDyeRow, self.selectedDyeCol)
    elseif (direction < 0) and (noRows or (self.selectedDyeRow == 1)) and self.moveOutCallback then
        self.moveOutCallback(ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_UP, self.selectedDyeRow, self.selectedDyeCol)
    elseif not noRows then
        self.selectedDyeRow = zo_clamp(self.selectedDyeRow + direction, 1, numRows)
        if self.selectedDyeCol > #self.swatchesByPosition[self.selectedDyeRow] then
            -- If the new row does not have enough columns, attempt to skip the row. If that row is still
            --  not long enough, just clamp to the last block in that column. It might be desired to expand
            --  this in case there are a couple of short rows before a longer one.
            self.selectedDyeRow = zo_clamp(self.selectedDyeRow + direction, 1, numRows)
            self.selectedDyeCol = zo_clamp(self.selectedDyeCol, 1, #self.swatchesByPosition[self.selectedDyeRow])
        end

        -- Make sure the next row is visible.
        self:UpdateRowVisible(direction)
    end
end

function ZO_Dyeing_Swatches_Gamepad:SetSelectedDyeColumn(columnIndex)
    if #self.swatchesByPosition ~= 0 then
        local previousSwatch = self:GetSelectedSwatch()

        local numColumns = #self.swatchesByPosition[self.selectedDyeRow]
        self.selectedDyeCol = zo_clamp(columnIndex, 1, numColumns)

        local newSwatch = self:GetSelectedSwatch()
        if previousSwatch ~= newSwatch then
            self:OnSelectionChanged(previousSwatch, newSwatch, SUPPRESS_SOUND)
        end
    end
end

function ZO_Dyeing_Swatches_Gamepad:ChangeSelectedDyeColumn(direction)
    if #self.swatchesByPosition ~= 0 then
        local numColumns = #self.swatchesByPosition[self.selectedDyeRow]

        if (direction > 0) and (self.selectedDyeCol == numColumns) and self.moveOutCallback then
            self.moveOutCallback(ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_RIGHT, self.selectedDyeRow, self.selectedDyeCol)
        elseif (direction < 0) and (self.selectedDyeCol == 1) and self.moveOutCallback then
            self.moveOutCallback(ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_LEFT, self.selectedDyeRow, self.selectedDyeCol)
        else
            self.selectedDyeCol = zo_clamp(self.selectedDyeCol + direction, 1, numColumns)
        end
    else
        if (direction > 0) and self.moveOutCallback then
            self.moveOutCallback(ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_RIGHT, self.selectedDyeRow, self.selectedDyeCol)
        elseif (direction < 0) and self.moveOutCallback then
            self.moveOutCallback(ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_LEFT, self.selectedDyeRow, self.selectedDyeCol)
        end
    end
end

function ZO_Dyeing_Swatches_Gamepad:OnSelectionChanged(previousSwatch, newSwatch, suppressSound)
    if previousSwatch then
        previousSwatch:SetSelected(false, nil, suppressSound)
    end
    if newSwatch then
        newSwatch:SetSelected(true, nil, suppressSound)
    else
        self.sharedHighlight:SetHidden(true)
    end
    if self.selectionChangedCallback then
        self.selectionChangedCallback(previousSwatch, newSwatch)
    end
end

function ZO_Dyeing_Swatches_Gamepad:UpdateDirectionalInput()
    -- Save off the previous selection for updating.
    local previousSwatch = self:GetSelectedSwatch()

    -- Perform the movement.
    local result = self.verticalMovementController:CheckMovement()
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self:ChangeSelectedDyeRow(1)
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self:ChangeSelectedDyeRow(-1)
    end

    local result = self.horizontalMovementController:CheckMovement()
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self:ChangeSelectedDyeColumn(1)
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self:ChangeSelectedDyeColumn(-1)
    end

    -- Update the selection, if needed.
    local newSwatch = self:GetSelectedSwatch()
    if previousSwatch ~= newSwatch then
        self:OnSelectionChanged(previousSwatch, newSwatch)
    end
end

function ZO_Dyeing_Swatches_Gamepad:SwitchToDyeingWithDyeId(dyeId)
    local dyePosition = self.positionByDyeId[dyeId]
    if dyePosition then
        local previousSwatch = self:GetSelectedSwatch()

        local row = dyePosition[1]
        local column = dyePosition[2]

        local previousRowIndex = self.selectedDyeRow

        self.selectedDyeRow = zo_clamp(row, 1, #self.swatchesByPosition)
        self.selectedDyeCol = zo_clamp(column, 1, #self.swatchesByPosition[self.selectedDyeRow])

        -- Highlight the current selection.
        self:OnSelectionChanged(previousSwatch, self:GetSelectedSwatch())

        -- Update the scroll offset to make the current row visible.
        if self.selectedDyeRow > previousRowIndex then
            self:UpdateRowVisible(1)
        elseif self.selectedDyeRow < previousRowIndex then
            self:UpdateRowVisible(-1)
        else
            -- Nothing to do if they are equal.
        end
    end
end

function ZO_Dyeing_Swatches_Gamepad:DoesDyeIdExistInPlayerDyes(dyeId)
    return self.positionByDyeId[dyeId] ~= nil
end

function ZO_Dyeing_Swatches_Gamepad:GetSelectedDyeId()
    local selectedSwatch = self:GetSelectedSwatch()
    if not selectedSwatch then
        return INVALID_DYE_ID
    end
    return selectedSwatch.dyeId
end

function ZO_Dyeing_Swatches_Gamepad:GetSelectedSwatch()
    if not self.swatchesByPosition then
        return nil
    end
    local selectedRow = self.swatchesByPosition[self.selectedDyeRow]
    if not selectedRow then
        return nil
    end
    return selectedRow[self.selectedDyeCol]
end

function ZO_Dyeing_Swatches_Gamepad:GetNumUnlockedDyes()
    return #self.unlockedDyeIds
end

function ZO_Dyeing_Swatches_Gamepad:GetRandomUnlockedDyeId()
    if #self.unlockedDyeIds > 0 then
        return self.unlockedDyeIds[zo_random(1, #self.unlockedDyeIds)]
    end
    return nil
end

function ZO_Dyeing_Swatches_Gamepad:RefreshDyeLayout()
    if self.control:IsHidden() then
        self.dirty = true
    else
        self:RefreshDyeLayout_Internal()
    end
end

function ZO_Dyeing_Swatches_Gamepad:RefreshDyeLayout_Internal()
    self.dirty = false

    local selectedDyeId = self:GetSelectedDyeId()
    local previousRowIndex = self.selectedDyeRow

    self.swatchesByPosition, self.positionByDyeId, self.unlockedDyeIds = ZO_Dyeing_LayoutSwatches(self.savedVars.showLocked, self.savedVars.sortStyle, self.swatchPool, self.headerPool, SWATCHES_LAYOUT_OPTIONS_GAMEPAD, self.control)

    local selectedRowCol = self.positionByDyeId[selectedDyeId]
    if selectedRowCol then
        -- The previously selected dye is still in the view, so set it as the selected row and column.
        --  NOTE: We know these coordinates are valid.
        self.selectedDyeRow = selectedRowCol[1]
        self.selectedDyeCol = selectedRowCol[2]
    else
        -- The selected dye no longer exists, default to the first position
        self.selectedDyeRow = 1
        self.selectedDyeCol = 1
    end

    -- Highlight the current selection.
    if self.hasSelection then
       self:OnSelectionChanged(nil, self:GetSelectedSwatch())
    end

    -- Update the scroll offset to make the current row visible.
    if self.selectedDyeRow > previousRowIndex then
        self:UpdateRowVisible(1)
    elseif self.selectedDyeRow < previousRowIndex then
        self:UpdateRowVisible(-1)
    else
        -- Nothing to do if they are equal.
    end
end
