ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE = "ZO_GridScrollList_Entry_Template_Keyboard"
ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE_DIMENSIONS_KEYBOARD = 32
ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD = "ZO_GridScrollList_Entry_Header_Template_Keyboard"

local GRID_LIST_OPERATION_ADD_CELL = 1
local GRID_LIST_OPERATION_ADD_HEADER = 2

ZO_GridScrollList = ZO_CallbackObject:Subclass()

function ZO_GridScrollList:New(...)
    local list = ZO_CallbackObject.New(self)
    list:Initialize(...)
    return list
end

function ZO_GridScrollList:Initialize(control)
    self.control = control

    self.container = control:GetNamedChild("Container")
    self.list = self.container:GetNamedChild("List")
    ZO_ScrollList_AddResizeOnScreenResize(self.list)
    self.scrollbar = self.list:GetNamedChild("ScrollBar")
    self.currentHeaderName = nil
end

function ZO_GridScrollList:SetLineBreakAmount(lineBreakAmount)
    self.lineBreakAmount = lineBreakAmount
end

function ZO_GridScrollList:SetHeaderTemplate(templateName, height, setupFunc, onHideFunc, resetControlFunc)
    local SPACING_XY = 0
    local IS_SELECTABLE = false
    local WIDTH = nil
    ZO_ScrollList_AddControlOperation(self.list, GRID_LIST_OPERATION_ADD_HEADER, templateName, WIDTH, height, resetControlFunc, setupFunc, onHideFunc, SPACING_XY, SPACING_XY, IS_SELECTABLE)
end

function ZO_GridScrollList:SetGridEntryTemplate(templateName, width, height, spacing, setupFunc, onHideFunc, resetControlFunc, spacingX, spacingY)
    local IS_SELECTABLE = true
    ZO_ScrollList_AddControlOperation(self.list, GRID_LIST_OPERATION_ADD_CELL, templateName, width, height, resetControlFunc, setupFunc, onHideFunc, spacingX, spacingY, IS_SELECTABLE)
end

function ZO_GridScrollList:AddEntry(data)
    if self.currentHeaderName ~= data.categoryName then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        if self.currentHeaderName or #scrollData > 0 then
            ZO_ScrollList_AddOperation(self.list, ZO_SCROLL_LIST_OPERATION_LINE_BREAK, { lineBreakAmount = self.lineBreakAmount })
        end
        self.currentHeaderName = data.categoryName
        ZO_ScrollList_AddOperation(self.list, GRID_LIST_OPERATION_ADD_HEADER, { header = data.categoryName })
    end
    ZO_ScrollList_AddOperation(self.list, GRID_LIST_OPERATION_ADD_CELL, data)
end

function ZO_GridScrollList:CommitGridList()
    ZO_ScrollList_Commit(self.list)
end

function ZO_GridScrollList:ClearGridList()
    ZO_Scroll_ResetToTop(self.list)
    ZO_ScrollList_Clear(self.list)
    self.currentHeaderName = nil
end

----------------------
-- Global functions --
----------------------

function ZO_DefaultGridEntrySetup(control, data, selected)
    if not control.icon then
        control.icon = control:GetNamedChild("Icon")
    end
    control.icon:SetTexture(data.iconFile)
end

function ZO_DefaultGridHeaderSetup(control, data, selected)
    control:SetText(data.header)
end