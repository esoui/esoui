ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE = "ZO_GridScrollList_Entry_Template_Keyboard"
ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE_DIMENSIONS_KEYBOARD = 32
ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD = "ZO_GridScrollList_Entry_Header_Template_Keyboard"

ZO_GRID_LIST_OPERATION_ADD_CELL = 1
ZO_GRID_LIST_OPERATION_ADD_HEADER = 2

FILL_ROW_WITH_EMPTY_CELLS = true

ZO_GridScrollList = ZO_CallbackObject:Subclass()

function ZO_GridScrollList:New(...)
    local list = ZO_CallbackObject.New(self)
    list:Initialize(...)
    return list
end

function ZO_GridScrollList:Initialize(control, fillRowWithEmptyCells)
    self.control = control

    self.container = control:GetNamedChild("Container")
    self.list = self.container:GetNamedChild("List")
    ZO_ScrollList_AddResizeOnScreenResize(self.list)
    self.scrollbar = self.list:GetNamedChild("ScrollBar")
    self.currentHeaderName = nil
    self.fillRowWithEmptyCells = fillRowWithEmptyCells or false
    self.rowCount = 0
end

function ZO_GridScrollList:SetLineBreakAmount(lineBreakAmount)
    self.lineBreakAmount = lineBreakAmount
end

function ZO_GridScrollList:SetYDistanceFromEdgeWhereSelectionCausesScroll(yDistanceFromEdgeWhereSelectionCausesScroll)
    ZO_ScrollList_SetYDistanceFromEdgeWhereSelectionCausesScroll(self.list, yDistanceFromEdgeWhereSelectionCausesScroll)
end

function ZO_GridScrollList:SetHeaderTemplate(templateName, height, setupFunc, onHideFunc, resetControlFunc)
    local SPACING_XY = 0
    local IS_SELECTABLE = false
    local WIDTH = nil
    ZO_ScrollList_AddControlOperation(self.list, ZO_GRID_LIST_OPERATION_ADD_HEADER, templateName, WIDTH, height, resetControlFunc, setupFunc, onHideFunc, SPACING_XY, SPACING_XY, IS_SELECTABLE)
end

function ZO_GridScrollList:SetGridEntryTemplate(templateName, width, height, setupFunc, onHideFunc, resetControlFunc, spacingX, spacingY, centerEntries)
    local IS_SELECTABLE = true
    ZO_ScrollList_AddControlOperation(self.list, ZO_GRID_LIST_OPERATION_ADD_CELL, templateName, width, height, resetControlFunc, setupFunc, onHideFunc, spacingX, spacingY, IS_SELECTABLE, centerEntries)
    self:RefreshEmptyCellData(width, spacingX)
end

function ZO_GridScrollList:RefreshEmptyCellData(width, spacingX)
    local listWidth = self.list:GetWidth()
    local numCellsPerRow = zo_floor(listWidth / (width + spacingX))
    self.numCellsPerRow = numCellsPerRow
end

function ZO_GridScrollList:AddEntry(data)
    if self.currentHeaderName ~= data.gridHeaderName then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        if self.currentHeaderName or #scrollData > 0 then
            self:FillRowWithEmptyCells()
            ZO_ScrollList_AddOperation(self.list, ZO_SCROLL_LIST_OPERATION_LINE_BREAK, { lineBreakAmount = self.lineBreakAmount })
        end
        self.currentHeaderName = data.gridHeaderName
        if self.currentHeaderName and self.currentHeaderName ~= "" then
            ZO_ScrollList_AddOperation(self.list, ZO_GRID_LIST_OPERATION_ADD_HEADER, { header = data.gridHeaderName })
        end
    end
    ZO_ScrollList_AddOperation(self.list, ZO_GRID_LIST_OPERATION_ADD_CELL, data)
    self.rowCount = self.rowCount + 1
end

function ZO_GridScrollList:FillRowWithEmptyCells()
    if self.fillRowWithEmptyCells then
        local numMissingCells = self.numCellsPerRow - zo_mod(self.rowCount, self.numCellsPerRow)
        if numMissingCells ~= self.numCellsPerRow then -- the row was full, don't need to add any empty cells
            for i = 1, numMissingCells do
                ZO_ScrollList_AddOperation(self.list, ZO_GRID_LIST_OPERATION_ADD_CELL, { isEmptyCell = true })
            end
        end
        self.rowCount = 0
    end
end

function ZO_GridScrollList:CommitGridList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    if #scrollData > 0 then -- only try to fill in a row if there exists a row to fill in
        self:FillRowWithEmptyCells()
    end
    ZO_ScrollList_Commit(self.list)
end

function ZO_GridScrollList:RefreshGridList()
    ZO_ScrollList_RefreshVisible(self.list)
end

function ZO_GridScrollList:RefreshGridListEntryData(entryData, overrideSetupCallback)
    ZO_ScrollList_RefreshVisible(self.list, entryData, overrideSetupCallback)
end

function ZO_GridScrollList:ClearGridList(retainScrollPosition)
    ZO_ScrollList_Clear(self.list)
    self.currentHeaderName = nil
    if not retainScrollPosition then
        ZO_Scroll_ResetToTop(self.list)
    end
end

function ZO_GridScrollList:HasEntries()
    local dataList = ZO_ScrollList_GetDataList(self.list)
    return #dataList > 0
end

function ZO_GridScrollList:AtTopOfGrid()
    return ZO_ScrollList_AtTopOfList(self.list)
end

function ZO_GridScrollList:GetData()
    return ZO_ScrollList_GetDataList(self.list)
end

do
    local ANIMATE_INSTANTLY = true

    function ZO_GridScrollList:ScrollDataToCenter(data)
        local dataIndex = ZO_ScrollList_GetDataIndex(self.list, data.dataEntry)
        ZO_ScrollList_SelectData(self.list, data)
        ZO_ScrollList_ScrollDataToCenter(self.list, dataIndex, ON_STOP_CALLBACK, ANIMATE_INSTANTLY)
    end
end

----------------------
-- Global functions --
----------------------

function ZO_DefaultGridHeaderSetup(control, data, selected)
    control:SetText(data.header)
end