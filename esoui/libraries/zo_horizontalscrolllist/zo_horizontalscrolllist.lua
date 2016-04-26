ZO_HorizontalScrollList = ZO_Object:Subclass()

ZO_HORIZONTALSCROLLLIST_MOVEMENT_TYPES = 
{
    INITIAL_UPDATE = 1,
    MOVE_RIGHT = 2,
    MOVE_LEFT = 3,
    -- LAST allows derived classes to start their movement enumerations after the base movements 
    LAST = 4,
}

ZO_HORIZONTAL_SCROLL_LIST_DISPLAY_FIXED_NUMBER_OF_ENTRIES = 1
ZO_HORIZONTAL_SCROLL_LIST_ANCHOR_ENTRIES_AT_FIXED_DISTANCE = 2

function ZO_HorizontalScrollListPlaySound(type)
    if type == ZO_HORIZONTALSCROLLLIST_MOVEMENT_TYPES.INITIAL_UPDATE then
        PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
    elseif type == ZO_HORIZONTALSCROLLLIST_MOVEMENT_TYPES.MOVE_RIGHT then
        PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
    elseif type == ZO_HORIZONTALSCROLLLIST_MOVEMENT_TYPES.MOVE_LEFT then
        PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
    end
end

--[[ Public  API ]]--
function ZO_HorizontalScrollList:New(...)
    local horizontalScrollList = ZO_Object.New(self)
    horizontalScrollList:Initialize(...)
    return horizontalScrollList
end

local function DefaultEqualityFunction(leftData, rightData)
    return leftData == rightData
end

local DEFAULT_NUM_VISIBLE_ENTRIES = 5

-- for best results numVisibleEntries should be odd
function ZO_HorizontalScrollList:Initialize(control, templateName, numVisibleEntries, setupFunction, equalityFunction, onCommitWithItemsFunction, onClearedFunction)
    self.control = control
    control.horizontalScrollList = self
    self.scrollControl = control:GetNamedChild("Scroll")

    self.setupFunction = setupFunction
    self.equalityFunction = equalityFunction or DefaultEqualityFunction
    self.onCommitWithItemsFunction = onCommitWithItemsFunction
    self.onClearedFunction = onClearedFunction

    self.numVisibleEntries = (numVisibleEntries or DEFAULT_NUM_VISIBLE_ENTRIES) + 2
    self.halfNumVisibleEntries = zo_floor(self.numVisibleEntries * .5)

    self.controlEntryWidth = control:GetWidth() / (self.numVisibleEntries - 2)
    self.offsetBetweenEntries = 0
    self.displayEntryType = ZO_HORIZONTAL_SCROLL_LIST_DISPLAY_FIXED_NUMBER_OF_ENTRIES

    self.leftArrow = self.control:GetNamedChild("LeftArrow")
    self.rightArrow = self.control:GetNamedChild("RightArrow")

    self.allowWrapping = false

    self.isMoving = false

    self.enabled = true

    self.onPlaySoundFunction = ZO_HorizontalScrollListPlaySound

    local function OnDragStart(clickedControl, button)
        if self.enabled then
            self.dragging = true
            self.draggingXStart = GetUIMousePosition()
        end
    end

    local function OnDragStop()
        if self.dragging then
            self.dragging = false

            local totalDeltaX = GetUIMousePosition() - self.draggingXStart
            local lastFrameDeltaX = GetUIMouseDeltas() * 15

            self:SetSelectedIndex(zo_round((self:CalculateSelectedIndexOffset() + totalDeltaX + lastFrameDeltaX) / self.controlEntryWidth))
        end
    end

    local function OnMouseUp(clickedControl, button, upInside)
        if self.dragging then
            OnDragStop()
        elseif button == MOUSE_BUTTON_INDEX_LEFT and upInside and self.enabled then
            self:SelectControl(clickedControl)
        end
    end

    self.control:SetHandler("OnDragStart", OnDragStart)
    self.control:SetHandler("OnMouseUp", OnDragStop)

    self.controls = {}
    for i = 1, self.numVisibleEntries do
        local entryControl = CreateControlFromVirtual("$(parent)", self.scrollControl, templateName, i)
        entryControl:SetHandler("OnDragStart", OnDragStart)
        entryControl:SetHandler("OnMouseUp", OnMouseUp)
        self.controls[i] = entryControl
    end

    self.control:SetHandler("OnUpdate", function() self:OnUpdate() end)

    self.noItemsLabel = self.control:GetNamedChild("NoItemsLabel")

    self:Clear()
end

function ZO_HorizontalScrollList:SetAllowWrapping(allowWrapping)
    self.allowWrapping = allowWrapping
end

function ZO_HorizontalScrollList:SetOnMovementChangedCallback(onMovementChangedCallback)
    self.onMovementChangedCallback = onMovementChangedCallback
end

function ZO_HorizontalScrollList:SetEnabled(enabled)
    if self.enabled ~= enabled then
        self.enabled = enabled

        self.dragging = false

        self:RefreshVisible()
    end
end

function ZO_HorizontalScrollList:SetScaleExtents(minScale, maxScale)
    self.minScale = minScale
    self.maxScale = maxScale
end

function ZO_HorizontalScrollList:SetNoItemText(text)
    if self.noItemsLabel then
        self.noItemsLabel:SetText(text)
    end
end

function ZO_HorizontalScrollList:SetDisplayEntryType(displayEntryType)
    self.displayEntryType = displayEntryType
end

function ZO_HorizontalScrollList:SetOffsetBetweenEntries(offsetBetweenEntries)
    self.offsetBetweenEntries = offsetBetweenEntries
end

function ZO_HorizontalScrollList:IsMoving()
    return self.isMoving
end

function ZO_HorizontalScrollList:SetSelectionHighlightInfo(selectionHighlightControl, selectionHighlightAnimation)
    self.selectionHighlightControl = selectionHighlightControl
    self.selectionHighlightAnimation = selectionHighlightAnimation
end

-- use to override the calculated entry width when we have a scroll list
-- whose width is not equivalent to the number of visible entries
function ZO_HorizontalScrollList:SetEntryWidth(entryWidth)
    self.controlEntryWidth = entryWidth
end

function ZO_HorizontalScrollList:RefreshVisible()
    if #self.list > 0 then
        local INITIAL_UPDATE = true
        if self.isMoving then
            self:UpdateAnchors(self.lastPrimaryControlOffsetX, INITIAL_UPDATE)
        else
            local RESELECTING_DURING_REBUILD = true
            self:UpdateAnchors(self:CalculateSelectedIndexOffsetWithDrag(), INITIAL_UPDATE, RESELECTING_DURING_REBUILD)
        end
    end
end

function ZO_HorizontalScrollList:AddEntry(data)
    self.list[#self.list + 1] = data
end

function ZO_HorizontalScrollList:MoveLeft()
    self:SetSelectedIndex((self.selectedIndex or 0) - 1)
end

function ZO_HorizontalScrollList:MoveRight()
    self:SetSelectedIndex((self.selectedIndex or 0) + 1)
end

function ZO_HorizontalScrollList:SetSelectedIndex(selectedIndex, allowEvenIfDisabled, withoutAnimation, reselectingDuringRebuild)
    if self.enabled or allowEvenIfDisabled then
        if selectedIndex and not self.allowWrapping then
            selectedIndex = zo_clamp(selectedIndex, 1 - #self.list, 0)
        end

        if self.selectedIndex ~= selectedIndex then
            if self.onTargetDataChangedCallback then
                local oldData = self.targetData
                local targetIndex = self:CalculateDataIndexFromOffset(-selectedIndex)
                self.targetData = self.list[targetIndex]
                self.onTargetDataChangedCallback(self.targetData, oldData, reselectingDuringRebuild)
            end

            if self.selectedIndex and self.active then
                if selectedIndex > self.selectedIndex then
                    self.onPlaySoundFunction(ZO_HORIZONTALSCROLLLIST_MOVEMENT_TYPES.MOVE_RIGHT)
                else
                    self.onPlaySoundFunction(ZO_HORIZONTALSCROLLLIST_MOVEMENT_TYPES.MOVE_LEFT)
                end
            end
            self.selectedIndex = selectedIndex
        end
    end

    if withoutAnimation then
        self:UpdateAnchors(self:CalculateSelectedIndexOffsetWithDrag())
    end
end

function ZO_HorizontalScrollList:SetSelectedDataIndex(dataIndex, allowEvenIfDisabled, withoutAnimation)
    self:SetSelectedIndex(1 - dataIndex, allowEvenIfDisabled, withoutAnimation)
end

function ZO_HorizontalScrollList:Clear()
    self.lastPrimaryControlOffsetX = nil
    self.oldSelectedData = self.selectedData
    self.selectedIndex = nil
    self.selectedData = nil
    self:SetMoving(false)
    self.list = {}

    for i, entry in ipairs(self.controls) do
        entry:SetHidden(true)
    end
    if self.onClearedFunction then
        self.onClearedFunction(self)
    end
end

local function FindMatchingIndex(oldSelectedData, halfNumVisibleEntries, newDataList, equalityFunction)
    if oldSelectedData then
        for newDataIndex, newData in ipairs(newDataList) do
            if equalityFunction(oldSelectedData, newData) then
                return 1 - newDataIndex
            end
        end
    end
    return nil
end

function ZO_HorizontalScrollList:FindIndexFromData(oldSelectedData, equalityFunction)
    if (not equalityFunction) then
        equalityFunction = function (oldData, newData) return (oldData == newData) end
    end
    return FindMatchingIndex(oldSelectedData, self.halfNumVisibleEntries, self.list, equalityFunction)
end

function ZO_HorizontalScrollList:Commit()
    local hasItems = #self.list > 0
    if hasItems then
        for i, entry in ipairs(self.controls) do
            entry:SetHidden(false)
        end

        local matchingIndex = FindMatchingIndex(self.oldSelectedData, self.halfNumVisibleEntries, self.list, self.equalityFunction)
        local reselectingDuringRebuild = matchingIndex ~= nil
        local ALLOW_EVEN_IF_DISABLED = true
        self:SetSelectedIndex(matchingIndex or 0, ALLOW_EVEN_IF_DISABLED, reselectingDuringRebuild)

        local INITIAL_UPDATE = true
        self:UpdateAnchors(self:CalculateSelectedIndexOffsetWithDrag(), INITIAL_UPDATE, reselectingDuringRebuild)
    end

    self.oldSelectedData = nil

    if self.noItemsLabel then
        self.noItemsLabel:SetHidden(hasItems)
    end

    local hideArrows = #self.list == 0 or (#self.list == 1 and not self.allowWrapping)
    self.leftArrow:SetHidden(hideArrows)
    self.rightArrow:SetHidden(hideArrows)

    if hasItems and self.onCommitWithItemsFunction then
        self.onCommitWithItemsFunction(self)
    end
end

function ZO_HorizontalScrollList:GetSelectedData()
    return self.selectedData
end

function ZO_HorizontalScrollList:GetControl()
    return self.control
end

function ZO_HorizontalScrollList:GetSelectedIndex()
    return self.selectedIndex
end

function ZO_HorizontalScrollList:GetCenterControl()
    return self.controls[self.halfNumVisibleEntries + 1]
end

function ZO_HorizontalScrollList:GetNumItems()
    return #self.list
end

function ZO_HorizontalScrollList:ApplyTemplateToControls(template)
    for i, entry in ipairs(self.controls) do
        ApplyTemplateToControl(entry, template)
    end
end

function ZO_HorizontalScrollList:SetMouseEnabled(mouseEnabled)
	self.control:SetMouseEnabled(mouseEnabled)
end

--[[ Private API ]]--

function ZO_HorizontalScrollList:OnUpdate()
    if #self.list > 0 and self.lastPrimaryControlOffsetX then
        local targetOffsetX = self:CalculateSelectedIndexOffsetWithDrag()
        if self.dragging then
            self:SetMoving(true)
            self:UpdateAnchors(targetOffsetX)
        elseif zo_abs(targetOffsetX - self.lastPrimaryControlOffsetX) > 2 then
            self:SetMoving(true)
            local xOffset = zo_deltaNormalizedLerp(self.lastPrimaryControlOffsetX, targetOffsetX, .2)
            self:UpdateAnchors(xOffset)
        elseif self.isMoving then
            self:SetMoving(false)
            self:UpdateAnchors(targetOffsetX)
        end
    end
end

function ZO_HorizontalScrollList:CalculateSelectedIndexOffset()
    if self.selectedIndex then
        return self.selectedIndex * self.controlEntryWidth
    end
    return 0
end

function ZO_HorizontalScrollList:CalculateSelectedIndexOffsetWithDrag()
    if self.dragging then
        if self.allowWrapping then
            return self:CalculateSelectedIndexOffset() + (GetUIMousePosition() - self.draggingXStart) 
        end
        return zo_clamp(self:CalculateSelectedIndexOffset() + (GetUIMousePosition() - self.draggingXStart), -self.controlEntryWidth * (#self.list - 1), 0)
    end
    return self:CalculateSelectedIndexOffset()
end

function ZO_HorizontalScrollList:CalculateOffsetIndex(controlIndex, newVisibleIndex)
    return (controlIndex - newVisibleIndex) - self.halfNumVisibleEntries - 1
end

function ZO_HorizontalScrollList:CalculateControlIndexFromOffset(offsetIndex, newVisibleIndex)
    return offsetIndex + newVisibleIndex + self.halfNumVisibleEntries + 1
end

function ZO_HorizontalScrollList:CalculateDataIndexFromOffset(offsetIndex)
    return offsetIndex % #self.list + 1
end

function ZO_HorizontalScrollList:SetOnSelectedDataChangedCallback(onSelectedDataChangedCallback)
    self.onSelectedDataChangedCallback = onSelectedDataChangedCallback
end

function ZO_HorizontalScrollList:SetOnTargetDataChangedCallback(onTargetDataChangedCallback)
    self.onTargetDataChangedCallback = onTargetDataChangedCallback
end

function ZO_HorizontalScrollList:UpdateAnchors(primaryControlOffsetX, initialUpdate, reselectingDuringRebuild)
    if self.isUpdatingAnchors then return end
    self.isUpdatingAnchors = true

    local oldPrimaryControlOffsetX = self.lastPrimaryControlOffsetX or 0
    local oldVisibleIndex = zo_round(oldPrimaryControlOffsetX / self.controlEntryWidth)
    local newVisibleIndex = zo_round(primaryControlOffsetX / self.controlEntryWidth)

    local visibleIndicesChanged = oldVisibleIndex ~= newVisibleIndex
    local oldData = self.selectedData
    for i, control in ipairs(self.controls) do
        local index = self:CalculateOffsetIndex(i, newVisibleIndex)
        if not self.allowWrapping and (index >= #self.list or index < 0) then
            control:SetHidden(true)
        else
            control:SetHidden(false)

            if initialUpdate or visibleIndicesChanged then
                local dataIndex = self:CalculateDataIndexFromOffset(index)
                local selected = i == self.halfNumVisibleEntries + 1

                local data = self.list[dataIndex]
                if selected then
                    self.selectedData = data
                    if not reselectingDuringRebuild and self.selectionHighlightAnimation and not self.selectionHighlightAnimation:IsPlaying() then
                        self.selectionHighlightAnimation:PlayFromStart()
                    end
                    if not initialUpdate and not reselectingDuringRebuild and self.dragging then
                        self.onPlaySoundFunction(ZO_HORIZONTALSCROLLLIST_MOVEMENT_TYPES.INITIAL_UPDATE)
                    end
                end
                self.setupFunction(control, data, selected, reselectingDuringRebuild, self.enabled, self.selectedFromParent)
            end

            local offsetX = primaryControlOffsetX + index * self.controlEntryWidth
            control:ClearAnchors()
            if self.displayEntryType == ZO_HORIZONTAL_SCROLL_LIST_DISPLAY_FIXED_NUMBER_OF_ENTRIES then
                self:SetDefaultEntryAnchor(control, offsetX)
            else
                self:AnchorEntryAtFixedOffset(control, offsetX, index, newVisibleIndex)
            end

            if self.minScale and self.maxScale then
                local amount = ZO_EaseInQuintic(zo_max(1.0 - zo_abs(offsetX) / (self.control:GetWidth() * .5), 0.0))
                control:SetScale(zo_lerp(self.minScale, self.maxScale, amount))
            end
        end
    end

    self.lastPrimaryControlOffsetX = primaryControlOffsetX

    self.leftArrow:SetEnabled(self.enabled and (self.allowWrapping or newVisibleIndex ~= 0))
    self.rightArrow:SetEnabled(self.enabled and (self.allowWrapping or newVisibleIndex ~= 1 - #self.list))

    self.isUpdatingAnchors = false

    if (self.selectedData ~= oldData or initialUpdate) and self.onSelectedDataChangedCallback then
        self.onSelectedDataChangedCallback(self.selectedData, oldData, reselectingDuringRebuild)
    end
end

function ZO_HorizontalScrollList:SetDefaultEntryAnchor(control, offsetX)
    control:SetAnchor(CENTER, self.control, CENTER, offsetX)
end

function ZO_HorizontalScrollList:AnchorEntryAtFixedOffset(control, offsetX, index, newVisibleIndex)
    local controlHalfWidth = self.controlEntryWidth / 2
    -- check if control is on the left side
    if offsetX < -controlHalfWidth then
        local nextControlIndex = self:CalculateControlIndexFromOffset(index + 1, newVisibleIndex)
        local nextControl = self.controls[nextControlIndex]
        control:SetAnchor(RIGHT, nextControl, LEFT, -self.offsetBetweenEntries)
    -- check if control is on the right side
    elseif offsetX > controlHalfWidth then
        local previousControlIndex = self:CalculateControlIndexFromOffset(index - 1, newVisibleIndex)
        local previousControl = self.controls[previousControlIndex]
        control:SetAnchor(LEFT, previousControl, RIGHT, self.offsetBetweenEntries)
    else
        self:SetDefaultEntryAnchor(control, offsetX)
    end
end

function ZO_HorizontalScrollList:SelectControl(controlToSelect)
    for i, control in ipairs(self.controls) do
        if controlToSelect == control then
            self:SetSelectedIndex((self.selectedIndex or 0) - (i - self.halfNumVisibleEntries - 1))
            break
        end
    end
end

function ZO_HorizontalScrollList:SelectControlFromCondition(conditionFunction)
    if (conditionFunction) then
        for i, control in ipairs(self.controls) do
            if conditionFunction(control) then
                self:SetSelectedIndex((self.selectedIndex or 0) - (i - self.halfNumVisibleEntries - 1))
                break
            end
        end
    end
end

function ZO_HorizontalScrollList:SetMoving(isMoving)
    if self.isMoving ~= isMoving then
        self.isMoving = isMoving
        if self.onMovementChangedCallback then
            self.onMovementChangedCallback(self, isMoving)
        end

        if self.selectionHighlightControl then
            self.selectionHighlightControl:SetHidden(isMoving)
        end
    end
end

--This is for the case where a horizontal scroll list is an entry in another list
-- and you want to change the horizontals look based on it being selected
function ZO_HorizontalScrollList:SetSelectedFromParent(selected)
    self.selectedFromParent = selected
end

function ZO_HorizontalScrollList:SetPlaySoundFunction(fn)
    self.onPlaySoundFunction = fn
end
