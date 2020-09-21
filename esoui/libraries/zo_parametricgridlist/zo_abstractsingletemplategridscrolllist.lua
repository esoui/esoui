----------------------
-- ZO_AbstractSingleTemplateGridScrollList
----------------------

ZO_GRID_SCROLL_LIST_AUTOFILL = true
ZO_GRID_SCROLL_LIST_DONT_AUTOFILL = false

ZO_AbstractSingleTemplateGridScrollList = ZO_AbstractGridScrollList:Subclass()

function ZO_AbstractSingleTemplateGridScrollList:New(...)
    return ZO_AbstractGridScrollList.New(self, ...)
end

function ZO_AbstractSingleTemplateGridScrollList:Initialize(control, autofillRows)
    ZO_AbstractGridScrollList.Initialize(self, control)
    self.controlsAddedSinceLastFill = 0
    self.autoFillRows = autofillRows or false
end

function ZO_AbstractSingleTemplateGridScrollList:SetHeaderTemplate(templateName, height, setupFunc, onHideFunc, resetControlFunc)
    self.headerOperationId = self:AddHeaderTemplate(templateName, height, setupFunc, onHideFunc, resetControlFunc)
end

function ZO_AbstractSingleTemplateGridScrollList:SetGridEntryTemplate(templateName, width, height, setupFunc, onHideFunc, resetControlFunc, spacingX, spacingY, centerEntries)
    self.entryOperationId = self:AddEntryTemplate(templateName, width, height, setupFunc, onHideFunc, resetControlFunc, spacingX, spacingY, centerEntries)
    self:RefreshEmptyCellData(width, spacingX)
end

-- Note: Order matters. When using this function, it must be called after SetGridEntryTemplate
function ZO_AbstractSingleTemplateGridScrollList:SetGridEntryVisibilityFunction(visiblityFunction)
    ZO_ScrollList_SetVisibilityFunction(self.list, self.entryOperationId, visiblityFunction)
end

function ZO_AbstractSingleTemplateGridScrollList:RefreshEmptyCellData(width, spacingX)
    local listWidth = self.list:GetWidth()
    local numCellsPerRow = zo_floor(listWidth / (width + spacingX))
    self.numCellsPerRow = numCellsPerRow
end

function ZO_AbstractSingleTemplateGridScrollList:AddEntry(data)
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
            -- data is only being kept for theoretical addon compat. There's no reason to have the entry data in the header operation, and no one should use it.
            ZO_ScrollList_AddOperation(self.list, self.headerOperationId, { header = gridHeaderData, data = data })
            if self.headerPostPadding > 0 then
                ZO_ScrollList_AddOperation(self.list, ZO_SCROLL_LIST_OPERATION_LINE_BREAK, { lineBreakAmount = self.headerPostPadding, indentX = self.indentAmount })
            end
        end
    end
    ZO_ScrollList_AddOperation(self.list, self.entryOperationId, data)
    self.controlsAddedSinceLastFill = self.controlsAddedSinceLastFill + 1
end

function ZO_AbstractSingleTemplateGridScrollList:FillRowWithEmptyCells(gridHeaderData)
    if self.autoFillRows then
        local numMissingCells = self.numCellsPerRow - zo_mod(self.controlsAddedSinceLastFill, self.numCellsPerRow)
        if numMissingCells ~= self.numCellsPerRow then -- the row was full, don't need to add any empty cells
            for i = 1, numMissingCells do
                ZO_ScrollList_AddOperation(self.list, self.entryOperationId, { gridHeaderData = gridHeaderData, isEmptyCell = true })
            end
        end
    end
    self.controlsAddedSinceLastFill = 0
end

function ZO_AbstractSingleTemplateGridScrollList:CommitGridList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    if #scrollData > 0 then -- only try to fill in a row if there exists a row to fill in
        self:FillRowWithEmptyCells(self.currentHeaderData)
    end
    ZO_AbstractGridScrollList.CommitGridList(self)
    self.controlsAddedSinceLastFill = 0
end
