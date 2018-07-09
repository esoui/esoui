ZO_SharedSmithingResearch = ZO_Object:Subclass()

function ZO_SharedSmithingResearch:New(...)
    local smithingResearch = ZO_Object.New(self)
    smithingResearch:Initialize(...)
    return smithingResearch
end

function ZO_SharedSmithingResearch:Initialize(control, owner, slotContainerName)
    self.control = control
    self.owner = owner

    self.timer = ZO_TimerBar:New(control:GetNamedChild("TimerBar"))
    self.timer:SetDirection(TIMER_BAR_COUNTS_DOWN)
    self.timer:SetTimeFormatParameters(TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)

    self.slotPool = ZO_ControlPool:New(slotContainerName, self.control)

    local function HandleDirtyEvent()
        self:HandleDirtyEvent()
    end

    local function OnResearchComplete(eventId, craftingType, researchLineIndex, traitIndex)
        local cancelDialog = ZO_Dialogs_FindDialog("CONFIRM_CANCEL_RESEARCH")
        if cancelDialog then
            local data = cancelDialog.data
            if data.craftingType == craftingType and data.researchLineIndex == researchLineIndex and data.traitIndex == traitIndex then
                ZO_Dialogs_ReleaseDialog("CONFIRM_CANCEL_RESEARCH")
            end
        end
        self:HandleDirtyEvent()
    end

    self.control:RegisterForEvent(EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED, OnResearchComplete)
    self.control:RegisterForEvent(EVENT_SMITHING_TRAIT_RESEARCH_CANCELED, HandleDirtyEvent)

    self.dirty = true
end

function ZO_SharedSmithingResearch:ChangeTypeFilter(filterData)
    self.typeFilter = filterData.descriptor
    self:HandleDirtyEvent()
end

function ZO_SharedSmithingResearch:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    if isCraftingTypeDifferent or not self.typeFilter then
        self:RefreshAvailableFilters()
    end
end

local MIN_SCALE = .6
local MAX_SCALE = 1.0
local BASE_NUM_ITEMS_IN_LIST = 5

function ZO_SharedSmithingResearch:InitializeResearchLineList(scollListClass, listSlotContainerName)
    local listContainer = self.control:GetNamedChild("ResearchLineList")
    listContainer.titleLabel:SetText(GetString(SI_SMITHING_RESEARCH_LINE_HEADER))
    listContainer.selectedLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    listContainer.extraInfoLabel:SetColor(self:GetExtraInfoColor())

    local function CountNumResearchableTraits(data)
        if not data.researchingTraitIndex and data.itemTraitCounts and not data.areAllTraitsKnown then
            local researchableCount = 0
            for traitIndex in pairs(data.itemTraitCounts) do
                researchableCount = researchableCount + 1
            end
            return researchableCount
        end
        return 0
    end

    local function SetupFunction(control, data, selected, selectedDuringRebuild)
        control.timerIcon:SetHidden(selected or not data.researchingTraitIndex)

        local researchableCount = CountNumResearchableTraits(data)
        if selected then
            self.traitLineText = zo_strformat(SI_SMITHING_RESEARCH_TRAIT_NAME_FORMAT, data.name)
            listContainer.selectedLabel:SetText(self.traitLineText)
            self.isResearchingTrait = false
            self:ShowTraitsFor(data)
            
            if data.researchingTraitIndex then
                local durationSecs, timeRemainingSecs = GetSmithingResearchLineTraitTimes(data.craftingType, data.researchLineIndex, data.researchingTraitIndex)
                if durationSecs and timeRemainingSecs then
                    local now = GetFrameTimeSeconds()
                    local timeElapsed = durationSecs - timeRemainingSecs
                    self.timer:Start(now - timeElapsed, now + timeRemainingSecs)
                    listContainer.extraInfoLabel:SetHidden(true)
                end
            else
                self.timer:Stop()
                listContainer.extraInfoLabel:SetHidden(false)
                if data.areAllTraitsKnown then
                    listContainer.extraInfoLabel:SetText(GetString(SI_SMITHING_RESEARCH_ALL_RESEARCHED))
                else
                    if researchableCount > 0 then
                        listContainer.extraInfoLabel:SetText(self:GetResearchTimeString(researchableCount, ZO_FormatTime(data.timeRequiredForNextResearchSecs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)))
                    else
                        listContainer.extraInfoLabel:SetText(GetString(SI_SMITHING_RESEARCH_NO_TRAITS_RESEARCHABLE))
                    end
                end
            end
        end

        ZO_ItemSlot_SetAlwaysShowStackCount(control, researchableCount > 0)
        ZO_ItemSlot_SetupSlot(control, researchableCount, data.icon)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end

    local function EqualityFunction(leftData, rightData)
        return leftData.craftingType == rightData.craftingType and leftData.researchLineIndex == rightData.researchLineIndex
    end

    self.researchLineList = scollListClass:New(listContainer.listControl, listSlotContainerName, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction)
    listContainer:RegisterForEvent(EVENT_SMITHING_TRAIT_RESEARCH_TIMES_UPDATED, function() self.researchLineList:RefreshVisible() end)

    local highlightTexture = listContainer.highlightTexture
    self.researchLineList:SetSelectionHighlightInfo(highlightTexture, highlightTexture and highlightTexture.pulseAnimation)
    self.researchLineList:SetScaleExtents(MIN_SCALE, MAX_SCALE)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.researchLineList)
end

function ZO_SharedSmithingResearch:OnControlsAcquired()
    -- Subclasses must implement this function if needed.
    self.owner:OnResearchSlotChanged()
end

function ZO_SharedSmithingResearch:HandleDirtyEvent()
    if self.control:IsHidden() then
        self.dirty = true
    else
        self:Refresh()
    end
end

local function GetTraitIndexForItem(bagId, slotIndex, craftingType, researchLineIndex, numTraits)
    for traitIndex = 1, numTraits do
        if CanItemBeSmithingTraitResearched(bagId, slotIndex, craftingType, researchLineIndex, traitIndex) then
            return traitIndex
        end
    end
    return nil
end

function ZO_SharedSmithingResearch:GenerateResearchTraitCounts(virtualInventoryList, craftingType, researchLineIndex, numTraits)
    local counts

    for itemId, itemInfo in pairs(virtualInventoryList) do
        local traitIndex = GetTraitIndexForItem(itemInfo.bag, itemInfo.index, craftingType, researchLineIndex, numTraits)
        if traitIndex then
            counts = counts or {}
            counts[traitIndex] = (counts[traitIndex] or 0) + 1
        end
    end

    return counts
end

function ZO_SharedSmithingResearch:FindResearchingTraitIndex(craftingType, researchLineIndex, numTraits)
    local areAllTraitsKnown = true
    for traitIndex = 1, numTraits do
        local traitType, _, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)

        if not known then
            areAllTraitsKnown = false

            local durationSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)
            if durationSecs then
                return traitIndex, areAllTraitsKnown
            end
        end
    end
    return nil, areAllTraitsKnown
end

do
    local function IsNotLockedOrRetraitedItem(bagId, slotIndex)
        return not IsItemPlayerLocked(bagId, slotIndex) and GetItemTraitInformation(bagId, slotIndex) ~= ITEM_TRAIT_INFORMATION_RETRAITED
    end

    function ZO_SharedSmithingResearch.IsResearchableItem(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
        return CanItemBeSmithingTraitResearched(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
                and IsNotLockedOrRetraitedItem(bagId, slotIndex)
    end

    function ZO_SharedSmithingResearch:Refresh()
        self.dirty = false

        self.researchLineList:Clear()
        local craftingType = GetCraftingInteractionType()

        local numCurrentlyResearching = 0

        local virtualInventoryList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, IsNotLockedOrRetraitedItem)
        PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, IsNotLockedOrRetraitedItem, virtualInventoryList)

        for researchLineIndex = 1, GetNumSmithingResearchLines(craftingType) do
            local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
            if numTraits > 0 then
                local researchingTraitIndex, areAllTraitsKnown = self:FindResearchingTraitIndex(craftingType, researchLineIndex, numTraits)
                if researchingTraitIndex then
                    numCurrentlyResearching = numCurrentlyResearching + 1
                end

                local expectedTypeFilter = ZO_CraftingUtils_GetSmithingFilterFromTrait(GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, 1))
                if expectedTypeFilter == self.typeFilter then
                    local itemTraitCounts = self:GenerateResearchTraitCounts(virtualInventoryList, craftingType, researchLineIndex, numTraits)
                    local data = { craftingType = craftingType, researchLineIndex = researchLineIndex, name = name, icon = icon, numTraits = numTraits, timeRequiredForNextResearchSecs = timeRequiredForNextResearchSecs, researchingTraitIndex = researchingTraitIndex, areAllTraitsKnown = areAllTraitsKnown, itemTraitCounts = itemTraitCounts }
                    self.researchLineList:AddEntry(data)
                end
            end
        end

        self.researchLineList:Commit()

        local maxResearchable = GetMaxSimultaneousSmithingResearch(craftingType)
        if numCurrentlyResearching >= maxResearchable then
            self.atMaxResearchLimit = true
        else
            self.atMaxResearchLimit = false
        end

        self:RefreshCurrentResearchStatusDisplay(numCurrentlyResearching, maxResearchable)

        if self.activeRow then
            self:OnResearchRowActivate(self.activeRow)
        end
    end
end

function ZO_SharedSmithingResearch:RefreshCurrentResearchStatusDisplay(currentlyResearching, maxResearchable)
    --Overridden in derived classes
end

function ZO_SharedSmithingResearch:ShowTraitsFor(data)
    self.slotPool:ReleaseAllObjects()

    local craftingType, researchLineIndex, numTraits = data.craftingType, data.researchLineIndex, data.numTraits
        
    -- store these to get access to them on refresh()
    self.craftingType = craftingType
    self.researchLineIndex = researchLineIndex
    self.numTraits = numTraits

    local currentAnchor = ZO_Anchor:New(TOPLEFT, self.control:GetNamedChild("TraitContainer"))

    local stride = 1
    local OFFSET_Y = 2

    for traitIndex = 1, numTraits do
        local traitType, _, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
        local durationSecs, timeRemainingSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)
        local slotControl = self.slotPool:AcquireObject()
        slotControl.owner = self

        slotControl.craftingType = craftingType
        slotControl.researchLineIndex = researchLineIndex
        slotControl.traitIndex = traitIndex

        slotControl.researchable = false

        slotControl.nameLabel:SetText(GetString("SI_ITEMTRAITTYPE", traitType))
        slotControl.traitType = traitType
        slotControl.traitDescription, slotControl.traitResearchSourceDescription, slotControl.traitMaterialSourceDescription = GetSmithingResearchLineTraitDescriptions(craftingType, researchLineIndex, traitIndex)
        if slotControl.traitResearchSourceDescription == "" then
            slotControl.traitResearchSourceDescription = nil
            slotControl.traitMaterialSourceDescription = nil
        end

        local icon = select(3, GetSmithingTraitItemInfo(traitType + 1))
        ZO_ItemSlot_SetupSlot(slotControl, 1, icon)

        self:SetupTraitDisplay(slotControl, data, known, durationSecs, traitIndex)

        ZO_Anchor_BoxLayout(currentAnchor, slotControl, traitIndex - 1, stride, 0, OFFSET_Y, slotControl:GetWidth(), slotControl:GetHeight(), 0, 0)
    end

    -- Let any subclasses know that slotpool controls have been released/acquired.
    self:OnControlsAcquired()
end

function ZO_SharedSmithingResearch:ActivateHighlight(row)
    if not row.fadeAnimation then
        row.fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", row:GetNamedChild("Highlight"))
        row.scaleAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IconSlotMouseOverAnimation", row.icon)
    end
    row.fadeAnimation:PlayForward()
    row.scaleAnimation:PlayForward()
end

function ZO_SharedSmithingResearch:DeactivateHighlight(row)
    if row.fadeAnimation then
        row.fadeAnimation:PlayBackward()
        row.scaleAnimation:PlayBackward()
    end
end

function ZO_SharedSmithingResearch:OnResearchRowActivate(row)
    self:SetupTooltip(row)

    self.activeRow = row
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    else
        self.owner:OnResearchSlotChanged()
    end
end

function ZO_SharedSmithingResearch:OnResearchRowDeactivate(row)
    self:ClearTooltip(row)

    self.activeRow = nil
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    else
        self.owner:OnResearchSlotChanged()
    end
end

function ZO_SharedSmithingResearch:IsResearchable()
    return (self.activeRow ~= nil) and self.activeRow.researchable and self:CanResearchCurrentTraitLine()
end

function ZO_SharedSmithingResearch:IsResearching()
    if self.activeRow then
        local activeRow = self.activeRow
        local durationSecs, timeRemainingSecs = GetSmithingResearchLineTraitTimes(activeRow.craftingType, activeRow.researchLineIndex, activeRow.traitIndex)
        return durationSecs ~= nil
    end
    return false
end

function ZO_SharedSmithingResearch:GetSelectedData()
    return self.researchLineList:GetSelectedData()
end

ZO_SharedSmithingResearchSelect = ZO_Object:Subclass()

function ZO_SharedSmithingResearchSelect:New(...)
    local researchSelect = ZO_Object.New(self)
    researchSelect:Initialize(...)
    return researchSelect
end

function ZO_SharedSmithingResearchSelect:Initialize(control)
    self.control = control
end

function ZO_SharedSmithingResearch:CanResearchCurrentTraitLine()
    local canResearchCurrentTraitLine = true
    for traitIndex = 1, self.numTraits do
        local durationSecs, timeRemainingSecs = GetSmithingResearchLineTraitTimes(self.craftingType, self.researchLineIndex, traitIndex)
        if durationSecs then
            canResearchCurrentTraitLine = false
            break
        end
    end
    return canResearchCurrentTraitLine
end

function ZO_SharedSmithingResearch:CanCancelResearch()
    return self.numTraits and not self:CanResearchCurrentTraitLine()
end

function ZO_SharedSmithingResearch:CancelResearch()
    local dialogData = {}
    dialogData.craftingType = self.craftingType
    dialogData.researchLineIndex = self.researchLineIndex

    local dialogParams = {}
    local researchingTrait = self:FindResearchingTraitIndex(self.craftingType, self.researchLineIndex, self.numTraits)
    local traitType, _, known = GetSmithingResearchLineTraitInfo(self.craftingType, self.researchLineIndex, researchingTrait)
    local researchLineName = GetSmithingResearchLineInfo(self.craftingType, self.researchLineIndex)
    dialogData.traitIndex = researchingTrait
    dialogParams.mainTextParams = { researchLineName, GetString("SI_ITEMTRAITTYPE", traitType), GetString(SI_PERFORM_ACTION_CONFIRMATION) }

    local dialogName = IsInGamepadPreferredMode() and ZO_GAMEPAD_CONFIRM_CANCEL_RESEARCH_DIALOG or "CONFIRM_CANCEL_RESEARCH"
    ZO_Dialogs_ShowPlatformDialog(dialogName, dialogData, dialogParams)
end