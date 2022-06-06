ZO_GRID_SCROLL_LIST_AUTOFILL = true
ZO_GRID_SCROLL_LIST_DONT_AUTOFILL = false

ZO_AbstractGridScrollList = ZO_InitializingCallbackObject:Subclass()

function ZO_AbstractGridScrollList:Initialize(control, autofillRows)
    self.control = control
    self.container = control:GetNamedChild("Container")
    self.list = self.container:GetNamedChild("List")
    ZO_ScrollList_AddResizeOnScreenResize(self.list)
    self.scrollbar = self.list:GetNamedChild("ScrollBar")
    self.currentHeaderName = nil -- Maintaining backwards compatability
    self.currentHeaderData = nil
    self.nextOperationId = 1
    self.indentAmount = 0
    self.headerPrePadding = 0
    self.headerPostPadding = 0
    self.templateOperationIds = {}
    self.autoFillRows = autofillRows or false
    self.controlsAddedSinceLastFill = 0
end

function ZO_AbstractGridScrollList:SetHeaderPrePadding(prePadding)
    self.headerPrePadding = prePadding
end

function ZO_AbstractGridScrollList:SetHeaderPostPadding(postPadding)
    self.headerPostPadding = postPadding
end

function ZO_AbstractGridScrollList:SetIndentAmount(indentAmount)
    self.indentAmount = indentAmount
    internalassert(self.nextOperationId == 1, "You have to call this function before adding templates or they won't get the indent amount")
end

function ZO_AbstractGridScrollList:SetYDistanceFromEdgeWhereSelectionCausesScroll(yDistanceFromEdgeWhereSelectionCausesScroll)
    ZO_ScrollList_SetYDistanceFromEdgeWhereSelectionCausesScroll(self.list, yDistanceFromEdgeWhereSelectionCausesScroll)
end

function ZO_AbstractGridScrollList:AddHeaderTemplate(templateName, height, setupFunc, onHideFunc, resetControlFunc)
    if self.templateOperationIds[templateName] == nil then
        local operationId = self.nextOperationId
        local SPACING_XY = 0
        local NOT_SELECTABLE = false
        local WIDTH = nil

        ZO_ScrollList_AddControlOperation(self.list, operationId, templateName, WIDTH, height, resetControlFunc, setupFunc, onHideFunc, SPACING_XY, SPACING_XY, self.indentAmount, NOT_SELECTABLE)
        ZO_ScrollList_SetTypeCategoryHeader(self.list, operationId, true)

        self.nextOperationId = self.nextOperationId + 1
        self.templateOperationIds[templateName] = operationId
        return operationId
    end

    return nil
end

function ZO_AbstractGridScrollList:AddEntryTemplate(templateName, width, height, setupFunc, onHideFunc, resetControlFunc, spacingX, spacingY, centerEntries, isSelectable)
    if self.templateOperationIds[templateName] == nil then
        local operationId = self.nextOperationId
        if isSelectable == nil then
            isSelectable = true
        end
        ZO_ScrollList_AddControlOperation(self.list, operationId, templateName, width, height, resetControlFunc, setupFunc, onHideFunc, spacingX, spacingY, self.indentAmount, isSelectable, centerEntries)

        self.nextOperationId = self.nextOperationId + 1
        self.templateOperationIds[templateName] = operationId

        if self.autoFillRows then
            assert(type(width) == "number", "AutoFillRows is not supported with dynamic width entry templates.")
            local listWidth = self.list:GetWidth()
            local numCellsPerRow = zo_floor(listWidth / (width + spacingX))
            if self.numCellsPerRow then
                assert(self.numCellsPerRow == numCellsPerRow, "AutoFillRows is only supported when the number of cells per row is consistent regardless of the entry templates used.")
            else
                self.numCellsPerRow = numCellsPerRow
            end
        end

        return operationId
    end

    return nil
end

function ZO_AbstractGridScrollList:SetEntryTemplateVisibilityFunction(templateName, visiblityFunction)
    local operationId = self.templateOperationIds[templateName]
    if operationId then
        ZO_ScrollList_SetVisibilityFunction(self.list, operationId, visiblityFunction)
    end
end

function ZO_AbstractGridScrollList:SetEntryTemplateEqualityFunction(templateName, equalityFunction)
    local operationId = self.templateOperationIds[templateName]
    if operationId then
        ZO_ScrollList_SetEqualityFunction(self.list, operationId, equalityFunction)
    end
end

function ZO_AbstractGridScrollList:SetAutoFillEntryTemplate(templateName)
    self.autoFillRowsOperationId = self.templateOperationIds[templateName]
end

function ZO_AbstractGridScrollList:AddEntry(data, templateName)
    local operationId = self.templateOperationIds[templateName]
    if operationId then
        local gridHeaderData = data.gridHeaderName or data.gridHeaderData
        if self.currentHeaderData ~= gridHeaderData then
            local scrollData = ZO_ScrollList_GetDataList(self.list)
            if self.currentHeaderData or #scrollData > 0 then
                -- we're starting a new section, so first make sure to fill out the last row of the previous section
                self:FillRowWithEmptyCells(self.currentHeaderData)
                ZO_ScrollList_AddOperation(self.list, ZO_SCROLL_LIST_OPERATION_LINE_BREAK, { lineBreakAmount = self.headerPrePadding })
            end
            self.currentHeaderData = gridHeaderData
            self.currentHeaderName = gridHeaderData -- Maintaining backwards compatability
            if self.currentHeaderData and self.currentHeaderData ~= "" then
                local headerOperationId = self.templateOperationIds[data.gridHeaderTemplate]
                -- data is only being kept for theoretical addon compat. There's no reason to have the entry data in the header operation, and no one should use it.
                ZO_ScrollList_AddOperation(self.list, headerOperationId, { header = gridHeaderData, data = data}) 
                if self.headerPostPadding > 0 then
                    ZO_ScrollList_AddOperation(self.list, ZO_SCROLL_LIST_OPERATION_LINE_BREAK, { lineBreakAmount = self.headerPostPadding, indentX = self.indentAmount })
                end
            end
        end
        ZO_ScrollList_AddOperation(self.list, operationId, data)
        self.controlsAddedSinceLastFill = self.controlsAddedSinceLastFill + 1
    end
end

function ZO_AbstractGridScrollList:FillRowWithEmptyCells(gridHeaderData)
    if self.autoFillRows and self.autoFillRowsOperationId then
        local numMissingCells = self.numCellsPerRow - zo_mod(self.controlsAddedSinceLastFill, self.numCellsPerRow)
        if numMissingCells ~= self.numCellsPerRow then -- the row was full, don't need to add any empty cells
            for i = 1, numMissingCells do
                ZO_ScrollList_AddOperation(self.list, self.autoFillRowsOperationId, { gridHeaderData = gridHeaderData, isEmptyCell = true })
            end
        end
    end
    self.controlsAddedSinceLastFill = 0
end

function ZO_AbstractGridScrollList:CommitGridList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    if #scrollData > 0 then -- only try to fill in a row if there exists a row to fill in
        self:FillRowWithEmptyCells(self.currentHeaderData)
    end
    ZO_ScrollList_Commit(self.list)
end

function ZO_AbstractGridScrollList:RecalculateVisibleEntries()
    -- At present determining which entries are visible is done in the commit
    -- But use a different function signature so we don't do any other behavior that might come with a call to CommitGridList in the future.
    -- CommitGridList is generally understood to be used after you add/remove entries from the list
    ZO_ScrollList_Commit(self.list)
end

function ZO_AbstractGridScrollList:IsSelectionOfTemplateType(templateName)
    local operationId = self.templateOperationIds[templateName]
    if operationId then
        local selectedData = ZO_ScrollList_GetSelectedData(self.list)
        if selectedData.dataEntry.typeId == operationId then
            return true
        end
    end
    return false
end

function ZO_AbstractGridScrollList:RefreshGridList()
    ZO_ScrollList_RefreshVisible(self.list)
end

function ZO_AbstractGridScrollList:RefreshGridListEntryData(entryData, overrideSetupCallback)
    ZO_ScrollList_RefreshVisible(self.list, entryData, overrideSetupCallback)
end

function ZO_AbstractGridScrollList:ClearGridList(retainScrollPosition)
    ZO_ScrollList_Clear(self.list)
    self.currentHeaderName = nil -- Maintaining backwards compatability
    self.currentHeaderData = nil
    if not retainScrollPosition then
        ZO_Scroll_ResetToTop(self.list)
    end
end

function ZO_AbstractGridScrollList:HasEntries()
    local dataList = ZO_ScrollList_GetDataList(self.list)
    return #dataList > 0
end

function ZO_AbstractGridScrollList:AtTopOfGrid()
    return ZO_ScrollList_AtTopOfList(self.list)
end

function ZO_AbstractGridScrollList:GetData()
    return ZO_ScrollList_GetDataList(self.list)
end

function ZO_AbstractGridScrollList:GetControlFromData(data)
    return ZO_ScrollList_GetDataControl(self.list, data)
end

function ZO_AbstractGridScrollList:ScrollDataToCenter(data, onScrollCompleteCallback, animateInstantly)
    local dataIndex = ZO_ScrollList_GetDataIndex(self.list, data.dataEntry)
    if internalassert(dataIndex ~= nil) then
        ZO_ScrollList_SelectData(self.list, data)
        ZO_ScrollList_ScrollDataToCenter(self.list, dataIndex, onScrollCompleteCallback, animateInstantly)
    end
end

function ZO_AbstractGridScrollList:SelectData(data)
    local dataIndex = ZO_ScrollList_GetDataIndex(self.list, data.dataEntry)
    if internalassert(dataIndex ~= nil) then
        ZO_ScrollList_SelectData(self.list, data)
    end
end

function ZO_AbstractGridScrollList:SetAutoSelectToMatchingDataEntry(dataEntry)
    ZO_ScrollList_SetAutoSelectToMatchingDataEntry(self.list, dataEntry)
end

function ZO_AbstractGridScrollList:GetScrollValue()
    return ZO_ScrollList_GetScrollValue(self.list)
end

function ZO_AbstractGridScrollList:ScrollToValue(value, onScrollCompleteCallback, animateInstantly)
    ZO_ScrollList_ScrollRelative(self.list, value, onScrollCompleteCallback, animateInstantly)
end

function ZO_AbstractGridScrollList:ResetToTop()
    ZO_Scroll_ResetToTop(self.list)
end

function ZO_AbstractGridScrollList:AddLineBreak(lineBreakAmount)
    ZO_ScrollList_AddOperation(self.list, ZO_SCROLL_LIST_OPERATION_LINE_BREAK, { lineBreakAmount = lineBreakAmount })
end

----------------------
-- Global functions --
----------------------

function ZO_DefaultGridHeaderSetup(control, data, selected)
    control:SetText(data.header)
end

function ZO_DefaultGridEntrySetup(control, data, list)
    if not control.icon then
        control.icon = control:GetNamedChild("Icon")
    end

    local icon = control.icon

    if data.iconColor then
        icon:SetColor(data.iconColor:UnpackRGBA())
    end

    if data.iconDesaturation then
        icon:SetDesaturation(data.iconDesaturation)
    end

    if data.textureSampleProcessingWeights then
        for type, weight in pairs(data.textureSampleProcessingWeights) do
            icon:SetTextureSampleProcessingWeight(type, weight)
        end
    end

    local iconFile = data.iconFile or data.icon or (data.GetIcon and data:GetIcon())
    if iconFile then
        icon:SetTexture(iconFile)
        icon:SetHidden(false)
    else
        icon:SetHidden(true)
    end
end

do
    local g_gridEntryScaleAnimationProvider = ZO_ReversibleAnimationProvider:New("ZO_GridEntry_IconSelectedAnimation")

    function ZO_GridEntry_SetIconScaledUp(control, scaledUp, instant)
        if control.icon then
            if scaledUp then
                g_gridEntryScaleAnimationProvider:PlayForward(control.icon, instant)
            else
                g_gridEntryScaleAnimationProvider:PlayBackward(control.icon, instant)
            end
        end
    end

    function ZO_GridEntry_SetIconScaledUpInstantly(control, scaledUp)
        ZO_GridEntry_SetIconScaledUp(control, scaledUp, true)
    end
end

function ZO_AbstractGridScrollList:GetSelectedData()
    return ZO_ScrollList_GetSelectedData(self.list)
end