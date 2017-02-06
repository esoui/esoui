local DEFAULT_EXPECTED_ENTRY_HEIGHT = ZO_GAMEPAD_DEFAULT_LIST_ENTRY_SELECTED_HEIGHT
local DEFAULT_EXPECTED_HEADER_HEIGHT = 24

ZO_PARAMETRIC_MOVEMENT_TYPES = 
{
    MOVE_NEXT = 1,
    MOVE_PREVIOUS = 2,
    JUMP_NEXT = 3,
    JUMP_PREVIOUS = 4,
    -- LAST allows derived classes to start their movement enumerations after the base movements 
    LAST = 5,
}

ZO_ParametricScrollList = ZO_CallbackObject:Subclass()

--[[ Public  API ]]--
function ZO_ParametricScrollList:New(...)
    local scrollList = ZO_CallbackObject.New(self)
    scrollList:Initialize(...)
    return scrollList
end

PARAMETRIC_SCROLL_LIST_VERTICAL = true
PARAMETRIC_SCROLL_LIST_HORIZONTAL = false
ZO_VERTICAL_PARAMETRIC_LIST_DEFAULT_FADE_GRADIENT_SIZE = 150
ZO_HORIZONTAL_PARAMETRIC_LIST_DEFAULT_FADE_GRADIENT_SIZE = 300

function ZO_ParametricScrollList:Initialize(control, mode, onActivatedChangedFunction, onCommitWithItemsFunction, onClearedFunction)
    self.control = control
    control.scrollList = self
    self.scrollControl = control:GetNamedChild("Scroll")
    
    local screenCenterControl = control:GetNamedChild("ListScreenCenterIsAlongTop")
    if(screenCenterControl) then
        self.alignToScreenCenterAnchor = screenCenterControl:GetNamedChild("ListScreenCenter")
    end

    self.mode = mode
    self.onActivatedChangedFunction = onActivatedChangedFunction
    self.onCommitWithItemsFunction = onCommitWithItemsFunction
    self.onClearedFunction = onClearedFunction
    self.onPlaySoundFunction = function()
        PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
    end

    self.previousArrow = self.control:GetNamedChild("PreviousArrow")
    self.nextArrow = self.control:GetNamedChild("NextArrow")

    self.scrollUpControl = self.control:GetNamedChild("ScrollUp")
    self.scrollDownControl = self.control:GetNamedChild("ScrollDown")

    self.minOffset = 0
    self.maxOffset = 40

    self.additonalMinBottomOffset = 0
    self.additonalMaxBottomOffset = 0

    self.universalPrePadding = 0
    self.universalPostPadding = 0

    self.headerDefaultPadding = 0
    self.headerSelectedPadding = 0

    self.defaultSelectedIndex = 0

    self.fixedCenterOffset = 0

    self.isMoving = false
    self.animationEnabled = true
    self.soundEnabled = true
    self.directionalInputEnabled = true
    self.validateGradient = true
    self.validGradientDirty = true
    self.anchorOppositeSide = false

    self:SetActive(false)
    self.enabled = true

    self.centerDampingFactor = 0

    self.movementController = ZO_MovementController:New(self.mode == PARAMETRIC_SCROLL_LIST_VERTICAL and MOVEMENT_CONTROLLER_DIRECTION_VERTICAL or MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    self.dataTypes = {}
	self.commitHistoryDictionary = {}

    self.control:SetHandler("OnUpdate", function() self:OnUpdate() end)

    self.noItemsLabel = self.control:GetNamedChild("NoItemsLabel")

    self:Clear()
end

local function DefaultEqualityFunction(leftData, rightData)
    return leftData == rightData
end

function ZO_ParametricScrollList:HasDataTemplate(templateName) 
    return self.dataTypes[templateName] ~= nil
end

function ZO_ParametricScrollList:AddDataTemplate(templateName, setupFunction, parametricFunction, equalityFunction, controlPoolPrefix, controlPoolResetFunction)
    if not self.dataTypes[templateName] then
        local controlPool = ZO_ControlPool:New(templateName, self.scrollControl, controlPoolPrefix)
        local dataTypeInfo = {
            pool = controlPool,
            setupFunction = setupFunction,
            parametricFunction = parametricFunction,
            equalityFunction = equalityFunction or DefaultEqualityFunction,
            hasHeader = false,
        }
        if controlPoolResetFunction then
            controlPool:SetCustomResetBehavior(controlPoolResetFunction)
        end
        self.dataTypes[templateName] = dataTypeInfo
    end
end

function ZO_ParametricScrollList:SetDataTemplateReleaseFunction(templateName, releaseFunction)
    if self.dataTypes[templateName] then
        self.dataTypes[templateName].pool:SetCustomResetBehavior(releaseFunction)
    end
end

function ZO_ParametricScrollList:SetDataTemplateWithHeaderReleaseFunction(templateName, releaseFunction)
    local function HeaderReleaseFunction(control)
        control.headerControl:SetHidden(true)
        releaseFunction(control)
    end
    self:SetDataTemplateReleaseFunction(templateName.."WithHeader", HeaderReleaseFunction)
end

function ZO_ParametricScrollList_DefaultMenuEntryWithHeaderSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    if data.header then 
        control:SetText(data.header)
    end
end

function ZO_ParametricScrollList:AddDataTemplateWithHeader(templateName, setupFunction , parametricFunction, equalityFunction, headerTemplateName, optionalHeaderSetupFunction, controlPoolPrefix)
    local entryTemplateName = templateName
    templateName = templateName.."WithHeader"
    if not self.dataTypes[templateName] then
        if controlPoolPrefix then 
            controlPoolPrefix = controlPoolPrefix.."WithHeader" 
        end
        local dataTypeInfo = {
            pool = ZO_ControlPool:New(entryTemplateName, self.scrollControl, controlPoolPrefix or templateName),
            setupFunction = setupFunction,
            parametricFunction = parametricFunction,
            equalityFunction = equalityFunction or DefaultEqualityFunction,
            headerSetupFunction = optionalHeaderSetupFunction or ZO_ParametricScrollList_DefaultMenuEntryWithHeaderSetup,
            hasHeader = true,
        }
        dataTypeInfo.pool:SetCustomFactoryBehavior(function(control)
            local headerControl = CreateControlFromVirtual(control:GetName().."Header", self.scrollControl, headerTemplateName)
            --We create the control as a child of the scroll control, but the anchors are specified in relation to this control.
            --We do this to have the header not inherit alpha from changing the control's alpha
            for i = 0, 1 do
                local isValid, point, relTo, relPoint, offsetX, offsetY = headerControl:GetAnchor(i)
                if isValid then
                    headerControl:SetAnchor(point, control, relPoint, offsetX, offsetY)
                end
            end
            control.headerControl = headerControl
        end)

        dataTypeInfo.pool:SetCustomResetBehavior(function(control)
                control.headerControl:SetHidden(true)
            end)

        dataTypeInfo.pool:SetCustomAcquireBehavior(function(control)
                control.headerControl:SetHidden(false)
            end)

        self.dataTypes[templateName] = dataTypeInfo
    end
end

function ZO_ParametricScrollList:AddEntry(templateName, data, prePadding, postPadding, preSelectedOffsetAdditionalPadding, postSelectedOffsetAdditionalPadding, selectedCenterOffset)
    if self.dataTypes[templateName] then
        self.templateList[#self.templateList + 1] = templateName
        self.dataList[#self.dataList + 1] = data

        -- NOTE: These are set to false if not specified as nil will cause the next entry to have an incorrect index in the field. Direct
        --  access is not recommended, use the GetSelectedAdditionalPaddingForDataIndex() or GetPaddingForDataIndex() functions instead.
        self.prePadding[#self.prePadding + 1] = prePadding or 0
        self.postPadding[#self.postPadding + 1] = postPadding or false
        self.preSelectedOffsetAdditionalPadding[#self.preSelectedOffsetAdditionalPadding + 1] = preSelectedOffsetAdditionalPadding or false
        self.postSelectedOffsetAdditionalPadding[#self.postSelectedOffsetAdditionalPadding + 1] = postSelectedOffsetAdditionalPadding or false
        self.selectedCenterOffset[#self.selectedCenterOffset + 1] = selectedCenterOffset or 0
    end
end

function ZO_ParametricScrollList:GetNumEntries()
    return #self.dataList
end

function ZO_ParametricScrollList:GetEntryData(index)
    return self.dataList[index]
end

function ZO_ParametricScrollList:AddEntryWithHeader(templateName, ...)
    self:AddEntry(templateName.."WithHeader", ...)
end

function ZO_ParametricScrollList:SetOnMovementChangedCallback(onMovementChangedCallback)
    self:RegisterCallback("MovementChanged", onMovementChangedCallback)
end

function ZO_ParametricScrollList:RemoveOnMovementChangedCallback(onMovementChangedCallback)
    self:UnregisterCallback("MovementChanged", onMovementChangedCallback)
end

function ZO_ParametricScrollList:SetOnTargetDataChangedCallback(onTargetDataChangedCallback)
    self:RegisterCallback("TargetDataChanged", onTargetDataChangedCallback)
end

function ZO_ParametricScrollList:RemoveOnTargetDataChangedCallback(onTargetDataChangedCallback)
    self:UnregisterCallback("TargetDataChanged", onTargetDataChangedCallback)
end

function ZO_ParametricScrollList:SetOnSelectedDataChangedCallback(onSelectedDataChangedCallback)
    self:RegisterCallback("SelectedDataChanged", onSelectedDataChangedCallback)
end

function ZO_ParametricScrollList:RemoveOnSelectedDataChangedCallback(onSelectedDataChangedCallback)
    self:UnregisterCallback("SelectedDataChanged", onSelectedDataChangedCallback)
end

function ZO_ParametricScrollList:RemoveAllOnSelectedDataChangedCallbacks()
    self:UnregisterAllCallbacks("SelectedDataChanged")
end

function ZO_ParametricScrollList:SetDrawScrollArrows(drawScrollArrows)
    self.drawScrollArrows = drawScrollArrows
end

function ZO_ParametricScrollList:SetAnchorOppositeSide(anchorOppositeSide)
    self.anchorOppositeSide = true
end

function ZO_ParametricScrollList:UpdateScrollArrows()
    if(self.drawScrollArrows) then 
        local selectedIndex = self:CalculateSelectedIndexOffsetWithDrag()

        local numItems = self:GetNumItems()

        local firstSelectedableIndex = self:GetNextSelectableIndex(0) -- this function adds 1 from the passed in current index

        if(self.scrollUpControl ~= nil) then
            local hideScrollUp = selectedIndex == firstSelectedableIndex or self:IsControlIndexFullyVisible(1)
            self.scrollUpControl:SetHidden(hideScrollUp)
        end

        if(self.scrollDownControl ~= nil) then
            local hideScrollDown = selectedIndex == numItems or self:IsControlIndexFullyVisible(numItems)
            self.scrollDownControl:SetHidden(hideScrollDown)
        end
    end
end

function ZO_ParametricScrollList:SetSortFunction(sortFunction)
    self.sortFunction = sortFunction
end

function ZO_ParametricScrollList:SetFixedCenterOffset(fixedCenterOffset)
    if self.fixedCenterOffset ~= fixedCenterOffset then
        self.fixedCenterOffset = fixedCenterOffset
        self.validGradientDirty = true
        self:RefreshVisible()
    end
end

function ZO_ParametricScrollList:SetAlignToScreenCenter(alignToScreenCenter, expectedEntryHeight)
    if(not self.alignToScreenCenterAnchor) then return end

    local expectedEntryHalfHeight = (expectedEntryHeight or DEFAULT_EXPECTED_ENTRY_HEIGHT) / 2.0

    if(self.alignToScreenCenter ~= alignToScreenCenter or self.alignToScreenCenterExpectedEntryHalfHeight ~= expectedEntryHalfHeight) then
        self.alignToScreenCenter = alignToScreenCenter
        self.alignToScreenCenterExpectedEntryHalfHeight = expectedEntryHalfHeight

        self.validGradientDirty = true
        self:RefreshVisible()
    end
end

function ZO_ParametricScrollList:SetActive(active, fireActivatedCallback)
    if self.active ~= active then
        --If the list is still animating when it is deactivated then complete the animation instantly before deactivating.
        --Otherwise, things can happen like selected index changing which the list is deactivated
        if not active and self:IsMoving() then
            self:UpdateAnchors(self.targetSelectedIndex)
            self:SetMoving(false)
        end
        
        self.active = active

        if self.active and self.directionalInputEnabled then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end

        if self.onActivatedChangedFunction and fireActivatedCallback ~= false then
            self.onActivatedChangedFunction(self, self.active)
        end
    end
end

function ZO_ParametricScrollList:SetOnActivatedChangedFunction(func)
    self.onActivatedChangedFunction = func
end

function ZO_ParametricScrollList:GetOnActivatedChangedFunction()
    return self.onActivatedChangedFunction
end 

function ZO_ParametricScrollList:IsActive()
    return self.active
end

function ZO_ParametricScrollList:Activate()
    self:SetActive(true)
end

function ZO_ParametricScrollList:ActivateWithoutChangedCallback()
    local FIRE_ACTIVATION_CHANGED = false
    self:SetActive(true, FIRE_ACTIVATION_CHANGED)
end

function ZO_ParametricScrollList:Deactivate()
    self:SetActive(false)
end

function ZO_ParametricScrollList:DeactivateWithoutChangedCallback()
    local FIRE_ACTIVATION_CHANGED = false
    self:SetActive(false, FIRE_ACTIVATION_CHANGED)
end

function ZO_ParametricScrollList:SetEnabled(enabled)
    if self.enabled ~= enabled then
        self.enabled = enabled

        self.dragging = false

        self:RefreshVisible()
    end
end

function ZO_ParametricScrollList:SetSelectedItemOffsets(minOffset, maxOffset)
    self.minOffset = minOffset
    self.maxOffset = maxOffset
end

function ZO_ParametricScrollList:SetAdditionalBottomSelectedItemOffsets(additonalMinBottomOffset, additonalMaxBottomOffset)
    self.additonalMinBottomOffset = additonalMinBottomOffset
    self.additonalMaxBottomOffset = additonalMaxBottomOffset
end

function ZO_ParametricScrollList:SetUniversalPrePadding(universalPrePadding)
    self.universalPrePadding = universalPrePadding
end

function ZO_ParametricScrollList:SetUniversalPostPadding(universalPostPadding)
    self.universalPostPadding = universalPostPadding
end

function ZO_ParametricScrollList:SetNoItemText(text)
    if self.noItemsLabel then
        self.noItemsLabel:SetText(text)
        self:RefreshNoItemLabelPosition()
    end
end

function ZO_ParametricScrollList:IsMoving()
    return self.isMoving
end

function ZO_ParametricScrollList:RefreshVisible()
    if self.dataList and (#self.dataList > 0) then
        local INITIAL_UPDATE = true
        local RESELECTING_DURING_REBUILD = true
        if self.isMoving then
            self:UpdateAnchors(self.lastContinousTargetOffset, INITIAL_UPDATE)
        else
            self:UpdateAnchors(self:CalculateSelectedIndexOffsetWithDrag(), INITIAL_UPDATE, RESELECTING_DURING_REBUILD)
        end
    end
    self:RefreshNoItemLabelPosition()
end

local function CanSelectData(data)
    if data and type(data) == "table" then
        return data.canSelect ~= false -- true if nil
    end
    return true -- default to true
end

function ZO_ParametricScrollList:CanSelect(newIndex)
    local data = self.dataList[zo_clamp(newIndex, 1, #self.dataList)]
    return CanSelectData(data)
end

function ZO_ParametricScrollList:MovePrevious()
    if #self.dataList > 1 then
        local newIndex = (self.targetSelectedIndex or self.selectedIndex or 2) - 1
        while newIndex >= 1 and  not self:CanSelect(newIndex) do
            newIndex = newIndex - 1
        end
        if newIndex >= 1 then
            self:SetSelectedIndex(newIndex)
            return true
        end
    end

    return false
end

function ZO_ParametricScrollList:MoveNext()
    if #self.dataList > 1 then
        local newIndex = self:GetNextSelectableIndex(self:CalculateSelectedIndexOffsetWithDrag())
        if newIndex <= #self.dataList then
            self:SetSelectedIndex(newIndex)
            return true
        end
    end

    return false
end

function ZO_ParametricScrollList:GetNumItems()
    return #self.dataList
end

function ZO_ParametricScrollList:IsControlIndexFullyVisible(index)
    local control = self.dataIndexToControl[index]

    if control then
        if(self.visibleControls[control] ~= true) then
            return false
        end

        local left, top, right, bottom = control:GetScreenRect()
        local leftList, topList, rightList, bottomList = self.control:GetScreenRect()

        return (bottom <= bottomList) and (top >= topList)
    end

    return false
end

function ZO_ParametricScrollList:GetSelectedIndex()
    return self.selectedIndex
end

function ZO_ParametricScrollList:SetSelectedIndexWithoutAnimation(selectedIndex, allowEvenIfDisabled, forceAnimation)
    self:EnableAnimation(false)
    self:SetSelectedIndex(selectedIndex, allowEvenIfDisabled, forceAnimation)
    self:EnableAnimation(true)
end

function ZO_ParametricScrollList:SetSelectedIndex(selectedIndex, allowEvenIfDisabled, forceAnimation, jumpType)
    self:SetJumping(false)

    if self.enabled or allowEvenIfDisabled then
        local oldTargetSelectedIndex = self.targetSelectedIndex
        self.targetSelectedIndex = zo_clamp(selectedIndex, 1, #self.dataList)
        local reachedTargetIndex = (self.targetSelectedIndex == self:CalculateSelectedIndexOffsetWithDrag())

        self:FireCallbacks("TargetDataChanged", self, self:GetDataForDataIndex(self.targetSelectedIndex), self:GetDataForDataIndex(oldTargetSelectedIndex), reachedTargetIndex, self.targetSelectedIndex)
        
        if self.targetSelectedIndex and self.selectedIndex then
            local moveAmount = zo_abs(self.targetSelectedIndex - self.selectedIndex)
            if jumpType and moveAmount > 0 then
                self:SetJumping(true)                
                self.onPlaySoundFunction(jumpType)
            end
        end

        if (not forceAnimation) and (not self.animationEnabled) then
            self:UpdateAnchors(self.targetSelectedIndex)
        end
    end
end

function ZO_ParametricScrollList:SetLastIndexSelected(jumpType)
    self:SetSelectedIndex(self:CalculateLastSelectableIndex(), nil, nil, jumpType)
end

function ZO_ParametricScrollList:SetFirstIndexSelected(jumpType)
    self:SetSelectedIndex(self:CalculateFirstSelectableIndex(), nil, nil, jumpType)
end

function ZO_ParametricScrollList:SetDefaultIndexSelected(animate, allowEvenIfDisabled, forceAnimation, jumpType)
    local index = self.defaultSelectedIndex or self:CalculateFirstSelectableIndex()
    if animate then
        self:SetSelectedIndex(index, allowEvenIfDisabled, forceAnimation, jumpType)
    else
        self:SetSelectedIndexWithoutAnimation(index, allowEvenIfDisabled, forceAnimation)
    end
end

function ZO_ParametricScrollList:CalculateFirstSelectableIndex()
    for i = 1, #self.dataList do
        if self:CanSelect(i) then
            return i
        end
    end
    return 1
end

function ZO_ParametricScrollList:CalculateLastSelectableIndex()
    for i = #self.dataList, 1, -1 do
        if self:CanSelect(i) then
            return i
        end
    end
    return #self.dataList
end

function ZO_ParametricScrollList:SetSelectedDataByEval(eval)
    self:SetSelectedDataByRangedEval(eval, 1, #self.dataList)
end

function ZO_ParametricScrollList:SetPreviousSelectedDataByEval(eval, jumpType)
    local selectedIndex = self.targetSelectedIndex or self.selectedIndex
    if selectedIndex then
        return self:SetSelectedDataByRangedEval(eval, zo_max(selectedIndex - 1, 1), 1, jumpType)
    end
end

function ZO_ParametricScrollList:SetNextSelectedDataByEval(eval, jumpType)
    local selectedIndex = self.targetSelectedIndex or self.selectedIndex
    if selectedIndex then
        return self:SetSelectedDataByRangedEval(eval, zo_min(selectedIndex + 1, #self.dataList), #self.dataList, jumpType)
    end
end

function ZO_ParametricScrollList:GetNextSelectableIndex(currentIndex)
    local newIndex = currentIndex + 1
    while (newIndex <= #self.dataList) and (self:CanSelect(newIndex) == false) do
        newIndex = newIndex + 1
    end
    return newIndex
end

function ZO_ParametricScrollList:SetSelectedDataByRangedEval(eval, startIndex, endIndex, jumpType)
    local direction = startIndex < endIndex and 1 or -1
    for i = startIndex, endIndex, direction do
        local data = self.dataList[i]
        if CanSelectData(data) and eval(data) then
            self:SetSelectedIndex(i, nil, nil, jumpType)
            return true
        end
    end
    return false
end

function ZO_ParametricScrollList:Clear()
    self.lastContinousTargetOffset = nil
    self.oldSelectedData = self.selectedData
    self.oldSelectedDataTemplate = self.templateList and self.templateList[self.selectedIndex]
    self.oldSelectedIndex = self.targetSelectedIndex
    self.selectedIndex = nil
    self.targetSelectedIndex = nil
    self.selectedData = nil
    self:SetMoving(false)
    self.dataList = {}
    self.templateList = {}
    self.prePadding = {}
    self.postPadding = {}
    self.preSelectedOffsetAdditionalPadding = {}
    self.postSelectedOffsetAdditionalPadding = {}
    self.selectedCenterOffset = {}
    self.lastCenterControlSize = nil

    self.visibleControls = {}
    self.dataIndexToControl = {}

    self.unseenControls = {}

	if self.currentCommitHistoryKey then
		self.commitHistoryDictionary[self.currentCommitHistoryKey] = { data = self.oldSelectedData, template = self.oldSelectedDataTemplate, selectedIndex = self.oldSelectedIndex }
	end

    for templateName, dataTypeInfo in pairs(self.dataTypes) do
        dataTypeInfo.pool:ReleaseAllObjects()
    end

    if self.onClearedFunction then
        self.onClearedFunction(self)
    end
end

local function FindMatchingIndex(oldSelectedData, newDataList, newTemplateList, oldTemplate, equalityFunction, oldSelectedIndex)
    for i = oldSelectedIndex, #newDataList do
        if newTemplateList[i] == oldTemplate and equalityFunction(oldSelectedData, newDataList[i]) then
            return i
        end
    end

    for i = oldSelectedIndex - 1, 1, -1 do
        if newTemplateList[i] == oldTemplate and equalityFunction(oldSelectedData, newDataList[i]) then
            return i
        end
    end

    return oldSelectedIndex
end

function ZO_ParametricScrollList:SetKeyForNextCommit(key)
	self.nextCommitHistoryKey = key
end

function ZO_ParametricScrollList:CommitWithoutReselect()
    local NO_RESELECT = true
    self:Commit(NO_RESELECT)
end

function ZO_ParametricScrollList:Commit(dontReselect, blockSelectionChangedCallback)
    self.validGradientDirty = true
    local dataListSize = #self.dataList
    local hasItems = dataListSize > 0
    if hasItems then
        if self.sortFunction then
            table.sort(self.dataList, self.sortFunction)
        end

		local nextSelectedIndex
		if self.nextCommitHistoryKey then
			local nextCommitHistory = self.commitHistoryDictionary[self.nextCommitHistoryKey]
			if nextCommitHistory then
				nextSelectedIndex = nextCommitHistory.selectedIndex
			end
		else
			nextSelectedIndex = self.oldSelectedIndex
		end
        
		local matchingIndex = self.targetSelectedIndex or nextSelectedIndex or self.defaultSelectedIndex
        if dontReselect then
            matchingIndex = self.defaultSelectedIndex
        else
            local oldSelectedData, oldSelectedDataTemplate

			if self.nextCommitHistoryKey and self.nextCommitHistoryKey ~= self.currentCommitHistoryKey then
				local nextCommitHistory = self.commitHistoryDictionary[self.nextCommitHistoryKey]
				if nextCommitHistory then
					oldSelectedData, oldSelectedDataTemplate = nextCommitHistory.data, nextCommitHistory.template
				end
			else
				oldSelectedData, oldSelectedDataTemplate = self.oldSelectedData, self.oldSelectedDataTemplate
			end

			if oldSelectedDataTemplate then
				local equalityFunction = self.dataTypes[oldSelectedDataTemplate].equalityFunction
				matchingIndex = FindMatchingIndex(oldSelectedData, self.dataList, self.templateList, oldSelectedDataTemplate, equalityFunction, matchingIndex)
            
				if (matchingIndex > dataListSize) then
					matchingIndex = dataListSize
				end
			end
        end

        while (matchingIndex <= dataListSize) and (self:CanSelect(matchingIndex) == false) do
            matchingIndex = matchingIndex + 1
        end
        if(matchingIndex > dataListSize) then
            matchingIndex = dataListSize
        end

        local ALLOW_EVEN_IF_DISABLED = true
        local FORCE_ANIMATION = true
        self:SetSelectedIndex(matchingIndex, ALLOW_EVEN_IF_DISABLED, FORCE_ANIMATION)

        local INITIAL_UPDATE = true
        local RESELECTING_DURING_REBUILD = true
        self:UpdateAnchors(self:CalculateSelectedIndexOffsetWithDrag(), INITIAL_UPDATE, RESELECTING_DURING_REBUILD, blockSelectionChangedCallback)

        -- If the selectedData is set in the setup function (such as for the header), the code above
        --  may have picked a non-selectable item if this is the first time the items were setup. As
        --  such, we need to check for that condition, and move to the next item if we hit it.
        if not CanSelectData(self.selectedData) then
            -- NOTE: MoveNext() will skip over additional unselectable items internally.
            if(matchingIndex == dataListSize) then
                self:MovePrevious()
            else
                self:MoveNext()
            end
        end
    end

    local oldSelectedData = self.oldSelectedData
    self.oldSelectedData = nil
    self.oldSelectedDataTemplate = nil
    self.oldSelectedIndex = nil

    if self.noItemsLabel then
        self.noItemsLabel:SetHidden(hasItems)
    end

    local hideArrows = dataListSize <= 1
    if self.previousArrow then
        self.previousArrow:SetHidden(hideArrows)
    end
    if self.nextArrow then
        self.nextArrow:SetHidden(hideArrows)
    end

	self.currentCommitHistoryKey, self.nextCommitHistoryKey = self.nextCommitHistoryKey, nil

    if hasItems then
        if self.onCommitWithItemsFunction then
            self.onCommitWithItemsFunction(self)
        end
    else
        if blockSelectionChangedCallback ~= true then
            self:FireCallbacks("SelectedDataChanged", self, nil, oldSelectedData, nil, self.targetSelectedIndex)
        end
    end
end

function ZO_ParametricScrollList:GetSelectedData()
    return self.selectedData
end

function ZO_ParametricScrollList:GetTargetData()
    local targetIndex = self:CalculateSelectedIndexOffsetWithDrag()
    return self:GetDataForDataIndex(targetIndex)
end

function ZO_ParametricScrollList:GetTargetIndex()
    return self:CalculateSelectedIndexOffsetWithDrag()
end

function ZO_ParametricScrollList:GetTargetControl()
    local targetIndex = self:CalculateSelectedIndexOffsetWithDrag()
    return self.dataIndexToControl[targetIndex]
end

function ZO_ParametricScrollList:GetControl()
    return self.control
end

function ZO_ParametricScrollList:GetScrollControl()
    return self.scrollControl
end

function ZO_ParametricScrollList:SetPlaySoundFunction(fn)
    self.onPlaySoundFunction = fn
end

function ZO_ParametricScrollList:SetMouseEnabled(mouseEnabled)
	self.control:SetMouseEnabled(mouseEnabled)
end

--[[ Private API ]]--
local function GetControlDimensionForMode(mode, control)
    return mode == PARAMETRIC_SCROLL_LIST_VERTICAL and control:GetHeight() or control:GetWidth()
end

local function TransformAnchorOffsetsForMode(mode, offsetX, offsetY)
    if mode == PARAMETRIC_SCROLL_LIST_VERTICAL then
        return offsetY, offsetX
    end
    return offsetX, offsetY
end

local function GetStartOfControl(mode, control)
    return mode == PARAMETRIC_SCROLL_LIST_VERTICAL and control:GetTop() or control:GetLeft()
end

local function GetEndOfControl(mode, control)
    return mode == PARAMETRIC_SCROLL_LIST_VERTICAL and control:GetBottom() or control:GetRight()
end

function ZO_ParametricScrollList:CalculateSelectedIndexOffsetWithDrag()
    return self.targetSelectedIndex or self.selectedIndex or 0
end

function ZO_ParametricScrollList:OnUpdate()
    if #self.dataList > 0 and self.lastContinousTargetOffset then
        local continousTargetOffset = self:CalculateSelectedIndexOffsetWithDrag()
        if self.dragging then
            self:SetMoving(true)
            self:UpdateAnchors(continousTargetOffset)
        elseif zo_abs(self.lastContinousTargetOffset - continousTargetOffset) > .01 then
            self:SetMoving(true)
            self:UpdateAnchors(self:CalculateNextLerpedContinousOffset(continousTargetOffset))
        elseif self.isMoving then
            self:SetMoving(false)
            self:UpdateAnchors(continousTargetOffset)
        end
    end
end

local SELECTION_LERP_RATE = 0.2
function ZO_ParametricScrollList:CalculateNextLerpedContinousOffset(continousTargetOffset)
    return zo_deltaNormalizedLerp(self.lastContinousTargetOffset, continousTargetOffset, SELECTION_LERP_RATE)
end

function ZO_ParametricScrollList:GetSelectedControl()
    return self.dataIndexToControl[self.selectedIndex]
end

function ZO_ParametricScrollList:EnableAnimation(enabled)
    self.animationEnabled = enabled
end

function ZO_ParametricScrollList:IsDirectionalInputEnabled()
    return self.directionalInputEnabled
end

function ZO_ParametricScrollList:SetDirectionalInputEnabled(enabled)
    self.directionalInputEnabled = enabled
    if enabled then
        DIRECTIONAL_INPUT:Activate(self, self.control)
    else
        DIRECTIONAL_INPUT:Deactivate(self)
    end
end

function ZO_ParametricScrollList:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()

    if self.customDirectionalInputHandler and self.customDirectionalInputHandler(result) then
        return
    end

    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self:MoveNext()
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self:MovePrevious()
    end
end

--Will fire a callback with the directional input result
--Optionally you can return true to consume the result before the list processes it
function ZO_ParametricScrollList:SetCustomDirectionInputHandler(handler)
    self.customDirectionalInputHandler = handler
end

function ZO_ParametricScrollList:SetHideUnselectedControls(state)
    self.hideUnselectedControls = state
end

function ZO_ParametricScrollList:SetAnchorForEntryControl(control, anchor1, anchor2, offsetX, offsetY) 
    local anchorTo = self.control

    if(self.alignToScreenCenter) then
        anchorTo = self.alignToScreenCenterAnchor
    end

    control:ClearAnchors()
    control:SetAnchor(anchor1, anchorTo, anchor2, offsetX, offsetY)
end

function ZO_ParametricScrollList:GetDesiredEntryAnchors()
    if self.entryAnchors then
       return self.entryAnchors[1], self.entryAnchors[2]
    elseif self.mode == PARAMETRIC_SCROLL_LIST_VERTICAL then
        if self.anchorOppositeSide then
            return BOTTOM, CENTER
        else
            return TOP, CENTER
        end
    else
        return TOP, TOP
    end
end

function ZO_ParametricScrollList:GetEntryFixedCenterOffset()
    if(self.alignToScreenCenter) then
        return self.fixedCenterOffset - self.alignToScreenCenterExpectedEntryHalfHeight
    end
    return self.fixedCenterOffset
end

local SELECTED = true
local UNSELECTED = false

function ZO_ParametricScrollList:UpdateAnchors(continousTargetOffset, initialUpdate, reselectingDuringRebuild, blockSelectionChangedCallback)
    self.visibleControls, self.unseenControls = self.unseenControls, self.visibleControls
    ZO_ClearTable(self.visibleControls)

    -- Find center control
    local newSelectedDataIndex = zo_round(continousTargetOffset)

    local centerControl, justCreated = self:AcquireControlAtDataIndex(newSelectedDataIndex)
    self.unseenControls[centerControl] = nil
    self.visibleControls[centerControl] = true
    local selectedData = self:GetDataForDataIndex(newSelectedDataIndex)
    local selectedDataChanged = self.selectedIndex ~= newSelectedDataIndex
    local oldSelectedData = self.selectedData

    if self.soundEnabled and not self.jumping and selectedDataChanged and oldSelectedData then
        if newSelectedDataIndex > self.selectedIndex then
            self.onPlaySoundFunction(ZO_PARAMETRIC_MOVEMENT_TYPES.MOVE_NEXT)
        else
            self.onPlaySoundFunction(ZO_PARAMETRIC_MOVEMENT_TYPES.MOVE_PREVIOUS)
        end
    end

    self.selectedData = selectedData
    self.selectedIndex = newSelectedDataIndex

    if justCreated or selectedDataChanged or initialUpdate then
        self:RunSetupOnControl(centerControl, self.selectedIndex, SELECTED, reselectingDuringRebuild, self.enabled, self.active)
    end

    local fixedCenterOffset = self:GetEntryFixedCenterOffset()

    local centerControlDimension = GetControlDimensionForMode(self.mode, centerControl)
    local baseOffset = newSelectedDataIndex - continousTargetOffset
    local preCenterPadding, postCenterPadding = self:GetPaddingForDataIndex(newSelectedDataIndex, 0, baseOffset)
    local centerOffset = centerControlDimension * baseOffset
    local centerSelectedOffsetAdditionalPrePadding, centerSelectedOffsetAdditionalPostPadding = self:GetSelectedAdditionalPaddingForDataIndex(newSelectedDataIndex)
    local centerSelectedOffset = self.selectedCenterOffset[newSelectedDataIndex]

    local parametricFunction = self:GetParametricFunctionForDataIndex(newSelectedDataIndex)
    if parametricFunction then
        parametricFunction(centerControl, 0, baseOffset)
    end
    
    local entryAnchor1, entryAnchor2 = self:GetDesiredEntryAnchors()

    local centerOffsetX, centerOffsetY = TransformAnchorOffsetsForMode(self.mode, centerOffset * self.centerDampingFactor + fixedCenterOffset + centerSelectedOffset * (1 - baseOffset), 0)
    self:SetAnchorForEntryControl(centerControl, entryAnchor1, entryAnchor2, centerOffsetX, centerOffsetY)

    if(not self.hideUnselectedControls) then
        -- Layout items before the center
        do
            local prevControlOffsets = centerOffset - (self.anchorOppositeSide and centerControlDimension or 0) + preCenterPadding + centerSelectedOffset * (1 - baseOffset)
            local startOfScrollContainer = GetStartOfControl(self.mode, self.control)
            for dataIndex = newSelectedDataIndex - 1, 1, -1 do
                local control = self:AcquireAndSetupControl(dataIndex, selectedDataChanged, initialUpdate, oldSelectedData, UNSELECTED)

                local distanceFromCenter = newSelectedDataIndex - dataIndex
                local preSelectedOffsetAdditionalPadding, _ = self:GetSelectedAdditionalPaddingForDataIndex(dataIndex)
                local parametricOffset = self:CalculateParametricOffset(centerSelectedOffsetAdditionalPrePadding, preSelectedOffsetAdditionalPadding, distanceFromCenter, baseOffset)
    
                local controlDimension = GetControlDimensionForMode(self.mode, control)
                local prePadding, postPadding = self:GetPaddingForDataIndex(dataIndex, distanceFromCenter, baseOffset)

                local parametricFunction = self:GetParametricFunctionForDataIndex(dataIndex)
                if parametricFunction then
                    parametricFunction(control, distanceFromCenter, baseOffset)
                end

                prevControlOffsets = prevControlOffsets - (self.anchorOppositeSide and 0 or controlDimension) - parametricOffset - postPadding
                self:SetAnchorForEntryControl(control, entryAnchor1, entryAnchor2, TransformAnchorOffsetsForMode(self.mode, prevControlOffsets + fixedCenterOffset, 0))
                prevControlOffsets = prevControlOffsets - prePadding - (self.anchorOppositeSide and controlDimension or 0) 

                if GetStartOfControl(self.mode, control) <= startOfScrollContainer then
                    break
                end
            end
        end

        -- Layout items after the center
        do
            local prevControlOffsets = centerOffset + (self.anchorOppositeSide and 0 or centerControlDimension) + postCenterPadding + centerSelectedOffset * (1 - baseOffset)
            local endOfScrollContainer = GetEndOfControl(self.mode, self.control)
            for dataIndex = newSelectedDataIndex + 1, #self.dataList do
                local control = self:AcquireAndSetupControl(dataIndex, selectedDataChanged, initialUpdate, oldSelectedData, UNSELECTED)

                local distanceFromCenter = newSelectedDataIndex - dataIndex
                local _, postSelectedOffsetAdditionalPadding = self:GetSelectedAdditionalPaddingForDataIndex(dataIndex)
                local parametricOffset = self:CalculateParametricOffset(centerSelectedOffsetAdditionalPostPadding, postSelectedOffsetAdditionalPadding, distanceFromCenter, baseOffset)
                local additionalBottomParametricOffset = self:CalculateAdditionalBottomParametricOffset(distanceFromCenter, baseOffset)

                local prePadding, postPadding = self:GetPaddingForDataIndex(dataIndex, distanceFromCenter, baseOffset)

                local parametricFunction = self:GetParametricFunctionForDataIndex(dataIndex)
                if parametricFunction then
                    parametricFunction(control, distanceFromCenter, baseOffset)
                end

                local controlDimension = GetControlDimensionForMode(self.mode, control)

                prevControlOffsets = prevControlOffsets + parametricOffset + prePadding + additionalBottomParametricOffset + (self.anchorOppositeSide and controlDimension or 0)

                self:SetAnchorForEntryControl(control, entryAnchor1, entryAnchor2, TransformAnchorOffsetsForMode(self.mode, prevControlOffsets + fixedCenterOffset, 0))
                
                prevControlOffsets = prevControlOffsets + (self.anchorOppositeSide and 0 or controlDimension) + postPadding

                if GetEndOfControl(self.mode, control) >= endOfScrollContainer then
                    break
                end
            end
        end
    end

    -- Remove unseen controls
    do
        for control in pairs(self.unseenControls) do
            self.unseenControls[control] = nil
            self:ReleaseControl(control)
        end
    end

    self.lastContinousTargetOffset = continousTargetOffset

    if selectedDataChanged and blockSelectionChangedCallback ~= true then
        local reachedTarget = (newSelectedDataIndex == self:CalculateSelectedIndexOffsetWithDrag())
        self:FireCallbacks("SelectedDataChanged", self, self.selectedData, oldSelectedData, reachedTarget, self.targetSelectedIndex)

        self:UpdateScrollArrows()

        self:SetJumping(not reachedTarget)
    end

    self:EnsureValidGradient()
end

function ZO_ParametricScrollList:RefreshNoItemLabelPosition()
    if self.noItemsLabel then
        local halfHeightOffset = self.noItemsLabel:GetTextHeight() / 2

        local entryAnchor1, entryAnchor2 = self:GetDesiredEntryAnchors()

        local centerOffsetX, centerOffsetY = TransformAnchorOffsetsForMode(self.mode, self.fixedCenterOffset - halfHeightOffset, 0)

        self:SetAnchorForEntryControl(self.noItemsLabel, entryAnchor1, entryAnchor2, centerOffsetX, centerOffsetY)
    end
end

local HAND_OFF_SPEED_FACTOR = 2
local function CalculateStandardOffset(distanceFromCenter, continuousParametricOffset, min, max, startAdditionalPadding, endAdditionalPadding, additionalPaddingEasingFunc)
    local parametricValue = zo_abs(zo_clamp(distanceFromCenter - continuousParametricOffset, -2, 2))


    local hasAdditionalPadding = (endAdditionalPadding ~= 0 or startAdditionalPadding ~= 0) and distanceFromCenter >= -1 and distanceFromCenter <= 1
    
    -- If easing function wasn't specified for additional padding, use the default
    if not additionalPaddingEasingFunc then
        additionalPaddingEasingFunc = ZO_EaseInQuartic
    end

    if parametricValue > 1 then
        local additionalPadding = hasAdditionalPadding and zo_lerp(startAdditionalPadding, endAdditionalPadding, zo_saturate(additionalPaddingEasingFunc(parametricValue - 1))) or 0
        return zo_lerp(max, min, zo_saturate(ZO_EaseInQuartic(parametricValue - 1) * HAND_OFF_SPEED_FACTOR)) + additionalPadding
    end

    local additionalPadding = hasAdditionalPadding and zo_lerp(endAdditionalPadding, startAdditionalPadding, zo_saturate(additionalPaddingEasingFunc(parametricValue))) or 0
    return zo_lerp(min, max, zo_saturate(ZO_EaseInQuartic(parametricValue) * HAND_OFF_SPEED_FACTOR)) + additionalPadding
end

function ZO_ParametricScrollList:CalculateParametricOffset(startAdditionalPadding, endAdditionalPadding, distanceFromCenter, continuousParametricOffset, additionalPaddingEasingFunc)
    return CalculateStandardOffset(distanceFromCenter, continuousParametricOffset, self.minOffset, self.maxOffset, startAdditionalPadding, endAdditionalPadding, additionalPaddingEasingFunc)
end

function ZO_ParametricScrollList:CalculateAdditionalBottomParametricOffset(distanceFromCenter, continuousParametricOffset, additionalPaddingEasingFunc)
    return CalculateStandardOffset(distanceFromCenter, continuousParametricOffset, self.additonalMinBottomOffset, self.additonalMaxBottomOffset, 0, 0, additionalPaddingEasingFunc)
end

function ZO_ParametricScrollList:GetSetupFunctionForDataIndex(dataIndex)
    local templateName = self.templateList[dataIndex]
    return self.dataTypes[templateName].setupFunction
end

function ZO_ParametricScrollList:RunSetupOnControl(control, dataIndex, selected, reselectingDuringRebuild, enabled, active)
    local setupFunction = self:GetSetupFunctionForDataIndex(dataIndex)
    local data = self:GetDataForDataIndex(dataIndex)
    setupFunction(control, data, selected, reselectingDuringRebuild, enabled, active)
    local dataTypeInfo = self.dataTypes[control.templateName]
    if dataTypeInfo.headerSetupFunction then
        dataTypeInfo.headerSetupFunction(control:GetNamedChild("Header"), data, selected, reselectingDuringRebuild, enabled, active)
    end
end 

function ZO_ParametricScrollList:GetParametricFunctionForDataIndex(dataIndex)
    local templateName = self.templateList[dataIndex]
    return self.dataTypes[templateName].parametricFunction
end

function ZO_ParametricScrollList:GetDataForDataIndex(dataIndex)
    return self.dataList[dataIndex]
end

function ZO_ParametricScrollList:SetHeaderPadding(defaultPadding, selectedPadding)
    self.headerDefaultPadding = defaultPadding
    self.headerSelectedPadding = selectedPadding
end

function ZO_ParametricScrollList:GetHasHeaderForDataIndex(dataIndex)
    local templateInfo = self.dataTypes[self.templateList[dataIndex]]
    local nextTemplateInfo = self.dataTypes[self.templateList[dataIndex + 1]]

    local isHeader = templateInfo and templateInfo.hasHeader
    local nextHeader = nextTemplateInfo and nextTemplateInfo.hasHeader

    return isHeader, nextHeader
end

function ZO_ParametricScrollList:GetSelectedAdditionalPaddingForDataIndex(dataIndex)
    local preSelectedOffsetAdditionalPadding = self.preSelectedOffsetAdditionalPadding[dataIndex]
    local postSelectedOffsetAdditionalPadding = self.postSelectedOffsetAdditionalPadding[dataIndex]

    if (not preSelectedOffsetAdditionalPadding) or (not postSelectedOffsetAdditionalPadding) then
        local isHeader, isNextHeader = self:GetHasHeaderForDataIndex(dataIndex)

        preSelectedOffsetAdditionalPadding = preSelectedOffsetAdditionalPadding or (isHeader and self.headerSelectedPadding) or 0
        postSelectedOffsetAdditionalPadding = postSelectedOffsetAdditionalPadding or (isNextHeader and self.headerSelectedPadding) or 0
    end

    return preSelectedOffsetAdditionalPadding, postSelectedOffsetAdditionalPadding
end

function ZO_ParametricScrollList:GetPaddingForDataIndex(dataIndex, distanceFromCenter, continousParametricOffset)
    local prePadding = self.prePadding[dataIndex]
    local postPadding = self.postPadding[dataIndex]
    if (not postPadding) then
        local isHeader, isNextHeader = self:GetHasHeaderForDataIndex(dataIndex)
        postPadding = postPadding or (isNextHeader and self.headerDefaultPadding) or 0
    end

    local rawParametricValue = zo_clamp(distanceFromCenter - continousParametricOffset, -1, 1)
    if rawParametricValue == 0 then
        return prePadding + self.universalPrePadding, postPadding + self.universalPostPadding
    end

    local parametricValue = zo_abs(rawParametricValue)
    if parametricValue > .5 then
        parametricValue = 1 - (parametricValue - .5) / .5
    else
        parametricValue = parametricValue * 2
    end

    local preParametricValue, postParametricValue
    if rawParametricValue < 0 then
        preParametricValue = parametricValue
        postParametricValue = 0
    else
        preParametricValue = 0
        postParametricValue = parametricValue
    end

    return zo_lerp(prePadding, prePadding * .25, preParametricValue) + self.universalPrePadding, zo_lerp(postPadding, postPadding * .25, postParametricValue) + self.universalPostPadding
end


local function HasEditControl(control)
    if(control:GetType() == CT_EDITBOX) then
        return true
    else
        local numChildren = control:GetNumChildren()    
        if numChildren > 0 then
            for i = 1, numChildren do
                local child = control:GetChild(i)
                if(child and HasEditControl(child)) then
                    return true
                end
            end
        end

        return false
    end
end

function ZO_ParametricScrollList:AcquireControlAtDataIndex(dataIndex)
    do
        local control = self.dataIndexToControl[dataIndex]
        if control then
            self.unseenControls[control] = nil
            self.visibleControls[control] = true
            return control, false
        end
    end

    local templateName = self.templateList[dataIndex]
    local control, key = self.dataTypes[templateName].pool:AcquireObject()
    control.key = key
    control.templateName = templateName
    control.dataIndex = dataIndex

    --Check if one of the children of this control is an edit box the first time we create one of these
    if(self.dataTypes[templateName].hasEditControl == nil) then
        self.dataTypes[templateName].hasEditControl = HasEditControl(control)
    end

    self.dataIndexToControl[dataIndex] = control
    self.visibleControls[control] = true

    return control, true
end

function ZO_ParametricScrollList:ReleaseControl(control)
    local templateName = control.templateName

    self.dataIndexToControl[control.dataIndex] = nil
    
    local pool = self.dataTypes[templateName].pool
    pool:ReleaseObject(control.key)
end

function ZO_ParametricScrollList:AcquireAndSetupControl(dataIndex, selectedDataChanged, initialUpdate, oldSelectedData, selected)
    local control, justCreated = self:AcquireControlAtDataIndex(dataIndex)
    local data = self:GetDataForDataIndex(dataIndex)
    if justCreated or initialUpdate or (selectedDataChanged and oldSelectedData == data) then
        self:RunSetupOnControl(control, dataIndex, selected, reselectingDuringRebuild, self.enabled, self.active)
    end

    return control
end

local function FindEditControl(control)
    if(control:GetType() == CT_EDITBOX) then
        return control
    else
        local numChildren = control:GetNumChildren()    
        if numChildren > 0 then
            for i = 1, numChildren do
                local child = control:GetChild(i)
                local editControl = FindEditControl(child)
                if(editControl ~= nil) then
                    return FindEditControl(child)
                end
            end
        end

        return nil
    end
end


function ZO_ParametricScrollList:SetMoving(isMoving)
    if self.isMoving ~= isMoving then
        self.isMoving = isMoving

        --check for edit controls that need to be defocused before moving the current selection
        if(isMoving and self:DoesTemplateHaveEditBox(self.selectedIndex)) then
            local currentSelectedControl = self:GetSelectedControl()
            local editControl = FindEditControl(currentSelectedControl)
            editControl:LoseFocus()
        end

        self:FireCallbacks("MovementChanged", self, isMoving)

        if self.selectionHighlightControl then
            self.selectionHighlightControl:SetHidden(isMoving)
        end

        if not isMoving then
            self:UpdateScrollArrows()
        end
    end
end

function ZO_ParametricScrollList:DoesTemplateHaveEditBox(dataIndex)
    local templateName = self.templateList[dataIndex]
    return self.dataTypes[templateName].hasEditControl
end

function ZO_ParametricScrollList:SetValidateGradient(validate)
    self.validateGradient = validate
end

function ZO_ParametricScrollList:EnsureValidGradient()
    if self.validateGradient and self.validGradientDirty then
        -- control dimensions used / gradient coordinates only apply to vertical lists 
        if self.mode == PARAMETRIC_SCROLL_LIST_VERTICAL then
            local listStart = GetStartOfControl(self.mode, self.scrollControl)
            local listEnd = GetEndOfControl(self.mode, self.scrollControl)
            local listMid = listStart + (GetControlDimensionForMode(self.mode, self.scrollControl) / 2.0)
            if self.alignToScreenCenter and self.alignToScreenCenterAnchor then
                listMid = GetStartOfControl(self.mode, self.alignToScreenCenterAnchor)
            end

            listMid = listMid + self.fixedCenterOffset

            local hasHeaders = false
            for templateName, dataTypeInfo in pairs(self.dataTypes) do
                if dataTypeInfo.hasHeader then
                    hasHeaders = true
                    break
                end
            end

            local selectedControlBufferStart = 0
            if hasHeaders then
                selectedControlBufferStart = selectedControlBufferStart - self.headerSelectedPadding + DEFAULT_EXPECTED_HEADER_HEIGHT
            end

            local selectedControlBufferEnd = DEFAULT_EXPECTED_ENTRY_HEIGHT
            if self.alignToScreenCenterExpectedEntryHalfHeight then
                selectedControlBufferEnd = self.alignToScreenCenterExpectedEntryHalfHeight * 2.0
            end

            -- Have some small minimum effect
            local MINIMUM_ALLOWED_FADE_GRADIENT = 32
            local gradientMaxStart = zo_max(listMid - listStart - selectedControlBufferStart, MINIMUM_ALLOWED_FADE_GRADIENT)
            local gradientMaxEnd = zo_max(listEnd - listMid - selectedControlBufferEnd, MINIMUM_ALLOWED_FADE_GRADIENT)

            local gradientStartSize = zo_min(gradientMaxStart, ZO_VERTICAL_PARAMETRIC_LIST_DEFAULT_FADE_GRADIENT_SIZE)
            local gradientEndSize = zo_min(gradientMaxEnd, ZO_VERTICAL_PARAMETRIC_LIST_DEFAULT_FADE_GRADIENT_SIZE)

            local FIRST_FADE_GRADIENT = 1
            local SECOND_FADE_GRADIENT = 2
            local GRADIENT_TEX_CORD_0 = 0
            local GRADIENT_TEX_CORD_1 = 1
            local GRADIENT_TEX_CORD_NEG_1 = -1
            self.scrollControl:SetFadeGradient(FIRST_FADE_GRADIENT, GRADIENT_TEX_CORD_0, GRADIENT_TEX_CORD_1, gradientStartSize)
            self.scrollControl:SetFadeGradient(SECOND_FADE_GRADIENT, GRADIENT_TEX_CORD_0, GRADIENT_TEX_CORD_NEG_1, gradientEndSize)
        end
        self.validGradientDirty = false
    end
end

function ZO_ParametricScrollList:IsEmpty()
    return #self.dataList == 0
end

function ZO_ParametricScrollList:SetJumping(isJumping)
    self.jumping = isJumping
end

function ZO_ParametricScrollList:SetSoundEnabled(isSoundEnabled)
    self.soundEnabled = isSoundEnabled
end

--in case you don't want your list to default to the first entry in the list!
function ZO_ParametricScrollList:SetDefaultSelectedIndex(defaultSelectedIndex)
    self.defaultSelectedIndex = defaultSelectedIndex
end

function ZO_ParametricScrollList:WhenInactiveSetTargetControlHidden(hidden)
    if not self.active then
        local targetControl = self:GetTargetControl()
        targetControl:SetHidden(hidden)
        if targetControl.headerControl then
            targetControl.headerControl:SetHidden(hidden)
        end
    end
end