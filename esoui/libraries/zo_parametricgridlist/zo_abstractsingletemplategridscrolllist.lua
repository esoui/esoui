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

function ZO_AbstractSingleTemplateGridScrollList:RefreshEmptyCellData(width, spacingX)
    local listWidth = self.list:GetWidth()
    local numCellsPerRow = zo_floor(listWidth / (width + spacingX))
    self.numCellsPerRow = numCellsPerRow
end

function ZO_AbstractSingleTemplateGridScrollList:AddEntry(data)
    local gridHeaderName = data.gridHeaderName
    if self.currentHeaderName ~= gridHeaderName then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        if self.currentHeaderName or #scrollData > 0 then
            -- we're starting a new section, so first make sure to fill out the last row of the previous section
            self:FillRowWithEmptyCells()
            ZO_ScrollList_AddOperation(self.list, ZO_SCROLL_LIST_OPERATION_LINE_BREAK, { lineBreakAmount = self.lineBreakAmount })
        end
        self.currentHeaderName = gridHeaderName
        if self.currentHeaderName and self.currentHeaderName ~= "" then
            ZO_ScrollList_AddOperation(self.list, self.headerOperationId, { header = gridHeaderName, data = data })
        end
    end
    ZO_ScrollList_AddOperation(self.list, self.entryOperationId, data)
    self.controlsAddedSinceLastFill = self.controlsAddedSinceLastFill + 1
end

function ZO_AbstractSingleTemplateGridScrollList:FillRowWithEmptyCells()
    if self.autoFillRows then
        local numMissingCells = self.numCellsPerRow - zo_mod(self.controlsAddedSinceLastFill, self.numCellsPerRow)
        if numMissingCells ~= self.numCellsPerRow then -- the row was full, don't need to add any empty cells
            for i = 1, numMissingCells do
                ZO_ScrollList_AddOperation(self.list, self.entryOperationId, { isEmptyCell = true })
            end
        end
    end
    self.controlsAddedSinceLastFill = 0
end

function ZO_AbstractSingleTemplateGridScrollList:CommitGridList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    if #scrollData > 0 then -- only try to fill in a row if there exists a row to fill in
        self:FillRowWithEmptyCells()
    end
    ZO_AbstractGridScrollList.CommitGridList(self)
    self.controlsAddedSinceLastFill = 0
end
